return {
    hook_drop=function(P)
        P.modeData.meter=P.modeData.meter+P.lastPiece.row*10
    end,
    
    title=function(P)
        return "Reliability"
    end,

    rulesText=function(P)
        return {
            "Gain 10 MP per line cleared.",
        }
    end,
}
