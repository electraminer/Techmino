return {
    hook_drop=function(P)
        if P.lastPiece.row>0 then
            -- Reward the player with meter based on combo
            meterValue=math.min(40,10*math.max(0,P.modeData.combo-1))
            P.modeData.meter=P.modeData.meter+meterValue
        end
    end,

    title=function(P)
        return "Diligence"
    end,

    rulesText=function(P)
        meterValue=math.min(40,10*P.modeData.combo)
        return {
            "Gain up to 40 MP per combo clear.",
            "10 MP / combo count (Current: "..meterValue..").",
        }
    end,
}
