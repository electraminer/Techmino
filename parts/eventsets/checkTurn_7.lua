local SLOW_TIME_CONTROLS = {
    mainTime = 60 * 60 * 15,
    turnTime = 60 * 30,
    periodTime = 60 * 30,
    increment = false,
    periods = 5,
    autoCommit = false,
}

local DEFAULT_TIME_CONTROLS = {
    mainTime = 60 * 60 * 10,
    turnTime = 60 * 15,
    periodTime = 60 * 15,
    increment = true,
    periods = 5,
    autoCommit = false,
}

local RAPID_TIME_CONTROLS = {
    mainTime = 60 * 60 * 5,
    turnTime = 60 * 10,
    periodTime = 60 * 10,
    increment = true,
    periods = 5,
    autoCommit = false,
}

local BLITZ_TIME_CONTROLS = {
    mainTime = 60 * 60 * 3,
    turnTime = 60 * 5,
    periodTime = 60 * 10,
    increment = true,
    periods = 5,
    autoCommit = true,
}

function getInitialPlayers()
    local players = {}
    for _,P in ipairs(PLAYERS) do
        table.insert(players, P.sid)
    end
    table.sort(players)
    return players
end

local function getPlayerObject(player)
    for _,P in ipairs(PLAYERS) do
        if P.sid == player then
            return P
        end
    end
end


function deepCopy(inputs, outputs, whitelists, blacklists)
    -- This is a list of the tables found in the input.
    local tables = inputs
    -- This is a map mapping tables in the input to tables in the output
    local tableMap = {}
    for i=1,#inputs do
        local t = tables[i]
        if i <= #outputs then
            tableMap[t] = outputs[i]
        else
            tableMap[t] = {}
        end
    end

    function allowed(i, k)
        local allowed = true
        if whitelists[i] then
            allowed = false
            for _,x in ipairs(whitelists[i]) do
                if x == k then
                    allowed = true
                end
            end
        end
        if blacklists[i] then
            for _,x in ipairs(blacklists[i]) do
                if x == k then
                    allowed = false
                end
            end
        end
        return allowed
    end

    -- Process each table to find all tables and make new table equivalents.
    local i = 1
    while i <= #tables do
        local t = tables[i]
        for k, v in pairs(t) do
            if type(v) == "table" and allowed(i, k) then
                if not tableMap[v] then
                    table.insert(tables, v)
                    tableMap[v] = {}
                end
            end
        end
        i = i + 1
    end

    -- Copy each table from the old table to the new table, replacing all tables with their equivalents.
    local newTables = {}
    for i=1,#tables do
        local oldTable = tables[i]
        local newTable = tableMap[oldTable]
        local metatable = getmetatable(oldTable)
        setmetatable(newTable, metatable)
        -- Clear the new table
        for k, v in pairs(newTable) do
            if allowed(i, k) then
                newTable[k] = nil
            end
        end
        for k, v in pairs(oldTable) do
            if allowed(i, k) then
                if type(k) == "table" then
                    MES.new("warn", "Found a table with keys as tables - this may go wrong!")
                end
                if type(v) == "table" then
                    newTable[k] = tableMap[v]
                else 
                    newTable[k] = v
                end
            end
        end

        table.insert(newTables, newTable)
    end

    return newTables
end


local function savestateCtx(P)
    local saved = {P, P.modeData.speculativeAtk}
    local whitelist = {{
        'field', 'visTime',
        'cur', 'curX', 'curY', 'ghoY',
        'nextQueue', 'holdQueue', 'stat',
        'combo', 'b2b', 'b3b',
        'atkBuffer', 'atkBufferSum', 'netAtk',
        'waiting', 'holdTime'
    }, false}
    local blacklist = {false, false}
    return saved, whitelist, blacklist
end

function saveState(P)
    local ctx, whitelists, blacklists = savestateCtx(P)
    local state = deepCopy(ctx, {}, whitelists, blacklists)
    table.insert(P.modeData.savestates, {
        state = state,
        atkTarget = P.modeData.lastTarget,
    })
end

