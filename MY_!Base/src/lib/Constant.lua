--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ��Ϸ����ö��
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

local KvpToObject = LIB.KvpToObject
local bStream = GLOBAL.GAME_PROVIDER == 'remote'
local bClassic = GLOBAL.GAME_BRANCH == 'classic'

local FORCE_TYPE = (function()
	local FORCE_TYPE = _G.FORCE_TYPE or SetmetaReadonly({
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
	})
	local res = {}
	for k, v in pairs_c(FORCE_TYPE) do
		if g_tStrings.tForceTitle[v] then
			res[k] = v
		end
	end
	return SetmetaReadonly(res)
end)()

LIB.CONSTANT = setmetatable({}, {
	__index = {
		MENU_DIVIDER = SetmetaReadonly({ bDevide = true }),
		EMPTY_TABLE = SetmetaReadonly({}),
		XML_LINE_BREAKER = GetFormatText('\n'),
		UI_OBJECT = UI_OBJECT or SetmetaReadonly({
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
		GLOBAL_HEAD = GLOBAL_HEAD or SetmetaReadonly({
			CLIENTPLAYER = 0,
			OTHERPLAYER  = 1,
			NPC          = 2,
			LIFE         = 0,
			GUILD        = 1,
			TITLE        = 2,
			NAME         = 3,
			MARK         = 4,
		}),
		EQUIPMENT_SUB = EQUIPMENT_SUB or SetmetaReadonly({
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
		EQUIPMENT_INVENTORY = EQUIPMENT_INVENTORY or SetmetaReadonly({
			MELEE_WEAPON  = 1 , -- ��ͨ��ս����
			BIG_SWORD     = 2 , -- �ؽ�
			RANGE_WEAPON  = 3 , -- Զ������
			CHEST         = 4 , -- ����
			HELM          = 5 , -- ͷ��
			AMULET        = 6 , -- ����
			LEFT_RING     = 7 , -- ���ֽ�ָ
			RIGHT_RING    = 8 , -- ���ֽ�ָ
			WAIST         = 9 , -- ����
			PENDANT       = 10, -- ��׺
			PANTS         = 11, -- ����
			BOOTS         = 12, -- Ь��
			BANGLE        = 13, -- ����
			PACKAGE1      = 14, -- ��չ����1
			PACKAGE2      = 15, -- ��չ����2
			PACKAGE3      = 16, -- ��չ����3
			PACKAGE4      = 17, -- ��չ����4
			PACKAGE_MIBAO = 18, -- �󶨰�ȫ��Ʒ״̬�����͵Ķ��ⱳ���� ��ItemList V9������
			BANK_PACKAGE1 = 19, -- �ֿ���չ����1
			BANK_PACKAGE2 = 20, -- �ֿ���չ����2
			BANK_PACKAGE3 = 21, -- �ֿ���չ����3
			BANK_PACKAGE4 = 22, -- �ֿ���չ����4
			BANK_PACKAGE5 = 23, -- �ֿ���չ����5
			ARROW         = 24, -- ����
			TOTAL         = 25,
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
		ROLE_TYPE_LABEL = SetmetaReadonly({
			[ROLE_TYPE.STANDARD_MALE  ] = _L['Man'],
			[ROLE_TYPE.STANDARD_FEMALE] = _L['Woman'],
			[ROLE_TYPE.LITTLE_BOY     ] = _L['Boy'],
			[ROLE_TYPE.LITTLE_GIRL    ] = _L['Girl'],
		}),
		FORCE_TYPE = FORCE_TYPE,
		FORCE_TYPE_LABEL = g_tStrings.tForceTitle,
		KUNGFU_TYPE = (function()
			local KUNGFU_TYPE = _G.KUNGFU_TYPE or SetmetaReadonly({
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
			for k, v in pairs_c(KUNGFU_TYPE) do
				if g_tStrings.tForceTitle[v] then
					res[k] = v
				end
			end
			return SetmetaReadonly(res)
		end)(),
		PEEK_OTHER_PLAYER_RESPOND = PEEK_OTHER_PLAYER_RESPOND or SetmetaReadonly({
			INVALID             = 0,
			SUCCESS             = 1,
			FAILED              = 2,
			CAN_NOT_FIND_PLAYER = 3,
			TOO_FAR             = 4,
		}),
		MIC_STATE = MIC_STATE or SetmetaReadonly({
			NOT_AVIAL = 1,
			CLOSE_NOT_IN_ROOM = 2,
			CLOSE_IN_ROOM = 3,
			KEY = 4,
			FREE = 5,
		}),
		SPEAKER_STATE = SPEAKER_STATE or SetmetaReadonly({
			OPEN = 1,
			CLOSE = 2,
		}),
		ITEM_QUALITY = SetmetaReadonly({
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
		-- ��ͬ���ֵĵ�ͼ ȫ��ָ��ͬһ��ID
		MAP_NAME_FIX = {
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
		NPC_NAME = {},
		NPC_NAME_FIX = {
			[58294] = 62347, -- ��������
		},
		NPC_HIDDEN = {
			[19153] = true, -- �ʹ���Χ�ܿ�
			[27634] = true, -- �ػ��갲»ɽ�ܿ�
			[56383] = true, -- ͨ�ؽ�����ɱ��ֿ���
			[60045] = true, -- ����ǵ�����η��Ĳ�֪��ʲô����
		},
		DOODAD_NAME = {},
		DOODAD_NAME_FIX = {},
		KUNGFU_LIST = (function()
			-- skillid, uitex, frame
			local KUNGFU_LIST = {
				-- MT
				{ dwForceID = FORCE_TYPE.TIAN_CE  , dwID = 10062, nIcon = 632  , szUITex = 'ui/Image/icon/skill_tiance01.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.MING_JIAO, dwID = 10243, nIcon = 3864 , szUITex = 'ui/Image/icon/mingjiao_taolu_7.UITex'  , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.CANG_YUN , dwID = 10389, nIcon = 6315 , szUITex = 'ui/Image/icon/Skill_CangY_33.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.SHAO_LIN , dwID = 10002, nIcon = 429  , szUITex = 'ui/Image/icon/skill_shaolin14.UITex'   , nFrame = 0  }, -- ����
				-- ����
				{ dwForceID = FORCE_TYPE.QI_XIU   , dwID = 10080, nIcon = 887  , szUITex = 'ui/Image/icon/skill_qixiu02.UITex'     , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.WU_DU    , dwID = 10176, nIcon = 2767 , szUITex = 'ui/Image/icon/wudu_neigong_2.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.WAN_HUA  , dwID = 10028, nIcon = 412  , szUITex = 'ui/Image/icon/skill_wanhua23.UITex'    , nFrame = 0  }, -- �뾭
				{ dwForceID = FORCE_TYPE.CHANG_GE , dwID = 10448, nIcon = 7067 , szUITex = 'ui/Image/icon/skill_0514_23.UITex'     , nFrame = 0  }, -- ��֪
				-- �ڹ�
				{ dwForceID = FORCE_TYPE.TANG_MEN , dwID = 10225, nIcon = 3184 , szUITex = 'ui/Image/icon/skill_tangm_20.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.QI_XIU   , dwID = 10081, nIcon = 888  , szUITex = 'ui/Image/icon/skill_qixiu03.UITex'     , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.WU_DU    , dwID = 10175, nIcon = 2766 , szUITex = 'ui/Image/icon/wudu_neigong_1.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.MING_JIAO, dwID = 10242, nIcon = 3865 , szUITex = 'ui/Image/icon/mingjiao_taolu_8.UITex'  , nFrame = 0  }, -- ��Ӱ
				{ dwForceID = FORCE_TYPE.CHUN_YANG, dwID = 10014, nIcon = 627  , szUITex = 'ui/Image/icon/skill_chunyang21.UITex'  , nFrame = 0  }, -- ��ϼ
				{ dwForceID = FORCE_TYPE.WAN_HUA  , dwID = 10021, nIcon = 406  , szUITex = 'ui/Image/icon/skill_wanhua17.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.SHAO_LIN , dwID = 10003, nIcon = 425  , szUITex = 'ui/Image/icon/skill_shaolin10.UITex'   , nFrame = 0  }, -- �׾�
				{ dwForceID = FORCE_TYPE.CHANG_GE , dwID = 10447, nIcon = 7071 , szUITex = 'ui/Image/icon/skill_0514_27.UITex'     , nFrame = 0  }, -- Ī��
				{ dwForceID = FORCE_TYPE.YAN_TIAN , dwID = 10615, nIcon = 13894, szUITex = 'ui/image/icon/skill_20_9_14_1.uitex'   , nFrame = 19 }, -- ̫��
				-- �⹦
				{ dwForceID = FORCE_TYPE.CANG_YUN , dwID = 10390, nIcon = 6314 , szUITex = 'ui/Image/icon/Skill_CangY_32.UITex'    , nFrame = 0  }, -- ��ɽ
				{ dwForceID = FORCE_TYPE.TANG_MEN , dwID = 10224, nIcon = 3165 , szUITex = 'ui/Image/icon/skill_tangm_01.UITex'    , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.CANG_JIAN, dwID = 10144, nIcon = 2376 , szUITex = 'ui/Image/icon/cangjian_neigong_1.UITex', nFrame = 0  }, -- ��ˮ
				{ dwForceID = FORCE_TYPE.CANG_JIAN, dwID = 10145, nIcon = 2377 , szUITex = 'ui/Image/icon/cangjian_neigong_2.UITex', nFrame = 0  }, -- ɽ��
				{ dwForceID = FORCE_TYPE.CHUN_YANG, dwID = 10015, nIcon = 619  , szUITex = 'ui/Image/icon/skill_chunyang13.UITex'  , nFrame = 0  }, -- ����
				{ dwForceID = FORCE_TYPE.TIAN_CE  , dwID = 10026, nIcon = 633  , szUITex = 'ui/Image/icon/skill_tiance02.UITex'    , nFrame = 0  }, -- ��ѩ
				{ dwForceID = FORCE_TYPE.GAI_BANG , dwID = 10268, nIcon = 4610 , szUITex = 'ui/Image/icon/skill_GB_30.UITex'       , nFrame = 0  }, -- Ц��
				{ dwForceID = FORCE_TYPE.BA_DAO   , dwID = 10464, nIcon = 8424 , szUITex = 'ui/Image/icon/daoj_16_8_25_16.UITex'   , nFrame = 0  }, -- �Ե�
				{ dwForceID = FORCE_TYPE.PENG_LAI , dwID = 10533, nIcon = 10709, szUITex = 'ui/image/icon/JNPL_18_10_30_27.uitex'  , nFrame = 45 }, -- ����
				{ dwForceID = FORCE_TYPE.LING_XUE , dwID = 10585, nIcon = 12128, szUITex = 'ui/image/icon/JNLXG_19_10_21_9.uitex'  , nFrame = 74 }, -- ��ѩ
			}
			local res = {}
			for _, v in ipairs(KUNGFU_LIST) do
				if v.dwForceID and Table_GetSkill(v.dwID) then
					insert(res, v)
				end
			end
			return res
		end)(),
		FORCE_AVATAR = setmetatable(
			KvpToObject({
				{ FORCE_TYPE.JIANG_HU , {'ui\\Image\\PlayerAvatar\\jianghu.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.SHAO_LIN , {'ui\\Image\\PlayerAvatar\\shaolin.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.WAN_HUA  , {'ui\\Image\\PlayerAvatar\\wanhua.tga'   , -2, false} }, -- ��
				{ FORCE_TYPE.TIAN_CE  , {'ui\\Image\\PlayerAvatar\\tiance.tga'   , -2, false} }, -- ���
				{ FORCE_TYPE.CHUN_YANG, {'ui\\Image\\PlayerAvatar\\chunyang.tga' , -2, false} }, -- ����
				{ FORCE_TYPE.QI_XIU   , {'ui\\Image\\PlayerAvatar\\qixiu.tga'    , -2, false} }, -- ����
				{ FORCE_TYPE.WU_DU    , {'ui\\Image\\PlayerAvatar\\wudu.tga'     , -2, false} }, -- �嶾
				{ FORCE_TYPE.TANG_MEN , {'ui\\Image\\PlayerAvatar\\tangmen.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.CANG_JIAN, {'ui\\Image\\PlayerAvatar\\cangjian.tga' , -2, false} }, -- �ؽ�
				{ FORCE_TYPE.GAI_BANG , {'ui\\Image\\PlayerAvatar\\gaibang.tga'  , -2, false} }, -- ؤ��
				{ FORCE_TYPE.MING_JIAO, {'ui\\Image\\PlayerAvatar\\mingjiao.tga' , -2, false} }, -- ����
				{ FORCE_TYPE.CANG_YUN , {'ui\\Image\\PlayerAvatar\\cangyun.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.CHANG_GE , {'ui\\Image\\PlayerAvatar\\changge.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.BA_DAO   , {'ui\\Image\\PlayerAvatar\\badao.tga'    , -2, false} }, -- �Ե�
				{ FORCE_TYPE.PENG_LAI , {'ui\\Image\\PlayerAvatar\\penglai.tga'  , -2, false} }, -- ����
				{ FORCE_TYPE.LING_XUE , {'ui\\Image\\PlayerAvatar\\lingxuege.tga', -2, false} }, -- ��ѩ
			}),
			{
				__index = function(t, k)
					return t[FORCE_TYPE.JIANG_HU]
				end,
				__metatable = true,
			}),
		FORCE_COLOR_FG_DEFAULT = setmetatable(
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
				{ FORCE_TYPE.CANG_YUN , bStream and { 255, 143, 80 } or { 180, 60, 0 } }, -- ����
				{ FORCE_TYPE.CHANG_GE , { 100, 250, 180 } }, -- ����
				{ FORCE_TYPE.BA_DAO   , { 106, 108, 189 } }, -- �Ե�
				{ FORCE_TYPE.PENG_LAI , { 171, 227, 250 } }, -- ����
				{ FORCE_TYPE.LING_XUE , bStream and { 253, 86, 86 } or { 161,   9,  34 } }, -- ��ѩ
				{ FORCE_TYPE.YAN_TIAN , { 166,  83, 251 } }, -- ����
			}),
			{
				__index = function(t, k)
					return { 225, 225, 225 }
				end,
				__metatable = true,
			}),
		FORCE_COLOR_BG_DEFAULT = setmetatable(
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
			}),
			{
				__index = function(t, k)
					return { 200, 200, 200 } -- NPC �Լ�δ֪����
				end,
				__metatable = true,
			}),
		CAMP_COLOR_FG_DEFAULT = setmetatable(
			KvpToObject({
				{ CAMP.NEUTRAL, { 255, 255, 255 } }, -- ����
				{ CAMP.GOOD   , {  60, 128, 220 } }, -- ������
				{ CAMP.EVIL   , bStream and { 255, 63, 63 } or { 160, 30, 30 } }, -- ���˹�
			}),
			{
				__index = function(t, k)
					return { 225, 225, 225 }
				end,
				__metatable = true,
			}),
		CAMP_COLOR_BG_DEFAULT = setmetatable(
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
		MSG_THEME = SetmetaReadonly({
			NORMAL = 0,
			ERROR = 1,
			WARNING = 2,
			SUCCESS = 3,
		}),
		QUEST_INFO = { -- ������Ϣ {����ID, ������NPCģ��ID}
		BIG_WARS = (function()
			for _, v in ipairs_r({
				-- 70��
				{
					{5116, 869}, -- �ͽ�Ӣ��������
					-- {5117, 869}, -- ��Ч��������
					{5118, 869}, -- �ͽ�Ӣ���칤��
					{5119, 869}, -- �ͽ�Ӣ�ۿ�����
					{5120, 869}, -- �ͽ�Ӣ�����ε�
					{5121, 869}, -- �ͽ�Ӣ������Ͽ
				},
				-- 95��
				{
					{14765, 869}, -- ��ս��Ӣ��΢ɽ��Ժ��
					{14766, 869}, -- ��ս��Ӣ�������֣�
					{14767, 869}, -- ��ս��Ӣ�������Ժ��
					{14768, 869}, -- ��ս��Ӣ����ɽʥȪ��
					{14769, 869}, -- ��ս��Ӣ������ˮ鿣�
				},
				-- 95����
				{
					{17816, 869}, -- ��ս��Ӣ�۵������£�
					{17817, 869}, -- ��ս��Ӣ����������
					{17818, 869}, -- ��ս��Ӣ�۵��ֺ�����
					{17819, 869}, -- ��ս��Ӣ��Ϧ�ո�
					{17820, 869}, -- ��ս��Ӣ�۰׵�ˮ����
				},
				-- 100��
				{
					{19191, 869}, -- ��ս��Ӣ�۾ű�ݣ�
					{19192, 869}, -- ��ս��Ӣ���������죡
					{19195, 869}, -- ��ս��Ӣ�۾�������
					{19196, 869}, -- ��ս��Ӣ�۴�����˿����
					{19197, 869}, -- ��ս��Ӣ����Ԩ����
					{21570, 869}, -- ��ս��Ӣ�����ױ�Ժ��
					{21572, 869}, -- ��ս��Ӣ�������죡
				},
				-- 110��
				{
					{22939, 869}, -- ��ս��Ӣ�۽�ڣ���䣡
					{22941, 869}, -- ��ս��Ӣ����ͩɽׯ��
					{22942, 869}, -- ��ս��Ӣ���������ǣ�
					{22950, 869}, -- ��ս��Ӣ���޺��ţ�
					{22951, 869}, -- ��ս��Ӣ�����뼯�浺��
				},
			}) do
				for _, vv in ipairs(v) do
					if GetQuestInfo(vv[1]) then
						return v
					end
				end
			end
			return {}
		end)(),
			TEAHOUSE_ROUTINE = {
				-- 90��
				-- {11115}, -- �������̽�����
				-- 95��
				-- {14246, 45009}, -- �����������в�
				-- 100��
				-- {19514, 63734}, -- �׺��Ʒ��Ų���
				-- 110��
				{22700, 101195}, -- ����������ƽ��
			},
			PUBLIC_ROUTINE = {
				{14831, 869}, -- ������Զ��������
			},
			ROOKIE_ROUTINE = {{21433, 67083}},
			CAMP_CRYSTAL_SCRAMBLE = {
				[CAMP.GOOD] = {
					-- {14727, 46968}, -- ��ھ���������
					-- {14729, 46968}, -- ��ھ���������
					-- {14893, 62002}, -- �����ˣ�ľ�����Ϸ�����
					-- {18904, 62002}, -- ��Դ��������
					-- {19200, 62002}, -- ��Դ��������
					-- {19310, 62002}, -- ��Դ��������
					-- {19719, 62002}, -- ���׵�ԴѰ����
					-- 100����
					-- {20306, 67195}, -- ľ�����Ϸ�����
					-- {20307, 67195}, -- ľ�����Ϸ�����
					-- {20308, 67195}, -- ľ�����Ϸ�����
					-- 110��
					{22195, 100967}, -- ���Ӻ���Σ��Ǳ
					{22196, 100967}, -- ���Ӻ���Σ��Ǳ
					{22197, 100967}, -- ���Ӻ���Σ��Ǳ
					{22680, 67195}, -- �������϶����
				},
				[CAMP.EVIL] = {
					-- {14728, 46969}, -- ��ھ���������
					-- {14730, 46969}, -- ��ھ���������
					-- {14894, 62039}, -- ���˹ȣ�ľ�����Ϸ�����
					-- {18936, 62039}, -- ��Դ��������
					-- {19201, 62039}, -- ��Դ��������
					-- {19311, 62039}, -- ��Դ��������
					-- {19720, 62039}, -- ���׵�ԴѰ����
					-- 100����
					-- {20309, 67196}, -- ľ�����Ϸ�����
					-- {20310, 67196}, -- ľ�����Ϸ�����
					-- {20311, 67196}, -- ľ�����Ϸ�����
					-- 110��
					{22198, 100961}, -- ���Ӻ���Σ��Ǳ
					{22199, 100961}, -- ���Ӻ���Σ��Ǳ
					{22200, 100961}, -- ���Ӻ���Σ��Ǳ
					{22679, 67196}, -- �������϶����
				},
			},
			CAMP_STRONGHOLD_TRADE = {
				[CAMP.GOOD] = {
					{11864, 36388}, -- �ݵ�ó�ף�������
				},
				[CAMP.EVIL] = {
					{11991, 36387}, -- �ݵ�ó�ף����˹�
				},
			},
			DRAGON_GATE_DESPAIR = {
				{17895, 59149},
			},
			LEXUS_REALITY = {
				{20220, 64489},
			},
			LIDU_GHOST_TOWN = {
				{18317, 64489},
			},
			FORCE_ROUTINE = KvpToObject({
				{ FORCE_TYPE.TIAN_CE  , {{8206, 16747}, {11254, 16747}, {11255, 16747}} }, -- ���
				{ FORCE_TYPE.CHUN_YANG, {{8347, 16747}, {8398, 16747}} }, -- ����
				{ FORCE_TYPE.WAN_HUA  , {{8348, 16747}, {8399, 16747}, {22842, 16747}, {22929, 16747}} }, -- ��
				{ FORCE_TYPE.SHAO_LIN , {{8349, 16747}, {8400, 16747}, {22851, 16747}, {22930, 16747}} }, -- ����
				{ FORCE_TYPE.QI_XIU   , {{8350, 16747}, {8401, 16747}, {22757, 16747}, {22758, 16747}} }, -- ����
				{ FORCE_TYPE.CANG_JIAN, {{8351, 16747}, {8402, 16747}, {22766, 16747}, {22767, 16747}} }, -- �ؽ�
				{ FORCE_TYPE.WU_DU    , {{8352, 16747}, {8403, 16747}} }, -- �嶾
				{ FORCE_TYPE.TANG_MEN , {{8353, 16747}, {8404, 16747}} }, -- ����
				{ FORCE_TYPE.MING_JIAO, {{9796, 16747}, {9797, 16747}} }, -- ����
				{ FORCE_TYPE.GAI_BANG , {{11245, 16747}, {11246, 16747}} }, -- ؤ��
				{ FORCE_TYPE.CANG_YUN , {{12701, 16747}, {12702, 16747}} }, -- ����
				{ FORCE_TYPE.CHANG_GE , {{14731, 16747}, {14732, 16747}} }, -- ����
				{ FORCE_TYPE.BA_DAO   , {{16205, 16747}, {16206, 16747}} }, -- �Ե�
				{ FORCE_TYPE.PENG_LAI , {{19225, 16747}, {19226, 16747}} }, -- ����
				{ FORCE_TYPE.LING_XUE , {{21067, 16747}, {21068, 16747}} }, -- ��ѩ
				{ FORCE_TYPE.YAN_TIAN , {{22775, 16747}, {22776, 16747}} }, -- ����
			}),
			PICKING_FAIRY_GRASS = {{8332, 16747}},
			FIND_DRAGON_VEINS = {{13600, 16747}},
			SNEAK_ROUTINE = {{7669, 16747}},
			ILLUSTRATION_ROUTINE = {{8440, 15675}},
		},
		BUFF_INFO = {
			EXAM_SHENG = {{10936, 0}},
			EXAM_HUI = {{4125, 0}},
		},
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
		MSG_TYPE_MENU = {
			{
				szCaption = g_tStrings.CHANNEL_CHANNEL,
				tChannels = {
					'MSG_NORMAL', 'MSG_PARTY', 'MSG_MAP', 'MSG_BATTLE_FILED', 'MSG_GUILD', 'MSG_GUILD_ALLIANCE', 'MSG_SCHOOL', 'MSG_WORLD',
					'MSG_TEAM', 'MSG_CAMP', 'MSG_GROUP', 'MSG_WHISPER', 'MSG_SEEK_MENTOR', 'MSG_FRIEND', 'MSG_IDENTITY', 'MSG_SYS',
				},
			}, {
				szCaption = g_tStrings.FIGHT_CHANNEL,
				tChannels = {
					[g_tStrings.STR_NAME_OWN] = {
						'MSG_SKILL_SELF_HARMFUL_SKILL', 'MSG_SKILL_SELF_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_BUFF',
						'MSG_SKILL_SELF_BE_HARMFUL_SKILL', 'MSG_SKILL_SELF_BE_BENEFICIAL_SKILL', 'MSG_SKILL_SELF_DEBUFF',
						'MSG_SKILL_SELF_SKILL', 'MSG_SKILL_SELF_MISS', 'MSG_SKILL_SELF_FAILED', 'MSG_SELF_DEATH',
					},
					[g_tStrings.TEAMMATE] = {
						'MSG_SKILL_PARTY_HARMFUL_SKILL', 'MSG_SKILL_PARTY_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_BUFF',
						'MSG_SKILL_PARTY_BE_HARMFUL_SKILL', 'MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL', 'MSG_SKILL_PARTY_DEBUFF',
						'MSG_SKILL_PARTY_SKILL', 'MSG_SKILL_PARTY_MISS', 'MSG_PARTY_DEATH',
					},
					[g_tStrings.OTHER_PLAYER] = {'MSG_SKILL_OTHERS_SKILL', 'MSG_SKILL_OTHERS_MISS', 'MSG_OTHERS_DEATH'},
					['NPC'] = {'MSG_SKILL_NPC_SKILL', 'MSG_SKILL_NPC_MISS', 'MSG_NPC_DEATH'},
					[g_tStrings.OTHER] = {'MSG_OTHER_ENCHANT', 'MSG_OTHER_SCENE'},
				},
			}, {
				szCaption = g_tStrings.CHANNEL_COMMON,
				tChannels = {
					[g_tStrings.ENVIROMENT] = {'MSG_NPC_NEARBY', 'MSG_NPC_YELL', 'MSG_NPC_PARTY', 'MSG_NPC_WHISPER'},
					[g_tStrings.EARN] = {
						'MSG_MONEY', 'MSG_EXP', 'MSG_ITEM', 'MSG_REPUTATION', 'MSG_CONTRIBUTE',
						'MSG_ATTRACTION', 'MSG_PRESTIGE', 'MSG_TRAIN', 'MSG_DESGNATION',
						'MSG_ACHIEVEMENT', 'MSG_MENTOR_VALUE', 'MSG_THEW_STAMINA', 'MSG_TONG_FUND'
					},
				},
			}
		},
		INVENTORY_INDEX = INVENTORY_INDEX,
		INVENTORY_EQUIP_LIST = {
			INVENTORY_INDEX.EQUIP,
			INVENTORY_INDEX.EQUIP_BACKUP1,
			INVENTORY_INDEX.EQUIP_BACKUP2,
			INVENTORY_INDEX.EQUIP_BACKUP3,
		},
		INVENTORY_PACKAGE_LIST = {
			INVENTORY_INDEX.PACKAGE,
			INVENTORY_INDEX.PACKAGE1,
			INVENTORY_INDEX.PACKAGE2,
			INVENTORY_INDEX.PACKAGE3,
			INVENTORY_INDEX.PACKAGE4,
			INVENTORY_INDEX.PACKAGE_MIBAO,
		},
		INVENTORY_BANK_LIST = {
			INVENTORY_INDEX.BANK,
			INVENTORY_INDEX.BANK_PACKAGE1,
			INVENTORY_INDEX.BANK_PACKAGE2,
			INVENTORY_INDEX.BANK_PACKAGE3,
			INVENTORY_INDEX.BANK_PACKAGE4,
			INVENTORY_INDEX.BANK_PACKAGE5,
		},
		INVENTORY_GUILD_BANK = INVENTORY_GUILD_BANK or INVENTORY_INDEX.TOTAL + 1, --���ֿ��������һ������λ��
		INVENTORY_GUILD_PAGE_SIZE = INVENTORY_GUILD_PAGE_SIZE or 100,
		INVENTORY_GUILD_PAGE_BOX_COUNT = 98,
	},
	__newindex = function() end,
})