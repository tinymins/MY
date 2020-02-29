--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ս��ͳ�� ������
-- @author   : ���� @˫���� @׷����Ӱ
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local DK = MY_Recount_DS.DK
local DK_REC = MY_Recount_DS.DK_REC
local DK_REC_SNAPSHOT = MY_Recount_DS.DK_REC_SNAPSHOT
local DK_REC_SNAPSHOT_STAT = MY_Recount_DS.DK_REC_SNAPSHOT_STAT
local DK_REC_STAT = MY_Recount_DS.DK_REC_STAT
local DK_REC_STAT_DETAIL = MY_Recount_DS.DK_REC_STAT_DETAIL
local DK_REC_STAT_SKILL = MY_Recount_DS.DK_REC_STAT_SKILL
local DK_REC_STAT_SKILL_DETAIL = MY_Recount_DS.DK_REC_STAT_SKILL_DETAIL
local DK_REC_STAT_SKILL_TARGET = MY_Recount_DS.DK_REC_STAT_SKILL_TARGET
local DK_REC_STAT_TARGET = MY_Recount_DS.DK_REC_STAT_TARGET
local DK_REC_STAT_TARGET_DETAIL = MY_Recount_DS.DK_REC_STAT_TARGET_DETAIL
local DK_REC_STAT_TARGET_SKILL = MY_Recount_DS.DK_REC_STAT_TARGET_SKILL

