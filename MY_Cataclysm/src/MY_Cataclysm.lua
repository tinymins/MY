--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 团队面板模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Cataclysm/MY_Cataclysm'
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_Cataclysm', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Enable Cataclysm Team Panel'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	eCss = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['configure'],
			_L['Raid style preset'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = '',
	},
	eFrameStyle = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			_L['Interface style'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = 'CATACLYSM',
	},
	bDrag = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			g_tStrings.WINDOW_LOCK,
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowInRaid = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Only in team'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEditMode = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			(string.gsub(g_tStrings.STR_RAID_MENU_RAID_EDIT, 'Ctrl', 'Alt')),
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowAllGrid = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Show AllGrid'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAnchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['UI Anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { s = 'LEFTCENTER', r = 'LEFTCENTER', x = 100, y = -200 },
	},
	nAutoLinkMode = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			_L['Arrangement'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 5,
	},
	nBGColorMode = { -- 0 不着色 1 根据距离 2 根据门派
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			g_tStrings.BACK_COLOR,
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nColoredName = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Name'],
			_L['Colored by...'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nNameVAlignment = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Name'],
			_L['V alignment'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nNameHAlignment = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Name'],
			_L['H alignment'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	nHPShownMode2 = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['Show mode'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	nHPShownNumMode = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['Show number mode'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 3,
	},
	nHPVAlignment = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['V alignment'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	nHPHAlignment = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['H alignment'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	bShowHPDecimal = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['Show Decimal'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffAboveMana = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Over mana bar'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nShowMP = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Show ManaCount'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bHPHitAlert = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Attack Warning'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nShowIcon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Show Icon Mode'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 2,
	},
	bShowDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show distance'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowBossTarget = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show Boss target'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBossFocus = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show Boss focus'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			g_tStrings.STR_RAID_DISTANCE,
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bEnableImportantSkill = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show important skill'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTargetTargetAni = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show target\'s target'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nNameFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Name'],
			_L['Name font'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 40,
	},
	nLifeFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['Life font'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 15,
	},
	nManaFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Mana'],
			g_tStrings.STR_SKILL_MANA .. g_tStrings.FONT,
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 190,
	},
	fNameFontScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Name'],
			_L['Font scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1.05,
	},
	fLifeFontScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['HP'],
			_L['Font scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1.05,
	},
	fManaFontScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Style'],
			_L['Mana'],
			_L['Font scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nMaxShowBuff = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Max count'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 4,
	},
	bLifeGradient = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['LifeBar Gradient'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bManaGradient = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['ManaBar Gradient'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			g_tStrings.STR_ALPHA,
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 220,
	},
	fBuffScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Buff scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	bAutoBuffSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Auto scale'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAltView = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Alt view player'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAltViewInFight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Alt view player'],
			_L['Disable in fight'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bHideTipInFight = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Don\'t show tip in fight'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowTipAtRightBottom = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show tip at right bottom'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bTempTargetEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			g_tStrings.STR_RAID_TARGET_ASSIST,
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nTempTargetDelay = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Target assist delay setting'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 0,
	},
	fScaleX = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			_L['Interface Width'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1.1,
	},
	fScaleY = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			_L['Interface Height'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1.0,
	},
	nDrawInterval = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Faster Refresh (Greater performance loss)'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 4,
	},
	bFasterHP = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Ultimate Refresh HP (Greater performance loss)'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bStaring = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Buff Staring'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowBuffTime = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Show Buff Time'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBuffNum = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Show Buff Num'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBuffReminder = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Show Buff Reminder'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffAltPublish = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Alt Click Publish'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffPushToOfficial = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Push buff to official'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffDataOfficial = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Enable official data'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffDataTeamMon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Enable MY_TeamMon data'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowAttention = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show attention shadow'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowCaution = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show caution animate'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowScreenHead = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show screen head'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowGroupNumber = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Interface settings'],
			_L['Show Group Number'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowEffect = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['ZuiWu Effect'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false, -- 五毒醉舞提示 万花距离提示 晚点做
	},
	bShowSputtering = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Show central party member tag'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tSputteringFontColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Set sputtering font color'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 79, 255, 108 },
	},
	nSputteringFontAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Set sputtering font alpha'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 192,
	},
	tSputteringShadowColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Set sputtering shadow color'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 79, 255, 108 },
	},
	nSputteringShadowAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Set sputtering shadow alpha'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 192,
	},
	nSputteringDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['MY_Cataclysm'],
			_L['Set sputtering distance'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 15,
	},
	aBuffList = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Buff settings'],
			_L['Buff list'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Any),
		xDefaultValue = {},
	},
	tDistanceLevel = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Edit Distance Level'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 20, 22, 200 },
	},
	tManaColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Mana'],
			g_tStrings.STR_SKILL_MANA .. g_tStrings.BACK_COLOR,
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 0, 96, 255 },
	},
	tDistanceCol = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Distance color'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {
			{ 0,   180, 52  }, -- 绿
			{ 0,   180, 52  }, -- 绿
			-- 免得被说乱
			-- { 230, 170, 40  }, -- 黄
			{ 230, 80,  80  }, -- 红
			{ 230, 80,  80  }, -- 红
		},
	},
	tOtherCol = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Other color'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number)),
		xDefaultValue = {
			{ 255, 255, 255 },
			{ 110, 110, 110 },
			{ 192, 192, 192 },
		},
	},
	tDistanceAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Distance alpha'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Number),
		xDefaultValue = {
			255,
			255,
			110,
		},
	},
	tOtherAlpha = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		szDescription = X.MakeCaption({
			_L['Grid Color'],
			_L['Other alpha'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = {
			0,
			255, -- 不在线
			110, -- 出同步范围
		},
	},
})
local D = {
	CFG = O,
	bVisible = true,
	bFold = false,
	BG_COLOR_MODE = {
		SAME_COLOR = 0,
		BY_DISTANCE = 1,
		BY_FORCE = 2,
		OFFICIAL = 3,
	},
}

