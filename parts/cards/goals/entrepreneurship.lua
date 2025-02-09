return {
    init=function(P)
        P.modeData.fiveCombosPerformed=0
    end,

    hook_drop=function(P)
        if P.modeData.combo==5 then
            P.modeData.fiveCombosPerformed=P.modeData.fiveCombosPerformed+1
        end
    end,

    score=function(P)
        return P.modeData.fiveCombosPerformed*2500
    end,

    title=function(P)
        return "Entrepreneurship"
    end,

    rulesText=function(P)
        score=P.modeData.fiveCombosPerformed*2500
        return {
            "Score +2500 bonus points for",
            "each 5-combo. (Current: "..score..").",
        }
    end,
}
