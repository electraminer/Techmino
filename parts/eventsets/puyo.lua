return {
    fieldW=6,
    fieldH=12,
    sequence='bag',seqData={28},
    fillClear=false,
    groupClear=true,
    fall=60,
    preCascade=true,
    face={[28]=3},
    blockColors={1,4,7,12},
    groupClearable={[1]=true,[4]=true,[7]=true,[12]=true},
    adjClearable={[19]=true,[20]=true,[21]=true,[22]=true,[23]=true},
    
    hook_atk_calculation = function(P)
        -- Rescale attack to be measured in terms of puyos, instead of rows
        P.atk = P.atk * 6
    end,

    task = function(P)
        local W = P.gameEnv.fieldW
        -- Change garbage release to not release more than a rock (30 puyo) at once
        function P:garbageRelease()-- Check garbage buffer and try to release them
            local n=1
            local totalRecv = 0
            while true do
                local A=self.atkBuffer[n]
                if A and A.countdown<=0 and not A.sent then
                    totalRecv = totalRecv + A.amount
                    if totalRecv > W*5 then
                        -- If put over 30, then only take the amount which hits 30
                        local extra = totalRecv - W*5
                        totalRecv = W*5
                        self.atkBufferSum = self.atkBufferSum - A.amount + extra
                        A.amount = extra
                        self.stat.pend = self.stat.pend + A.amount - extra
                        break
                    end
                    self.atkBufferSum=self.atkBufferSum-A.amount
                    A.sent,A.time=true,0
                    self.stat.pend=self.stat.pend+A.amount
                    n=n+1
                else
                    break
                end
            end
            -- Trim down field to ensure it isn't too big
            for i=1,#P.field do
                -- reverse iterate
                index = #P.field - i + 1
                empty = true
                for j=1,W do
                    if P.field[index] ~= 0 then
                        empty = false
                    end
                end
                if not empty then
                    -- Found top of field, stop
                    break
                end
                table.remove(P.field, index)
            end
            -- Send garbage all at once instead of in multiple chunks
            for i=#P.field,P.gameEnv.fieldH do
                -- Ensure field is full height so that garbage falls from above
                table.insert(P.field, LINE.new(0,true,W))
                table.insert(P.visTime, LINE.new(1e99,true,W))
            end
            local lineColor = 21
            if totalRecv == W*5 then
                -- sending a ROCK, change color
                lineColor = 22
            end
            for i=1,MATH.floor(totalRecv/W) do
                -- Insert a full line of garbage
                table.insert(P.field, LINE.new(lineColor,true,W))
                table.insert(P.visTime, LINE.new(1e99,true,W))
            end
            -- Insert a partially filled line
            local line = LINE.new(0,true,W)
            for i=1,totalRecv % W do
                local pos = self.holeRND:random(W)
                while line[pos] ~= 0 do
                    -- Reroll
                    pos = self.holeRND:random(W)
                end
                line[pos] = 20 -- Need to randomize this
            end
            table.insert(P.field, line)
            table.insert(P.visTime, LINE.new(1e99,true,W))
            
            -- Mark blocks for cascade so the garbage falls
            local cascadeBlocks = {}
            for y,row in ipairs(self.field) do
                for x,cell in ipairs(row) do
                    if cell then
                        cascadeBlocks[x + y * #row] = true
                    end
                end
            end
            if self:_cascade(cascadeBlocks) then
                self.fallingBlocks = cascadeBlocks
                
                self:_updateFalling(self.gameEnv.fall)

            end
        end
    end,
}
