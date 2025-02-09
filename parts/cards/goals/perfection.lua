return {
    init=function(P)
        P.modeData.longestChain=0
    end,

    hook_drop=function(P)
        P.modeData.longestChain=math.max(P.modeData.longestChain,P.modeData.b2b)
    end,

    score=function(P)
        return P.modeData.longestChain*500
    end,
    
    title=function(P)
        return "Perfection"
    end,

    rulesText=function(P)
        score=P.modeData.longestChain*500
        return {
            "Score bonus points for your",
            "longest b2b chain.",
            "+500 / chain (Current: "..score..").",
        }
    end,
}
