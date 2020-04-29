local function check_tsd(P)
	if #P.clearedRow>0 then
		if P.lastClear~=52 then
			P:lose()
		elseif #P.clearedRow>0 then
			P.modeData.event=P.modeData.event+1
		end
	end
end

return{
	color=color.magenta,
	env={
		drop=60,lock=60,
		freshLimit=15,
		dropPiece=check_tsd,
		ospin=false,
		bg="matrix",bgm="reason",
	},
	pauseLimit=true,
	load=function()
		newPlayer(1,340,15)
	end,
	mesDisp=function(P,dx,dy)
		setFont(75)
		mStr(P.modeData.event,-81,330)
		mText(drawableText.tsd,-81,407)
	end,
	score=function(P)return{P.modeData.event,P.stat.time}end,
	scoreDisp=function(D)return D[1].."TSD   "..toTime(D[2])end,
	comp=function(a,b)return a[1]>b[1]or a[1]==b[1]and a[2]<b[2]end,
	getRank=function(P)
		local T=P.modeData.event
		return
		T>=21 and 5 or
		T>=19 and 4 or
		T>=16 and 3 or
		T>=13 and 2 or
		T>=10 and 1 or
		T>=1 and 0
	end,
}