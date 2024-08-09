-- The amount of frames in each player's main time.
local MAIN_TIME = 60 * 60 * 15
-- The amount of frames to make each move before the main time starts to count down.
local MOVE_TIME = 60 * 30
-- If this is true, the player's main time will be incremented by their move time if they have any left.
local USE_INCREMENT = true
-- Once a player's main time runs out, this is the amount of time in each period.
local BYO_YOMI = 60 * 30
-- Total number of periods before reaching Sudden Death.
local TOTAL_PERIODS = 5
-- If this is true, placing a piece will automatically commit (no undo!)
-- This is auto-enabled in BYO-YOMI period, and for AI (since they don't undo)
local AUTO_COMMIT = false

local function getSpeed(period, totalPeriods)
    local speed = period / totalPeriods * 2
    if speed == 0 then
        return 1e99
    elseif speed <= 1 then
        local blocksPerSecond = 2 + speed * 18
        return 60 / blocksPerSecond
    elseif speed < 2 then
        local blocksPerFrame = 0.34 + (speed - 1) * 9.66
        return 1 / blocksPerFrame
    else
        return 0
    end
end

local function firstPlayer()
    local firstID = 1e99
    local firstPlayer = nil
    for i=1,#PLY_ALIVE do
        if PLY_ALIVE[i].sid < firstID then
            firstID = PLY_ALIVE[i].sid
            firstPlayer = PLY_ALIVE[i]
        end
    end
    return firstPlayer
end

local function nextPlayer(P)
    local nextID = 1e99
    local nextPlayer = firstPlayer()
    for i=1,#PLY_ALIVE do
        -- Only check players later in the turn order than the current player
        if PLY_ALIVE[i].sid > P.sid then
            if PLY_ALIVE[i].sid < nextID then
                nextID = PLY_ALIVE[i].sid
                nextPlayer = PLY_ALIVE[i]
            end
        end
    end
    return nextPlayer
end

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

function saveState(inputs, outputs, whitelists, blacklists)
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
    for i,p in ipairs(PLAYERS) do
        table.insert(saved, p.atkBuffer)
        table.insert(saved, p.netAtk)
    end
    -- return saved, {}, {{'modeData', 'keyPressing'}}
    return saved, {{"field", "visTime", "cur", "curX", "curY", "nextQueue", "holdQueue", "ghoY", "stat"}}, {}
end

function commit(P)
    -- Go back to the piece spawning
    if #P.modeData.savestates >= 1 and not P.type == 'bot' then
        local savestate = P.modeData.savestates[#P.modeData.savestates]
        local ctx, whitelists, blacklists = savestateCtx(P)
        saveState(savestate, ctx, whitelists, blacklists)
    end
    -- Reveal RNG
    local turns = P.stat.piece - P.modeData.lastCommit
    for i=1,turns do
        P:newNext(true)
    end
    -- Reveal garbage
    local totalAtk = 0
    for _,atk in ipairs(P.modeData.speculativeAtk) do
        totalAtk = totalAtk + atk
    end
    for _,atk in ipairs(P.modeData.speculativeAtk) do
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
    -- Clear savestates
    P.modeData.savestates = {}
    local ctx, whitelists, blacklists = savestateCtx(P)
    local savestate = saveState(ctx, {}, whitelists, blacklists)
    table.insert(P.modeData.savestates, savestate)

    -- Pass the turn
    if P.stat.piece%7==0 and P.modeData.lastCommit ~= P.stat.piece then
        P.control = false
        if P.modeData.period > TOTAL_PERIODS then
            -- Sudden Death
            P.modeData.moveTime = 0
        elseif P.modeData.period > 0 then
            P.modeData.moveTime = BYO_YOMI
        else
            if USE_INCREMENT then
                P.modeData.mainTime = P.modeData.mainTime + P.modeData.moveTime
            end
            P.modeData.moveTime = MOVE_TIME
        end

        P = nextPlayer(P)
        P.control = true
        P.modeData.startingPeriod = P.modeData.period
        P.modeData.savestates = {}
        P.modeData.lastCommit = P.stat.piece
        P.waiting = 0
        if P.modeData.fakedQueue then
            -- Remove the fake piece from the start of the next queue
            table.remove(P.nextQueue, 1)
            P.modeData.fakedQueue = false
        end
    end
    P.modeData.lastCommit = P.stat.piece
end

local getSeqGen=require"parts.player.seqGenerators"
return {
    task=function(P)
        -- Generate the custom RNG generators for each player
        -- First burn a value for each SID count
        for i=1,P.sid do
            local burn = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
        end
        -- We are adding two separate generations together to ensure no correlation.
        local seed = P.seqRND:random(256*256*256) + P.seqRND:random(703*703)
        P.modeData.seqRND = love.math.newRandomGenerator(seed)
        P.modeData.atkRND = love.math.newRandomGenerator(seed)
        P.modeData.seqGen = coroutine.create(getSeqGen(P.gameEnv.sequence))
        P.modeData.bagLineCounter = 0
        P.modeData.atkLast = 0
        P.modeData.speculativeAtk = {}
        P.gameEnv.garbageSpeed = 0

        P.nextQueue = {}
        function P:newNext(force)
            if force then
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
                    P:newNext(true)
                end
            end
        end
        for i=1,8 do
            P:newNext(true)
        end
        P.control = false
        P.modeData.mainTime = MAIN_TIME
        P.modeData.moveTime = MOVE_TIME
        P.modeData.period = 0
        P.modeData.startingPeriod = 0
        P.gameEnv.drop = 1e99
        P.dropDelay = 1e99
        P.modeData.savestates = {}
        P.modeData.lastCommit = P.stat.piece
        if MAIN_TIME == 0 then
            P.modeData.moveTime = BYO_YOMI
            P.modeData.period = 1
            P.modeData.startingPeriod = 1
            local gravity = getSpeed(P.modeData.period, TOTAL_PERIODS)
            P.gameEnv.drop = gravity
            P.dropDelay = gravity
            P.gameEnv.lock = 30
            P.lockDelay = 30
        end
        -- Wait until the countdown finishes
        while P.frameRun < 179 do
            -- Currently does not supress the first piece spawn
            coroutine.yield()
        end
        P.gameEnv.wait = 0
        P.control = P == firstPlayer()
        if P == firstPlayer() then
            P.control = true
            P.waiting = 0
            P.modeData.fakedQueue = false
        else 
            -- Fake the queue so you can see the piece that was spawned
            table.insert(P.nextQueue, 1, P.cur)
            P.modeData.fakedQueue = true
        end
        while true do
            if P.control then
                if P.waiting > 1e98 then
                    -- Auto pass turn
                    if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
                        commit(P)
                    end
                end
                if P.modeData.moveTime > 0 then
                    -- Move time
                    P.modeData.moveTime = P.modeData.moveTime - 1
                elseif P.modeData.mainTime > 0 then
                    -- Main time
                    P.modeData.mainTime = P.modeData.mainTime - 1
                elseif P.modeData.period < TOTAL_PERIODS then
                    -- Once main time has expired, start a new byo-yomi period and raise the speed
                    P.modeData.moveTime = BYO_YOMI
                    P.modeData.period = P.modeData.period + 1
                    local gravity = getSpeed(P.modeData.period, TOTAL_PERIODS)
                    P.gameEnv.drop = gravity
                    P.dropDelay = gravity
                    P.gameEnv.lock = 30
                    P.lockDelay = 30
                    if P.cur then
                        P:freshMoveBlock()
                    end
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
    
    mesDisp=function(P)
		-- Display time remaining
        setFont(30)
        if P.modeData.period > TOTAL_PERIODS then
            GC.mStr("DEATH", 539, 465)
            drawDial(539, 545, 0, 0)
        elseif P.modeData.period > 0 then
            GC.mStr("PERIOD "..P.modeData.period, 539, 465)
            drawDial(539, 545, P.modeData.moveTime, P.modeData.moveTime / MOVE_TIME)
        elseif P.modeData.moveTime == 0 then
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, 0, P.modeData.mainTime / MAIN_TIME)
        else
            GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)
            drawDial(539, 545, P.modeData.moveTime, P.modeData.moveTime / MOVE_TIME)
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
        time = MATH.floor(time / 60)
        local minutes = time % 60
        time = MATH.floor(time / 60)
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
            if P.modeData.moveTime + 60 > BYO_YOMI then
                caption = "SPEED UP"
                alert = "LV"..P.modeData.period
                if P.modeData.period == TOTAL_PERIODS then
                    alert = "20G"
                end
            end
            if P.modeData.period > TOTAL_PERIODS and P.modeData.moveTime > -60 then
                caption = "SUDDEN DEATH"
                alert = ""
                frames = P.modeData.moveTime + 60
            end
        end
        if alert then
            drawTimeAlert(alert, caption, frames)
        end
    end,

    hook_spawn=function(P)
        local ctx, whitelists, blacklists = savestateCtx(P)
        local savestate = saveState(ctx, {}, whitelists, blacklists)
        table.insert(P.modeData.savestates, savestate)
        
        if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
            commit(P)
        end
    end,

    hook_drop=function(P)
        if P.stat.piece%7==0 then
            local ctx, whitelists, blacklists = savestateCtx(P)
            local savestate = saveState(ctx, {}, whitelists, blacklists)
            table.insert(P.modeData.savestates, savestate)
            P.waiting = 1e99
        end
        -- Parse garbage
        if #P.clearedRow == 0 then
            for i,atk in ipairs(P.atkBuffer) do
                -- Store the attack in the table
                table.insert(P.modeData.speculativeAtk, atk.amount)
                atk.line = 1023
                -- Receive the garbage
                atk.countdown = 0
            end
            P:garbageRelease()
        end
    end,
    
    hook_die=function(P)
        P.modeData.speculativeAtk = {}
    end,

    -- Commit
    fkey1=function(P)
        commit(P)
    end,

    -- Undo
    fkey2=function(P)
        -- Undo disabled when automatically committing
        if AUTO_COMMIT or P.type == 'bot' or P.modeData.period > 0 then
            return
        end

        local savestate = nil
        if #P.modeData.savestates >= 2 then
            P.modeData.savestates[#P.modeData.savestates] = nil
        end
        if #P.modeData.savestates >= 1 then
            local savestate = P.modeData.savestates[#P.modeData.savestates]
            local ctx, whitelists, blacklists = savestateCtx(P)
            saveState(savestate, ctx, whitelists, blacklists)
        end
    end
}
