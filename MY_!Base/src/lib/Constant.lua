--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ����ö��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Constant')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

local KvpToObject = X.KvpToObject

local function PickBranch(tData)
	return tData[X.ENVIRONMENT.GAME_BRANCH] or tData['remake']
end

local FORCE_TYPE = (function()
	local FORCE_TYPE = _G.FORCE_TYPE or X.FreezeTable({
		JIANG_HU  = 0 , -- ����
		SHAO_LIN  = 1 , -- ����
		WAN_HUA   = 2 , -- ��
		TIAN_CE   = 3 , -- ���
		CHUN_YANG = 4 , -- ����
		QI_XIU    = 5 , -- ����
		WU_DU     = 6 , -- �嶾
		TANG_MEN  = 7 , -- ����
		CANG_JIAN = 8 , -- �ؽ�
		GAI_BANG  = 9 , -- ؤ��
		MING_JIAO = 10, -- ����
		CANG_YUN  = 21, -- ����
		CHANG_GE  = 22, -- ����
		BA_DAO    = 23, -- �Ե�
		PENG_LAI  = 24, -- ����
		LING_XUE  = 25, -- ��ѩ
		YAN_TIAN  = 211, -- ����
		YAO_ZONG  = 212, -- ҩ��
		DAO_ZONG  = 213, -- ����
		WAN_LING  = 214, -- ����
		DUAN_SHI  = 215, -- ����
	})
	local res = {}
	for k, v in X.pairs_c(FORCE_TYPE) do
		if g_tStrings.tForceTitle[v] then
			res[k] = v
		end
	end
	return X.FreezeTable(res)
end)()

