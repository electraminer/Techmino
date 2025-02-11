return {
    init=function(P)
        P.modeData.equalityClearTypes={0,0,0,0}
    end,

    hook_drop=function(P)
        if P.lastPiece.row>0 then
            local idx=math.min(P.lastPiece.row,4)
            P.modeData.equalityClearTypes[idx]=P.modeData.equalityClearTypes[idx]+P.lastPiece.row
        end
    end,

    score=function(P)
        Q=P.modeData.equalityClearTypes
        if Q==0 then
            Q={0,0,0,0}
        end
        local x=1000
        for i=1,4 do
            x=math.min(x,Q[i])
        end
        return x*1000
    end,

    title=function(P)
        return "Equality"
    end,

    rulesText=function(P)
        Q=P.modeData.equalityClearTypes
        if Q==0 then
            Q={0,0,0,0}
        end
        local x=1000
        for i=1,4 do
            x=math.min(x,Q[i])
        end
        score=x*1000
        return {
            "Score based on your least-used",
            "clear type: S="..Q[1].." D="..Q[2].." T="..Q[3].." Q="..Q[4],
            "+1000 per line (Current: "..score..")",
        }
    end,
}
