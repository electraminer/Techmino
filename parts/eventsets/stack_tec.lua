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
		attack.stalledByZone = nil
	end
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
	local _test = P.modeData.timePerQuarter
	-- Send each line
	local totalSendTime = TIME_PER_QUARTER
	-- Exit zone and send the attack
	P.modeData.Zone=0
	for i,attack in ipairs(P.modeData.builtAttack) do
		local T = randomTarget(P)
		local cancelledAttack = P:cancel(attack)
		local sendTime = totalSendTime * i / #P.modeData.builtAttack -- Lines come in over time
		P:attack(T,attack - cancelledAttack, sendTime, generateLine(P.atkRND:random(10)))
	end
	P.modeData.builtAttack={}
	
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
	-- layout = "royale",
	fieldH=20,
	task=function(P)
		P.modeData.LineTotal=0
		P.modeData.Zone=0
		P.modeData.FrameZoneStarted=0
		P.modeData.builtAttack={}
		P.modeData.timePerQuarter = 0

		-- Replace attack function
		function P:attack(target, send, time, line)
			if P.modeData.Zone > 0 then
				-- Total up sent attack
				table.insert(P.modeData.builtAttack, send)
			else
				self:extraEvent('attack', target.sid, send, time, line)
			end
		end

		while true do
			for i,attack in pairs(P.atkBuffer) do
				-- Make sure attacks in zone are stalled
				if attack.stalledByZone then
					attack.countdown = attack.stalledCountdown
				end
				-- Make sure all attacks are delayed, so they can be manually processed one at a time
				attack.countdown = MATH.max(attack.countdown, P.gameEnv.garbageSpeed)
			end
			if P.modeData.Zone > 0 then
				-- Calculate zone time
				local zoneLength = (P.modeData.Zone)*TIME_PER_QUARTER
				local zoneTimeElapsed = P.stat.frame - P.modeData.FrameZoneStarted
				local zoneTimeLeft = zoneLength - zoneTimeElapsed
				if zoneTimeElapsed == 1 or zoneTimeElapsed == 16 then
					-- Zone enter SFX
					SFX.play("reach")
				end
				-- Stall attacks in the attack buffer while zone is active
				for i,attack in pairs(P.atkBuffer) do
					if not attack.stalledByZone then
						attack.stalledByZone = true
						attack.stalledCountdown = attack.countdown
					end
				end
				
				-- End zone when time runs out
				if zoneTimeLeft <= -3 * 60 then
					_endZone(P)
				end
				P.gameEnv.wait = 0
				P.gameEnv.fall = 0
			else
				P.gameEnv.wait = 4
				P.gameEnv.fall = 20
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
			local meterLeft = MATH.max(zoneTimeLeft / TIME_PER_QUARTER / 4, 0)
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
		elseif c == 0 then
			-- Process only one line of the garbage queue
			if P.atkBuffer[1] and P.atkBuffer[1].countdown <= P.gameEnv.garbageSpeed then
				P.atkBuffer[1].countdown = 0
				P:garbageRelease()
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