return {
    hook_drop=function(P)
        if P.lastPiece.row>0 then
            -- Reward the player with meter based on b2b
            -- Should max out at 50 meter per clear at 10 b2b chain
            meterValue=math.min(50,5*(P.modeData.b2b-1))
            P.modeData.meter=P.modeData.meter+meterValue
        end
    end,
}
