return {
    init=function(P)
        P.modeData.currentlyCheating=0
    end,

    activate=function(P)
        if P.modeData.currentlyCheating==0 then
            if P.modeData.meter<125 then return end
            -- Spend meter on the first cheat
            P.modeData.meter=P.modeData.meter-125
            -- You get 15 cheating charges (there are charges so you can't stall forever)
            P.modeData.currentlyCheating=15
        end

        -- Use a cheating charge
        P.modeData.currentlyCheating=P.modeData.currentlyCheating-1

        id=(P.cur.id%7)+1
        -- Respawn the current piece
        P.cur=P:_getBlock(id,nil,nil,0)
        P:resetBlock()
        P:freshMoveBlock()
    end,

    hook_drop=function(P)
        -- Reset cheating charges when you place the piece
        P.modeData.currentlyCheating=0
    end,

    cost=125,
    
    title=function(P)
        return "The Cheater"
    end,

    rulesText=function(P)
        return {
            "125 MP: Select the next piece.",
            "Repeat the ability to cycle",
            "between pieces for free.",
        }
    end,
}
