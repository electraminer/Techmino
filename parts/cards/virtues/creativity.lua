return {
    hook_drop=function(P)
        if P.lastPiece.spin and P.lastPiece.id~=5 then
            P.modeData.meter=P.modeData.meter+20*P.lastPiece.row
        end
    end,

    title=function(P)
        return "Creativity"
    end,

    rulesText=function(P)
        return {
            "Gain 20 MP per line cleared with",
            "an all-spin (T-spins do not count)."
        }
    end,
}
