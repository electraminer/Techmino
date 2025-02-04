
local getSeqGen=require"parts.player.seqGenerators"


renderMeter=function(P)
    GC.push("transform")
    -- Apply field swing
    local O=P.swingOffset
    if P.gameEnv.shakeFX then
        local k=P.gameEnv.shakeFX
        GC.translate(O.x*k+150+150,O.y*k+300)
        GC.rotate(O.a*k)
        GC.translate(-150,-300)
    else
        GC.translate(150,0)
    end

    if P.modeData.meterAnimation==0 then
        P.modeData.meterAnimation={
            start=0,
            target=math.min(P.modeData.meter,1000),
            startTime=P.frameRun,
        }
    end

    local animLength=20
    local animTime=P.frameRun-P.modeData.meterAnimation.startTime
    local animProgression=math.min(animTime/animLength, 1)

    local start=P.modeData.meterAnimation.start
    local target=P.modeData.meterAnimation.target
    local difference=target-start
    local lerp=start+difference*animProgression

    if P.modeData.meter~=target then
        P.modeData.meterAnimation.target=math.min(P.modeData.meter,1000)
        P.modeData.meterAnimation.start=lerp
        P.modeData.meterAnimation.startTime=P.frameRun
    end

    if animProgression<1 then
        if difference>0 then
            -- Increasing meter
            GC.setColor(.8,1,.2)
            GC.rectangle('fill', -14, 600-target*.6, 11, target*.6, 2)
            GC.setColor(1,0.5,0)
            GC.rectangle('fill', -14, 600-lerp*.6, 11, lerp*.6, 2)
        else
            -- Decreasing meter
            GC.setColor(.8,1,.2)
            GC.rectangle('fill', -14, 600-lerp*.6, 11, lerp*.6, 2)
            GC.setColor(1,0.5,0)
            GC.rectangle('fill', -14, 600-target*.6, 11, target*.6, 2)
        end
    elseif target>0 then
        -- Still meter
        GC.setColor(1,0.5,0)
        GC.rectangle('fill', -14, 600-target*.6, 11, target*.6, 2)
    end
    GC.pop()
end

return {
    mesDisp=function(P)
        setFont(55)
        GC.mStr(string.format("%06d",P.modeData.score),250,-80)
        GC.mStr(string.format("%02d",P.modeData.rowProgress),420,-80)
        renderMeter(P)
    end,
    task=function(P)
        -- Set up game env
        P.gameEnv.pushSpeed=10
        P.gameEnv.nextCount=4
        P.gameEnv.drop=5
        P.gameEnv.lock=30
        -- Set up custom setting defaults
        P.modeData.garbagePreview=4 --Number of garbage lines shown
        P.modeData.garbageDistribution=function() -- Function that generates garbage lines
            return generateLine(P.atkRND:random(10))
        end
        -- Set up variables
        P.modeData.score=0
        P.modeData.b2b=0
        P.modeData.combo=0
        P.modeData.rowProgress=0
        P.modeData.meter=0
        -- Choose cards
        P.modeData.location=require("parts.cards.locations.".."arenaOfGlory")
        P.modeData.virtues={
            require("parts.cards.virtues.".."reliability"),
            require("parts.cards.virtues.".."perseverance"),
        }
        -- Initialize cards list
        P.modeData.cards={}
        table.insert(P.modeData.cards,P.modeData.location)
        for i=1,#P.modeData.virtues do
            table.insert(P.modeData.cards,P.modeData.virtues[i])
        end
        -- Initialize cards
        for i=1,#P.modeData.cards do
            if P.modeData.cards[i].init then
                P.modeData.cards[i].init(P)
            end
        end
        -- Set up garbage
        for i=1,P.modeData.garbagePreview do
            P:garbageRise(20,1,P.modeData.garbageDistribution())
        end

        while true do
            -- Clear normal b2b
            P.b2b=0
            coroutine.yield()
        end
    end,
    hook_drop=function(P)
        score=0
        b2b=false
        if P.lastPiece.pc or P.lastPiece.hpc then --PC (or HPC, because of garbage)
            b2b=true
            score=400*(1+P.lastPiece.row)
        elseif P.lastPiece.id==5 and P.lastPiece.spin then -- Tspin
            b2b=true
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
        if P.lastPiece.row>0 then
            if b2b then
                if P.modeData.b2b>0 then
                    score=score*1.5
                end
                P.modeData.b2b=P.modeData.b2b+1
            else
                P.modeData.b2b=0
            end
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

        -- Trigger cards
        for i=1,#P.modeData.cards do
            if P.modeData.cards[i].hook_drop then
                P.modeData.cards[i].hook_drop(P)
            end
        end
        
    end
}
