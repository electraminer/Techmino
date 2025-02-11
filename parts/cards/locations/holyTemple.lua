return {
    init=function(P)
        P.modeData.lastMeter=0
        -- Garbage contains 2 holes
        P.modeData.garbageDistribution=function()
            local hole1=P.atkRND:random(10)
            local hole2=P.atkRND:random(10)
            if P.atkRND:random(2)==1 and hole1~=hole2 then
                local line=1023
                line=line-math.pow(2,hole1)
                line=line-math.pow(2,hole2)
                return line
            end
            return generateLine(hole1)
        end
    end,

    tick=function(P)
        if P.modeData.meter>P.modeData.lastMeter then
            local increase=P.modeData.meter-P.modeData.lastMeter
            P.modeData.meter=P.modeData.meter+increase*0.5
        end
        P.modeData.lastMeter=P.modeData.meter
    end,
    
    title=function(P)
        return "Holy Temple"
    end,

    rulesText=function(P)
        return {
            "Meter charges 50% faster.",
            "Garbage often contains 2 holes.",
        }
    end,
}