local FORCE_LIST = {
	{ dwID = FORCE_TYPE.JIANG_HU , szUITex = 'ui\\Image\\PlayerAvatar\\jianghu.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.SHAO_LIN , szUITex = 'ui\\Image\\PlayerAvatar\\shaolin.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.WAN_HUA  , szUITex = 'ui\\Image\\PlayerAvatar\\wanhua.tga'        , nFrame = -2, bAnimate = false }, -- ��
	{ dwID = FORCE_TYPE.TIAN_CE  , szUITex = 'ui\\Image\\PlayerAvatar\\tiance.tga'        , nFrame = -2, bAnimate = false }, -- ���
	{ dwID = FORCE_TYPE.CHUN_YANG, szUITex = 'ui\\Image\\PlayerAvatar\\chunyang.tga'      , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.QI_XIU   , szUITex = 'ui\\Image\\PlayerAvatar\\qixiu.tga'         , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.WU_DU    , szUITex = 'ui\\Image\\PlayerAvatar\\wudu.tga'          , nFrame = -2, bAnimate = false }, -- �嶾
	{ dwID = FORCE_TYPE.TANG_MEN , szUITex = 'ui\\Image\\PlayerAvatar\\tangmen.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.CANG_JIAN, szUITex = 'ui\\Image\\PlayerAvatar\\cangjian.tga'      , nFrame = -2, bAnimate = false }, -- �ؽ�
	{ dwID = FORCE_TYPE.GAI_BANG , szUITex = 'ui\\Image\\PlayerAvatar\\gaibang.tga'       , nFrame = -2, bAnimate = false }, -- ؤ��
	{ dwID = FORCE_TYPE.MING_JIAO, szUITex = 'ui\\Image\\PlayerAvatar\\mingjiao.tga'      , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.CANG_YUN , szUITex = 'ui\\Image\\PlayerAvatar\\cangyun.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.CHANG_GE , szUITex = 'ui\\Image\\PlayerAvatar\\changge.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.BA_DAO   , szUITex = 'ui\\Image\\PlayerAvatar\\badao.tga'         , nFrame = -2, bAnimate = false }, -- �Ե�
	{ dwID = FORCE_TYPE.PENG_LAI , szUITex = 'ui\\Image\\PlayerAvatar\\penglai.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.LING_XUE , szUITex = 'ui\\Image\\PlayerAvatar\\lingxuege.tga'     , nFrame = -2, bAnimate = false }, -- ��ѩ
	{ dwID = FORCE_TYPE.YAN_TIAN , szUITex = 'ui\\Image\\PlayerAvatar\\yantianzong.dds'   , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.YAO_ZONG , szUITex = 'ui\\Image\\PlayerAvatar\\beitianyaozong.dds', nFrame = -2, bAnimate = false }, -- ҩ��
	{ dwID = FORCE_TYPE.DAO_ZONG , szUITex = 'ui\\Image\\PlayerAvatar\\daozong.dds'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.WAN_LING , szUITex = 'ui\\Image\\PlayerAvatar\\wanling.tga'       , nFrame = -2, bAnimate = false }, -- ����
	{ dwID = FORCE_TYPE.DUAN_SHI , szUITex = 'ui\\Image\\PlayerAvatar\\DuanShi.tga'       , nFrame = -2, bAnimate = false }, -- ����
}
for i, v in X.ipairs_r(FORCE_LIST) do
	if not v.dwID or not g_tStrings.tForceTitle[v.dwID] then
		table.remove(FORCE_LIST, i)
	end
end

local KUNGFU_TYPE = (function()
	local KUNGFU_TYPE = {
		XI_SUI    = 10002, -- ���� ϴ�辭
		YI_JIN    = 10003, -- ���� �׽
		ZI_XIA    = 10014, -- ���� ��ϼ��
		TAI_XU    = 10015, -- ���� ̫�齣��
		HUA_JIAN  = 10021, -- �� ������
		LI_JING   = 10028, -- �� �뾭�׵�
		AO_XUE    = 10026, -- ��� ��Ѫս��
		TIE_LAO   = 10062, -- ��� ������
		YUN_CHANG = 10080, -- ���� �����ľ�
		BING_XIN  = 10081, -- ���� ���ľ�
		WEN_SHUI  = 10144, -- �ؽ� ��ˮ��
		SHAN_JU   = 10145, -- �ؽ� ɽ�ӽ���
		DU_JING   = 10175, -- �嶾 ����
		BU_TIAN   = 10176, -- �嶾 �����
		JING_YU   = 10224, -- ���� �����
		TIAN_LUO  = 10225, -- ���� ���޹��
		FEN_YING  = 10242, -- ���� ��Ӱʥ��
		MING_ZUN  = 10243, -- ���� ����������
		XIAO_CHEN = 10268, -- ؤ�� Ц����
		TIE_GU    = 10389, -- ���� ������
		FEN_SHAN  = 10390, -- ���� ��ɽ��
		MO_WEN    = 10447, -- ���� Ī��
		XIANG_ZHI = 10448, -- ���� ��֪
		BEI_AO    = 10464, -- �Ե� ������
		LING_HAI  = 10533, -- ���� �躣��
		YIN_LONG  = 10585, -- ��ѩ ������
		TAI_XUAN  = 10615, -- ���� ̫����
		LING_SU   = 10626, -- ҩ�� ����
		WU_FANG   = 10627, -- ҩ�� �޷�
		GU_FENG   = 10698, -- ���� �·��
		SHAN_HAI  = 10756, -- ���� ɽ���ľ�
		ZHOU_TIAN = 10786, -- ���� ���칦
	}
	local res = {}
	for k, v in pairs(KUNGFU_TYPE) do
		if Table_GetSkill(v) then
			res[k] = v
		end
	end
	return X.FreezeTable(res)
end)()

-- skillid, uitex, frame
local KUNGFU_LIST = {
	-- MT
	{ dwID = KUNGFU_TYPE.TIE_LAO  , dwForceID = FORCE_TYPE.TIAN_CE  , nIcon = 632  , szUITex = 'ui/Image/icon/skill_tiance01.UITex'    , nFrame = 0  }, -- ��� ������
	{ dwID = KUNGFU_TYPE.MING_ZUN , dwForceID = FORCE_TYPE.MING_JIAO, nIcon = 3864 , szUITex = 'ui/Image/icon/mingjiao_taolu_7.UITex'  , nFrame = 0  }, -- ���� ����������
	{ dwID = KUNGFU_TYPE.TIE_GU   , dwForceID = FORCE_TYPE.CANG_YUN , nIcon = 6315 , szUITex = 'ui/Image/icon/Skill_CangY_33.UITex'    , nFrame = 0  }, -- ���� ������
	{ dwID = KUNGFU_TYPE.XI_SUI   , dwForceID = FORCE_TYPE.SHAO_LIN , nIcon = 429  , szUITex = 'ui/Image/icon/skill_shaolin14.UITex'   , nFrame = 0  }, -- ���� ϴ�辭
	-- ����
	{ dwID = KUNGFU_TYPE.YUN_CHANG, dwForceID = FORCE_TYPE.QI_XIU   , nIcon = 887  , szUITex = 'ui/Image/icon/skill_qixiu02.UITex'     , nFrame = 0  }, -- ���� �����ľ�
	{ dwID = KUNGFU_TYPE.BU_TIAN  , dwForceID = FORCE_TYPE.WU_DU    , nIcon = 2767 , szUITex = 'ui/Image/icon/wudu_neigong_2.UITex'    , nFrame = 0  }, -- �嶾 �����
	{ dwID = KUNGFU_TYPE.LI_JING  , dwForceID = FORCE_TYPE.WAN_HUA  , nIcon = 412  , szUITex = 'ui/Image/icon/skill_wanhua23.UITex'    , nFrame = 0  }, -- �� �뾭�׵�
	{ dwID = KUNGFU_TYPE.XIANG_ZHI, dwForceID = FORCE_TYPE.CHANG_GE , nIcon = 7067 , szUITex = 'ui/Image/icon/skill_0514_23.UITex'     , nFrame = 0  }, -- ���� ��֪
	{ dwID = KUNGFU_TYPE.LING_SU  , dwForceID = FORCE_TYPE.YAO_ZONG , nIcon = 15593, szUITex = 'ui/image/icon/skill_21_9_10_1.UITex '  , nFrame = 0  }, -- ҩ�� ����
	-- �ڹ�
	{ dwID = KUNGFU_TYPE.TIAN_LUO , dwForceID = FORCE_TYPE.TANG_MEN , nIcon = 3184 , szUITex = 'ui/Image/icon/skill_tangm_20.UITex'    , nFrame = 0  }, -- ���� ���޹��
	{ dwID = KUNGFU_TYPE.BING_XIN , dwForceID = FORCE_TYPE.QI_XIU   , nIcon = 888  , szUITex = 'ui/Image/icon/skill_qixiu03.UITex'     , nFrame = 0  }, -- ���� ���ľ�
	{ dwID = KUNGFU_TYPE.DU_JING  , dwForceID = FORCE_TYPE.WU_DU    , nIcon = 2766 , szUITex = 'ui/Image/icon/wudu_neigong_1.UITex'    , nFrame = 0  }, -- �嶾 ����
	{ dwID = KUNGFU_TYPE.FEN_YING , dwForceID = FORCE_TYPE.MING_JIAO, nIcon = 3865 , szUITex = 'ui/Image/icon/mingjiao_taolu_8.UITex'  , nFrame = 0  }, -- ���� ��Ӱʥ��
	{ dwID = KUNGFU_TYPE.ZI_XIA   , dwForceID = FORCE_TYPE.CHUN_YANG, nIcon = 627  , szUITex = 'ui/Image/icon/skill_chunyang21.UITex'  , nFrame = 0  }, -- ���� ��ϼ��
	{ dwID = KUNGFU_TYPE.HUA_JIAN , dwForceID = FORCE_TYPE.WAN_HUA  , nIcon = 406  , szUITex = 'ui/Image/icon/skill_wanhua17.UITex'    , nFrame = 0  }, -- �� ������
	{ dwID = KUNGFU_TYPE.YI_JIN   , dwForceID = FORCE_TYPE.SHAO_LIN , nIcon = 425  , szUITex = 'ui/Image/icon/skill_shaolin10.UITex'   , nFrame = 0  }, -- ���� �׾���
	{ dwID = KUNGFU_TYPE.MO_WEN   , dwForceID = FORCE_TYPE.CHANG_GE , nIcon = 7071 , szUITex = 'ui/Image/icon/skill_0514_27.UITex'     , nFrame = 0  }, -- ���� Ī��
	{ dwID = KUNGFU_TYPE.TAI_XUAN , dwForceID = FORCE_TYPE.YAN_TIAN , nIcon = 13894, szUITex = 'ui/image/icon/skill_20_9_14_1.uitex'   , nFrame = 0  }, -- ���� ̫����
	{ dwID = KUNGFU_TYPE.WU_FANG  , dwForceID = FORCE_TYPE.YAO_ZONG , nIcon = 15594, szUITex = 'ui/image/icon/skill_21_9_10_2.UITex '  , nFrame = 0  }, -- ҩ�� �޷�
	{ dwID = KUNGFU_TYPE.DUAN_SHI , dwForceID = FORCE_TYPE.DUAN_SHI , nIcon = 22823, szUITex = 'ui/Image/icon/skill/Duanshi/skill_ds_8_28_1.UITex', nFrame = 0 }, -- ���� ���칦
	-- �⹦
	{ dwID = KUNGFU_TYPE.FEN_SHAN , dwForceID = FORCE_TYPE.CANG_YUN , nIcon = 6314 , szUITex = 'ui/Image/icon/Skill_CangY_32.UITex'    , nFrame = 0  }, -- ���� ��ɽ��
	{ dwID = KUNGFU_TYPE.JING_YU  , dwForceID = FORCE_TYPE.TANG_MEN , nIcon = 3165 , szUITex = 'ui/Image/icon/skill_tangm_01.UITex'    , nFrame = 0  }, -- ���� �����
	{ dwID = KUNGFU_TYPE.WEN_SHUI , dwForceID = FORCE_TYPE.CANG_JIAN, nIcon = 2376 , szUITex = 'ui/Image/icon/cangjian_neigong_1.UITex', nFrame = 0  }, -- �ؽ� ��ˮ��
	{ dwID = KUNGFU_TYPE.SHAN_JU  , dwForceID = FORCE_TYPE.CANG_JIAN, nIcon = 2377 , szUITex = 'ui/Image/icon/cangjian_neigong_2.UITex', nFrame = 0  }, -- �ؽ� ɽ�ӽ���
	{ dwID = KUNGFU_TYPE.TAI_XU   , dwForceID = FORCE_TYPE.CHUN_YANG, nIcon = 619  , szUITex = 'ui/Image/icon/skill_chunyang13.UITex'  , nFrame = 0  }, -- ���� ̫�齣��
	{ dwID = KUNGFU_TYPE.AO_XUE   , dwForceID = FORCE_TYPE.TIAN_CE  , nIcon = 633  , szUITex = 'ui/Image/icon/skill_tiance02.UITex'    , nFrame = 0  }, -- ��� ��Ѫս��
	{ dwID = KUNGFU_TYPE.XIAO_CHEN, dwForceID = FORCE_TYPE.GAI_BANG , nIcon = 4610 , szUITex = 'ui/Image/icon/skill_GB_30.UITex'       , nFrame = 0  }, -- ؤ�� Ц����
	{ dwID = KUNGFU_TYPE.BEI_AO   , dwForceID = FORCE_TYPE.BA_DAO   , nIcon = 8424 , szUITex = 'ui/Image/icon/daoj_16_8_25_16.UITex'   , nFrame = 0  }, -- �Ե� ������
	{ dwID = KUNGFU_TYPE.LING_HAI , dwForceID = FORCE_TYPE.PENG_LAI , nIcon = 10709, szUITex = 'ui/image/icon/JNPL_18_10_30_27.uitex'  , nFrame = 0  }, -- ���� �躣��
	{ dwID = KUNGFU_TYPE.YIN_LONG , dwForceID = FORCE_TYPE.LING_XUE , nIcon = 12128, szUITex = 'ui/image/icon/JNLXG_19_10_21_9.uitex'  , nFrame = 0  }, -- ��ѩ ������
	{ dwID = KUNGFU_TYPE.GU_FENG  , dwForceID = FORCE_TYPE.DAO_ZONG , nIcon = 17633, szUITex = 'ui/image/icon/skill_22_9_7_2.uitex'    , nFrame = 51 }, -- ���� �·��
	{ dwID = KUNGFU_TYPE.SHAN_HAI , dwForceID = FORCE_TYPE.WAN_LING , nIcon = 19664, szUITex = 'ui/image/icon/skill_23_8_22_1.uitex'   , nFrame = 9  }, -- ���� ɽ���ľ�
}
for i, v in X.ipairs_r(KUNGFU_LIST) do
	if not v.dwForceID or not Table_GetSkill(v.dwID) then
		table.remove(KUNGFU_LIST, i)
	end
end

local TEAM_MARK = {
	CLOUD = 1,
	SWORD = 2,
	AX    = 3,
	HOOK  = 4,
	DRUM  = 5,
	SHEAR = 6,
	STICK = 7,
	JADE  = 8,
	DART  = 9,
	FAN   = 10,
}

local MSG_TYPE_MENU = X.Clone(_G.UI_CHANNEL_POPUP_SETTING_TABLE) or {
	{
		szOption = g_tStrings.CHANNEL,
		'MSG_NORMAL', 'MSG_PARTY', 'MSG_MAP', 'MSG_BATTLE_FILED', 'MSG_GUILD',
		'MSG_GUILD_ALLIANCE', 'MSG_SCHOOL', 'MSG_WORLD', 'MSG_TEAM', 'MSG_ROOM', 'MSG_CAMP',
		'MSG_SEEK_MENTOR', 'MSG_FRIEND', 'MSG_GROUP', 'MSG_WHISPER', 'MSG_IDENTITY', 'MSG_JJC_BULLET_SCREEN', 'MSG_BATTLE_FIELD_SIDE', 'MSG_STORY_NPC', 'MSG_STORY_PLAYER', 'MSG_SSG_WHISPER',
	},
	{
		szOption = g_tStrings.EARN,
		'MSG_MONEY', 'MSG_EXP', 'MSG_ITEM', 'MSG_REPUTATION', 'MSG_CONTRIBUTE', 'MSG_ATTRACTION', 'MSG_PRESTIGE',
		'MSG_TRAIN', 'MSG_DESGNATION', 'MSG_ACHIEVEMENT', 'MSG_MENTOR_VALUE',
		'MSG_TONG_FUND', 'MSG_THEW_STAMINA',  'MSG_ARCHITECTURE',
	},
	{
		szOption = g_tStrings.FIGHT_MSG,
		{
			szOption = g_tStrings.STR_NAME_OWN,
			'MSG_SKILL_SELF_SKILL', 'MSG_SKILL_SELF_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_HARMFUL_SKILL',
			'MSG_SKILL_SELF_BE_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_BE_HARMFUL_SKILL',
			'MSG_SKILL_SELF_BUFF', 'MSG_SKILL_SELF_DEBUFF',
			'MSG_SKILL_SELF_MISS', 'MSG_SKILL_SELF_FAILED',
			'MSG_SELF_KILL', 'MSG_SELF_DEATH',
		},
		{
			szOption = g_tStrings.TEAMMATE,
			'MSG_SKILL_PARTY_SKILL', 'MSG_SKILL_PARTY_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_HARMFUL_SKILL',
			'MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_BE_HARMFUL_SKILL',
			'MSG_SKILL_PARTY_BUFF', 'MSG_SKILL_PARTY_DEBUFF', 'MSG_SKILL_PARTY_MISS', 'MSG_PARTY_KILL', 'MSG_PARTY_DEATH',
		},
		{
			szOption = g_tStrings.ENEMY,
			'MSG_SKILL_ENEMY_SKILL', 'MSG_SKILL_ENEMY_HARMFUL_SKILL', 'MSG_SKILL_ENEMY_BENEFICAL_SKILL',
			'MSG_SKILL_ENEMY_MISS', 'MSG_ENEMY_KILL', 'MSG_ENEMY_DEATH',
		},
		{
			szOption = g_tStrings.OTHER_PLAYER,
			'MSG_SKILL_OTHERS_SKILL', 'MSG_SKILL_OTHERS_BENEFICIAL_SKILL', 'MSG_SKILL_OTHERS_HARMFUL_SKILL',
			'MSG_SKILL_OTHERS_MISS', 'MSG_OTHERS_KILL', 'MSG_OTHERS_DEATH',
		},
		{
			szOption = 'NPC',
			'MSG_SKILL_NPC_SKILL', 'MSG_SKILL_NPC_BENEFICIAL_SKILL', 'MSG_SKILL_NPC_HARMFUL_SKILL', 'MSG_SKILL_NPC_MISS',
			'MSG_NPC_KILL', 'MSG_NPC_DEATH',
		},
		{
			szOption = g_tStrings.OTHER,
			'MSG_OTHER_ENCHANT', 'MSG_OTHER_SCENE',
		},
	},
	{
		szOption = g_tStrings.ENVIROMENT,
		'MSG_NPC_NEARBY', 'MSG_NPC_YELL', 'MSG_NPC_PARTY', 'MSG_NPC_WHISPER', 'MSG_NPC_FACE',
	},
}
table.insert(MSG_TYPE_MENU[1], 1, 'MSG_SYS')

local INVENTORY_INDEX_INDEX = setmetatable(
	{
		-- ���ֿ�������ⱳ��λ��
		GUILD_BANK = 10000,
		GUILD_BANK_PACKAGE1 = 10001,
		GUILD_BANK_PACKAGE2 = 10002,
		GUILD_BANK_PACKAGE3 = 10003,
		GUILD_BANK_PACKAGE4 = 10004,
		GUILD_BANK_PACKAGE5 = 10005,
		GUILD_BANK_PACKAGE6 = 10006,
		GUILD_BANK_PACKAGE7 = 10007,
		GUILD_BANK_PACKAGE8 = 10008,
	},
	{ __index = _G.INVENTORY_INDEX }
)
local INVENTORY_INDEX = setmetatable({}, { __index = INVENTORY_INDEX_INDEX, __newindex = function() end })

local CONSTANT = {
	MENU_DIVIDER = X.FreezeTable({ bDevide = true }),
	EMPTY_TABLE = X.FreezeTable({}),
	XML_LINE_BREAKER = GetFormatText('\n'),
	MAX_PLAYER_LEVEL = 50,
	UI_OBJECT = UI_OBJECT or X.FreezeTable({
		NONE             = -1, -- ��Box
		ITEM             = 0 , -- �����е���Ʒ��nUiId, dwBox, dwX, nItemVersion, nTabType, nIndex
		SHOP_ITEM        = 1 , -- �̵�������۵���Ʒ nUiId, dwID, dwShopID, dwIndex
		OTER_PLAYER_ITEM = 2 , -- ����������ϵ���Ʒ nUiId, dwBox, dwX, dwPlayerID
		ITEM_ONLY_ID     = 3 , -- ֻ��һ��ID����Ʒ������װ������֮��ġ�nUiId, dwID, nItemVersion, nTabType, nIndex
		ITEM_INFO        = 4 , -- ������Ʒ nUiId, nItemVersion, nTabType, nIndex, nCount(��nCount����dwRecipeID)
		SKILL            = 5 , -- ���ܡ�dwSkillID, dwSkillLevel, dwOwnerID
		CRAFT            = 6 , -- ���ա�dwProfessionID, dwBranchID, dwCraftID
		SKILL_RECIPE     = 7 , -- �䷽dwID, dwLevel
		SYS_BTN          = 8 , -- ϵͳ����ݷ�ʽdwID
		MACRO            = 9 , -- ��
		MOUNT            = 10, -- ��Ƕ
		ENCHANT          = 11, -- ��ħ
		NOT_NEED_KNOWN   = 15, -- ����Ҫ֪������
		PENDANT          = 16, -- �Ҽ�
		PET              = 17, -- ����
		MEDAL            = 18, -- �������
		BUFF             = 19, -- BUFF
		MONEY            = 20, -- ��Ǯ
		TRAIN            = 21, -- ��Ϊ
		EMOTION_ACTION   = 22, -- ��������
	}),
	GLOBAL_HEAD = GLOBAL_HEAD or X.FreezeTable({
		CLIENTPLAYER = 0,
		OTHERPLAYER  = 1,
		NPC          = 2,
		LIFE         = 0,
		GUILD        = 1,
		TITLE        = 2,
		NAME         = 3,
		MARK         = 4,
	}),
	EQUIPMENT_SUB = EQUIPMENT_SUB or X.FreezeTable({
		MELEE_WEAPON      = 0 , -- ��ս����
		RANGE_WEAPON      = 1 , -- Զ������
		CHEST             = 2 , -- ����
		HELM              = 3 , -- ͷ��
		AMULET            = 4 , -- ����
		RING              = 5 , -- ��ָ
		WAIST             = 6 , -- ����
		PENDANT           = 7 , -- ��׺
		PANTS             = 8 , -- ����
		BOOTS             = 9 , -- Ь��
		BANGLE            = 10, -- ����
		WAIST_EXTEND      = 11, -- �����Ҽ�
		PACKAGE           = 12, -- ����
		ARROW             = 13, -- ����
		BACK_EXTEND       = 14, -- �����Ҽ�
		HORSE             = 15, -- ����
		BULLET            = 16, -- �������
		FACE_EXTEND       = 17, -- �����Ҽ�
		MINI_AVATAR       = 18, -- Сͷ��
		PET               = 19, -- ����
		L_SHOULDER_EXTEND = 20, -- ���Ҽ�
		R_SHOULDER_EXTEND = 21, -- �Ҽ�Ҽ�
		BACK_CLOAK_EXTEND = 22, -- ����
		TOTAL             = 23, --
	}),
	EQUIPMENT_INVENTORY = EQUIPMENT_INVENTORY or X.FreezeTable({
		MELEE_WEAPON  = 0 , -- ��ͨ��ս����
		BIG_SWORD     = 1 , -- �ؽ�
		RANGE_WEAPON  = 2 , -- Զ������
		CHEST         = 3 , -- ����
		HELM          = 4 , -- ͷ��
		AMULET        = 5 , -- ����
		LEFT_RING     = 6 , -- ���ֽ�ָ
		RIGHT_RING    = 7 , -- ���ֽ�ָ
		WAIST         = 8 , -- ����
		PENDANT       = 9, -- ��׺
		PANTS         = 10, -- ����
		BOOTS         = 11, -- Ь��
		BANGLE        = 12, -- ����
		PACKAGE1      = 13, -- ��չ����1
		PACKAGE2      = 14, -- ��չ����2
		PACKAGE3      = 15, -- ��չ����3
		PACKAGE4      = 16, -- ��չ����4
		PACKAGE_MIBAO = 17, -- �󶨰�ȫ��Ʒ״̬�����͵Ķ��ⱳ���� ��ItemList V9������
		BANK_PACKAGE1 = 18, -- �ֿ���չ����1
		BANK_PACKAGE2 = 19, -- �ֿ���չ����2
		BANK_PACKAGE3 = 20, -- �ֿ���չ����3
		BANK_PACKAGE4 = 21, -- �ֿ���չ����4
		BANK_PACKAGE5 = 22, -- �ֿ���չ����5
		ARROW         = 23, -- ����
		TOTAL         = 24,
	}),
	CHARACTER_OTACTION_TYPE = setmetatable({}, {
		__index = setmetatable(
			{
				ACTION_IDLE            = 0,
				ACTION_SKILL_PREPARE   = 1,
				ACTION_SKILL_CHANNEL   = 2,
				ACTION_RECIPE_PREPARE  = 3,
				ACTION_PICK_PREPARE    = 4,
				ACTION_PICKING         = 5,
				ACTION_ITEM_SKILL      = 6,
				ACTION_CUSTOM_PREPARE  = 7,
				ACTION_CUSTOM_CHANNEL  = 8,
				ACTION_SKILL_HOARD     = 9,
				ANCIENT_ACTION_PREPARE = 1000,
			},
			{ __index = _G.CHARACTER_OTACTION_TYPE }),
		__newindex = function() end,
	}),
	ROLE_TYPE_LABEL = X.FreezeTable({
		[ROLE_TYPE.STANDARD_MALE  ] = _L['Man'],
		[ROLE_TYPE.STANDARD_FEMALE] = _L['Woman'],
		[ROLE_TYPE.LITTLE_BOY     ] = _L['Boy'],
		[ROLE_TYPE.LITTLE_GIRL    ] = _L['Girl'],
	}),
	FORCE_LIST = FORCE_LIST,
	FORCE_TYPE = FORCE_TYPE,
	FORCE_TYPE_LABEL = g_tStrings.tForceTitle,
	FORCE_AVATAR = ((function()
		local FORCE_AVATAR = {}
		for i, v in ipairs(FORCE_LIST) do
			FORCE_AVATAR[v.dwID] = {v.szUITex, v.nFrame, v.bAnimate}
		end
		return setmetatable(
			FORCE_AVATAR,
			{
				__index = function(t, k)
					return t[FORCE_TYPE.JIANG_HU]
				end,
				__metatable = true,
			})
	end)()),
	KUNGFU_LIST = KUNGFU_LIST,
	KUNGFU_TYPE = KUNGFU_TYPE,
	KUNGFU_TYPE_LABEL_ABBR = setmetatable(X.Clone(_L.KUNGFU_TYPE_LABEL_ABBR), {
		__index = function(t)
			return _L.KUNGFU_TYPE_LABEL_ABBR[0]
		end,
		__metatable = true,
	}),
	KUNGFU_FORCE_TYPE = ((function()
		local res = {}
		for i, v in ipairs(KUNGFU_LIST) do
			res[v.dwID] = v.dwForceID
		end
		return res
	end)()),
	KUNGFU_MOUNT_TYPE = (function()
		local KUNGFU_MOUNT_TYPE = _G.KUNGFU_TYPE or X.FreezeTable({
			TIAN_CE     = 1,      -- ����ڹ�
			WAN_HUA     = 2,      -- ���ڹ�
			CHUN_YANG   = 3,      -- �����ڹ�
			QI_XIU      = 4,      -- �����ڹ�
			SHAO_LIN    = 5,      -- �����ڹ�
			CANG_JIAN   = 6,      -- �ؽ��ڹ�
			GAI_BANG    = 7,      -- ؤ���ڹ�
			MING_JIAO   = 8,      -- �����ڹ�
			WU_DU       = 9,      -- �嶾�ڹ�
			TANG_MEN    = 10,     -- �����ڹ�
			CANG_YUN    = 18,     -- �����ڹ�
			CHANG_GE    = 19,     -- �����ڹ�
			BA_DAO      = 20,     -- �Ե��ڹ�
			PENG_LAI    = 21,     -- �����ڹ�
			LING_XUE    = 22,     -- ��ѩ�ڹ�
			YAN_TIAN    = 23,     -- �����ڹ�
		})
		local res = {}
		for k, v in X.pairs_c(KUNGFU_MOUNT_TYPE) do
			if g_tStrings.tForceTitle[v] then
				res[k] = v
			end
		end
		return X.FreezeTable(res)
	end)(),
	PEEK_OTHER_PLAYER_RESPOND = PEEK_OTHER_PLAYER_RESPOND or X.FreezeTable({
		INVALID             = 0,
		SUCCESS             = 1,
		FAILED              = 2,
		CAN_NOT_FIND_PLAYER = 3,
		TOO_FAR             = 4,
	}),
	MIC_STATE = MIC_STATE or X.FreezeTable({
		NOT_AVIAL = 1,
		CLOSE_NOT_IN_ROOM = 2,
		CLOSE_IN_ROOM = 3,
		KEY = 4,
		FREE = 5,
	}),
	SPEAKER_STATE = SPEAKER_STATE or X.FreezeTable({
		OPEN = 1,
		CLOSE = 2,
	}),
	CHAT_PANEL_INDEX_LIST = X.FreezeTable({
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10,
		11,
		'_Recently',
	}),
	ITEM_QUALITY = X.FreezeTable({
		GRAY    = 0, -- ��ɫ
		WHITE   = 1, -- ��ɫ
		GREEN   = 2, -- ��ɫ
		BLUE    = 3, -- ��ɫ
		PURPLE  = 4, -- ��ɫ
		NACARAT = 5, -- ��ɫ
		GLODEN  = 6, -- ����
	}),
	CRAFT_TYPE = {
		MINING = 1, --�ɿ�
		HERBALISM = 2, -- ��ũ
		SKINNING = 3, -- �Ҷ�
		READING = 8, -- �Ķ�
	},
	MOBA_MAP = {
		[412] = true, -- ���ǵ�
	},
	STARVE_MAP = {
		[421] = true, -- �˿��С������ѹ�
		[422] = true, -- �˿��С�ɣ���ԭ
		[423] = true, -- �˿��С���ˮկ
		[424] = true, -- �˿��С�����Ϫ
		[425] = true, -- �˿��С��Ļ���
		[433] = true, -- �˿��С��м��ջ
		[434] = true, -- �˿��С�����ɽ
		[435] = true, -- �˿��С����幬
		[436] = true, -- �˿��С�������
		[437] = true, -- �˿��С���ѩ·
		[438] = true, -- �˿��С��ż�̳
		[439] = true, -- �˿��С���ӫ��
		[440] = true, -- �˿��С�����Ͽ
		[441] = true, -- �˿��С��������
		[442] = true, -- �˿��С������ֵ�
		[443] = true, -- �˿��С�������
		[461] = true, -- �˿��С���ӣ��
		[527] = true, -- �˿��С����뵺
		[528] = true, -- �˿��С���ˮ
	},
	MONSTER_MAP = {
		[562] = true, -- ��ս����¼
	},
	ROGUELIKE_MAP = {
		[995] = true, -- �˻ĺ��
	},
	-- ���ӵ�ͼ����������ͼ��ӳ�������ͼ��Ч�Ĺ��ܣ���ͬһ��ͼ���ӵ�ͼʱ���ϲ����ݵ�����ͼ
	MAP_MERGE = {
		[143] = 147, -- ����֮��
		[144] = 147, -- ����֮��
		[145] = 147, -- ����֮��
		[146] = 147, -- ����֮��
		[195] = 196, -- ���Ź�֮��
		[276] = 281, -- �ý�԰
		[278] = 281, -- �ý�԰
		[279] = 281, -- �ý�԰
		[280] = 281, -- �ý�԰
		[296] = 297, -- ���ž���
	},
	MAP_NAME = {},
	NPC_NAME = {
		[58294] = '{$N62347}', -- ��������
	},
	NPC_HIDDEN = {
		[19153] = true, -- �ʹ���Χ�ܿ�
		[27634] = true, -- �ػ��갲»ɽ�ܿ�
		[56383] = true, -- ͨ�ؽ�����ɱ��ֿ���
		[60045] = true, -- ����ǵ�����η��Ĳ�֪��ʲô����
	},
	DOODAD_NAME = {
		[3713] = '{$D1}', -- ����
		[3714] = '{$D1}', -- ����
		[3114] = '{$I5,11091}', -- ��ü��ѿ
		[3115] = '{$I5,11092}', -- ����ʯ��
		[3116] = '{$I5,11093}', -- �������
	},
	FORCE_FOREGROUND_COLOR = (function()
		local OFFICIAL_COLOR = {}
		local function GetOfficialForceColor(k)
			if not OFFICIAL_COLOR[k] then
				local tColor
				if GetKungfuSchoolColor and Table_ForceToSchool then
					local bSuccess, dwSchoolID = X.SafeXpCall(Table_ForceToSchool, k)
					if bSuccess and dwSchoolID then
						local bSuccess, nR, nG, nB = X.SafeXpCall(GetKungfuSchoolColor, dwSchoolID)
						if bSuccess and nR and nG and nB then
							tColor = { nR, nG, nB }
						end
					end
				end
				OFFICIAL_COLOR[k] = tColor or {}
			end
			return X.Unpack(OFFICIAL_COLOR[k])
		end
		return setmetatable(
			KvpToObject({
				{ FORCE_TYPE.JIANG_HU , { 255, 255, 255 } }, -- ����
				{ FORCE_TYPE.SHAO_LIN , { 255, 178,  95 } }, -- ����
				{ FORCE_TYPE.WAN_HUA  , { 196, 152, 255 } }, -- ��
				{ FORCE_TYPE.TIAN_CE  , { 255, 111,  83 } }, -- ���
				{ FORCE_TYPE.CHUN_YANG, {  22, 216, 216 } }, -- ����
				{ FORCE_TYPE.QI_XIU   , { 255, 129, 176 } }, -- ����
				{ FORCE_TYPE.WU_DU    , {  55, 147, 255 } }, -- �嶾
				{ FORCE_TYPE.TANG_MEN , { 121, 183,  54 } }, -- ����
				{ FORCE_TYPE.CANG_JIAN, { 214, 249,  93 } }, -- �ؽ�
				{ FORCE_TYPE.GAI_BANG , { 205, 133,  63 } }, -- ؤ��
				{ FORCE_TYPE.MING_JIAO, { 240,  70,  96 } }, -- ����
				{ FORCE_TYPE.CANG_YUN , X.IS_REMOTE and { 255, 143, 80 } or { 180, 60, 0 } }, -- ����
				{ FORCE_TYPE.CHANG_GE , { 100, 250, 180 } }, -- ����
				{ FORCE_TYPE.BA_DAO   , { 106, 108, 189 } }, -- �Ե�
				{ FORCE_TYPE.PENG_LAI , { 171, 227, 250 } }, -- ����
				{ FORCE_TYPE.LING_XUE , X.IS_REMOTE and { 253, 86, 86 } or { 161,   9,  34 } }, -- ��ѩ
				{ FORCE_TYPE.YAN_TIAN , { 166,  83, 251 } }, -- ����
				{ FORCE_TYPE.YAO_ZONG , {   0, 172, 153 } }, -- ҩ��
				{ FORCE_TYPE.DAO_ZONG , { 107, 183, 242 } }, -- ����
				{ FORCE_TYPE.WAN_LING , { 235, 215, 115 } }, -- ����
			}),
			{
				__index = function(t, k)
					local tColor
					local nR, nG, nB = GetOfficialForceColor(k)
					if nR and nG and nB then
						tColor = { nR, nG, nB }
					end
					-- NPC �Լ�δ֪����
					if not tColor then
						tColor = { 225, 225, 225 }
					end
					t[k] = tColor
					return tColor
				end,
				__metatable = true,
			}
		)
	end)(),
	FORCE_BACKGROUND_COLOR = (function()
		local OFFICIAL_COLOR = {}
		local function GetOfficialForceColor(k)
			if not OFFICIAL_COLOR[k] then
				local tColor
				if ForceUI_GetFightColor then
					local bSuccess, tRetColor = X.SafeCall(ForceUI_GetFightColor, k)
					if bSuccess and tRetColor then
						tColor = tRetColor
					end
				end
				OFFICIAL_COLOR[k] = tColor or {}
			end
			return X.Unpack(OFFICIAL_COLOR[k])
		end
		return setmetatable(
			KvpToObject({
				{ FORCE_TYPE.JIANG_HU , { 220, 220, 220 } }, -- ����
				{ FORCE_TYPE.SHAO_LIN , { 125, 112,  10 } }, -- ����
				{ FORCE_TYPE.WAN_HUA  , {  47,  14,  70 } }, -- ��
				{ FORCE_TYPE.TIAN_CE  , { 105,  14,  14 } }, -- ���
				{ FORCE_TYPE.CHUN_YANG, {   8,  90, 113 } }, -- ���� 56,175,255,232
				{ FORCE_TYPE.QI_XIU   , { 162,  74, 129 } }, -- ����
				{ FORCE_TYPE.WU_DU    , {   7,  82, 154 } }, -- �嶾
				{ FORCE_TYPE.TANG_MEN , {  75, 113,  40 } }, -- ����
				{ FORCE_TYPE.CANG_JIAN, { 148, 152,  27 } }, -- �ؽ�
				{ FORCE_TYPE.GAI_BANG , { 159, 102,  37 } }, -- ؤ��
				{ FORCE_TYPE.MING_JIAO, { 145,  80,  17 } }, -- ����
				{ FORCE_TYPE.CANG_YUN , { 157,  47,   2 } }, -- ����
				{ FORCE_TYPE.CHANG_GE , {  31, 120, 103 } }, -- ����
				{ FORCE_TYPE.BA_DAO   , {  49,  39, 110 } }, -- �Ե�
				{ FORCE_TYPE.PENG_LAI , {  93,  97, 126 } }, -- ����
				{ FORCE_TYPE.LING_XUE , { 161,   9,  34 } }, -- ��ѩ
				{ FORCE_TYPE.YAN_TIAN , {  96,  45, 148 } }, -- ����
				{ FORCE_TYPE.YAO_ZONG , {  10,  81,  87 } }, -- ҩ��
				{ FORCE_TYPE.DAO_ZONG , {  64, 101, 169 } }, -- ����
				{ FORCE_TYPE.WAN_LING , { 160, 135,  75 } }, -- ����
			}),
			{
				__index = function(t, k)
					local tColor
					local nR, nG, nB = GetOfficialForceColor(k)
					if nR and nG and nB then
						tColor = { nR, nG, nB }
					end
					-- NPC �Լ�δ֪����
					if not tColor then
						tColor = { 200, 200, 200 }
					end
					t[k] = tColor
					return tColor
				end,
				__metatable = true,
			}
		)
	end)(),
	CAMP_FOREGROUND_COLOR = setmetatable(
		KvpToObject({
			{ CAMP.NEUTRAL, { 255, 255, 255 } }, -- ����
			{ CAMP.GOOD   , {  60, 128, 220 } }, -- ������
			{ CAMP.EVIL   , X.IS_REMOTE and { 255, 63, 63 } or { 160, 30, 30 } }, -- ���˹�
		}),
		{
			__index = function(t, k)
				return { 225, 225, 225 }
			end,
			__metatable = true,
		}),
	CAMP_BACKGROUND_COLOR = setmetatable(
		KvpToObject({
			{ CAMP.NEUTRAL, { 255, 255, 255 } }, -- ����
			{ CAMP.GOOD   , {  60, 128, 220 } }, -- ������
			{ CAMP.EVIL   , { 160,  30,  30 } }, -- ���˹�
		}),
		{
			__index = function(t, k)
				return { 225, 225, 225 }
			end,
			__metatable = true,
		}),
	MSG_THEME = X.FreezeTable({
		NORMAL = 0,
		ERROR = 1,
		WARNING = 2,
		SUCCESS = 3,
	}),
	SKILL_TYPE = {
		[15054] = {
			[25] = 'HEAL', -- ÷����Ū
		},
	},
	MINI_MAP_POINT = {
		QUEST_REGION    = 1,
		TEAMMATE        = 2,
		SPARKING        = 3,
		DEATH           = 4,
		QUEST_NPC       = 5,
		DOODAD          = 6,
		MAP_MARK        = 7,
		FUNCTION_NPC    = 8,
		RED_NAME        = 9,
		NEW_PQ	        = 10,
		SPRINT_POINT    = 11,
		FAKE_FELLOW_PET = 12,
	},
	HOMELAND_RESULT_CODE = _G.HOMELAND_RESULT_CODE or {
		APPLY_COMMUNITY_INFO = 503,
	},
	FLOWERS_UIID = {
		[163810] = true, -- ��õ��
		[163811] = true, -- ��õ��
		[163812] = true, -- ��õ��
		[163813] = true, -- ��õ��
		[163814] = true, -- ��õ��
		[163815] = true, -- ��õ��
		[163816] = true, -- ��õ��
		[163817] = true, -- ��õ��
		[163818] = true, -- ��ɫõ��
		[163819] = true, -- ��õ��
		[163820] = true, -- �۰ٺ�
		[163821] = true, -- �Ȱٺ�
		[163822] = true, -- �װٺ�
		[163823] = true, -- �ưٺ�
		[163824] = true, -- �̰ٺ�
		[163825] = true, -- ��ɫ����
		[163826] = true, -- ��ɫ����
		[163827] = true, -- ��ɫ����
		[163828] = true, -- ��ɫ����
		[163829] = true, -- ��ɫ����
		[163830] = true, -- ��ɫ����
		[163831] = true, -- ��ɫ������
		[163832] = true, -- ��ɫ������
		[163833] = true, -- ��ɫ������
		[163834] = true, -- ��ɫ������
		[163835] = true, -- ��ɫ������
		[163836] = true, -- ����ǣţ
		[163837] = true, -- 糽�ǣţ
		[163838] = true, -- ���ǣţ
		[163839] = true, -- �Ͻ�ǣţ
		[163840] = true, -- �ƽ�ǣţ
		[163841] = true, -- ӫ�������
		[163842] = true, -- ӫ�������
		[163843] = true, -- ӫ�������
		[163844] = true, -- ӫ�������
		[163845] = true, -- ӫ�������
		[250069] = true, -- ���ȶ�������
		[250070] = true, -- ���ȶ�������
		[250071] = true, -- ���ȶ�������
		[250072] = true, -- ���ȶ�������
		[250073] = true, -- ���ȶ�������
		[250074] = true, -- ���ȶ�������
		[250075] = true, -- ���ȶ���������
		[250076] = true, -- ���ȶ������Ʒ�
		[250510] = true, -- �׺�«
		[250512] = true, -- ���«
		[250513] = true, -- �Ⱥ�«
		[250514] = true, -- �ƺ�«
		[250515] = true, -- �̺�«
		[250516] = true, -- ���«
		[250517] = true, -- ����«
		[250518] = true, -- �Ϻ�«
		[250519] = true, -- ��ͨ����
		[250520] = true, -- ����
		[250521] = true, -- ����
		[250522] = true, -- ����
		[250523] = true, -- ��ͨ���
		[250524] = true, -- �Ϲ����
		[250525] = true, -- ��ݼ����
		[250526] = true, -- ��ݼ�����
		[250527] = true, -- ��ݼ���Ϻ�
		[250528] = true, -- �ۻƹ�
		[250529] = true, -- �ϻƹ�
	},
	PLAYER_TALK_CHANNEL_TO_MSG_TYPE = KvpToObject({
		{ PLAYER_TALK_CHANNEL.WHISPER          , 'MSG_WHISPER'           },
		{ PLAYER_TALK_CHANNEL.NEARBY           , 'MSG_NORMAL'            },
		{ PLAYER_TALK_CHANNEL.TEAM             , 'MSG_PARTY'             },
		{ PLAYER_TALK_CHANNEL.ROOM             , 'MSG_ROOM'              },
		{ PLAYER_TALK_CHANNEL.TONG             , 'MSG_GUILD'             },
		{ PLAYER_TALK_CHANNEL.TONG_ALLIANCE    , 'MSG_GUILD_ALLIANCE'    },
		{ PLAYER_TALK_CHANNEL.TONG_SYS         , 'MSG_GUILD'             },
		{ PLAYER_TALK_CHANNEL.WORLD            , 'MSG_WORLD'             },
		{ PLAYER_TALK_CHANNEL.FORCE            , 'MSG_SCHOOL'            },
		{ PLAYER_TALK_CHANNEL.CAMP             , 'MSG_CAMP'              },
		{ PLAYER_TALK_CHANNEL.FRIENDS          , 'MSG_FRIEND'            },
		{ PLAYER_TALK_CHANNEL.RAID             , 'MSG_TEAM'              },
		{ PLAYER_TALK_CHANNEL.SENCE            , 'MSG_MAP'               },
		{ PLAYER_TALK_CHANNEL.BATTLE_FIELD     , 'MSG_BATTLE_FILED'      },
		{ PLAYER_TALK_CHANNEL.LOCAL_SYS        , 'MSG_SYS'               },
		{ PLAYER_TALK_CHANNEL.GM_MESSAGE       , 'MSG_SYS'               },
		{ PLAYER_TALK_CHANNEL.NPC_WHISPER      , 'MSG_NPC_WHISPER'       },
		{ PLAYER_TALK_CHANNEL.NPC_SAY_TO       , 'MSG_NPC_WHISPER'       },
		{ PLAYER_TALK_CHANNEL.NPC_NEARBY       , 'MSG_NPC_NEARBY'        },
		{ PLAYER_TALK_CHANNEL.NPC_PARTY        , 'MSG_NPC_PARTY'         },
		{ PLAYER_TALK_CHANNEL.NPC_SENCE        , 'MSG_NPC_YELL'          },
		{ PLAYER_TALK_CHANNEL.FACE             , 'MSG_FACE'              },
		{ PLAYER_TALK_CHANNEL.NPC_FACE         , 'MSG_NPC_FACE'          },
		{ PLAYER_TALK_CHANNEL.NPC_SAY_TO_CAMP  , 'MSG_CAMP'              },
		{ PLAYER_TALK_CHANNEL.IDENTITY         , 'MSG_IDENTITY'          },
		{ PLAYER_TALK_CHANNEL.BULLET_SCREEN    , 'MSG_JJC_BULLET_SCREEN' },
		{ PLAYER_TALK_CHANNEL.BATTLE_FIELD_SIDE, 'MSG_BATTLE_FIELD_SIDE' },
		{ PLAYER_TALK_CHANNEL.STORY_NPC        , 'MSG_STORY_NPC'         },
		{ PLAYER_TALK_CHANNEL.STORY_NPC_YELL   , 'MSG_STORY_NPC'         },
		{ PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER, 'MSG_STORY_NPC'         },
		{ PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO, 'MSG_STORY_NPC'         },
		{ PLAYER_TALK_CHANNEL.STORY_PLAYER     , 'MSG_STORY_PLAYER'      },
	}),
	MSG_TYPE_LIST = (function()
		local aList = {}
		local function CollectMsgType(node)
			for _, v in ipairs(node) do
				if X.IsString(v) then
					table.insert(aList, v)
				elseif X.IsTable(v) then
					CollectMsgType(v)
				end
			end
			return aList
		end
		return CollectMsgType(MSG_TYPE_MENU)
	end)(),
	MSG_TYPE_MENU = MSG_TYPE_MENU,
	PLAYER_TALK_CHANNEL_HEADER = KvpToObject({
		{ PLAYER_TALK_CHANNEL.NEARBY       , '/s '  },
		{ PLAYER_TALK_CHANNEL.FRIENDS      , '/o '  },
		{ PLAYER_TALK_CHANNEL.TONG_ALLIANCE, '/a '  },
		{ PLAYER_TALK_CHANNEL.TEAM         , '/p '  },
		{ PLAYER_TALK_CHANNEL.RAID         , '/t '  },
		{ PLAYER_TALK_CHANNEL.ROOM         , '/gr ' },
		{ PLAYER_TALK_CHANNEL.BATTLE_FIELD , '/b '  },
		{ PLAYER_TALK_CHANNEL.TONG         , '/g '  },
		{ PLAYER_TALK_CHANNEL.SENCE        , '/y '  },
		{ PLAYER_TALK_CHANNEL.FORCE        , '/f '  },
		{ PLAYER_TALK_CHANNEL.CAMP         , '/c '  },
		{ PLAYER_TALK_CHANNEL.WORLD        , '/h '  },
	}),
	INVENTORY_INDEX = INVENTORY_INDEX,
	INVENTORY_TYPE = {
		EQUIP           = 1, -- ���ϴ�װ��λ��
		PACKAGE         = 2, -- �������Զ��л����ⱳ��
		BANK            = 3, -- �ֿ�
		GUILD_BANK      = 4, -- ���ֿ�
		ORIGIN_PACKAGE  = 5, -- ԭʼ����
		LIMITED_PACKAGE = 6, -- ���ⱳ��
	},
	INVENTORY_EQUIP_LIST = {
		INVENTORY_INDEX.EQUIP,
		INVENTORY_INDEX.EQUIP_BACKUP1,
		INVENTORY_INDEX.EQUIP_BACKUP2,
		X.IIf(X.IS_CLASSIC, nil, INVENTORY_INDEX.EQUIP_BACKUP3),
	},
	INVENTORY_PACKAGE_LIST = {
		INVENTORY_INDEX.PACKAGE,
		INVENTORY_INDEX.PACKAGE1,
		INVENTORY_INDEX.PACKAGE2,
		INVENTORY_INDEX.PACKAGE3,
		INVENTORY_INDEX.PACKAGE4,
		INVENTORY_INDEX.PACKAGE_MIBAO,
	},
	INVENTORY_LIMITED_PACKAGE_LIST = {
		INVENTORY_INDEX.LIMITED_PACKAGE,
	},
	INVENTORY_BANK_LIST = {
		INVENTORY_INDEX.BANK,
		INVENTORY_INDEX.BANK_PACKAGE1,
		INVENTORY_INDEX.BANK_PACKAGE2,
		INVENTORY_INDEX.BANK_PACKAGE3,
		INVENTORY_INDEX.BANK_PACKAGE4,
		INVENTORY_INDEX.BANK_PACKAGE5,
	},
	INVENTORY_GUILD_BANK_LIST = {
		INVENTORY_INDEX.GUILD_BANK,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE1,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE2,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE3,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE4,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE5,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE6,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE7,
		INVENTORY_INDEX.GUILD_BANK_PACKAGE8,
	},
	AUCTION_ITEM_LIST_TYPE = _G.AUCTION_ITEM_LIST_TYPE or X.FreezeTable({
		NORMAL_LOOK_UP = 0,
		PRICE_LOOK_UP  = 1,
		DETAIL_LOOK_UP = 2,
		SELL_LOOK_UP   = 3,
		AVG_LOOK_UP    = 4,
	}),
	LOOT_ITEM_TYPE = _G.LOOT_ITEM_TYPE or X.FreezeTable({
		INVALID               = 0,
		OWNER_LOOT            = 1,
		OVER_TIME_LOOTER_FREE = 2,
		ABSOLUTE_FREE         = 3,
		LOOTER_FREE           = 4,
		NEED_DISTRIBUTE       = 5,
		NEED_ROLL             = 6,
		NEED_BIDDING          = 7,
		TOTAL                 = 8,
	}),
	NPC_SPECIES_TYPE = _G.NPC_SPECIES_TYPE or X.FreezeTable({
		NPC_HUMANOID    = 1,
		NPC_BEAST       = 2,
		NPC_MECHANICAL  = 3,
		NPC_UNDEAD      = 4,
		NPC_GHOST       = 5,
		NPC_PLANT       = 6,
		NPC_LEGENDARY   = 7,
		NPC_CRITTER     = 8,
		NPC_OTHER       = 9,
		NPC_PET         = 10,
		NPC_GAS         = 11,
		NPC_BATTERY     = 12,
		NPC_TRAP        = 13,
		NPC_BOMB        = 14,
		NPC_FELLOW_PET  = 15,
		NPC_SWORD_POWER = 16,
		NPC_ASSISTED    = 17,
		NPC_MIRAGE      = 18,
		NPC_BEAST_PET   = 19,
		NPC_TONRAUM     = 20,
	}),
	DOODAD_KIND = X.FreezeTable(
		setmetatable({
			SPRINT = _G.DOODAD_KIND.SPRINT or _G.DOODAD_KIND.BANQUET or 15,
			BANQUET = _G.DOODAD_KIND.BANQUET or _G.DOODAD_KIND.SPRINT or 15,
		}, { __index = _G.DOODAD_KIND })
	),
	TEAM_MARK,
	TEAM_MARK_NAME = {
		[TEAM_MARK.CLOUD] = _L['TEAM_MARK_CLOUD'],
		[TEAM_MARK.SWORD] = _L['TEAM_MARK_SWORD'],
		[TEAM_MARK.AX   ] = _L['TEAM_MARK_AX'   ],
		[TEAM_MARK.HOOK ] = _L['TEAM_MARK_HOOK' ],
		[TEAM_MARK.DRUM ] = _L['TEAM_MARK_DRUM' ],
		[TEAM_MARK.SHEAR] = _L['TEAM_MARK_SHEAR'],
		[TEAM_MARK.STICK] = _L['TEAM_MARK_STICK'],
		[TEAM_MARK.JADE ] = _L['TEAM_MARK_JADE' ],
		[TEAM_MARK.DART ] = _L['TEAM_MARK_DART' ],
		[TEAM_MARK.FAN  ] = _L['TEAM_MARK_FAN'  ],
	},
	CLIENT_VERSION_TYPE = _G.CLIENT_VERSION_TYPE or X.FreezeTable({
		NORMAL                 = 0,
		WEGAME                 = 1,
		STREAMING              = 2,
		MOBILE_ANDROID         = 3,
		MOBILE_IOS             = 4,
		MOBILE_PC              = 5,
		MOBILE_OHOS            = 6,
		MOBILE_MAC             = 7,
		MOBILE_WLCLOUD_ANDROID = 8,
		MOBILE_WLCLOUD_IOS     = 9,
	}),
	MACHINE_GPU_TYPE = X.FreezeTable({
		LOW    = 1,
		NORMAL = 2,
	}),
	MACHINE_GPU_LEVEL = X.FreezeTable({
		ENABLE     =  0,
		ATTEND     =  1,
		LOWEST     =  2, -- ���
		LOW_MOST   =  3, -- ��Լ
		LOW        =  4, -- ����
		MEDIUM     =  5, -- Ψ�� // �⵵���������ˣ�ԭ��ѡ�⵵���˽����Ժ�ֱ�Ӹĳɾ���
		HIGH       =  6, -- ��Ч
		PERFECTION =  7, -- ��Ӱ
		HD         =  8, -- ����
		PERFECT    = 10, -- ����
		EXPLORE    =  9, -- ̽�� // �� PERFECT Ҫ�ߣ�����ö��ֵȴСһ��
	}),
	USER_SETTINGS_LOCATION_OVERRIDE = X.FreezeTable({
		PRESET = 0,
		ROLE   = 1,
		SERVER = 2,
		GLOBAL = 3,
	}),
	ZHEN_PAI = PickBranch({
		classic = TALENT_TAB or KvpToObject({
			{
				FORCE_TYPE.SHAO_LIN,
				{
					{
						{ 2549, 2559, 2556, 0 },
						{ 2557, 2558, 2564, 2560 },
						{ 2561, 2563, 2551, 2565 },
						{ 2566, 2567, 2568, 64095 },
						{ 2570, 64002, 64004, 64096 },
						{ 64106, 2572, 64109, 0 },
					},
					{
						{ 2573, 2574, 2575, 0 },
						{ 2576, 2577, 2578, 2579 },
						{ 2580, 2581, 2582, 2583 },
						{ 2584, 2585, 2586, 2587 },
						{ 2588, 2562, 0, 0 },
						{ 0, 2589, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.WAN_HUA,
				{
					{
						{ 2629, 2630, 2631, 0 },
						{ 2632, 2633, 2634, 2635 },
						{ 2639, 2637, 2638, 2636 },
						{ 2640, 2641, 2642, 64010 },
						{ 2643, 2644, 64112, 64022 },
						{ 64114, 2645, 64113, 0 },
					},
					{
						{ 2647, 2648, 2652, 0 },
						{ 2650, 2651, 2649, 2653 },
						{ 2654, 2655, 2656, 2657 },
						{ 2658, 2659, 2660, 3789 },
						{ 2661, 64001, 64116, 64131 },
						{ 0, 2663, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.TIAN_CE,
				{
					{
						{ 2595, 2596, 2597, 0 },
						{ 2598, 2599, 2600, 2601 },
						{ 2602, 2603, 2604, 2605 },
						{ 2606, 2607, 2608, 64117 },
						{ 64118, 2609, 2610, 64119 },
						{ 0, 2611, 0, 0 },
					},
					{
						{ 2612, 2613, 2614, 0 },
						{ 2615, 2616, 2617, 2618 },
						{ 2619, 2620, 2621, 2622 },
						{ 2623, 2624, 2625, 0 },
						{ 2626, 2627, 0, 0 },
						{ 0, 2628, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.CHUN_YANG,
				{
					{
						{ 2682, 2683, 0, 2684 },
						{ 2685, 2686, 2687, 2688 },
						{ 2689, 2690, 2691, 2692 },
						{ 2693, 2694, 2695, 2696 },
						{ 2698, 2697, 64008, 64135 },
						{ 64137, 64136, 2699, 0 },
					},
					{
						{ 2665, 2666, 0, 2667 },
						{ 2679, 2669, 2670, 2671 },
						{ 2672, 2673, 2674, 2675 },
						{ 64129, 2677, 2676, 2678 },
						{ 4080, 2668, 2680, 64133 },
						{ 64134, 2681, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.QI_XIU,
				{
					{
						{ 2700, 2701, 2702, 0 },
						{ 2703, 2704, 2709, 2706 },
						{ 2707, 2708, 2705, 2710 },
						{ 2711, 2712, 64098, 2713 },
						{ 0, 2714, 2715, 0 },
						{ 0, 2716, 64103, 0 },
					},
					{
						{ 2717, 2718, 2719, 0 },
						{ 2720, 2721, 2722, 2723 },
						{ 2724, 2725, 2726, 2727 },
						{ 2728, 2729, 2730, 2731 },
						{ 64104, 64105, 2732, 0 },
						{ 0, 2733, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.WU_DU,
				{
					{
						{ 2993, 0, 2935, 2936 },
						{ 2937, 2938, 2939, 2940 },
						{ 2941, 2218, 2942, 2943 },
						{ 2945, 2946, 2944, 64139 },
						{ 64140, 2947, 2948, 0 },
						{ 0, 0, 2227, 0 },
					},
					{
						{ 2949, 2950, 0, 2951 },
						{ 2952, 2953, 2954, 2955 },
						{ 2956, 2957, 2958, 2959 },
						{ 2960, 0, 2961, 2962 },
						{ 64138, 64041, 2963, 2964 },
						{ 0, 64643, 2965, 0 },
					},
				}
			},
			{
				FORCE_TYPE.TANG_MEN,
				{
					{
						{ 3260, 3261, 3262, 0 },
						{ 3263, 3264, 3265, 3266 },
						{ 3267, 3101, 3268, 3269 },
						{ 3270, 3271, 3272, 3492 },
						{ 0, 3273, 64082, 0 },
						{ 0, 3100, 0, 0 },
					},
					{
						{ 3275, 3276, 3277, 0 },
						{ 3278, 3279, 3280, 3281 },
						{ 64081, 3110, 3283, 3284 },
						{ 3285, 3286, 3287, 0 },
						{ 3288, 3282, 0, 0 },
						{ 0, 3111, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.CANG_JIAN,
				{
					{
						{ 2734, 2735, 2736, 0 },
						{ 2737, 2738, 2739, 2740 },
						{ 2741, 2742, 2748, 2743 },
						{ 2745, 2744, 3417, 64024 },
						{ 2747, 2749, 64124, 2762 },
						{ 0, 2750, 0, 64125 },
					},
					{
						{ 2751, 2752, 2753, 0 },
						{ 2754, 2760, 2763, 2757 },
						{ 2758, 2755, 2759, 2761 },
						{ 2746, 2756, 2764, 64126 },
						{ 2765, 2766, 2767, 0 },
						{ 0, 2768, 0, 0 },
					},
				}
			},
			{
				FORCE_TYPE.MING_JIAO,
				{
					{
						{ 3986, 3987, 3988, 0 },
						{ 3989, 3990, 3991, 3992 },
						{ 3977, 3993, 3994, 3995 },
						{ 3996, 3997, 3998, 3999 },
						{ 4000, 4001, 0, 0 },
						{ 0, 3978, 0, 0 },
					},
					{
						{ 4002, 4003, 4004, 0 },
						{ 4005, 4009, 4007, 4008 },
						{ 3983, 4013, 4010, 4011 },
						{ 4012, 4006, 4014, 4015 },
						{ 4016, 4017, 0, 0 },
						{ 0, 3985, 0, 0 },
					},
				}
			},
		}),
	}),
}

-- ���������ҵȼ�����
RegisterEvent('PLAYER_ENTER_SCENE', function()
	CONSTANT.MAX_PLAYER_LEVEL = math.max(
		CONSTANT.MAX_PLAYER_LEVEL,
		X.GetClientPlayer().nMaxLevel
	)
end)

X.CONSTANT = setmetatable({}, { __index = CONSTANT, __newindex = function() end })

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
