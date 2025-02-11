return {
    activate=function(P)
        if P.modeData.meter<250 then return end
        local pieces={}
        for i=1,P.gameEnv.nextCount do
            if P.atkRND:random(4)==1 then
                -- Hit a random pento/trimino
                table.insert(pieces, P.atkRND:random(22)+7)
            else
                -- Hit a normal piece
                table.insert(pieces, P.atkRND:random(7))
            end
        end
        -- Add a guaranteed I5
        table.insert(pieces, P.atkRND:random(P.gameEnv.nextCount+1), 25)

        -- Respawn the current piece
        P.cur=P:_getBlock(pieces[1],nil,nil,0)
        P:resetBlock()
        P:freshMoveBlock()
        
        for i=1,P.gameEnv.nextCount do
            P.nextQueue[i]=P:_getBlock(pieces[i+1],nil,nil,0)
        end

        P.modeData.meter=P.modeData.meter-250
    end,

    cost=250,
    
    title=function(P)
        return "The Gambler"
    end,

    rulesText=function(P)
        return {
            "250 MP: Fully randomize the",
            "current and upcoming pieces.",
            "You will get at least one I5.",
        }
    end,
}
