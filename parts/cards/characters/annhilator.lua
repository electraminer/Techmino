return {
    activate=function(P)
        if P.modeData.meter<1000 then return end
        P.modeData.meter=P.modeData.meter-1000

        P.field={}
        P.visTimes={}
        P:freshMoveBlock()

        -- Refill with garbage
        for i=1,P.modeData.garbagePreview do
            P:garbageRise(20,1,P.modeData.garbageDistribution())
        end
    end,

    cost=1000,
    
    title=function(P)
        return "The Annhilator"
    end,

    rulesText=function(P)
        return {
            "1000 MP: Clear the entire board.",
        }
    end,
}
