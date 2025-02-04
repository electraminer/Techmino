
local getSeqGen=require"parts.player.seqGenerators"

return {
    mesDisp=function(P)
        setFont(55)
        GC.mStr(string.format("%06d",P.modeData.score),250,-80)
        GC.mStr(string.format("%02d",P.modeData.rowProgress),420,-80)
    end,
    task=function(P)
        P.gameEnv.pushSpeed=10
        P.gameEnv.nextCount=4
        P.gameEnv.drop=4
        P.gameEnv.lock=30

        P.modeData.garbagePreview=4 --Number of garbage lines shown
        P.modeData.garbageDistribution=function() -- Function that generates garbage lines
            return generateLine(P.atkRND:random(10))
        end

        P.modeData.score=0
        P.modeData.b2b=0
        P.modeData.combo=0
        P.modeData.rowProgress=0
        P.modeData.meter=1000
        
        P.modeData.location=require("parts.cards.locations.".."darkCavern")

        if P.modeData.location.init then
            P.modeData.location.init(P)
        end

        for i=1,P.modeData.garbagePreview do
            P:garbageRise(20,1,P.modeData.garbageDistribution())
        end
    end,
    hook_drop=function(P)
        score=0
        b2b=false
        if P.lastPiece.pc or P.lastPiece.hpc then --PC (or HPC, because of garbage)
            b2b=true
            score=400*(1+P.lastPiece.row)
        elseif P.lastPiece.id==5 and P.lastPiece.spin then -- Tspin
            if P.lastPiece.row>0 then
                b2b=true
            end
            score=400*(1+P.lastPiece.row)
            if P.lastPiece.mini then
                score=score/2
            end
        elseif P.lastPiece.row==4 then --Quad
            b2b=true
            score=800
        elseif P.lastPiece.row>0 then --Normal clear
            score=({100,300,500})[P.lastPiece.row]
        end
        --Handle b2b
        if b2b and P.modeData.b2b>0 then
            score=score*1.5
            P.modeData.b2b=P.modeData.b2b+1
        else
            P.modeData.b2b=0
        end
        --Handle combo
        if P.lastPiece.row>0 then
            score=score+P.modeData.combo*50
            P.modeData.combo=P.modeData.combo+1
        else
            P.modeData.combo=0
        end
        --Update score
        P.modeData.score=P.modeData.score+score

        --Update line counter
        P.modeData.rowProgress=P.modeData.rowProgress+P.lastPiece.row-P.lastPiece.dig

        --Add new garbage
        for i=1,P.lastPiece.dig do
            P:garbageRise(20,1,P.modeData.garbageDistribution())
        end
    end
}
