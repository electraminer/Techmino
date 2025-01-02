return {
    -- White T piece mode - when you place 2 T pieces in a row, you get a third for free
    task=function(P)
        -- Do something once, or in a loop
        MES.new('', "Run at Initialization")
        P.modeData.lastIsTSpin=false

        while true do
            coroutine.yield()
            -- MES.new('', "Run Every Frame")
        end
    end,

    hook_atk_calculation=function(P)
        if P.lastPiece.color==21 and P.lastPiece.spin and P.lastPiece.row>0 then
            P.lastPiece.atk=P.lastPiece.atk+4
        end
    end,

    hook_drop=function(P)
        local isTSpin=P.lastPiece.row>0 and P.lastPiece.spin and P.lastPiece.id==5 and P.lastPiece.color~=21
        if isTSpin and P.modeData.lastIsTSpin then
            table.insert(P.nextQueue, 1, P:_getBlock(5,nil,21,nil))
        end
        -- Update last T spin
        P.modeData.lastIsTSpin=isTSpin
    end,

    mesDisp=function(P)
        -- Do any visual updates (like score counters)
    end,
}
