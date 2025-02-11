return {
    init=function(P)
        P.modeData.linesDug=0
    end,

    hook_drop=function(P)
        P.modeData.linesDug=P.modeData.linesDug+P.lastPiece.dig
    end,

    score=function(P)
        return P.modeData.linesDug*500
    end,

    title=function(P)
        return "Sustainability"
    end,

    rulesText=function(P)
        score=P.modeData.linesDug*500
        return {
            "Score +500 bonus points for",
            "each line dug (Current: "..score..").",
        }
    end,
}
