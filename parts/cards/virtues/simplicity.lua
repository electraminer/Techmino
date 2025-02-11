return {
    hook_drop=function(P)
        if P.lastPiece.row>=4 then
            P.modeData.meter=P.modeData.meter+100
        end
    end,
    
    title=function(P)
        return "Simplicity"
    end,

    rulesText=function(P)
        return {
            "Gain 100 MP per Techrash.",
        }
    end,
}
