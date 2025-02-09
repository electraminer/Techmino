return {
    init=function(P)
        P.gameEnv.nextCount=1
        P.modeData.garbagePreview=P.modeData.garbagePreview+5
    end,
    
    title=function(P)
        return "Dark Cavern"
    end,

    rulesText=function(P)
        return {
            "Garbage is 5 lines higher.",
            "You only have 1 next box.",
        }
    end,
}
