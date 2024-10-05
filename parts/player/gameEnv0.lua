return {
    das=10,arr=2,
    dascut=0,irscut=6,dropcut=0,
    sddas=2,sdarr=2,
    ihs=true,irs=true,ims=true,
    logicalIHS=true,logicalIRS=true,logicalIMS=true,

    ghostType='gray',
    block=true,ghost=.3,center=1,
    smooth=false,grid=.16,lineNum=.5,
    upEdge=true,
    bagLine=true,
    text=true,
    score=true,
    lockFX=2,
    dropFX=2,
    moveFX=2,
    clearFX=2,
    splashFX=2,
    shakeFX=2,
    atkFX=2,

    bufferWarn=false,
    highCam=false,
    nextPos=false,
    showSpike=false,

    hideBoard=false,
    flipBoard=false,

    drop=60,lock=60,
    wait=0,fall=0,
    hang=5,hurry=1e99,
    bone=false,
    lockout=false,
    fieldW=10,
    fieldH=20,heightLimit=1e99,
    trueNextCount=10,nextCount=6,nextStartPos=1,
    holdMode='hold',holdCount=1,
    infHold=false,phyHold=false,
    ospin=true,deepDrop=false,
    RS='TRS',
    sequence='bag',
    seqData={1,2,3,4,5,6,7},
    skinSet='crystal_scf',
    face=false,skin=false,
    mission=false,

    life=0,
    garbageSpeed=1,
    pushSpeed=3,
    noTele=false,
    visible='show',
    freshLimit=1e99,easyFresh=true,
    bufferLimit=1e99,
    fillClear=true,
    groupClear=false,

    layout='normal',
    fkey1=false,fkey2=false,
    keyCancel={},
    fine=false,fineKill=false,
    b2bKill=false,
    missionKill=false,
    mindas=0,minarr=0,minsdarr=0,
    noInitSZO=false,

    mesDisp={},
    hook_drop={},
    hook_die={},
    hook_atk_calculation={},
    task={},

    extraEvent={
        {'attack', 4},
        {'removePlayer', 1},
    },
    extraEventHandler={
        attack=function(P, source, ...)
            P:beAttacked(source, ...)
        end,

        removePlayer=function(P, source, ...)
        
        end,
    },

    eventSet="X",

    bg='none',bgm='race',
    allowMod=true,
    blockColors={1,4,7,12},
    groupClearable={[1]=true,[4]=true,[7]=true,[12]=true},
    adjClearable={[19]=true,[20]=true,[21]=true,[22]=true,[23]=true},

    preCascade = false,
}
