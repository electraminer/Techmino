return {
    init=function(P)
        P.modeData.perfectClears=0
    end,

    hook_drop=function(P)
        if P.lastPiece.hpc or P.lastPiece.pc then
            P.modeData.perfectClears=P.modeData.perfectClears+1
        end
    end,

    score=function(P)
        return P.modeData.perfectClears*3000
    end,

    title=function(P)
        return "Satisfaction"
    end,

    rulesText=function(P)
        score=P.modeData.perfectClears*3000
        return {
            "Score +3000 bonus points for",
            "each PC/HPC (Current: "..score..").",
        }
    end,
}
