return {
    init=function(P)
        P.modeData.masteryClearTypes={0,0,0,0}
    end,

    hook_drop=function(P)
        if P.lastPiece.row>0 then
            local idx=math.min(P.lastPiece.row,4)
            P.modeData.masteryClearTypes[idx]=P.modeData.masteryClearTypes[idx]+P.lastPiece.row
        end
    end,

    score=function(P)
        Q=P.modeData.masteryClearTypes
        if Q==0 then
            Q={0,0,0,0}
        end
        local x=0
        for i=1,4 do
            x=math.max(x,Q[i])
        end
        return x*250
    end,

    title=function(P)
        return "Mastery"
    end,

    rulesText=function(P)
        Q=P.modeData.masteryClearTypes
        if Q==0 then
            Q={0,0,0,0}
        end
        local x=0
        for i=1,4 do
            x=math.max(x,Q[i])
        end
        score=x*250
        return {
            "Score based on your most-used",
            "clear type: S="..Q[1].." D="..Q[2].." T="..Q[3].." Q="..Q[4],
            "+250 per line (Current: "..score..")",
        }
    end,
}
