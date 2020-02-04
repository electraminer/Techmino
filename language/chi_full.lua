local BK="返回"
local actName={
	"左移:","右移:",
	"顺时针旋转:","逆时针旋转:","180°旋转:",
	"硬降:","软降:",
	"暂存:","功能键:",
	"重新开始:",
	"左瞬移:","右瞬移:","软降到底:","软降一格:","软降四格:","软降十格:",
	"落在最左:","落在最右:","列在最左:","列在最右:",
}
return{
	atkModeName={"随机","徽章","击杀","反击"},
	royale_remain=function(n)return"剩余 "..n.." 名玩家"end,
	cmb={nil,nil,"3 Combo","4 Combo","5 Combo","6 Combo","7 Combo","8 Combo","9 Combo","10 Combo!","11 Combo!","12 Combo!","13 Combo!","14 Combo!","15 Combo!","16 Combo!","17 Combo!","18 Combo!","19 Combo!","MEGACMB"},
	techrash="四清",
	techrashB2B="满贯 四清",
	techrashB3B="大满贯 四清",
	block={"Z","S","L","J","T","O","I"},
	clear={"单清","双清","三清"},
	spin={"Z型回旋","S型回旋","L型回旋","J型回旋","T型回旋","O型回旋","I型回旋"},
	b2b="满贯",b3b="大满贯",
	mini="迷你",
	PC="场地全清",
	hold="暂存",next="下一个",

	stage=function(n)return"关卡 "..n end,
	great="不错!",
	awesome="精彩。",
	continue="继续。",
	maxspeed="最高速度",
	speedup="速度加快",

	win="胜利",
	lose="失败",
	pause="暂停",
	finish="结束",
	pauseCount="暂停统计",

	custom="自定义游戏",
	customOption={
		drop="下落延迟:",
		lock="锁定延迟:",
		wait="放块延迟:",
		fall="消行延迟:",
		next="序列数量:",
		hold="暂存:",
		sequence="序列:",
		visible="可见性:",
		target="目标行数:",
		freshLimit="锁延刷新次数:",
		opponent="对手速度等级:",
		bg="背景:",
		bgm="背景音乐:",
	},
	customVal={
		drop={"[20G]",1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,25,30,40,60,180,"∞"},
		lock={0,1,2,3,4,5,6,7,8,9,10,12,14,16,18,20,25,30,40,60,180,"∞"},
		wait=nil,
		fall=nil,
		next=nil,
		hold={"开","关","无限"},
		sequence={"bag7","his4","随机"},
		visible={"可见","半隐","全隐","瞬隐"},
		target={10,20,40,100,200,500,1000,"∞"},
		freshLimit={0,8,15,"∞"},
		opponent={"无电脑","9S Lv1","9S Lv2","9S Lv3","9S Lv4","9S Lv5","CC Lv1","CC Lv2","CC Lv3","CC Lv4","CC Lv5","CC Lv6"},
	},
	softdropdas="软降DAS:",
	softdroparr="软降ARR:",
	snapLevelName={"任意摆放","10px吸附","20px吸附","40px吸附","60px吸附","80px吸附"},
	keyboard="键盘",joystick="手柄",
	space="空格",enter="回车",
	ctrlSetHelp="方向键选择/翻页,回车修改,esc返回",
	setting_game="游戏设置",
	setting_graphic="画面设置",
	setting_sound="声音设置",
	musicRoom="音乐室",
	nowPlaying="正在播放:",
	VKTchW="触摸点权重",
	VKOrgW="原始点权重",
	VKCurW="当前点权重",

	actName=actName,
	modeName={
		[0]="自定义",
		"竞速","马拉松","大师","经典","禅","无尽","单挑","回合制","仅TSD","隐形",
		"挖掘","生存","防守","进攻","科研",
		"C4W练习","全清训练","全清挑战","49人混战","99人混战","干旱","多人",
	},
	modeInfo={
		sprint="挑战世界纪录",
		marathon="尝试坚持到最后",
		master="成为方块大师",
		classic="高速经典",
		zen="无重力消除200行",
		infinite="科研沙盒",
		solo="打败AI",
		round="下棋",
		tsd="尽可能做T旋双清",
		blind="最强大脑",
		dig="核能挖掘机",
		survivor="你能存活多久?",
		defender="防守练习",
		attacker="进攻练习",
		tech="尽可能不要普通消除!",
		c4wtrain="无 限 连 击",
		pctrain="熟悉全清定式的组合",
		pcchallenge="100行内尽可能多全清",
		techmino49="49人混战",
		techmino99="99人混战",
		drought="异常序列",
		hotseat="友尽模式",
	},

	load={"加载语音ing","加载音乐ing","加载音效ing","加载完成",},
	tips={
		"不是动画,真的在加载!",
		"大满贯10连击消四全清!",
		"<方块研究所>有一个Nspire-CX版本!",
		"B2B2B???",
		"B2B2B2B存在吗?",
		"MEGACMB!",
		"ALLSPIN!",
		"O型回旋三清!",
		"Miya:喵!",
		"225238922  哔哩哔哩 干杯~",
		"适度游戏益脑,沉迷游戏伤身,合理安排时间,享受健康生活",
		"合群了就会消失,但是消失不代表没有意义",
		"学会使用两个旋转键,三个更好",
		"更小的DAS和ARR拥有更高的操作上限(如果你还能控制得了的话)",
		"注意到\"旋转\"到底对方块做了些什么吗?",
		"20G本质是一套全新的游戏规则",
		"不要在上课时玩游戏!",
		"本游戏难度上限很高,做好心理准备",
		"方块可以不是个休闲游戏",
		"调到特殊的日期也不会发生什么的",
		"3.1415926535897932384",
		"2.7182818284590452353",
		"Let-The-Bass-Kick!",
		"使用love2d引擎制作",
		"有疑问?先看设置有没有你想要的",
		"有建议的话可以把信息反馈给作者~",
		"不要按F8",
		"秘密代码:626",
		"CLASSIC SEXY RUSSIAN BLOCKS",
		"戴上耳机获得最佳体验",
		"LrL,RlR  LLr,RRl  RRR/LLL  F!!",--ZSLJTTI
	},
	stat={
		"游戏运行次数:",
		"游戏局数:",
		"游戏时间:",
		"按键数:",
		"旋转数:",
		"暂存次数:",
		"方块使用:",
		"消行数:",
		"攻击行数:",
		"发送数:",
		"接收数:",
		"上涨数:",
		"消除数:",
		"旋转消行数:",
		"满贯数:",
		"全清数:",
		"效率:",
		"多余操作:",
		"最简操作率:",
	},
	help={
		"好像也没啥好帮助的吧?就当是关于了",
		"这只是一个方块游戏,请勿过度解读和随意联想",
		"不过就当成TOP/C2/KOS/TGM3/JS玩好了",
		"游戏还在测试阶段,请 勿 外 传",
		"",
		"使用LOVE2D引擎",
		"作者:MrZ   邮箱:1046101471@qq.com",
		"程序:MrZ  美术:MrZ  音乐:MrZ  音效:MrZ 语音:Miya",
		"特别感谢:Farter,Flyz,196,Teatube,T830,[所有测试人员]和 你!",
		"错误或者建议请附带相关信息发送到作者邮箱~",
	},
	used=[[
使用工具:
	Beepbox
	GFIE
	Goldwave
使用库:
	Cold_Clear[MinusKelvin]
	simple-love-lights[dylhunn]
]],
	support="支持作者",
	group="官方QQ群",
	warning="禁 止 私 自 传 播",
	WidgetText={
		main={
			lang="全-Lang",
			qplay="快速开始",
			play="开始",
			setting="设置",
			music="音乐室",
			stat="统计信息",
			help="帮助",
			quit="退出",
		},
		mode={
			up="↑",
			down="↓",
			left="←",
			right="→",
			start="开始",
			custom="自定义(C)",
			back=BK,
		},
		music={
			bgm="BGM",
			up="↑",
			play="播放",
			down="↓",
			back=BK,
		},
		custom={
			up="↑",
			down="↓",
			left="←",
			right="→",
			start1="消除开始",
			start2="拼图开始",
			draw="画图(D)",
			set1="40行(1)",
			set2="1v1(2)",
			set3="无尽(3)",
			set4="隐形(4)",
			set5="极限(5)",
			back=BK,
		},
		draw={
			any="不定",
			block1="Z",
			block2="S",
			block3="L",
			block4="J",
			block5="T",
			block6="O",
			block7="I",
			gb1="■",
			gb2="■",
			gb3="■",
			gb4="■",
			gb5="■",
			space="×",
			clear="清除",
			back=BK,
		},
		play={
			pause="暂停",
		},
		pause={
			resume=	"继续",
			restart="重新开始",
			setting="设置",
			quit=	"退出",
		},

		setting_game={
			graphic="←画面设置",
			sound="声音设置→",
			dasD="-",dasU="+",
			arrD="-",arrU="+",
			sddasD="-",sddasU="+",
			sdarrD="-",sdarrU="+",
			quickR="快速重新开始",
			swap="组合键切换攻击模式",
			fine="极简操作提示音",
			ctrl="键位设置",
			touch="触屏设置",
			back=BK,
		},
		setting_graphic={
			sound="←声音设置",
			game="游戏设置→",
			ghost="阴影",
			grid="网格",
			center="旋转中心",
			skin="皮肤",
			bg="背景",
			bgblock="背景动画",
			smo="平滑下落",
			dropFX="下落特效等级",
			shakeFX="晃动特效等级",
			atkFX="攻击特效等级",
			fullscreen="全屏",
			frame="绘制帧率",
			back=BK,
		},
		setting_sound={
			game="←游戏设置",
			graphic="画面设置→",
			sfx="音效",
			bgm="音乐",
			vib="震动",
			voc="语音",
			stereo="双声道",
			back=BK,
		},
		setting_key={
			back=BK,
		},
		setting_touch={
			hide="显示虚拟按键",
			track="按键自动跟踪",
			tkset="跟踪设置",
			default="默认组合",
			snap=function()return text.snapLevelName[snapLevel]end,
			alpha=function()return setting.VKAlpha.."0%"end,
			icon="图标",
			size="大小",
			toggle="开关",
			back=BK,
		},
		setting_touchSwitch={
			b1=	actName[1],b2=actName[2],b3=actName[3],b4=actName[4],
			b5=	actName[5],b6=actName[6],b7=actName[7],b8=actName[8],
			b9=	actName[9],b10=actName[10],b11=actName[11],b12=actName[12],
			b13=actName[13],b14=actName[14],b15=actName[15],b16=actName[16],
			b17=actName[17],b18=actName[18],b19=actName[19],b20=actName[20],
			norm="标准",
			pro="专业",
			back=BK,
		},
		setting_trackSetting={
			VKDodge="自动避让",
			back=BK,
		},
		help={
			his="历史",
			qq="作者QQ",
			back=BK,
		},
		history={
			prev="↑",
			next="↓",
			back=BK,
		},
		stat={
			path="打开存储目录",
			back=BK,
		},
	},
}