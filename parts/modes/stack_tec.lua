return {
    env={
        life=1,
        drop=60,lock=60,
        wait=6,
        hang=15,
        pushSpeed=1e99,
        garbageSpeed=1,
        eventSet='stack_tec',
        bg='rainbow',bgm='push',
    },
    load=function()
        PLY.newPlayer(1)
        PLY.newAIPlayer(2,BOT.template{type='CC',speedLV=7,next=4,hold=true,node=40000})
    end,
}
