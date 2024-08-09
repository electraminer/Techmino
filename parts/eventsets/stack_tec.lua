local LINES_PER_QUARTER = 7
local TIME_PER_QUARTER = 60 * 5

local function _endZone(P)
	if P.cur then
		P:freshMoveBlock ('push')
	end
	TABLE.cut(P.clearedRow)
	local zoneLines = P:clearFilledLines(1,P.garbageBeneath)
	-- Release attacks in the buffer
	for i,attack in pairs(P.atkBuffer) do
		if attack.stalledByZone then
			attack.countdown = attack.stalledCountdown
			attack.stalledByZone = nil
			attack.stalledCountdown = nil
		end
	end
	-- Restore the player's attack power
	P.strength = 0
	-- Separate the lines attack into chunks, more quarter zones get bonus chunks
	local linesAttackChunks = P.modeData.Zone + 2
	-- Chunks grow for larger zones
	local linesAttack = math.floor(zoneLines / 4)
	-- Number of extra lines not accounted for by zoneLines / 4
	local linesAttackRemainder = zoneLines % 4
	for i=1,linesAttackChunks do
		if i <= linesAttackRemainder then
			-- Add 1 extra attack for each remainder
			table.insert(P.modeData.builtAttack, linesAttack + 1)
		elseif linesAttack > 0 then
			table.insert(P.modeData.builtAttack, linesAttack)
		end
	end

	-- Bonus attack for Ulticrash and above
	local bonusLines = math.max(zoneLines - 19, 0)
	local bonusAttack = bonusLines * bonusLines * 4
	if bonusAttack > 0 then
		table.insert(P.modeData.builtAttack, bonusAttack)
	end

	-- Send each line
	local totalSendTime = TIME_PER_QUARTER
	for i,attack in ipairs(P.modeData.builtAttack) do
		local T = randomTarget(P)
		local cancelledAttack = P:cancel(attack)
		local sendTime = totalSendTime * i / #P.modeData.builtAttack -- Lines come in over time
		P:attack(T,attack - cancelledAttack,sendTime,generateLine(P.atkRND:random(10)))
	end
	-- Do we need to add the attack statistics for this?
	--above code needs testing outside of singleplayer
	P.modeData.builtAttack={}
	P.modeData.Zone=0
	
	if P.cur then
		P:freshMoveBlock ('push')
	end
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
		P.modeData.builtAttack={}

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
				-- Player cannot attack immediately - so their strength is negative to suppress it
				-- This causes them to deal negative damage, which is instead counted as Zone damage
				P.strength = -8
				
				-- End zone when time runs out
				if zoneTimeLeft <= -3 * 60 then
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
			local zoneLength = (P.modeData.Zone)*TIME_PER_QUARTER
			local zoneTimeElapsed = P.stat.frame - P.modeData.FrameZoneStarted
			local zoneTimeLeft = zoneLength - zoneTimeElapsed
			-- Total up sent attack
			if -P.lastPiece.atk > 0 then
				table.insert(P.modeData.builtAttack, -P.lastPiece.atk)
			end
			-- Add the cleared lines back underneath the board
			P:garbageRise(21,c,1023)
			P.stat.row=P.stat.row-c
			if P.cur then
				P:freshMoveBlock('push')
			end
			
			-- End zone when time runs out
			if zoneTimeLeft <= 0 then
				_endZone(P)
			end
		end
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