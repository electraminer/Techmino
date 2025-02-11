
local getSeqGen=require"parts.player.seqGenerators"

local renderMeter=function(P)
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


local CARDS={
    locations={"greenMeadows","darkCavern","arenaOfGlory","holyTemple"},
    virtues={
        "cleanliness","creativity","diligence","intelligence",
        "lawfulness","perseverance","reliability","simplicity",
    },
    characters={"annhilator","architect","cheater","gambler"},
    goals={"entrepreneurship","perfection","sustainability","satisfaction","equality","mastery"},
}

local TYPES={"locations","virtues","virtues","characters","characters","goals","goals"}

local initCards=function(P)
    P.modeData.cards={}
    for i=1,#TYPES do
        local type=TYPES[i]
        if P.modeData.choices[i]==0 then
            local toUpper=(TYPES[i]:gsub("^%l", string.upper))
            table.insert(P.modeData.cards, {
                title=function(P) return "Random "..string.sub(toUpper,0,-2) end,
                rulesText=function(P) return {"???"} end,
            })
        else
            local card=require("parts.cards."..type.."."..CARDS[type][P.modeData.choices[i]])
            table.insert(P.modeData.cards, card)
        end
    end
end

local finalizeCards=function(P)
    P.modeData.cards={}
    P.modeData.characters={}
    cardsUsed={} -- Keep track of card names used to prevent duplicates
    for i=1,#TYPES do
        local type=TYPES[i]
        local choice=P.modeData.choices[i]
        if choice==0 then
            choice=P.seqRND:random(#CARDS[type])
            -- Reroll until we find something that hasn't been used before
            while cardsUsed[type.."."..CARDS[type][choice]] do
                choice=P.seqRND:random(#CARDS[type])
            end
        end
        -- Add card if not a duplicate
        local card=require("parts.cards."..type.."."..CARDS[type][choice])
        if cardsUsed[type.."."..CARDS[type][choice]] then
            table.insert(P.modeData.cards, {
                title=function(P) return "None" end,
                rulesText=function(P) return {} end,
            })
            P.modeData.choices[i]=-1
        else
            cardsUsed[type.."."..CARDS[type][choice]]=true
            table.insert(P.modeData.cards, card)
            P.modeData.choices[i]=choice
            if type=="characters" then
                table.insert(P.modeData.characters, card)
            end
        end
    end
end

return {
    mesDisp=function(P)
        -- Calculate score with bonuses
        local finalScore=P.modeData.score
        for i=1,#P.modeData.cards do
            if P.modeData.cards[i].score then
                finalScore=finalScore+P.modeData.cards[i].score(P)
            end
        end
        local scoreStr=string.format("%06d",finalScore)
            .."  "..string.format("%02d",P.modeData.rowProgress)
            .."/"..P.modeData.rowTarget
        local y=-80
        setFont(55)
        if P.modeData.selectingCards then
            setFont(40)
            scoreStr=P.modeData.ready and "Readied Up" or "Hard Drop to Ready Up"
            y=-70
        elseif P.stat.piece==0 and P.waiting>0 then
            setFont(40)
            scoreStr="Starting in "..math.floor(P.waiting/60)
            y=-70
        end
        GC.mStr(scoreStr, 300,y)

        local y=-30

        if P.type=='human' then
            setFont(30)
            GC.print("Rules",600,y)
            y=y+30

            for i=1,#P.modeData.cards do
                GC.setColor(1,1,1)
                if P.modeData.selected==i then
                    GC.setColor(1,0,0)
                end
                setFont(25)
                if P.modeData.cards[i].title then
                    GC.print(P.modeData.cards[i].title(P),600,y+5)
                end
                y=y+30
                if P.modeData.cards[i].rulesText then
                    setFont(25)
                    local rulesText=P.modeData.cards[i].rulesText(P)
                    for i=1,3 do
                        setFont(20)
                        GC.print(rulesText[i] or "",600,y)
                        y=y+20
                    end
                end
            end
        end
        renderMeter(P)
    end,
    task=function(P)
        -- Set row target (we do this up top so that the player can place their piece during setup without counting as game end)
        P.modeData.rowTarget=100
        -- Set up card selection
        P.modeData.cards={}
        P.modeData.choices={}
        P.modeData.ready=false
        -- Hide most of the board for card selection
        P.gameEnv.nextCount=0
        P.gameEnv.holdCount=0
        local firstPiece=P.nextQueue[1]
        P.nextQueue[1]=P:_getBlock(5,nil,nil,0)
        -- Wait 1 frame to go to the actual start of the game
        coroutine.yield()
        P.modeData.neededPlayers=#PLAYERS
        -- Set all choices to 0 (RANDOM)
        for i=1,#TYPES do
            table.insert(P.modeData.choices, 0)
        end
        initCards(P,false)
        -- Record the base position of the player's piece, this is used to detect movements and rotations
        local baseX=P.curX
        local baseY=P.curY
        local baseDir=P.cur.dir
        if P.sid==1 then
            P.modeData.selected=1
        end
        P.modeData.selectingCards=true
        P.gameEnv.wait=60*30
        P.gameEnv.hurry=0
        while P.modeData.selectingCards do
            if not P.cur then
                P.control=false
                if not P.modeData.ready then
                    P.modeData.ready=true
                    P:extraEvent('readyUp')
                    P.stat.piece=0
                end
            elseif P.sid~=1 then
                -- Non-host players cannot choose
            elseif P.cur.dir==(baseDir+1)%4 then
                -- Rotate right moves up (since this is often bound to Up)
                P:spin(3)
                P.modeData.selected=P.modeData.selected-1
            elseif P.cur.dir==(baseDir+3)%4 then
                -- Rotate left moves down (to be opposite of rotate right)
                P:spin(1)
                P.modeData.selected=P.modeData.selected+1
            elseif P.curY<baseY then
                -- Move down moves down
                P.modeData.selected=P.modeData.selected+1
            elseif P.curX<baseX then
                -- Move left moves left
                P:extraEvent('chooseCard', P.modeData.selected, P.modeData.choices[P.modeData.selected]-1)
            elseif P.curX>baseX then
                -- Move right moves right
                P:extraEvent('chooseCard', P.modeData.selected, P.modeData.choices[P.modeData.selected]+1)
            end
            -- Reset piece position
            P.curX=baseX
            P.curY=baseY
            -- Make sure selection stays within bounds (wrapping if needed)
            if P.sid==1 then
                P.modeData.selected=((P.modeData.selected-1)%#TYPES)+1
            end
            coroutine.yield()
        end
        P.modeData.selected=-1
        -- Reset game
        P.field={}
        P.visTimes={}
        table.insert(P.nextQueue,1,firstPiece)
        P.gameEnv.pushSpeed=10
        P.gameEnv.nextCount=4
        P.gameEnv.holdCount=1
        P.gameEnv.drop=5
        P.gameEnv.lock=30
        P.gameEnv.wait=0
        P.gameEnv.hurry=1e99
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
        -- Disable attacks
        P.strength=-4
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
            -- Cap the meter
            P.modeData.meter=math.min(P.modeData.meter,1000)
            -- Clear normal b2b
            P.b2b=0
            -- Trigger cards that tick every frame
            for i=1,#P.modeData.cards do
                if P.modeData.cards[i].tick then
                    P.modeData.cards[i].tick(P)
                end
            end
            coroutine.yield()
        end
    end,
    hook_drop=function(P)
        score=0
        b2b=false
        if P.lastPiece.pc or P.lastPiece.hpc then --PC (or HPC, because of garbage)
            b2b=true
            score=400*(1+P.lastPiece.row)
        elseif P.lastPiece.spin then -- Spin
            b2b=true
            score=400*(1+P.lastPiece.row)
            if P.lastPiece.mini then
                score=score/4
            elseif P.lastPiece.id~=5 then -- All-spin
                score=score/2
            end
        elseif P.lastPiece.row>=4 then --Quad
            b2b=true
            score=800+1200*(P.lastPiece.row-4)
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

        -- End the game
        if P.modeData.rowProgress>=P.modeData.rowTarget then
            P.control=false
        end
        
    end,

    hook_die=function(P)
        P.curY=P.curY+20
        P.control=false
        return
    end,

    fkey1=function(P)
        if P.modeData.characters~=0 and #P.modeData.characters>=1 then
            P.modeData.characters[1].activate(P)
        end
    end,

    fkey2=function(P)
        if P.modeData.characters~=0 and #P.modeData.characters>=2 then
            P.modeData.characters[2].activate(P)
        end
    end,

    extraEvent={
        {'chooseCard',2},
        {'readyUp',0},
        {'finalizeCards',0},
    },

    extraEventHandler={
        chooseCard=function(P,source,slot,choice)
            P.modeData.choices[slot]=choice%(#CARDS[TYPES[slot]]+1)
            initCards(P)
        end,
        readyUp=function(P,source)
            P.modeData.neededPlayers=P.modeData.neededPlayers-1
            if P.sid==1 and P.modeData.neededPlayers==0 then
                P:extraEvent('finalizeCards')
            end
        end,
        finalizeCards=function(P,source)
            finalizeCards(P)
            P.modeData.selectingCards=false
            P.control=true
        end,
    },
}
