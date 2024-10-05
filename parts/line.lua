local LINE={}
function LINE.new(val,isGarbage,width)
    local t={}
    for i=1,width do t[i]=val end
    t.garbage=isGarbage==true
    return t
end
function LINE.discard(t)
end
return LINE
