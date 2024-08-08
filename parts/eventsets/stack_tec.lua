
function endZone(P)
	P.modeData.Zone=0
	P:freshMoveBlock('push')
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
end


return {
	fieldH=20,
	task=function(P)
		P.modeData.LineTotal=0
		P.modeData.Zone=0
		P.modeData.FrameZoneStarted=0
	end,
    mesDisp=function(P)
        setFont(60)
        GC.mStr(P.stat.row,63,280)
		setFont(30)
		love.graphics.setColor(0,1,0,1)
		if P.modeData.LineTotal<7 then love.graphics.setColor(1,0,0,1) end
		if P.modeData.LineTotal==28 then love.graphics.setColor(0,1,1,1) end
		if P.modeData.Zone>0 then
			love.graphics.setColor(1,1,0,1)
			if P.stat.frame<P.modeData.FrameZoneStarted+((P.modeData.Zone)*60*5) then
			GC.mStr((math.floor((P.modeData.FrameZoneStarted+((P.modeData.Zone)*60*5)-P.stat.frame)/6)/10),55,400)
			else
				love.graphics.setColor(1,0,0,1)
				GC.mStr("0",55,400)
			end
		end
		
		if P.modeData.Zone==0 then
		GC.mStr(P.modeData.LineTotal.."/28 ("..math.floor(P.modeData.LineTotal/7).."/4)",55,400)
		end
		love.graphics.setColor(1,1,1,1)
        mText(TEXTOBJ.line,63,350)
        PLY.draw.drawMarkLine(P,20,.3,1,1,TIME()%.42<.21 and .95 or .6)
    end,

	hook_drop=function(P)
		local c=#P.clearedRow
		if #P.clearedRow>0 and P.modeData.Zone==0 then
			P.modeData.LineTotal=P.modeData.LineTotal+#P.clearedRow
			if P.modeData.LineTotal>28 then P.modeData.LineTotal=28 end
		end

		if P.modeData.Zone>0 then
			P:garbageRise(21,c,1023)
			P.stat.row=P.stat.row-c
		end
		P:freshMoveBlock('push')
	end,

	task=function(P)
		while true do
			if P.modeData.Zone > 0 then
				-- Calculate zone time
				local zoneLength = (P.modeData.Zone)*60*5
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
					endZone(P)
				end
			end
			
			coroutine.yield()
		end
	end,
	
	fkey1=function(P)
		if P.modeData.LineTotal>=7 then
			P.modeData.Zone=math.floor(P.modeData.LineTotal/7)
			P.modeData.LineTotal=0
			P.modeData.FrameZoneStarted=P.stat.frame
		end
	end,
	
    hook_die=function(P)
		endZone(P)
    end,
}