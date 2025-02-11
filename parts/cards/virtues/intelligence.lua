return {
    hook_drop=function(P)
        if P.lastPiece.pc or P.lastPiece.hpc then
            P.modeData.meter=P.modeData.meter+150
        end
    end,

    title=function(P)
        return "Intelligence"
    end,

    rulesText=function(P)
        return {
            "Gain 150 MP per HPC / PC.",
        }
    end,
}
