return {
    activate=function(P)
        if P.modeData.meter<250 then return end
        local y=1
        while P.field[y].garbage do
            y=y+1
        end
        highestGarb=y-1
        for y=1,highestGarb-1 do
            for x=1,10 do
                P.field[y][x]=P.field[highestGarb][x]
            end
        end

        P.modeData.meter=P.modeData.meter-250
    end,

    cost=250,

    title=function(P)
        return "The Architect"
    end,

    rulesText=function(P)
        return {
            "250 MP: Clean up all garbage.",
        }
    end,
}