local DISPLAY_MODE = { -- ͳ����ʾ
	NPC    = 1, -- ֻ��ʾNPC
	PLAYER = 2, -- ֻ��ʾ���
	BOTH   = 3, -- �����ʾ
}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_Recount_UI.ini'
local STAT_TYPE = MY_Recount.STAT_TYPE
local STAT_TYPE_KEY = MY_Recount.STAT_TYPE_KEY
local STAT_TYPE_NAME = MY_Recount.STAT_TYPE_NAME
local SKILL_RESULT = MY_Recount.SKILL_RESULT
local SKILL_RESULT_NAME = MY_Recount.SKILL_RESULT_NAME
local RANK_FRAME  = {
	169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182,
	183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193
}
local FORCE_BAR_CSS = {
	{}, -- GLOBAL
	{
		[-1                  ] = { r = 255, g = 255, b = 255, a = 150 }, -- NPC
		[CONSTANT.FORCE_TYPE.JIANG_HU ] = { r = 255, g = 255, b = 255, a = 255 }, -- ����
		[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { r = 210, g = 180, b = 0  , a = 144 }, -- ����
		[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { r = 127, g = 31 , b = 223, a = 180 }, -- ��
		[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { r = 160, g = 0  , b = 0  , a = 200 }, -- ���
		[CONSTANT.FORCE_TYPE.CHUN_YANG] = { r = 56 , g = 175, b = 255, a = 144 }, -- ���� 56,175,255,232
		[CONSTANT.FORCE_TYPE.QI_XIU   ] = { r = 255, g = 127, b = 255, a = 128 }, -- ����
		[CONSTANT.FORCE_TYPE.WU_DU    ] = { r = 63 , g = 31 , b = 159, a = 128 }, -- �嶾
		[CONSTANT.FORCE_TYPE.TANG_MEN ] = { r = 0  , g = 133, b = 144, a = 180 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_JIAN] = { r = 255, g = 255, b = 0  , a = 144 }, -- �ؽ�
		[CONSTANT.FORCE_TYPE.GAI_BANG ] = { r = 205, g = 133, b = 63 , a = 180 }, -- ؤ��
		[CONSTANT.FORCE_TYPE.MING_JIAO] = { r = 253, g = 84 , b = 0  , a = 144 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_YUN ] = { r = 180, g = 60 , b = 0  , a = 255 }, -- ����
		[CONSTANT.FORCE_TYPE.CHANG_GE ] = { r = 100, g = 250, b = 180, a = 100 }, -- ����
		[CONSTANT.FORCE_TYPE.BA_DAO   ] = { r = 71 , g = 73 , b = 166, a = 128 }, -- �Ե�
		[CONSTANT.FORCE_TYPE.PENG_LAI ] = { r = 195, g = 171, b = 227, a = 250 }, -- ����
	},
	{
		[-1                  ] = { r = 255, g = 255, b = 255, a = 150 }, -- NPC
		[CONSTANT.FORCE_TYPE.JIANG_HU ] = { r = 255, g = 255, b = 255, a = 255 }, -- ����
		[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { r = 210, g = 180, b = 0  , a = 144 }, -- ����
		[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { r = 100, g = 0  , b = 150, a = 96  }, -- ��
		[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { r = 0  , g = 128, b = 0  , a = 255 }, -- ���
		[CONSTANT.FORCE_TYPE.CHUN_YANG] = { r = 0  , g = 175, b = 230, a = 112 }, -- ����
		[CONSTANT.FORCE_TYPE.QI_XIU   ] = { r = 240, g = 80 , b = 240, a = 96  }, -- ����
		[CONSTANT.FORCE_TYPE.WU_DU    ] = { r = 0  , g = 128, b = 255, a = 144 }, -- �嶾
		[CONSTANT.FORCE_TYPE.TANG_MEN ] = { r = 121, g = 183, b = 54 , a = 144 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_JIAN] = { r = 215, g = 241, b = 74 , a = 144 }, -- �ؽ�
		[CONSTANT.FORCE_TYPE.GAI_BANG ] = { r = 205, g = 133, b = 63 , a = 180 }, -- ؤ��
		[CONSTANT.FORCE_TYPE.MING_JIAO] = { r = 240, g = 70 , b = 96 , a = 180 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_YUN ] = { r = 180, g = 60 , b = 0  , a = 255 }, -- ����
		[CONSTANT.FORCE_TYPE.CHANG_GE ] = { r = 100, g = 250, b = 180, a = 150 }, -- ����
		[CONSTANT.FORCE_TYPE.BA_DAO   ] = { r = 71 , g = 73 , b = 166, a = 128 }, -- �Ե�
		[CONSTANT.FORCE_TYPE.PENG_LAI ] = { r = 195, g = 171, b = 227, a = 250 }, -- ����
	},
	{
		[-1                  ] = { image = 'ui/Image/Common/Money.UITex', frame = 215 }, -- NPC
		[CONSTANT.FORCE_TYPE.JIANG_HU ] = { image = 'ui/Image/Common/Money.UITex', frame = 210 }, -- ����
		[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { image = 'ui/Image/Common/Money.UITex', frame = 203 }, -- ����
		[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { image = 'ui/Image/Common/Money.UITex', frame = 205 }, -- ��
		[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { image = 'ui/Image/Common/Money.UITex', frame = 206 }, -- ���
		[CONSTANT.FORCE_TYPE.CHUN_YANG] = { image = 'ui/Image/Common/Money.UITex', frame = 209 }, -- ����
		[CONSTANT.FORCE_TYPE.QI_XIU   ] = { image = 'ui/Image/Common/Money.UITex', frame = 204 }, -- ����
		[CONSTANT.FORCE_TYPE.WU_DU    ] = { image = 'ui/Image/Common/Money.UITex', frame = 208 }, -- �嶾
		[CONSTANT.FORCE_TYPE.TANG_MEN ] = { image = 'ui/Image/Common/Money.UITex', frame = 207 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_JIAN] = { image = 'ui/Image/Common/Money.UITex', frame = 168 }, -- �ؽ�
		[CONSTANT.FORCE_TYPE.GAI_BANG ] = { image = 'ui/Image/Common/Money.UITex', frame = 234 }, -- ؤ��
		[CONSTANT.FORCE_TYPE.MING_JIAO] = { image = 'ui/Image/Common/Money.UITex', frame = 232 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_YUN ] = { image = 'ui/Image/Common/Money.UITex', frame = 26  }, -- ����
		[CONSTANT.FORCE_TYPE.CHANG_GE ] = { image = 'ui/Image/Common/Money.UITex', frame = 30  }, -- ����
		[CONSTANT.FORCE_TYPE.BA_DAO   ] = { image = 'ui/Image/Common/Money.UITex', frame = 35  }, -- �Ե�
		[CONSTANT.FORCE_TYPE.PENG_LAI ] = { image = 'ui/Image/Common/Money.UITex', frame = 42  }, -- ����
	},
	{
		[-1                  ] = { image = 'ui/Image/Common/Money.UITex', frame = 220 }, -- NPC
		[CONSTANT.FORCE_TYPE.JIANG_HU ] = { image = 'ui/Image/Common/Money.UITex', frame = 220 }, -- ����
		[CONSTANT.FORCE_TYPE.SHAO_LIN ] = { image = 'ui/Image/Common/Money.UITex', frame = 216 }, -- ����
		[CONSTANT.FORCE_TYPE.WAN_HUA  ] = { image = 'ui/Image/Common/Money.UITex', frame = 212 }, -- ��
		[CONSTANT.FORCE_TYPE.TIAN_CE  ] = { image = 'ui/Image/Common/Money.UITex', frame = 215 }, -- ���
		[CONSTANT.FORCE_TYPE.CHUN_YANG] = { image = 'ui/Image/Common/Money.UITex', frame = 218 }, -- ����
		[CONSTANT.FORCE_TYPE.QI_XIU   ] = { image = 'ui/Image/Common/Money.UITex', frame = 211 }, -- ����
		[CONSTANT.FORCE_TYPE.WU_DU    ] = { image = 'ui/Image/Common/Money.UITex', frame = 213 }, -- �嶾
		[CONSTANT.FORCE_TYPE.TANG_MEN ] = { image = 'ui/Image/Common/Money.UITex', frame = 214 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_JIAN] = { image = 'ui/Image/Common/Money.UITex', frame = 217 }, -- �ؽ�
		[CONSTANT.FORCE_TYPE.GAI_BANG ] = { image = 'ui/Image/Common/Money.UITex', frame = 233 }, -- ؤ��
		[CONSTANT.FORCE_TYPE.MING_JIAO] = { image = 'ui/Image/Common/Money.UITex', frame = 228 }, -- ����
		[CONSTANT.FORCE_TYPE.CANG_YUN ] = { image = 'ui/Image/Common/Money.UITex', frame = 219 }, -- ����
		[CONSTANT.FORCE_TYPE.CHANG_GE ] = { image = 'ui/Image/Common/Money.UITex', frame = 30  }, -- ����
		[CONSTANT.FORCE_TYPE.BA_DAO   ] = { image = 'ui/Image/Common/Money.UITex', frame = 35  }, -- �Ե�
		[CONSTANT.FORCE_TYPE.PENG_LAI ] = { image = 'ui/Image/Common/Money.UITex', frame = 42  }, -- ����
	},
}

local D = {}
local O = {
	nCss             = 1,                   -- ��ǰ��ʽ��
	nChannel         = STAT_TYPE.DPS,       -- ��ǰ��ʾ��ͳ��ģʽ
	bAwayMode        = true,                -- ����DPSʱ�Ƿ��ȥ����ʱ��
	bSysTimeMode     = false,               -- ʹ�ùٷ�ս��ͳ�Ƽ�ʱ��ʽ
	bGroupSameNpc    = true,                -- �Ƿ�ϲ�ͬ��NPC����
	bGroupSameEffect = true,                -- �Ƿ�ϲ�ͬ��Ч��
	bHideAnonymous   = true,                -- ����û���ֵ�����
	bShowPerSec      = true,                -- ��ʾΪÿ�����ݣ���֮��ʾ�ܺͣ�
	bShowEffect      = true,                -- ��ʾ��Ч�˺�/����
	bShowZeroVal     = false,               -- ��ʾ��ֵ��¼
	nDisplayMode     = DISPLAY_MODE.BOTH,   -- ͳ����ʾģʽ����ʾNPC/������ݣ���Ĭ�ϻ����ʾ��
	nDrawInterval    = GLOBAL.GAME_FPS / 2, -- UI�ػ����ڣ�֡��
	bShowNodataTeammate = false,            -- ��ʾû�����ݵĶ���
}
RegisterCustomData('MY_Recount_UI.nCss')
RegisterCustomData('MY_Recount_UI.nChannel')
RegisterCustomData('MY_Recount_UI.bAwayMode')
RegisterCustomData('MY_Recount_UI.bSysTimeMode')
RegisterCustomData('MY_Recount_UI.bGroupSameNpc')
RegisterCustomData('MY_Recount_UI.bGroupSameEffect')
RegisterCustomData('MY_Recount_UI.bHideAnonymous')
RegisterCustomData('MY_Recount_UI.bShowPerSec')
RegisterCustomData('MY_Recount_UI.bShowEffect')
RegisterCustomData('MY_Recount_UI.bShowZeroVal')
RegisterCustomData('MY_Recount_UI.nDisplayMode')
RegisterCustomData('MY_Recount_UI.nDrawInterval')
RegisterCustomData('MY_Recount_UI.bShowNodataTeammate')

-- ���ݻ������������ɫ������ɫ����
do
local function CalcGlobalCss()
	local tCss = FORCE_BAR_CSS[1]
	for _, dwForceID in pairs_c(CONSTANT.FORCE_TYPE) do
		local r, g, b = LIB.GetForceColor(dwForceID, 'background')
		tCss[dwForceID] = { r = r, g = g, b = b, a = 150 }
	end
	local r, g, b = LIB.GetForceColor(-1, 'background')
	tCss[-1] = { r = r, g = g, b = b, a = 150 }
end
CalcGlobalCss()

local function onForceColorUpdate()
	CalcGlobalCss()
	FireUIEvent('MY_RECOUNT_CSS_UPDATE')
end
LIB.RegisterEvent('MY_FORCE_COLOR_UPDATE', onForceColorUpdate)
end

function D.Open()
	Wnd.OpenWindow(SZ_INI, 'MY_Recount_UI')
end

function D.Close()
	Wnd.CloseWindow('MY_Recount_UI')
end

function D.UpdateAnchor(frame)
	local an = LIB.GetStorage('FrameAnchor.MY_Recount')
		or { x = 0, y = -70, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' }
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

-- �ػ���������
function D.DrawUI(frame)
	frame:Lookup('Wnd_Title', 'Text_Title'):SetText(STAT_TYPE_NAME[MY_Recount_UI.nChannel])
	frame:Lookup('Wnd_Main', 'Handle_List'):Clear()
	frame:Lookup('Wnd_Main', 'Handle_Me').bInited = nil
	D.UpdateUI(frame)
end

-- ˢ�����ݻ���
function D.UpdateUI(frame)
	local data = MY_Recount.GetDisplayData()
	if not data then
		return
	end

	-- ��ȡͳ������
	local tInfo, szUnit
	if MY_Recount_UI.nChannel == STAT_TYPE.DPS then       -- �˺�ͳ��
		tInfo, szUnit = data[DK.DAMAGE], 'DPS'
	elseif MY_Recount_UI.nChannel == STAT_TYPE.HPS then   -- ����ͳ��
		tInfo, szUnit = data[DK.HEAL], 'HPS'
	elseif MY_Recount_UI.nChannel == STAT_TYPE.BDPS then  -- ����ͳ��
		tInfo, szUnit = data[DK.BE_DAMAGE], 'DPS'
	elseif MY_Recount_UI.nChannel == STAT_TYPE.BHPS then  -- ����ͳ��
		tInfo, szUnit = data[DK.BE_HEAL], 'HPS'
	end
	local tRecord = tInfo[DK_REC.STAT]

	-- ����ս��ʱ��
	local szTimeChannel = MY_Recount_UI.bSysTimeMode and STAT_TYPE_KEY[MY_Recount_UI.nChannel]
	local nTimeCount = MY_Recount_DS.GeneFightTime(data, szTimeChannel)
	local szTimeCount = LIB.FormatTimeCounter(nTimeCount, '%M:%ss')
	if LIB.IsInArena() then
		szTimeCount = LIB.GetFightTime('M:ss')
	end
	-- �Լ��ļ�¼
	local tMyRec

	-- �������� ����Ҫ��ʾ���б�
	local nMaxValue, aResult, tResult = 0, {}, {}
	for dwID, rec in pairs(tRecord) do
		if (MY_Recount_UI.bShowZeroVal or rec[MY_Recount_UI.bShowEffect and DK_REC_STAT.TOTAL_EFFECT or DK_REC_STAT.TOTAL] > 0)
		and (
			MY_Recount_UI.nDisplayMode == DISPLAY_MODE.BOTH or  -- ȷ����ʾģʽ����ʾNPC/��ʾ���/ȫ����ʾ��
			(MY_Recount_UI.nDisplayMode == DISPLAY_MODE.NPC and not IsPlayer(dwID)) or
			(MY_Recount_UI.nDisplayMode == DISPLAY_MODE.PLAYER and IsPlayer(dwID))
		) then
			local id, tRec = dwID
			if not IsPlayer(dwID) then
				id = MY_Recount_UI.bGroupSameNpc and MY_Recount_DS.GetNameAusID(data, dwID) or dwID
				tRec = tResult[id]
			end
			if tRec then -- ͬ���ϲ�����
				tRec.nValue = tRec.nValue + (rec[DK_REC_STAT.TOTAL] or 0)
				tRec.nEffectValue = tRec.nEffectValue + (rec[DK_REC_STAT.TOTAL_EFFECT] or 0)
			else -- ������
				tRec = {
					id           = id                                      ,
					szName       = MY_Recount_DS.GetNameAusID(data, dwID)  ,
					dwForceID    = MY_Recount_DS.GetForceAusID(data, dwID) ,
					nValue       = rec[DK_REC_STAT.TOTAL] or 0             ,
					nEffectValue = rec[DK_REC_STAT.TOTAL_EFFECT] or 0      ,
					nTimeCount   = max( -- ����ս��ʱ�� ��ֹ����DPSʱ����0
						MY_Recount_UI.bAwayMode
							and MY_Recount_DS.GeneFightTime(data, szTimeChannel, dwID) -- ɾȥ����ʱ��
							or nTimeCount,
						1), -- ��ɾȥ����ʱ��
				}
				tResult[id] = tRec
				insert(aResult, tRec)
			end
		end
	end
	-- ȫ��û���ݵĶ���
	if LIB.IsInParty() and MY_Recount_UI.bShowNodataTeammate then
		local list = GetClientTeam().GetTeamMemberList()
		for _, dwID in ipairs(list) do
			local info = GetClientTeam().GetMemberInfo(dwID)
			if not tResult[dwID] then
				insert(aResult, {
					id             = dwID              ,
					szName         = info.szName       ,
					dwForceID      = info.dwForceID    ,
					nValue         = 0                 ,
					nEffectValue   = 0                 ,
					nTimeCount     = max(nTimeCount, 1),
				})
				tResult[dwID] = aResult
			end
		end
	end

	-- ����ƽ��ֵ�����ֵ
	for _, tRec in ipairs(aResult) do
		if MY_Recount_UI.bShowPerSec then -- ����ƽ��ֵ
			tRec.nValuePS       = tRec.nValue / tRec.nTimeCount
			tRec.nEffectValuePS = tRec.nEffectValue / tRec.nTimeCount
			nMaxValue = max(nMaxValue, tRec.nValuePS, tRec.nEffectValuePS)
		else
			nMaxValue = max(nMaxValue, tRec.nValue, tRec.nEffectValue)
		end
	end

	-- �б�����
	local szSortKey = 'nValue'
	if MY_Recount_UI.bShowEffect and MY_Recount_UI.bShowPerSec then
		szSortKey = 'nEffectValuePS'
	elseif MY_Recount_UI.bShowEffect then
		szSortKey = 'nEffectValue'
	elseif MY_Recount_UI.bShowPerSec then
		szSortKey = 'nValuePS'
	end
	sort(aResult, function(p1, p2)
		return p1[szSortKey] > p2[szSortKey]
	end)

	-- ��Ⱦ�б�
	local hList = frame:Lookup('Wnd_Main', 'Handle_List')
	for i, p in pairs(aResult) do
		-- �Լ��ļ�¼
		if p.id == UI_GetClientPlayerID() then
			tMyRec = p
			tMyRec.nRank = i
		end
		local hItem = hList:Lookup('Handle_LI_' .. p.id)
		if not hItem then
			hItem = hList:AppendItemFromIni(SZ_INI, 'Handle_Item')
			hItem.OnItemRefreshTip = D.OnItemRefreshTip
			hItem:SetName('Handle_LI_' .. p.id)
			local css = FORCE_BAR_CSS[O.nCss][p.dwForceID] or {}
			if css.image and css.frame then -- uitex, frame
				hItem:Lookup('Image_PerFore'):FromUITex(css.image, css.frame)
				hItem:Lookup('Image_PerBack'):FromUITex(css.image, css.frame)
				hItem:Lookup('Shadow_PerFore'):Hide()
				hItem:Lookup('Shadow_PerBack'):Hide()
			else -- r, g, b
				hItem:Lookup('Shadow_PerFore'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_PerBack'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Image_PerFore'):Hide()
				hItem:Lookup('Image_PerBack'):Hide()
			end
			hItem:Lookup('Image_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Image_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Shadow_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Shadow_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Text_L'):SetText(MY_Recount.GetTargetShowName(p.szName, p.dwForceID ~= -1))
			hItem.id = p.id
		end
		if hItem:GetIndex() ~= i - 1 then
			hItem:ExchangeIndex(i - 1)
		end
		-- ����
		if RANK_FRAME[i] then
			hItem:Lookup('Text_Rank'):Hide()
			hItem:Lookup('Image_Rank'):Show()
			hItem:Lookup('Image_Rank'):SetFrame(RANK_FRAME[i])
		else
			hItem:Lookup('Text_Rank'):SetText(i .. '.')
			hItem:Lookup('Text_Rank'):Show()
			hItem:Lookup('Image_Rank'):Hide()
		end
		-- ɫ�鳤��
		local fPerBack, fPerFore = 0, 0
		if nMaxValue > 0 then
			if MY_Recount_UI.bShowPerSec then
				fPerBack = p.nValuePS / nMaxValue
				fPerFore = p.nEffectValuePS / nMaxValue
			else
				fPerBack = p.nValue / nMaxValue
				fPerFore = p.nEffectValue / nMaxValue
			end
			hItem:Lookup('Image_PerBack'):SetPercentage(fPerBack)
			hItem:Lookup('Image_PerFore'):SetPercentage(fPerFore)
			hItem:Lookup('Shadow_PerBack'):SetW(fPerBack * hItem:GetW())
			hItem:Lookup('Shadow_PerFore'):SetW(fPerFore * hItem:GetW())
		end
		-- ����/���� ������ɫ
		local tAway = data[DK.AWAYTIME][p.id]
		local bAway = tAway and #tAway > 0 and not tAway[#tAway][2]
		if hItem.bAway ~= bAway then
			if bAway then
				hItem:Lookup('Text_L'):SetFontColor(192, 192, 192)
				hItem:Lookup('Text_R'):SetFontColor(192, 192, 192)
			else
				hItem:Lookup('Text_L'):SetFontColor(255, 255, 255)
				hItem:Lookup('Text_R'):SetFontColor(255, 255, 255)
			end
		end
		-- ��ֵ��ʾ
		if MY_Recount_UI.bShowEffect then
			if MY_Recount_UI.bShowPerSec then
				hItem:Lookup('Text_R'):SetText(math.floor(p.nEffectValue / p.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_R'):SetText(p.nEffectValue)
			end
		else
			if MY_Recount_UI.bShowPerSec then
				hItem:Lookup('Text_R'):SetText(math.floor(p.nValue / p.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_R'):SetText(p.nValue)
			end
		end
		hItem.data = p
	end
	hList.szUnit     = szUnit
	hList.nTimeCount = nTimeCount
	hList:FormatAllItemPos()

	-- ��Ⱦ�ײ��Լ���ͳ��
	local hItem = frame:Lookup('Wnd_Main', 'Handle_Me')
	-- ��ʼ����ɫ
	if not hItem.bInited then
		hItem.OnItemRefreshTip = D.OnItemRefreshTip
		local dwForceID = (LIB.GetClientInfo() or {}).dwForceID
		if dwForceID then
			local css = FORCE_BAR_CSS[O.nCss][dwForceID] or {}
			if css.image and css.frame then -- uitex, frame
				hItem:Lookup('Image_Me_PerFore'):FromUITex(css.image, css.frame)
				hItem:Lookup('Image_Me_PerBack'):FromUITex(css.image, css.frame)
				hItem:Lookup('Shadow_Me_PerFore'):Hide()
				hItem:Lookup('Shadow_Me_PerBack'):Hide()
				hItem:Lookup('Image_Me_PerFore'):Show()
				hItem:Lookup('Image_Me_PerBack'):Show()
			else -- r, g, b
				hItem:Lookup('Shadow_Me_PerFore'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_Me_PerBack'):SetColorRGB(css.r or 0, css.g or 0, css.b or 0)
				hItem:Lookup('Shadow_Me_PerFore'):Show()
				hItem:Lookup('Shadow_Me_PerBack'):Show()
				hItem:Lookup('Image_Me_PerFore'):Hide()
				hItem:Lookup('Image_Me_PerBack'):Hide()
			end
			hItem:Lookup('Image_Me_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Image_Me_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem:Lookup('Shadow_Me_PerFore'):SetAlpha(css.a or 255)
			hItem:Lookup('Shadow_Me_PerBack'):SetAlpha((css.a or 255) / 255 * 100)
			hItem.bInited = true
		end
	end
	if tMyRec then
		local fPerBack, fPerFore = 0, 0
		if nMaxValue > 0 then
			if MY_Recount_UI.bShowPerSec then
				fPerBack = tMyRec.nValuePS / nMaxValue
				fPerFore = tMyRec.nEffectValuePS / nMaxValue
			else
				fPerBack = tMyRec.nValue / nMaxValue
				fPerFore = tMyRec.nEffectValue / nMaxValue
			end
			hItem:Lookup('Image_Me_PerBack'):SetPercentage(fPerBack)
			hItem:Lookup('Image_Me_PerFore'):SetPercentage(fPerFore)
			hItem:Lookup('Shadow_Me_PerBack'):SetW(fPerBack * hItem:GetW())
			hItem:Lookup('Shadow_Me_PerFore'):SetW(fPerFore * hItem:GetW())
		else
			hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
			hItem:Lookup('Image_Me_PerFore'):SetPercentage(1)
			hItem:Lookup('Shadow_Me_PerBack'):SetW(hItem:GetW())
			hItem:Lookup('Shadow_Me_PerFore'):SetW(hItem:GetW())
		end
		-- ���ս����ʱ
		hItem:Lookup('Text_Me_L'):SetText('[' .. tMyRec.nRank .. '] ' .. szTimeCount)
		-- �Ҳ�����
		if MY_Recount_UI.bShowEffect then
			if MY_Recount_UI.bShowPerSec then
				hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nEffectValue / tMyRec.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_Me_R'):SetText(tMyRec.nEffectValue)
			end
		else
			if MY_Recount_UI.bShowPerSec then
				hItem:Lookup('Text_Me_R'):SetText(math.floor(tMyRec.nValue / tMyRec.nTimeCount) .. ' ' .. szUnit)
			else
				hItem:Lookup('Text_Me_R'):SetText(tMyRec.nValue)
			end
		end
	else
		hItem:Lookup('Text_Me_L'):SetText(szTimeCount)
		hItem:Lookup('Text_Me_R'):SetText('')
		hItem:Lookup('Image_Me_PerBack'):SetPercentage(1)
		hItem:Lookup('Image_Me_PerFore'):SetPercentage(0)
		hItem:Lookup('Shadow_Me_PerBack'):SetW(hItem:GetW())
		hItem:Lookup('Shadow_Me_PerFore'):SetW(0)
	end
end

-- ########################################################################## --
--                                     #                 #         #          --
--                           # # # # # # # # # # #       #   #     #          --
--   # #     # # # # # # #       #     #     #         #     #     #          --
--     #     #       #           # # # # # # #         #     # # # # # # #    --
--     #     #       #                 #             # #   #       #          --
--     #     #       #         # # # # # # # # #       #           #          --
--     #     #       #                 #       #       #           #          --
--     #     #       #       # # # # # # # # # # #     #   # # # # # # # #    --
--     #     #       #                 #       #       #           #          --
--       # #     # # # # #     # # # # # # # # #       #           #          --
--                                     #               #           #          --
--                                   # #               #           #          --
-- ########################################################################## --
function D.OnFrameCreate()
	D.DrawUI(this)
	D.UpdateAnchor(this)
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_MY_MOSAICS_RESET')
	this:RegisterEvent('MY_RECOUNT_CSS_UPDATE')
	this:RegisterEvent('MY_RECOUNT_DISP_DATA_UPDATE')
	this:RegisterEvent('MY_RECOUNT_UI_CONFIG_UPDATE')
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'ON_MY_MOSAICS_RESET'
	or event == 'MY_RECOUNT_CSS_UPDATE'
	or event == 'MY_RECOUNT_DISP_DATA_UPDATE'
	or event == 'MY_RECOUNT_UI_CONFIG_UPDATE' then
		D.DrawUI(this)
	end
end

-- �����ػ�
function D.OnFrameBreathe()
	if this.nLastRedrawFrame
	and GetLogicFrameCount() - this.nLastRedrawFrame > 0
	and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount_UI.nDrawInterval then
		return
	end
	this.nLastRedrawFrame = GetLogicFrameCount()

	-- �鿴��ʷ������սʱ����Ҫˢ��UI
	if select(2, MY_Recount.GetDisplayData()) or not LIB.GetFightUUID() then
		return
	end
	D.UpdateUI(this)
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	LIB.SetStorage('FrameAnchor.MY_Recount', GetFrameAnchor(this))
end

function D.OnItemLButtonClick()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = UI_GetClientPlayerID()
		name = 'Handle_LI_' .. UI_GetClientPlayerID()
	end
	if id and name:find('Handle_LI_') == 1 then
		MY_Recount_DT_Open(id, MY_Recount_UI.nChannel)
	end
end

function D.OnItemRefreshTip()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = UI_GetClientPlayerID()
		name = 'Handle_LI_' .. UI_GetClientPlayerID()
	end
	name:gsub('Handle_LI_(.+)', function()
		if tonumber(id) then
			id = tonumber(id)
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local DataDisplay = MY_Recount.GetDisplayData()
		local szChannel = STAT_TYPE_KEY[MY_Recount_UI.nChannel]
		local tRec = MY_Recount_DS.GetMergeTargetData(DataDisplay, szChannel, id, O.bGroupSameNpc, O.bGroupSameEffect)
		if tRec then
			local szXml = GetFormatText((DataDisplay[DK.NAME_LIST][id] or id) .. '\n', 60, 255, 45, 255)
			local szColon = g_tStrings.STR_COLON
			local t = {}
			for szEffectID, p in pairs(tRec[DK_REC_STAT.SKILL]) do
				local szName = MY_Recount_DS.GetEffectNameAusID(DataDisplay, szChannel, szEffectID) or szEffectID
				insert(t, {
					szName = szName,
					rec = p,
					bAnonymous = IsEmpty(szName) or szName:sub(1, 1) == '#',
				})
			end
			sort(t, function(p1, p2)
				return p1.rec[DK_REC_STAT_SKILL.TOTAL] > p2.rec[DK_REC_STAT_SKILL.TOTAL]
			end)
			for _, p in ipairs(t) do
				if (MY_Recount_UI.bShowZeroVal or p.rec[DK_REC_STAT_SKILL.TOTAL] > 0)
				and (not MY_Recount_UI.bHideAnonymous or not p.bAnonymous) then
					szXml = szXml .. GetFormatText(p.szName .. '\n', nil, 255, 150, 0)
					szXml = szXml .. GetFormatText(_L['total: '] .. p.rec[DK_REC_STAT_SKILL.TOTAL]
						.. ' ' .. _L['effect: '] .. p.rec[DK_REC_STAT_SKILL.TOTAL_EFFECT] .. '\n')
					for _, nSkillResult in ipairs({
						SKILL_RESULT.HIT     ,
						SKILL_RESULT.INSIGHT ,
						SKILL_RESULT.CRITICAL,
						SKILL_RESULT.MISS    ,
					}) do
						local nCount = 0
						if p.rec[DK_REC_STAT_SKILL.DETAIL][nSkillResult] then
							nCount = not MY_Recount_UI.bShowZeroVal
								and p.rec[DK_REC_STAT_SKILL.DETAIL][nSkillResult][DK_REC_STAT_SKILL_DETAIL.NZ_COUNT]
								or p.rec[DK_REC_STAT_SKILL.DETAIL][nSkillResult][DK_REC_STAT_SKILL_DETAIL.COUNT]
						end
						szXml = szXml .. GetFormatText(SKILL_RESULT_NAME[nSkillResult] .. szColon, nil, 255, 202, 126)
						szXml = szXml .. GetFormatText(string.format('%2d', nCount) .. ' ')
					end
					szXml = szXml .. GetFormatText('\n')
				end
			end
			if DataDisplay[DK.AWAYTIME][id] then
				szXml = szXml .. GetFormatText(_L(
					'away count: %d, away time: %ds',
					#DataDisplay[DK.AWAYTIME][id],
					MY_Recount_DS.GeneAwayTime(DataDisplay, id, MY_Recount_UI.bSysTimeMode)
				), nil, 255, 191, 255)
			end
			OutputTip(szXml, 500, {x, y, w, h})
		end
	end)
end

function D.OnItemMouseLeave()
	HideTip()
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Right' then
		if MY_Recount_UI.nChannel == STAT_TYPE.DPS then
			MY_Recount_UI.nChannel = STAT_TYPE.HPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.HPS then
			MY_Recount_UI.nChannel = STAT_TYPE.BDPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.BDPS then
			MY_Recount_UI.nChannel = STAT_TYPE.BHPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.BHPS then
			MY_Recount_UI.nChannel = STAT_TYPE.DPS
		end
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Left' then
		if MY_Recount_UI.nChannel == STAT_TYPE.HPS then
			MY_Recount_UI.nChannel = STAT_TYPE.DPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.BDPS then
			MY_Recount_UI.nChannel = STAT_TYPE.HPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.BHPS then
			MY_Recount_UI.nChannel = STAT_TYPE.BDPS
		elseif MY_Recount_UI.nChannel == STAT_TYPE.DPS then
			MY_Recount_UI.nChannel = STAT_TYPE.BHPS
		end
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Option' then
		PopupMenu(MY_Recount.GetMenu())
	elseif name == 'Btn_History' then
		PopupMenu(MY_Recount.GetHistoryMenu())
	elseif name == 'Btn_Empty' then
		MY_Recount_DS.Flush()
		MY_Recount.SetDisplayData(0)
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Issuance' then
		PopupMenu(MY_Recount.GetPublishMenu())
	end
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		this:GetRoot():Lookup('Wnd_Main'):Hide()
		this:GetRoot():SetSize(280, 30)
		this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Hide()
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		this:GetRoot():Lookup('Wnd_Main'):Show()
		this:GetRoot():SetSize(280, 262)
		this:GetRoot():Lookup('Wnd_Title', 'Image_Bg'):Show()
	end
end

LIB.RegisterStorageInit('MY_Recount_UI', function()
	if LIB.GetStorage('BoolValues.MY_Recount_Enable') then
		D.Open()
	else
		D.Close()
	end
end)

-- Global exports
do
local settings = {
	exports = {
		{
			root = D,
			preset = 'UIEvent'
		},
		{
			fields = {
				Open = D.Open,
				Close = D.Close,
				FORCE_BAR_CSS = FORCE_BAR_CSS,
				DISPLAY_MODE = DISPLAY_MODE,
			},
		},
		{
			fields = {
				nCss = true,
				nChannel = true,
				bAwayMode = true,
				bSysTimeMode = true,
				bGroupSameNpc = true,
				bGroupSameEffect = true,
				bHideAnonymous = true,
				bShowPerSec = true,
				bShowEffect = true,
				bShowZeroVal = true,
				nDisplayMode = true,
				nDrawInterval = true,
				bShowNodataTeammate = true,
				anchor = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				nCss = true,
				nChannel = true,
				bAwayMode = true,
				bSysTimeMode = true,
				bGroupSameNpc = true,
				bGroupSameEffect = true,
				bHideAnonymous = true,
				bShowPerSec = true,
				bShowEffect = true,
				bShowZeroVal = true,
				nDisplayMode = true,
				nDrawInterval = true,
				bShowNodataTeammate = true,
				anchor = true,
			},
			triggers = {
				nCss = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bAwayMode = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bSysTimeMode = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bGroupSameNpc = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bGroupSameEffect = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bHideAnonymous = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bShowPerSec = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bShowEffect = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bShowZeroVal = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				nDisplayMode = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
				bShowNodataTeammate = function() FireUIEvent('MY_RECOUNT_UI_CONFIG_UPDATE') end,
			},
			root = O,
		},
	},
}
MY_Recount_UI = LIB.GeneGlobalNS(settings)
end