function D.AnnounceShielded()
	local bBlock = X.IsInCompetitionMap() and X.IsClientPlayerMountMobileKungfu()
	if bBlock and not D.bBlockMessageAnnounced then
		X.OutputSystemMessage(_L['MY_Cataclysm_Buff is blocked in current kungfu, temporary disabled.'])
	end
	D.bBlockMessageAnnounced = bBlock
end

-- 解析
function D.EncodeBuffRule(v, bNoBasic)
	local a = {}
	if not bNoBasic then
		table.insert(a, v.szName or v.dwID)
		if v.nLevel then
			table.insert(a, 'lv' .. v.nLevel)
		end
	end
	if v.nStackNum then
		table.insert(a, 'sn' .. (v.szStackOp or '>=') .. v.nStackNum)
	end
	if v.bOnlyMe then
		table.insert(a, 'me')
	end
	if v.bOnlyMine or v.bOnlySelf or v.bSelf then
		table.insert(a, 'mine')
	end
	a = { table.concat(a, '|') }

	if v.col then
		local cols = { v.col }
		if v.nColAlpha and v.col:sub(1, 1) ~= '#' then
			table.insert(cols, v.nColAlpha)
		end
		table.insert(a, '[' .. table.concat(cols, '|') .. ']')
	end
	if not X.IsEmpty(v.szReminder) then
		table.insert(a, '(' .. v.szReminder .. ')')
	end
	if v.nPriority then
		table.insert(a, '#' .. v.nPriority)
	end
	if v.bAttention then
		table.insert(a, '!!')
	end
	if v.bCaution then
		table.insert(a, '!!!')
	end
	if v.bScreenHead then
		if v.colScreenHead then
			table.insert(a, '!!!!|[' .. v.colScreenHead .. ']')
		else
			table.insert(a, '!!!!')
		end
	end
	if v.bDelete then
		table.insert(a, '-')
	end
	return table.concat(a, ',')
end

function D.DecodeBuffRule(line)
	line = X.TrimString(line)
	if line ~= '' then
		local tab = {}
		local vals = X.SplitString(line, ',')
		for i, val in ipairs(vals) do
			if i == 1 then
				local vs = X.SplitString(val, '|')
				for j, v in ipairs(vs) do
					v = X.TrimString(v)
					if v ~= '' then
						if j == 1 then
							tab.dwID = tonumber(v)
							if not tab.dwID then
								tab.szName = v
							end
						elseif v == 'self' or v == 'mine' then
							tab.bOnlyMine = true
						elseif v:sub(1, 2) == 'lv' then
							tab.nLevel = tonumber((v:sub(3)))
						elseif v:sub(1, 2) == 'sn' then
							if tonumber(v:sub(4, 4)) then
								tab.szStackOp = v:sub(3, 3)
								tab.nStackNum = tonumber((v:sub(4)))
							else
								tab.szStackOp = v:sub(3, 4)
								tab.nStackNum = tonumber((v:sub(5)))
							end
						end
					end
				end
			elseif val == '!!' then
				tab.bAttention = true
			elseif val == '!!!' then
				tab.bCaution = true
			elseif val == '!!!!' or val:sub(1, 5) == '!!!!|' then
				tab.bScreenHead = true
				local vs = X.SplitString(val, '|')
				for _, v in ipairs(vs) do
					if v:sub(1, 1) == '[' and v:sub(-1, -1) == ']' then
						tab.colScreenHead = v:sub(2, -2)
					end
				end
			elseif val == '-' then
				tab.bDelete = true
			elseif val:sub(1, 1) == '#' then
				tab.nPriority = tonumber((val:sub(2)))
			elseif val:sub(1, 1) == '[' and val:sub(-1, -1) == ']' then
				val = val:sub(2, -2)
				if val:sub(1, 1) == '#' then
					tab.col = val
				else
					local vs = X.SplitString(val, '|')
					tab.col = vs[1]
					tab.nColAlpha = vs[2] and tonumber(vs[2])
				end
			elseif val:sub(1, 1) == '(' and val:sub(-1, -1) == ')' then
				tab.szReminder = val:sub(2, -2)
			end
		end
		if tab.dwID or tab.szName then
			return tab
		end
	end
