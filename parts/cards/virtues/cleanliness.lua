return {
    hook_drop=function(P)
        P.modeData.meter=P.modeData.meter+P.lastPiece.dig*25
    end,
    
    title=function(P)
        return "Cleanliness"
    end,

    rulesText=function(P)
        return {
            "Gain 25 MP per garbage line dug.",
        }
    end,
}
