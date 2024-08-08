local LINES_PER_QUARTER = 7
local TIME_PER_QUARTER = 60 * 5

local function _endZone(P)
	P.modeData.Zone=0
	P:freshMoveBlock ('push')
	TABLE.cut(P.clearedRow)
	P:clearFilledLines(1,P.garbageBeneath)
	-- Release attacks in the buffer
	for i,attack in pairs(P.atkBuffer) do
		if attack.stalledByZone then
			attack.countdown = attack.stalledCountdown
			attack.stalledByZone = nil
			attack.stalledCountdown = nil
		end
	end
	--TODO: send BuiltAttack
	--based on 1,2,3, or 4 quarters
    local T = randomTarget(P)
	local sendTime = 300 -- How to calculate sendTime?
	P:attack(T,P.modeData.BuiltAttack,sendTime,generateLine(P.atkRND:random(10)))
	--above code needs testing outside of singleplayer
	P.modeData.BuiltAttack=0
end

local function _drawMeter(x,y,meters)
	GC.setColor(0,0,0,.4)
	GC.circle('fill',x,y,36)

	GC.setLineWidth(8)
	local i = 1
	while i <= #meters do
		local amount = meters[i]
		local color = meters[i + 1]
		GC.setColor(color)
		GC.arc('line','open',x,y,40,-MATH.tau/4,amount*MATH.tau-MATH.tau/4)
		i = i + 2
	end

	setFont(25)
	GC.mStr("ZONE",x,y-16)
end

return {
	fieldH=20,
	task=function(P)
		P.modeData.LineTotal=0
		P.modeData.Zone=0
		P.modeData.FrameZoneStarted=0
		P.modeData.BuiltAttack=0

		while true do
			if P.modeData.Zone > 0 then
				-- Calculate zone time
				local zoneLength = (P.modeData.Zone)*TIME_PER_QUARTER
				local zoneTimeElapsed = P.stat.frame - P.modeData.FrameZoneStarted
				local zoneTimeLeft = zoneLength - zoneTimeElapsed
				-- Stall attacks in the attack buffer while zone is active
				for i,attack in pairs(P.atkBuffer) do
					if not attack.stalledByZone then
						attack.stalledByZone = true
						attack.stalledCountdown = attack.countdown
						attack.countdown = attack.countdown + P.gameEnv.garbageSpeed * zoneTimeLeft
					end
				end
				-- End zone when time runs out
				if zoneTimeLeft <= 0 then
					_endZone(P)
				end
			end
			
			coroutine.yield()
		end
	end,
    mesDisp=function(P)
		-- Display row
        setFont(60)
        GC.mStr(P.stat.row,63,280)
		setFont(30)
		-- love.graphics.setColor(0,1,0,1)
		-- if P.modeData.LineTotal<7 then love.graphics.setColor(1,0,0,1) end
		-- if P.modeData.LineTotal==28 then love.graphics.setColor(0,1,1,1) end

		local animationDuration = 60
		local animationCycle = (P.stat.frame % animationDuration) / animationDuration
		
		if P.modeData.Zone > 0 then
			local zoneLength = (P.modeData.Zone)*TIME_PER_QUARTER
			local zoneTimeElapsed = P.stat.frame - P.modeData.FrameZoneStarted
			local zoneTimeLeft = zoneLength - zoneTimeElapsed
			local meterLeft = zoneTimeLeft / TIME_PER_QUARTER / 4
			_drawMeter(63, 440, {
				meterLeft, {COLOR.HSVToRGB(animationCycle, 0.89, 0.91)}
			})
		else
			local zoneMeter = P.modeData.LineTotal / LINES_PER_QUARTER / 4
			local zoneStrength = math.floor(P.modeData.LineTotal / LINES_PER_QUARTER)
			local color = COLOR.white
			if zoneMeter == 1 then
				local animationZigzag = math.abs(animationCycle - 0.5) * 2
				color = {COLOR.HSVToRGB(0.51, 0.77 * animationZigzag, 0.88)}
			end
			_drawMeter(63, 440, {
				zoneMeter, COLOR.gray,
				zoneStrength / 4, color,
			})
		end

		love.graphics.setColor(1,1,1,1)
        mText(TEXTOBJ.line,63,350)
        PLY.draw.drawMarkLine(P,20,.3,1,1,TIME()%.42<.21 and .95 or .6)

    end,

	hook_drop=function(P)
		local c=#P.clearedRow
		if #P.clearedRow>0 and P.modeData.Zone==0 then
			P.modeData.LineTotal=P.modeData.LineTotal+#P.clearedRow
			if P.modeData.LineTotal>LINES_PER_QUARTER*4 then
				P.modeData.LineTotal=LINES_PER_QUARTER*4
			end
		end

		if P.modeData.Zone>0 then
			-- Total up sent attack
			P.modeData.BuiltAttack=P.modeData.BuiltAttack+P.lastPiece.atk
			-- Add the cleared lines back underneath the board
			P:garbageRise(21,c,1023)
			P.stat.row=P.stat.row-c
		end
		P:freshMoveBlock('push')
	end,
	
	fkey1=function(P)
		if P.modeData.LineTotal>=LINES_PER_QUARTER then
			P.modeData.Zone=math.floor(P.modeData.LineTotal/LINES_PER_QUARTER)
			P.modeData.LineTotal=0
			P.modeData.FrameZoneStarted=P.stat.frame
		end
	end,
	
    hook_die=function(P)
		_endZone(P)
    end,
}