end

function D.OpenBuffRuleEditor(rec, onChangeNotify, onCloseNotify, bHideBase)
	local w, h = 320, 320
	local ui = X.UI.CreateFrame('MY_Cataclysm_BuffConfig', {
		w = w, h = h,
		text = _L['Edit buff'],
		close = true, anchor = 'CENTER',
	}):Remove(function()
		if not bHideBase and not rec.dwID and (not rec.szName or rec.szName == '') then
			onChangeNotify()
		end
		X.SafeCall(onCloseNotify)
	end)
	local nPaddingX, nPaddingY = 25, 60
	local x, y = nPaddingX, nPaddingY
	if not bHideBase then
		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Name or id'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 105, h = 25,
			text = rec.dwID or rec.szName,
			onChange = function(text)
				if tonumber(text) then
					rec.dwID = tonumber(text)
					rec.szName = nil
				else
					rec.dwID = nil
					rec.szName = text
				end
				onChangeNotify(rec)
			end,
		}):Width() + 15

		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Level'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 60, h = 25,
			placeholder = _L['No limit'],
			editType = X.UI.EDIT_TYPE.NUMBER, text = rec.nLevel,
			onChange = function(text)
				rec.nLevel = tonumber(text)
				onChangeNotify(rec)
			end,
		}):Width() + 5
		y = y + 30
		y = y + 10
	end

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Stacknum'],
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndComboBox', {
		name = 'WndComboBox_StackOp',
		x = x, y = y, w = 90, h = 25,
		text = rec.szStackOp
			and X.GetOperatorName(rec.szStackOp)
			or (rec.nStackNum and X.GetOperatorName('>=') or _L['No limit']),
		menu = function()
			local this = this
			local menu = {{
				szOption = _L['No limit'],
				fnAction = function()
					rec.szStackOp = nil
					ui:Children('#WndEditBox_StackNum'):Text('')
					onChangeNotify(rec)
					X.UI(this):Text(_L['No limit'])
					X.UI.ClosePopupMenu()
				end,
			}}
			return X.InsertOperatorMenu(
				menu,
				rec.szStackOp,
				function(szOp)
					rec.szStackOp = szOp
					onChangeNotify(rec)
					X.UI(this):Text(X.GetOperatorName(szOp))
					X.UI.ClosePopupMenu()
				end
			)
		end,
	}):Width() + 5
	x = x + ui:Append('WndEditBox', {
		name = 'WndEditBox_StackNum',
		x = x, y = y, w = 30, h = 25,
		editType = X.UI.EDIT_TYPE.NUMBER,
		text = rec.nStackNum,
		onChange = function(text)
			rec.nStackNum = tonumber(text)
			if rec.nStackNum then
				if not rec.szStackOp then
					rec.szStackOp = '>='
					ui:Children('#WndComboBox_StackOp'):Text(X.GetOperatorName('>='))
				end
			end
			onChangeNotify(rec)
		end,
	}):Width() + 10

	ui:Append('WndCheckBox', {
		x = x, y = y - 10,
		text = _L['Only mine'],
		checked = rec.bOnlyMine,
		onCheck = function(bChecked)
			rec.bOnlyMine = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	ui:Append('WndCheckBox', {
		x = x, y = y + 10,
		text = _L['Only me'],
		checked = rec.bOnlyMe,
		onCheck = function(bChecked)
			rec.bOnlyMe = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	y = y + 30
	y = y + 10

	if not bHideBase then
		x = nPaddingX
		y = y + 10
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Hide (Can Modify Default Data)'],
			checked = rec.bDelete,
			onCheck = function(bChecked)
				rec.bDelete = bChecked
				onChangeNotify(rec)
			end,
		}):AutoWidth():Width() + 5
		y = y + 30
		y = y + 10
	end

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Reminder'],
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 30, h = 25,
		text = rec.szReminder,
		onChange = function(text)
			rec.szReminder = text
			onChangeNotify(rec)
		end,
		autoEnable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Priority'],
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 40, h = 25,
		editType = X.UI.EDIT_TYPE.NUMBER,
		text = rec.nPriority,
		onChange = function(text)
			rec.nPriority = tonumber(text)
			onChangeNotify(rec)
		end,
		autoEnable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Color'],
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.col and {X.HumanColor2RGB(rec.col)} or {255, 255, 0},
		onLClick = function()
			local this = this
			X.UI.OpenColorPicker(function(r, g, b)
				local a = rec.col and select(4, X.Hex2RGB(rec.col)) or 255
				rec.nColAlpha = a
				rec.col = X.RGB2Hex(r, g, b, a)
				X.UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onRClick = function()
			X.UI(this):Color(255, 255, 0)
			rec.col = nil
			onChangeNotify(rec)
		end,
		tip = {
			render = _L['Left click to change color, right click to clear color'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		autoEnable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.colScreenHead and {X.HumanColor2RGB(rec.colScreenHead)} or {255, 255, 0},
		onLClick = function()
			local this = this
			X.UI.OpenColorPicker(function(r, g, b)
				rec.colScreenHead = X.RGB2Hex(r, g, b)
				X.UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onRClick = function()
			X.UI(this):Color(255, 255, 0)
			rec.colScreenHead = nil
			onChangeNotify(rec)
		end,
		tip = {
			render = _L['Left click to change screen head color, right click to clear color'],
			position = X.UI.TIP_POSITION.TOP_BOTTOM,
		},
		autoEnable = function() return not rec.bDelete end,
	}):Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Border alpha'],
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndSlider', {
		x = x, y = y, text = '',
		range = {0, 255},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		value = rec.col and select(4, X.HumanColor2RGB(rec.col)) or rec.nColAlpha or 255,
		onChange = function(nVal)
			if rec.col then
				local r, g, b = X.Hex2RGB(rec.col)
				if r and g and b then
					rec.col = X.RGB2Hex(r, g, b, nVal)
				end
			end
			rec.nColAlpha = nVal
			onChangeNotify(rec)
		end,
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Attention'],
		checked = rec.bAttention,
		onCheck = function(bChecked)
			rec.bAttention = bChecked
			onChangeNotify(rec)
		end,
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Caution'],
		checked = rec.bCaution,
		onCheck = function(bChecked)
			rec.bCaution = bChecked
			onChangeNotify(rec)
		end,
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Screen Head'],
		checked = rec.bScreenHead,
		onCheck = function(bChecked)
			rec.bScreenHead = bChecked
			onChangeNotify(rec)
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
		autoEnable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5

	y = y + 50
	ui:Append('WndButton', {
		x = (w - 120) / 2, y = y, w = 120,
		text = _L['Delete'], color = {223, 63, 95},
		buttonStyle = 'FLAT',
		onClick = function()
			local function fnAction()
				onChangeNotify()
				ui:Remove()
			end
			if rec.dwID or (rec.szName and rec.szName ~= '') then
				X.Confirm(_L('Delete [%s]?', rec.szName or rec.dwID), fnAction)
			else
				fnAction()
			end
		end,
	})
	y = y + 30

	h = y + 15
	ui:Height(h)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Cataclysm',
	exports = {
		{
			fields = {
				'CFG',
				'bVisible',
				'bFold',
				'BG_COLOR_MODE',
				'EncodeBuffRule',
				'DecodeBuffRule',
				'OpenBuffRuleEditor',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'CFG',
				'bVisible',
				'bFold',
				'BG_COLOR_MODE',
			},
			triggers = {
				bVisible = function()
					FireUIEvent('MY_CATACLYSM_SET_VISIBLE')
				end,
				bFold = function()
					FireUIEvent('MY_CATACLYSM_SET_FOLD')
				end,
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_Cataclysm = X.CreateModule(settings)
end

X.RegisterEvent('LOADING_END', 'MY_Cataclysm__AnnounceShielded', D.AnnounceShielded)
X.RegisterKungfuMount('MY_Cataclysm__AnnounceShielded', D.AnnounceShielded)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
