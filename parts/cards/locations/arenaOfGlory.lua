return {
    init=function(P)
        -- Initialize 4-hist randomizer
        hist={1,2,1,2}
        function P:newNext()
            piece=P.seqRND:random(7)
            for attempt=1,4 do
                includes=false
                for i=1,4 do
                    if hist[#hist-i+1]==piece then
                        includes=true
                    end
                end
                if includes then
                    piece=P.seqRND:random(7)
                end
            end
            table.insert(hist, piece)
            P:getNext(piece, 0)
        end
        P.nextQueue={}
        for _=1,P.gameEnv.trueNextCount do
            P:newNext()
        end
        -- Increase gravity
        P.gameEnv.drop=0
        -- Reduce DAS (so that gravity works)
        P.gameEnv.arr=math.max(P.gameEnv.arr,1)
        -- Increase entry delay (so that IRS works)
        P.gameEnv.wait=math.max(P.gameEnv.wait,6)
    end,

    title=function(P)
        return "Arena of Glory"
    end,

    rulesText=function(P)
        return {
            "Maximum gravity is enabled.",
            "Pieces no longer follow 7-bag.",
        }
    end,
}
