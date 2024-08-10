local DEFAULT_TIME_CONTROLS = {
    mainTime: 60 * 60 * 15
    moveTime: 60 * 30
    periodTime: 60 * 30
    increment: true,
    periods: 5,
    autoCommit: false,
}

local function getInitialPlayers(player)
    local players = {}
    for _,P in PLAYERS do
        table.insert(players, P.sids)
    end
    return players
end

local function getPlayerObject(player)
    for _,P in players do
        if P.sid == player then
            return P
        end
    end
end

-- TURN ORDER

function generateTurnOrder(P, players, rnd)
    local turnOrder = {}
    for _,player in ipairs(players) do
        local position = rnd:random(#turnOrder + 1)
        table.insert(turnOrder, position, player)
    end
    P.modeData.turnOrder = turnOrder
    P.modeData.turn = 1
end

function passTurn(P)
    P.modeData.turn += 1
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
    if turn > #P.modeData.turnOrder then
        turn = 1
    end
    -- TODO make this work in teams mode
    return P.modeData.turnOrder[turn]
end

function endTurn(P)
    P.control = false
    if P.modeData.period > P.gameEnv.timeControls.periods then
        -- Sudden Death
        P.modeData.moveTime = 0
    elseif P.modeData.period > 0 then
        P.modeData.moveTime = P.gameEnv.timeControls.periodTime
    else
        if USE_INCREMENT then
            P.modeData.mainTime = P.modeData.mainTime + P.modeData.moveTime
        end
        P.modeData.moveTime = P.gameEnv.timeControls.moveTime
    end
end

function startTurn(P)
    P.modeData.releasedAtk = {}
    P.modeData.startedTurnAtPiece = P.stat.piece
    P.modeData.startingPeriod = P.modeData.period
    local lastSavestate = P.modeData.savestates[#P.modeData.savestates]
    P.modeData.savestates = {lastSavestate}
    
    if P.modeData.fakedQueue then
        -- Remove the fake piece from the start of the next queue
        table.remove(P.nextQueue, 1)
        P.modeData.fakedQueue = false
    end
    
    P.control = true
    P.waiting = 0
end

-- UNDO AND COMMIT

function revealQueue(P)
    local turns = P.stat.piece - P.modeData.lastCommit
    for i=1,turns do
        P:newNext(true)
    end
end

function revealAtk(P)
    local totalAtk = 0
    for _,atk in ipairs(P.modeData.releasedAtk) do
        totalAtk = totalAtk + atk
    end
    for _,atk in ipairs(P.modeData.releasedAtk) do
        local position = 0
        if P.modeData.atkLast == 0 then
            position = P.modeData.atkRND:random(10)
        else
            position = P.modeData.atkRND:random(9)
            if position >= P.modeData.atkLast then
                position = position + 1
            end
        end
        P.modeData.atkLast = position
        for i=1,atk do
            P.field[totalAtk][position] = 0
            totalAtk = totalAtk - 1
        end
    end
    P.modeData.speculativeAtk = {}
end

function commit(P)
    -- Reveal RNG
    local pieces = P.stat.piece - P.modeData.lastCommitAtPiece or P.modeData.startedTurnAtPiece
    revealQueue(P, pieces)
    revealAtk(P)
    -- Clear savestates
    local lastSavestate = P.modeData.savestates[#P.modeData.savestates]
    P.modeData.savestates = {lastSavestate}
    -- Update number of pieces placed
    P.modeData.lastCommitAtPiece = P.stat.piece
    local turnPieces = P.stat.piece - P.modeData.startedTurnAtPiece
    -- Pass turn
    if turnPieces == 7 then
        P.control = false
        endTurn(P)
        broadcastEvent('passTurn')
    end
end

function undo(P)
    -- Undo disabled when automatically committing
    if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
        return
    end

    local savestate = nil
    if #P.modeData.savestates >= 2 then
        P.modeData.savestates[#P.modeData.savestates] = nil
    end
    if #P.modeData.savestates >= 1 then
        loadState(state)
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
    local saved = {P, P.modeData.releasedAtk}
    local whitelist = {{
        'field', 'visTime',
        'cur', 'curX', 'curY', 'ghoY',
        'nextQueue', 'holdQueue', 'stat',
        'combo', 'b2b', 'b3b',
    }, false}
    local blacklist = {false, false}
    return saved, whitelist, blacklist
end

function saveState(P, atkTarget)
    local ctx, whitelists, blacklists = savestateCtx(P)
    local state = deepCopy(ctx, {}, whitelists, blacklists)
    table.insert(P.modeData.savestates, {
        state = state,
        atkTarget = atkTarget,
    })
end

function loadState(P)
    local savestate = P.modeData.savestates[#P.modeData.savestates]
    local ctx, whitelists, blacklists = savestateCtx(P)
    deepCopy(savestate.state, ctx, whitelists, blacklists)
    if savestate.atkTarget then
        broadcastEvent('undoAtk', atkTarget)
    end
end

-- Generate the unique queues for each player
local getSeqGen = require "parts.player.seqGenerators"
local function createUniqueQueues(P)
    -- First burn a value for each SID count
    for i=1,P.sid do
        local burn = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
    end
    -- We are adding two separate generations together to ensure no correlation.
    local seed = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
    P.modeData.seqRND = love.math.newRandomGenerator(seed)
    P.modeData.atkRND = love.math.newRandomGenerator(seed)
    -- Sequence generator like the bag rando
    P.modeData.seqGen = coroutine.create(getSeqGen(P.gameEnv.sequence))
    -- Bag status
    P.modeData.bagLineCounter = 0
    -- Last garbage hole position to avoid repeats
    P.modeData.atkLast = 0
end

local function newNextUniqueQueue(P)
    local status, piece = coroutine.resume(P.modeData.seqGen, P.modeData.seqRND, P.gameEnv.seqData)
    if not status then
        assert(piece == 'cannot resume dead coroutine')
    elseif piece then
        P:getNext(piece, P.modeData.bagLineCounter)
        P.modeData.bagLineCounter = 0
    else
        if P.gameEnv.bagLine then
            P.modeData.bagLineCounter = P.modeData.bagLineCounter+1
        end
        newNext(P)
    end
end

local function init(P)
    P.gameEnv.timeControls = DEFAULT_TIME_CONTROLS

    createUniqueQueues(P)

    -- Disable generating next pieces
    function P:newNext(force) end
    -- Replace the next queue
    P.nextQueue = {}
    for i=1,8 do
        newNextUniqueQueue(true)
    end
    -- Disable sending and recieving garbage
    P.badges = -8
    P.gameEnv.garbageSpeed = 0
    -- Garbage speed is instant
    P.gameEnv.pushSpeed = 1e99
    -- No gravity
    P.gameEnv.drop = 1e99
    P.dropDelay = 1e99
    P.gameEnv.lock = 1e99
    P.lockDelay = 1e99
    -- Start with no player turns active
    P.control = false
    -- Initialize chess clock
    P.modeData.mainTime = P.gameEnv.timeControls.mainTime
    P.modeData.moveTime = P.gameEnv.timeControls.periodTime
    P.modeData.period = 0
    P.modeData.startingPeriod = 0
    -- Set starting savestate
    P.modeData.savestates = {}
    saveState(P, nil)
end

local function advancePeriod(P)
    -- Advance period and reset period time
    P.modeData.moveTime = P.gameEnv.timeControls.periodTime
    P.modeData.period = P.modeData.period + 1
    -- Once periods begin lock delay is enabled
    P.gameEnv.lock = 30
    P.lockDelay = 30
    -- Increase gravity speed
    local blocksPerSecond = 2 * 10 ^ ((period - 1) / (totalPeriods - 1) * 2.5)
    local gravity = 60 / blocksPerSecond
    if period == totalPeriods then
        gravity = 0
    end
    P.gameEnv.drop = gravity
    P.dropDelay = gravity
end

local function undoAtk(P)
    table.remove(P.atkBuffer, #P.atkBuffer)
end

return {
    task = function(P)
        init(P)
        -- Wait until the countdown finishes
        while P.frameRun < 179 do
            coroutine.yield()
        end
        generateTurnOrder(P, getInitialPlayers())
        if P.modeData.turnOrder[1] == P.sid then
            startTurn(P)
        else 
            -- Fake the queue so you can see the piece that was spawned
            table.insert(P.nextQueue, 1, P.cur)
            P.modeData.fakedQueue = true
        end
        while true do
            if P.control then
                if P.waiting > 1e98 then
                    -- Auto pass turn if waiting at the end of your turn
                    if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
                        commit(P)
                    end
                end
                if P.modeData.moveTime > 0 then
                    P.modeData.moveTime = P.modeData.moveTime - 1
                elseif P.modeData.mainTime > 0 then
                    P.modeData.mainTime = P.modeData.mainTime - 1
                elseif P.modeData.period < TOTAL_PERIODS then
                    advancePeriod(P)
                else
                    -- Once the final period has expired, enter sudden death with Step Reset
                    P.gameEnv.easyFresh = false
                    P.modeData.period = TOTAL_PERIODS + 1
                    P.modeData.moveTime = P.modeData.moveTime - 1
                end
            end
            coroutine.yield()
        end
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
        -- Recieve attack
        if #P.clearedRow == 0 then
            for i,atk in ipairs(P.atkBuffer) do
                -- Store the attack in the table
                table.insert(P.modeData.releasedAtk, atk.amount)
                -- Receive the garbage
                atk.countdown = 0
            end
            P:garbageRelease()
        end
        local turnPieces = P.stat.piece - P.modeData.startedTurnAtPiece
        -- Save state
        saveState(P, target)
        -- End turn
        if turnPieces == 7 then
            P.waiting = 1e99
        end
        -- Auto commit
        if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
            commit(P)
        end
    end,
    
    hook_die = function(P)
        -- Clear saved garbage
        P.modeData.releasedAtk = {}
    end,

    fkey1 = commit,
    fkey2 = undo,
    
    disconnect_hook = removePlayer,

    extraEvents = {
        {'passTurn', 0}
        {'undoAtk', 1}
    },

    eventHandlers = {
        passTurn = function(P, sender)
            passTurn(P),
        end,
        undoAtk = function(P, sender, target)
            if P.sid == target then
                undoAtk(P)
            end
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
            drawDial(539, 545, P.modeData.moveTime, P.modeData.moveTime / P.gameEnv.timeControls.periodTime)
        elseif P.modeData.moveTime == 0 then
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, 0, P.modeData.mainTime / P.gameEnv.timeControls.mainTime)
        else
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, P.modeData.moveTime, P.modeData.moveTime / P.gameEnv.timeControls.moveTime)
        end

        if not P.control then
            return
        end

        -- Display turn status
        local piecesRemaining = 7 - P.stat.piece % 7
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
        local time = P.modeData.moveTime
        if P.modeData.moveTime == 0 then
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
            if (minutes == 30 or minutes == 20 or minutes == 10 or minutes <= 5) and seconds == 0 then
                alert = string.format("%d:00", minutes)
            end
        elseif seconds == 30 or seconds == 20 or seconds == 10 or seconds <= 5 then
            alert = string.format("%d", seconds)
        end

        -- If at the start of a new byo-yomi period, announce the speed increase
        if P.modeData.period ~= P.modeData.startingPeriod then
            if P.modeData.moveTime + 60 > P.gameEnv.timeControls.periodTime then
                caption = "SPEED UP"
                alert = "LV"..P.modeData.period
                if P.modeData.period == P.gameEnv.timeControls.periods then
                    alert = "20G"
                end
            end
            if P.modeData.period > P.gameEnv.timeControls.periods and P.modeData.moveTime > -60 then
                caption = "SUDDEN DEATH"
                alert = ""
                frames = P.modeData.moveTime + 60
            end
        end
        if alert then
            drawTimeAlert(alert, caption, frames)
        end
    end,
}