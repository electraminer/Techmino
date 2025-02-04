return {
    hook_drop=function(P)
        P.modeData.meter=P.modeData.meter+P.lastPiece.row*10
    end,
}
