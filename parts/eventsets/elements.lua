ELEMENTS = {
    fire = COLOR.red,
    water = COLOR.sea,
}

return {
    task = function(P)
        local elements = {}
        for element,_ in pairs(ELEMENTS) do
            elements[element] = 0
        end
        P.modeData.elements = elements
    end,

    hook_atk_calculation = function(P)
        -- Remove back-to-back, since the bar is being used for something else.
        P.b2b = 0
        
        local total = 0
        for element,amount in pairs(P.modeData.elements) do
            total = total + amount
        end
        P.atk = P.atk + total / 200

        local piece = P.lastPiece
        if piece.spin then
            if piece.id == 1 then -- Z
                P.modeData.elements.fire = P.modeData.elements.fire + 50 * piece.row
            elseif piece.id == 3 then -- J
                P.modeData.elements.water = P.modeData.elements.water +  50 * piece.row
            end
            P:extraEvent('breakElement', piece.id)
        end

    end,
    extraEvent = {
        {'breakElement', 1},
    },

    extraEventHandler = {
        breakElement = function(P, source, pieceId)
            if P.sid ~= source then
                if pieceId == 3 then
                    P.modeData.elements.fire = 0
                elseif pieceId == 1 then
                    P.modeData.elements.water = 0
                end
            end
        end,
    },
    
    -- VISUALS
    mesDisp=function(P)
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

            if P.modeData.elemAnimation == 0 then
                local start = {}
                local target = {}
                for element,_ in pairs(ELEMENTS) do
                    start[element] = 0
                    target[element] = P.modeData.elements[element]
                end
                P.modeData.elemAnimation = {
                    start = start,
                    target = target,
                    startTime = P.frameRun,
                }
            end

            local animLength = 20
            local animTime = P.frameRun - P.modeData.elemAnimation.startTime
            local animProgression = math.min(animTime / animLength, 1)

            local elements = {}
            local modified = false
            local difference = 0
            local total = 0
            local lastAmount = 0
            for element,_ in pairs(ELEMENTS) do
                local start = P.modeData.elemAnimation.start[element]
                local target = P.modeData.elemAnimation.target[element]
                local amount = start + (target - start) * animProgression
                elements[element] = amount
                total = total + amount
                lastAmount = amount
                difference = difference + target - start

                if P.modeData.elements[element] ~= target then
                    modified = true
                    P.modeData.elemAnimation.target[element] = P.modeData.elements[element]
                end
            end

            if modified then
                P.modeData.elemAnimation.start = elements
                P.modeData.elemAnimation.startTime = P.frameRun
            end

            if animProgression < 1 then
                if difference > 0 then
                    -- Increasing meter
                    local amount = difference * (1 - animProgression)
                    total = total + amount
                    GC.setColor(.8,1,.2)
                    GC.rectangle('fill', -14, 600-total*.6, 11, (amount + lastAmount)*.6, 2)
                else
                    -- Decreasing meter
                    local amount = -difference * animProgression
                    total = total + amount
                    GC.setColor(.8,1,.2)
                    GC.rectangle('fill', -14, 600-total*.6, 11, (amount + lastAmount)*.6, 2)
                end
            end

            local total = 0
            for element,amount in pairs(elements) do
                if amount > 0 then
                    lastAmount = amount
                    total = total + amount
                    GC.setColor(ELEMENTS[element])
                    GC.rectangle('fill', -14, 600-total*.6, 11, amount*.6, 2)
                end
            end
        GC.pop()
        -- Display main colored bar
        -- Display flashing top meter
        -- if TIME()%.5<.3 then
        --     GC.setColor(1,1,1)
        --     GC.rectangle('fill',-15,b<50 and 570 or 120,13,3,2)
        -- end
    end,
}