-- The amount of frames in each player's main time.
local MAIN_TIME = 60 * 30
-- The amount of frames to make each move before the main time starts to count down.
local MOVE_TIME = 60 * 5
-- If this is true, the player's main time will be incremented by their move time if they have any left.
local USE_INCREMENT = true
-- Once a player's main time runs out, this is the amount of time in each period.
local BYO_YOMI = 60 * 5
-- Total number of periods before reaching Sudden Death.
local TOTAL_PERIODS = 9

local function getSpeed(period, totalPeriods)
    local speed = period / totalPeriods * 3
    if speed == 0 then
        return 1e99, 1e99
    elseif speed <= 1 then
        local blocksPerSecond = 2 + speed * 18
        return 60 / blocksPerSecond, 30
    elseif speed <= 2 then
        local blocksPerFrame = 0.34 + (speed - 1) * 9.66
        return 1 / blocksPerFrame, 30
    elseif speed == 2 then
        return 0, 30
    elseif speed <= 3 then
        local lockFrames = 30 - (speed - 2) * 22
        return 0, lockFrames
    else
        return 0, 0
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
    local frames = time % 60
    time = MATH.floor(time / 60)
    local seconds = time % 60
    time = MATH.floor(time / 60)
    local minutes = time % 60
    time = MATH.floor(time / 60)
    local hours = time

    if hours >= 1 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%d:%02d.%01d", minutes, seconds, MATH.floor(frames / 6))
    end
end

local function toHumanTimeShort(time)
    local frames = time % 60
    time = MATH.floor(time / 60)
    local seconds = time % 60
    time = MATH.floor(time / 60)
    local minutes = time

    if minutes >= 1 then
        return string.format("%d:%02d", minutes, seconds)
    elseif seconds >= 10 then
        return string.format("%d", seconds)
    else
        return string.format("%d.%01d", seconds, MATH.floor(frames / 6))
    end
end

local dialNeedle=TEXTURE.dial.needle
local function drawDial(x, y, moveTime)
    local timeProportion = moveTime / MOVE_TIME
    local theta = MATH.tau * timeProportion - MATH.tau/4
    -- Dial back - no longer opaque to cover other dial
    GC.setColor(COLOR.black)
    GC.circle('fill', x, y, 36)
    -- Dial needle
    GC.setColor(COLOR.white)
    GC.draw(dialNeedle, x, y, theta, nil, nil, 1, 1)
    -- Dial border
    GC.setLineWidth(3)
    GC.setColor(COLOR.gray)
    GC.circle('line', x, y, 37)
    -- Filled dial border
    GC.setColor(COLOR.white)
    GC.arc('line','open', x, y, 37, -MATH.tau/4, theta)
    -- Time display
    setFont(30)
    GC.mStr(toHumanTimeShort(moveTime), x, y-21)
end

return {
    task=function(P)
        P.control = false
        P.modeData.mainTime = MAIN_TIME
        P.modeData.moveTime = MOVE_TIME
        P.modeData.period = 0
        if MAIN_TIME == 0 then
            P.modeData.moveTime = BYO_YOMI
            P.modeData.period = 1
        end
        -- Wait until the countdown finishes
        while P.frameRun <= 180 do
            coroutine.yield()
        end
        P.control = P == firstPlayer()
        while true do
            local gravity, lock = getSpeed(P.modeData.period, TOTAL_PERIODS)
            P.gameEnv.drop = gravity
            P.gameEnv.lock = lock
            if P.control then
                if P.modeData.moveTime > 0 then
                    P.modeData.moveTime = P.modeData.moveTime - 1
                elseif P.modeData.mainTime > 0 then
                    P.modeData.mainTime = P.modeData.mainTime - 1
                else
                    P.modeData.period = P.modeData.period + 1
                end
            end
            coroutine.yield()
        end
    end,
    
    mesDisp=function(P)
		-- Display time remaining
		setFont(30)
        GC.mStr(toHumanTime(P.modeData.mainTime), 539, 465)

        drawDial(539, 545, P.modeData.moveTime)
    end,

    hook_drop=function(P)
        if P.stat.piece%7==0 and #PLY_ALIVE>1 then
            P.control = false
            if P.modeData.mainTime == 0 then
                P.modeData.moveTime = BYO_YOMI
            else
                if USE_INCREMENT then
                    P.modeData.mainTime = P.modeData.mainTime + P.modeData.moveTime
                end
                P.modeData.moveTime = MOVE_TIME
            end
            nextPlayer(P).control = true
        end
    end,
}