function loadState(P)
    local savestate = P.modeData.savestates[#P.modeData.savestates]
    local ctx, whitelists, blacklists = savestateCtx(P)
    deepCopy(savestate.state, ctx, whitelists, blacklists)
end


-- -- TURN ORDER

function initTurnOrder(P)
    local players = P.modeData.players
    local turnOrder = {}
    for _,player in ipairs(players) do
        local position = P.modeData.turnOrderRND:random(#turnOrder + 1)
        table.insert(turnOrder, position, player)
    end
    P.modeData.turnOrder = turnOrder
    P.modeData.turn = 1
end

function passTurn(P)
    P.modeData.turn = P.modeData.turn + 1
    if P.modeData.turn > #P.modeData.turnOrder then
        P.modeData.turn = 1
    end
    if P.modeData.turnOrder[P.modeData.turn] == P.sid then
        startTurn(P)
    end
end

function removePlayer(P, player)
    local index = 0
    for i,p in P.modeData.turnOrder do
        if player == p then
            index = i
        end
    end
    if P.modeData.turn > index then
        P.modeData.turn = P.modeData.turn - 1
    end
    table.remove(P.modeData.turnOrder, index)
    if P.modeData.turnOrder[P.modeData.turn] == P.sid then
        beginTurn(P)
    end
end

local function getTarget(P)
    local turn = 0
    for i,player in ipairs(P.modeData.turnOrder) do
        if player == P.sid then
            turn = i
        end
    end
    turn = turn + 1
    if turn > #P.modeData.turnOrder then
        turn = 1
    end
    -- TODO make this work in teams mode
    return P.modeData.turnOrder[turn]
end

function startTurn(P)
    P.modeData.startedTurnAtPiece = P.stat.piece
    P.modeData.startingPeriod = P.modeData.period
    
    -- Clear savestates
    P.modeData.savestates = {}

    if P.modeData.fakedQueue == true then
        -- Remove the fake piece from the start of the next queue
        table.remove(P.nextQueue, 1)
        P.modeData.fakedQueue = false
        saveState(P)
    end
    
    P.control = true
    P.waiting = 0
end

function undo(P)
    -- Undo disabled during periods
    if P.modeData.period > 0 then return end

    -- Remove the first savestate so you actually go to the previous piece
    local savestate = nil
    if #P.modeData.savestates >= 2 then
        local savestate = P.modeData.savestates[#P.modeData.savestates]
        if savestate.atkTarget ~= 0 then
            P:extraEvent('undoAtk', savestate.atkTarget)
        end
        P.modeData.savestates[#P.modeData.savestates] = nil
    end
    if #P.modeData.savestates >= 1 then
        loadState(P)
    end
end

local function undoAtk(P)
    local atk = table.remove(P.atkBuffer, #P.atkBuffer)
    P.atkBufferSum = P.atkBufferSum - atk.amount
end

-- Generate a unique RNG queue for each player
local function initRNG(P)
    -- Before we make the RNG unique, create a synced turn RNG
    local seed = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
    P.modeData.turnOrderRND = love.math.newRandomGenerator(seed)
    -- First burn a value for each SID count
    for i=1,P.sid do
        local burn = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
    end
    -- We are adding two separate generations together to ensure no correlation.
    local seed = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
    P.modeData.uniqueRND = love.math.newRandomGenerator(seed)
    -- Replace the RNG queues with the new unique ones.
    P.seqRND = love.math.newRandomGenerator(seed)
    P.holeRND = love.math.newRandomGenerator(seed)

    -- Replace the existing next queue with a new one.
    -- Previously, we generated 10 pieces, so generate 4 more to round out the bag.
    for _=1,4 do
        P:newNext()
    end
    -- Now create a new bag. Everyone will get the same non-bag first piece.
    P.nextQueue = {P.nextQueue[1]}
    -- Piece is gray to indicate it's not part of the bag.
    P.nextQueue[1].color = 20
    for _=1,7 do
        P:newNext()
    end
end

local getSeqGen = require "parts.player.seqGenerators"
function initSpeculativeNext(P)
    local newNext = P.newNext
    -- Adding a next piece is converted into speculation.
    P.modeData.lastCommitAtPiece = 0
    function P:newNext()
        -- Do nothing, the piece counter will increment to allow speculation
        if P.modeData.lastCommitAtPiece == -1 then
            -- During speculation, the function might get called recursively so work in this case.
            newNext(P)
        end
    end
    -- Speculation is converted into generating next pieces on a commit.
    function P:commitNewNext()
        P.modeData.duringSpeculaton = true
        local speculativeNext = P.stat.piece - P.modeData.lastCommitAtPiece
        P.modeData.lastCommitAtPiece = -1
        for _=1,speculativeNext do
            newNext(P)
        end
        P.modeData.duringSpeculaton = nil
        P.modeData.lastCommitAtPiece = P.stat.piece
    end
end

function initSpeculativeAtk(P)
    local garbageRise = P.garbageRise
    -- Rising garbage is converted into speculation.
    P.modeData.speculativeAtk = {}
    local garbageRise = P.garbageRise
    function P:garbageRise(color, amount, line)
        garbageRise(P, color, amount, 1023)
        table.insert(P.modeData.speculativeAtk, amount)
        tryAutoCommit(self) -- Try auto commit immediately, to ensure ColdClear never sees filled lines.
    end
    -- Speculation is converted into generating garbage holes on a commit.
    P.modeData.atkLast = P.holeRND:random(10)
    function P:commitGarbageRise()
        local totalAtk = 0
        for _,atk in ipairs(P.modeData.speculativeAtk) do
            totalAtk = totalAtk + atk
        end
        for _,atk in ipairs(P.modeData.speculativeAtk) do
            local position = P.holeRND:random(9)
            if position >= P.modeData.atkLast then
                position = position + 1
            end
            P.modeData.atkLast = position
            for _=1,atk do
                P.field[totalAtk][position] = 0
                totalAtk = totalAtk - 1
            end
        end
        P.modeData.speculativeAtk = {}
    end
end

function commit(P)
    P:commitNewNext()
    P:commitGarbageRise()
    -- Clear savestates
    P.modeData.savestates = {}
    saveState(P)
    -- Pass turn
    local turnPieces = P.stat.piece - P.modeData.startedTurnAtPiece
    if turnPieces == 7 then
        P.control = false
        initTurnTimer(P)
        P:extraEvent('passTurn')
    end
end

function tryAutoCommit(P)
    if P.modeData.period > 0 or P.type == 'bot' or P.gameEnv.timeControls.autoCommit then
        commit(P)
    end
end

-- Initialize the game to the default speed settings
function initSpeedSettings(P)
    P.gameEnv.drop = 1e99
    P.gameEnv.lock = 1e99
    P.gameEnv.garbageSpeed = 1e99
    P.gameEnv.pushSpeed = 1e99
    P.gameEnv.holdCount = 1e99
end

-- Initialize the main chess clock for a player
function initMainTimer(P)
    P.modeData.mainTime = P.gameEnv.timeControls.mainTime
    P.modeData.turnTime = 0
    P.modeData.period = 0
    P.modeData.startingPeriod = 0
end

-- Reset the chess clock for a player's next turn
function initTurnTimer(P)
    -- Ensure period is advanced if the main time is 0, for instance if playing with no main time
    if P.modeData.mainTime == 0 and P.modeData.period == 0 then
        advancePeriod(P)
    end
    if P.modeData.period > P.gameEnv.timeControls.periods then
        -- Sudden Death
        P.modeData.turnTime = 0
    elseif P.modeData.period > 0 then
        -- Start with period time if in periods
        P.modeData.turnTime = P.gameEnv.timeControls.periodTime
    else
        -- Check increment and use main time
        if USE_INCREMENT then
            P.modeData.mainTime = P.modeData.mainTime + P.modeData.turnTime
        end
        P.modeData.turnTime = P.gameEnv.timeControls.turnTime
    end
end


-- Tick the player's chess clock each frame
function tickChessTimer(P)
    if P.modeData.turnTime > 0 then
        P.modeData.turnTime = P.modeData.turnTime - 1
    elseif P.modeData.mainTime > 0 then
        P.modeData.mainTime = P.modeData.mainTime - 1
    elseif P.modeData.period < P.gameEnv.timeControls.periods then
        advancePeriod(P)
    else
        -- Once the final period has expired, enter sudden death with Step Reset
        P.gameEnv.easyFresh = false
        P.modeData.period = P.gameEnv.timeControls.periods + 1
        P.modeData.turnTime = P.modeData.turnTime - 1
    end
end

-- Advance the player's period to raise the speed level
function advancePeriod(P)
    -- Advance period and reset period time
    P.modeData.turnTime = P.gameEnv.timeControls.periodTime
    P.modeData.period = P.modeData.period + 1
    -- Once periods begin, lock delay is enabled
    P.gameEnv.lock = 30
    P.lockDelay = 30
    -- Increase gravity speed
    local progression = (P.modeData.period - 1) / (P.gameEnv.timeControls.periods - 1)
    local blocksPerSecond = 2 * 10 ^ (progression * 2.5)
    local gravity = 60 / blocksPerSecond
    if progression == 2.5 then
        gravity = 0
    end
    P.gameEnv.drop = gravity
    P.dropDelay = gravity
end

return {
    task = function(P)
        P.gameEnv.timeControls = DEFAULT_TIME_CONTROLS

        initMainTimer(P)
        initTurnTimer(P)
        initSpeedSettings(P)

        initRNG(P)
        initSpeculativeNext(P)
        initSpeculativeAtk(P)
        
        -- Disable sending garbage
        P.strength = -8
        P.modeData.savestates = {}

        -- Wait until the countdown finishes
        while P.frameRun < 179 do
            coroutine.yield()
        end
        P.control = false

        P.modeData.players = getInitialPlayers()
        initTurnOrder(P)

        -- Fake the queue for non-active players so you can see the piece that was spawned
        table.insert(P.nextQueue, 1, P.cur)
        P.modeData.fakedQueue = true

        if P.modeData.turnOrder[1] == P.sid then
            startTurn(P)
        end
        while true do
            if P.control then
                if P.waiting > 1e98 then
                    -- Auto pass turn if waiting at the end of your turn
                    tryAutoCommit(P)
                end
                tickChessTimer(P)
            end
            coroutine.yield()
        end
    end,
    
    hook_spawn = function(P)
        saveState(P)
        tryAutoCommit(P)
    end,

    hook_drop = function(P)
        -- Send attack
        local totalAtk = -P.lastPiece.atk
        local cancelledAtk = P:cancel(totalAtk)
        local sentAtk = totalAtk - cancelledAtk
        local target = nil
        if sentAtk > 0 then
            target = getTarget(P)
            P:attack(getPlayerObject(target), sentAtk, 1, 1023) 
        end
        P.modeData.lastTarget = target

        -- End turn
        local turnPieces = P.stat.piece - P.modeData.startedTurnAtPiece
        if turnPieces == 7 then
            P.waiting = 1e99
            saveState(P)
        end
        -- Auto commit
        tryAutoCommit(P)
    end,
    
    hook_die = function(P)
        -- Clear saved garbage
        P.modeData.speculativeAtk = {}
        -- Eliminate player if they have no stocks left
        if P.result then
            P:extraEvent('removePlayer', P.sid)
        end
    end,
    
    fkey1 = function(P)
        commit(P)
    end,

    fkey2 = function(P)
        undo(P)
    end,

    extraEvent = {
        {'passTurn', 0},
        {'undoAtk', 1},
        {'removePlayer', 1},
    },

    extraEventHandler = {
        passTurn = function(P, source)
            passTurn(P)
        end,
        undoAtk = function(P, source, target)
            if P.sid == target then
                undoAtk(P)
            end
        end,
        removePlayer = function(P, source, player)
            removePlayer(P, player)
        end,
    },

    -- VISUALS
    mesDisp=function(P)
        local function toHumanTime(time)
            time = time + 59
            time = MATH.floor(time / 60)
            local seconds = time % 60
            time = MATH.floor(time / 60)
            local minutes = time % 60
            time = MATH.floor(time / 60)
            local hours = time
        
            if hours >= 1 then
                return string.format("%d:%02d:%02d", hours, minutes, seconds)
            else
                return string.format("%d:%02d", minutes, seconds)
            end
        end
        
        local function toHumanTimeShort(time)
            time = time + 59
            time = MATH.floor(time / 60)
            local seconds = time % 60
            time = MATH.floor(time / 60)
            local minutes = time
        
            if minutes >= 1 then
                return string.format("%d:%02d", minutes, seconds)
            else
                return string.format("%d", seconds)
            end
        end
        
        local dialNeedle=TEXTURE.dial.needle
        local function drawDial(x, y, time, timeProportion)
            local theta = MATH.tau * (timeProportion%1) - MATH.tau/4
            -- Dial back - no longer opaque to cover other dial
            GC.setColor(COLOR.black)
            GC.circle('fill', x, y, 36)
            -- Dial needle
            GC.setColor(COLOR.white)
            GC.draw(dialNeedle, x, y, theta, nil, nil, 1, 1)
            -- Dial border
            GC.setLineWidth(3)
            GC.setColor(COLOR.gray)
            if timeProportion > 1 then
                GC.setColor(COLOR.white)
            end
            GC.circle('line', x, y, 37)
            -- Filled dial border
            GC.setColor(COLOR.white)
            if timeProportion > 1 then
                GC.setColor(COLOR.green)
            end
            GC.arc('line','open', x, y, 37, -MATH.tau/4, theta)
            -- Time display
            setFont(30)
            if time > 0 then
                GC.mStr(toHumanTimeShort(time), x, y-21)
            end
        end
        
        local function drawTimeAlert(alert, caption, frames)
            GC.push('transform')
                -- Center of the field
                GC.translate(300,300)
        
                -- Default color is white
                local r,g,b = 1,1,1
                -- Special colors for 3, 2, 1
                if alert == "3" then
                    r,g,b = 0.7,0.8,0.98
                elseif alert == "2" then
                    r,g,b = 0.98,0.85,0.75
                elseif alert == "1" then
                    r,g,b = 1,0.7,0.7
                end
        
                -- Fading caption
                setFont(30)
                GC.setColor(r,g,b,frames/60)
                GC.mStr(caption,0,-100)
        
                -- Special styles for 5, 4, 3, 2, 1
                local fancy = false
                if alert == "5" or alert == "4" or alert == "3" or alert == "2" or alert == "1" then
                    fancy = true
                end
                if alert == "3" then
                    if frames > 45 then GC.rotate((frames-45)^2*.00355) end
                elseif alert == "2" then
                    if frames > 45 then GC.scale(1+(frames/15-3)^2,1) end
                elseif alert == "1" then
                    if frames > 45 then GC.scale(1,1+(frames/15-3)^2) end
                end
        
        
                setFont(100)
        
                -- Fancy animation where the number gets bigger and smaller
                if fancy then
                    GC.setColor(r,g,b)
                    GC.push('transform')
                        GC.mStr(alert,0,-70)
                        GC.scale(MATH.min(frames/20,1)^.4)
                    GC.pop()
        
                    GC.scale((1.5-frames/60*.6)^1.5)
                end
                
                -- Fading number
                GC.setColor(r,g,b,frames/60)
                GC.mStr(alert,0,-70)
        
            GC.pop()
        end

		-- Display time remaining
        setFont(30)
        if P.modeData.period > P.gameEnv.timeControls.periods then
            GC.mStr("DEATH", 539, 465)
            drawDial(539, 545, 0, 0)
        elseif P.modeData.period > 0 then
            GC.mStr("PERIOD "..P.modeData.period, 539, 465)
            drawDial(539, 545, P.modeData.turnTime, P.modeData.turnTime / P.gameEnv.timeControls.periodTime)
        elseif P.modeData.turnTime == 0 then
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, 0, P.modeData.mainTime / P.gameEnv.timeControls.mainTime)
        else
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, P.modeData.turnTime, P.modeData.turnTime / P.gameEnv.timeControls.turnTime)
        end

        if not P.control then
            return
        end

        -- Display turn status
        local pieces = P.stat.piece - P.modeData.startedTurnAtPiece
        local piecesRemaining = 7 - pieces
        if P.waiting > 1e98 then
            local animationCycle = (P.frameRun % 60) / 60
            animationCycle = MATH.abs(animationCycle - 0.5) * 2
            GC.setColor(1, 1, 1, 0.5 + 0.5*animationCycle)
            local key = 'Function 1'
            for k,v in pairs(KEY_MAP.keyboard) do
                if v == 9 then
                    key = "Press "..string.upper(k)
                    break
                end
            end
            GC.mStr(key.." to pass", 300, 10)
        elseif piecesRemaining == 1 then
            GC.mStr(piecesRemaining.." placement left", 300, 10)
        else
            GC.mStr(piecesRemaining.." placements left", 300, 10)
        end

        -- Display timer alert message
        local caption = "MOVE TIME"
        local time = P.modeData.turnTime
        if P.modeData.turnTime == 0 then
            time = P.modeData.mainTime
            caption = "MAIN TIME"
        elseif P.modeData.period > 0 then
            caption = "PERIOD "..P.modeData.period
        end
        local frames = time % 60
        time = time + 59
        time = math.floor(time / 60)
        local seconds = time % 60
        time = math.floor(time / 60)
        local minutes = time % 60
        time = math.floor(time / 60)
        local hours = time % 60

        -- Get the time alert if there is any
        local alert = nil
        if hours >= 1 then
            if minutes == 0 and seconds == 0 then
                alert = string.format("%dh", hours)
            end
        elseif minutes >= 1 then
            if (minutes == 30 or minutes == 20 or minutes == 15 or minutes == 10 or minutes <= 5) and seconds == 0 then
                alert = string.format("%d:00", minutes)
            end
        elseif seconds == 30 or seconds == 20 or seconds == 15 or seconds == 10 or seconds <= 5 then
            alert = string.format("%d", seconds)
        end

        -- If at the start of a new byo-yomi period, announce the speed increase
        if P.modeData.period ~= P.modeData.startingPeriod then
            if P.modeData.turnTime + 60 > P.gameEnv.timeControls.periodTime then
                caption = "SPEED UP"
                alert = "LV"..P.modeData.period
                if P.modeData.period == P.gameEnv.timeControls.periods then
                    alert = "20G"
                end
            end
            if P.modeData.period > P.gameEnv.timeControls.periods and P.modeData.turnTime > -60 then
                caption = "SUDDEN DEATH"
                alert = ""
                frames = P.modeData.turnTime + 60
            end
        end
        if alert then
            drawTimeAlert(alert, caption, frames)
        end
    end,
}