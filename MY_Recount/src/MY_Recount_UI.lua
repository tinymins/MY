--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计 主界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Recount/MY_Recount_UI'
local PLUGIN_NAME = 'MY_Recount'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Recount'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^18.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local DK = MY_Recount_DS.DK
local DK_REC = MY_Recount_DS.DK_REC
local DK_REC_STAT = MY_Recount_DS.DK_REC_STAT
local DK_REC_STAT_DETAIL = MY_Recount_DS.DK_REC_STAT_DETAIL
local DK_REC_STAT_SKILL = MY_Recount_DS.DK_REC_STAT_SKILL
local DK_REC_STAT_SKILL_DETAIL = MY_Recount_DS.DK_REC_STAT_SKILL_DETAIL
local DK_REC_STAT_SKILL_TARGET = MY_Recount_DS.DK_REC_STAT_SKILL_TARGET
local DK_REC_STAT_TARGET = MY_Recount_DS.DK_REC_STAT_TARGET
local DK_REC_STAT_TARGET_DETAIL = MY_Recount_DS.DK_REC_STAT_TARGET_DETAIL
local DK_REC_STAT_TARGET_SKILL = MY_Recount_DS.DK_REC_STAT_TARGET_SKILL

local DISPLAY_MODE = { -- 统计显示
	NPC    = 1, -- 只显示NPC
	PLAYER = 2, -- 只显示玩家
	BOTH   = 3, -- 混合显示
}
local SZ_INI = PLUGIN_ROOT .. '/ui/MY_Recount_UI.ini'
local STAT_TYPE = MY_Recount.STAT_TYPE
local STAT_TYPE_LIST = MY_Recount.STAT_TYPE_LIST
local STAT_TYPE_KEY = MY_Recount.STAT_TYPE_KEY
local STAT_TYPE_UNIT = MY_Recount.STAT_TYPE_UNIT
local STAT_TYPE_NAME = MY_Recount.STAT_TYPE_NAME
local SKILL_RESULT = MY_Recount.SKILL_RESULT
local SKILL_RESULT_NAME = MY_Recount.SKILL_RESULT_NAME
local RANK_FRAME  = {
	169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182,
	183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193
}
local FORCE_BAR_CSS = X.LoadLUAData({'config/recount/barcss.jx3dat', X.PATH_TYPE.GLOBAL}, { passphrase = false }) or {
	X.KvpToObject({
		{-1                           , { r = 255, g = 255, b = 255, a = 150 }}, -- NPC
		{X.CONSTANT.FORCE_TYPE.JIANG_HU , { r = 255, g = 255, b = 255, a = 255 }}, -- 江湖
		{X.CONSTANT.FORCE_TYPE.SHAO_LIN , { r = 210, g = 180, b = 0  , a = 144 }}, -- 少林
		{X.CONSTANT.FORCE_TYPE.WAN_HUA  , { r = 127, g = 31 , b = 223, a = 180 }}, -- 万花
		{X.CONSTANT.FORCE_TYPE.TIAN_CE  , { r = 160, g = 0  , b = 0  , a = 200 }}, -- 天策
		{X.CONSTANT.FORCE_TYPE.CHUN_YANG, { r = 56 , g = 175, b = 255, a = 144 }}, -- 纯阳 56,175,255,232
		{X.CONSTANT.FORCE_TYPE.QI_XIU   , { r = 255, g = 127, b = 255, a = 128 }}, -- 七秀
		{X.CONSTANT.FORCE_TYPE.WU_DU    , { r = 63 , g = 31 , b = 159, a = 128 }}, -- 五毒
		{X.CONSTANT.FORCE_TYPE.TANG_MEN , { r = 0  , g = 133, b = 144, a = 180 }}, -- 唐门
		{X.CONSTANT.FORCE_TYPE.CANG_JIAN, { r = 255, g = 255, b = 0  , a = 144 }}, -- 藏剑
		{X.CONSTANT.FORCE_TYPE.GAI_BANG , { r = 205, g = 133, b = 63 , a = 180 }}, -- 丐帮
		{X.CONSTANT.FORCE_TYPE.MING_JIAO, { r = 253, g = 84 , b = 0  , a = 144 }}, -- 明教
		{X.CONSTANT.FORCE_TYPE.CANG_YUN , { r = 180, g = 60 , b = 0  , a = 255 }}, -- 苍云
		{X.CONSTANT.FORCE_TYPE.CHANG_GE , { r = 100, g = 250, b = 180, a = 100 }}, -- 长歌
		{X.CONSTANT.FORCE_TYPE.BA_DAO   , { r = 71 , g = 73 , b = 166, a = 128 }}, -- 霸刀
		{X.CONSTANT.FORCE_TYPE.PENG_LAI , { r = 195, g = 171, b = 227, a = 250 }}, -- 蓬莱
	}),
	X.KvpToObject({
		{-1                           , { r = 255, g = 255, b = 255, a = 150 }}, -- NPC
		{X.CONSTANT.FORCE_TYPE.JIANG_HU , { r = 255, g = 255, b = 255, a = 255 }}, -- 江湖
		{X.CONSTANT.FORCE_TYPE.SHAO_LIN , { r = 210, g = 180, b = 0  , a = 144 }}, -- 少林
		{X.CONSTANT.FORCE_TYPE.WAN_HUA  , { r = 100, g = 0  , b = 150, a = 96  }}, -- 万花
		{X.CONSTANT.FORCE_TYPE.TIAN_CE  , { r = 0  , g = 128, b = 0  , a = 255 }}, -- 天策
		{X.CONSTANT.FORCE_TYPE.CHUN_YANG, { r = 0  , g = 175, b = 230, a = 112 }}, -- 纯阳
		{X.CONSTANT.FORCE_TYPE.QI_XIU   , { r = 240, g = 80 , b = 240, a = 96  }}, -- 七秀
		{X.CONSTANT.FORCE_TYPE.WU_DU    , { r = 0  , g = 128, b = 255, a = 144 }}, -- 五毒
		{X.CONSTANT.FORCE_TYPE.TANG_MEN , { r = 121, g = 183, b = 54 , a = 144 }}, -- 唐门
		{X.CONSTANT.FORCE_TYPE.CANG_JIAN, { r = 215, g = 241, b = 74 , a = 144 }}, -- 藏剑
		{X.CONSTANT.FORCE_TYPE.GAI_BANG , { r = 205, g = 133, b = 63 , a = 180 }}, -- 丐帮
		{X.CONSTANT.FORCE_TYPE.MING_JIAO, { r = 240, g = 70 , b = 96 , a = 180 }}, -- 明教
		{X.CONSTANT.FORCE_TYPE.CANG_YUN , { r = 180, g = 60 , b = 0  , a = 255 }}, -- 苍云
		{X.CONSTANT.FORCE_TYPE.CHANG_GE , { r = 100, g = 250, b = 180, a = 150 }}, -- 长歌
		{X.CONSTANT.FORCE_TYPE.BA_DAO   , { r = 71 , g = 73 , b = 166, a = 128 }}, -- 霸刀
		{X.CONSTANT.FORCE_TYPE.PENG_LAI , { r = 195, g = 171, b = 227, a = 250 }}, -- 蓬莱
	}),
	X.KvpToObject({
		{-1                           , { image = 'ui/Image/Common/Money.UITex', frame = 215 }}, -- NPC
		{X.CONSTANT.FORCE_TYPE.JIANG_HU , { image = 'ui/Image/Common/Money.UITex', frame = 210 }}, -- 大侠
		{X.CONSTANT.FORCE_TYPE.SHAO_LIN , { image = 'ui/Image/Common/Money.UITex', frame = 203 }}, -- 少林
		{X.CONSTANT.FORCE_TYPE.WAN_HUA  , { image = 'ui/Image/Common/Money.UITex', frame = 205 }}, -- 万花
		{X.CONSTANT.FORCE_TYPE.TIAN_CE  , { image = 'ui/Image/Common/Money.UITex', frame = 206 }}, -- 天策
		{X.CONSTANT.FORCE_TYPE.CHUN_YANG, { image = 'ui/Image/Common/Money.UITex', frame = 209 }}, -- 纯阳
		{X.CONSTANT.FORCE_TYPE.QI_XIU   , { image = 'ui/Image/Common/Money.UITex', frame = 204 }}, -- 七秀
		{X.CONSTANT.FORCE_TYPE.WU_DU    , { image = 'ui/Image/Common/Money.UITex', frame = 208 }}, -- 五毒
		{X.CONSTANT.FORCE_TYPE.TANG_MEN , { image = 'ui/Image/Common/Money.UITex', frame = 207 }}, -- 唐门
		{X.CONSTANT.FORCE_TYPE.CANG_JIAN, { image = 'ui/Image/Common/Money.UITex', frame = 168 }}, -- 藏剑
		{X.CONSTANT.FORCE_TYPE.GAI_BANG , { image = 'ui/Image/Common/Money.UITex', frame = 234 }}, -- 丐帮
		{X.CONSTANT.FORCE_TYPE.MING_JIAO, { image = 'ui/Image/Common/Money.UITex', frame = 232 }}, -- 明教
		{X.CONSTANT.FORCE_TYPE.CANG_YUN , { image = 'ui/Image/Common/Money.UITex', frame = 26  }}, -- 苍云
		{X.CONSTANT.FORCE_TYPE.CHANG_GE , { image = 'ui/Image/Common/Money.UITex', frame = 30  }}, -- 长歌
		{X.CONSTANT.FORCE_TYPE.BA_DAO   , { image = 'ui/Image/Common/Money.UITex', frame = 35  }}, -- 霸刀
		{X.CONSTANT.FORCE_TYPE.PENG_LAI , { image = 'ui/Image/Common/Money.UITex', frame = 42  }}, -- 蓬莱
	}),
	X.KvpToObject({
		{-1                           , { image = 'ui/Image/Common/Money.UITex', frame = 220 }}, -- NPC
		{X.CONSTANT.FORCE_TYPE.JIANG_HU , { image = 'ui/Image/Common/Money.UITex', frame = 220 }}, -- 大侠
		{X.CONSTANT.FORCE_TYPE.SHAO_LIN , { image = 'ui/Image/Common/Money.UITex', frame = 216 }}, -- 少林
		{X.CONSTANT.FORCE_TYPE.WAN_HUA  , { image = 'ui/Image/Common/Money.UITex', frame = 212 }}, -- 万花
		{X.CONSTANT.FORCE_TYPE.TIAN_CE  , { image = 'ui/Image/Common/Money.UITex', frame = 215 }}, -- 天策
		{X.CONSTANT.FORCE_TYPE.CHUN_YANG, { image = 'ui/Image/Common/Money.UITex', frame = 218 }}, -- 纯阳
		{X.CONSTANT.FORCE_TYPE.QI_XIU   , { image = 'ui/Image/Common/Money.UITex', frame = 211 }}, -- 七秀
		{X.CONSTANT.FORCE_TYPE.WU_DU    , { image = 'ui/Image/Common/Money.UITex', frame = 213 }}, -- 五毒
		{X.CONSTANT.FORCE_TYPE.TANG_MEN , { image = 'ui/Image/Common/Money.UITex', frame = 214 }}, -- 唐门
		{X.CONSTANT.FORCE_TYPE.CANG_JIAN, { image = 'ui/Image/Common/Money.UITex', frame = 217 }}, -- 藏剑
		{X.CONSTANT.FORCE_TYPE.GAI_BANG , { image = 'ui/Image/Common/Money.UITex', frame = 233 }}, -- 丐帮
		{X.CONSTANT.FORCE_TYPE.MING_JIAO, { image = 'ui/Image/Common/Money.UITex', frame = 228 }}, -- 明教
		{X.CONSTANT.FORCE_TYPE.CANG_YUN , { image = 'ui/Image/Common/Money.UITex', frame = 219 }}, -- 苍云
		{X.CONSTANT.FORCE_TYPE.CHANG_GE , { image = 'ui/Image/Common/Money.UITex', frame = 30  }}, -- 长歌
		{X.CONSTANT.FORCE_TYPE.BA_DAO   , { image = 'ui/Image/Common/Money.UITex', frame = 35  }}, -- 霸刀
		{X.CONSTANT.FORCE_TYPE.PENG_LAI , { image = 'ui/Image/Common/Money.UITex', frame = 42  }}, -- 蓬莱
	}),
}
table.insert(FORCE_BAR_CSS, { [-1] = { r = 255, g = 255, b = 255 } }) -- GLOBAL

local O = X.CreateUserSettingsModule('MY_Recount_UI', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 0, y = -70, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' },
	},
	nCss = { -- 当前样式表
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1,
	},
	nChannel = { -- 当前显示的统计模式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Number,
		xDefaultValue = STAT_TYPE.DPS,
	},
	bAwayMode = { -- 计算DPS时是否减去暂离时间
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSysTimeMode = { -- 使用官方战斗统计计时方式
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bGroupSameNpc = { -- 是否合并同名NPC数据
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bGroupSameEffect = { -- 是否合并同名效果
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bHideAnonymous = { -- 隐藏没名字的数据
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowPerSec = { -- 显示为每秒数据（反之显示总和）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowEffect = { -- 显示有效伤害/治疗
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowZeroVal = { -- 显示零值记录
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nDisplayMode = { -- 统计显示模式（显示NPC/玩家数据）（默认混合显示）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Number,
		xDefaultValue = DISPLAY_MODE.BOTH,
	},
	nDrawInterval = { -- UI重绘周期（帧）
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Number,
		xDefaultValue = X.ENVIRONMENT.GAME_FPS / 2,
	},
	bShowNodataTeammate = { -- 显示没有数据的队友
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Recount'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

-- 根据基础库的门派配色创建配色方案
function D.OnForceColorUpdate()
	local tCss = FORCE_BAR_CSS[1]
	for _, dwForceID in X.pairs_c(X.CONSTANT.FORCE_TYPE) do
		local r, g, b = X.GetForceColor(dwForceID, 'background')
		tCss[dwForceID] = { r = r, g = g, b = b, a = 255 }
	end
	local r, g, b = X.GetForceColor(-1, 'background')
	tCss[-1] = { r = r, g = g, b = b, a = 255 }
	FireUIEvent('MY_RECOUNT_CSS_UPDATE')
end

function D.Open()
	X.UI.OpenFrame(SZ_INI, 'MY_Recount_UI')
end

function D.Close()
	X.UI.CloseFrame('MY_Recount_UI')
end

function D.CheckOpen()
	if MY_Recount_DS.bEnable and O.bEnable then
		D.Open()
	else
		D.Close()
	end
end

function D.UpdateAnchor(frame)
	local an = O.anchor
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	frame:CorrectPos()
end

-- 重绘整个界面
function D.DrawUI(frame)
	frame:Lookup('Wnd_Title', 'Text_Title'):SetText(STAT_TYPE_NAME[MY_Recount_UI.nChannel])
	frame:Lookup('Wnd_Main', 'Handle_List'):Clear()
	frame:Lookup('Wnd_Main', 'Handle_Me').bInited = nil
	D.UpdateUI(frame)
end

-- 刷新数据绘制
function D.UpdateUI(frame)
	local data = MY_Recount.GetDisplayData()
	if not data then
		return
	end

	-- 获取统计数据
	local eDKKey = STAT_TYPE_KEY[MY_Recount_UI.nChannel]
	if not eDKKey then
		return
	end
	local tData = data[eDKKey]
	if not tData then
		return
	end
	local tRecord, szUnit = tData[DK_REC.STAT], STAT_TYPE_UNIT[MY_Recount_UI.nChannel]

	-- 计算战斗时间
	local eTimeChannel = MY_Recount_UI.bSysTimeMode and STAT_TYPE_KEY[MY_Recount_UI.nChannel]
	local nTimeCount = MY_Recount_DS.GeneFightTime(data, eTimeChannel)
	local szTimeCount = X.FormatDuration(nTimeCount, 'SYMBOL', { mode = 'fixed-except-leading', maxUnit = 'minute', keepUnit = 'minute' })
	if X.IsInArenaMap() then
		szTimeCount = X.GetFightTime('M:ss')
	end
	-- 自己的记录
	local tMyRec

	-- 整理数据 生成要显示的列表
	local nMaxValue, aResult, tResult = 0, {}, {}
	for dwID, rec in pairs(tRecord) do
		local bShowZeroVal = MY_Recount_UI.bShowZeroVal
			or MY_Recount.StatContainsImportantEffect(rec)
		if (bShowZeroVal or rec[MY_Recount_UI.bShowEffect and DK_REC_STAT.TOTAL_EFFECT or DK_REC_STAT.TOTAL] > 0)
		and (
			MY_Recount_UI.nDisplayMode == DISPLAY_MODE.BOTH or  -- 确定显示模式（显示NPC/显示玩家/全部显示）
			(MY_Recount_UI.nDisplayMode == DISPLAY_MODE.NPC and not X.IsPlayer(dwID)) or
			(MY_Recount_UI.nDisplayMode == DISPLAY_MODE.PLAYER and X.IsPlayer(dwID))
		) then
			local id, tRec = dwID
			if not X.IsPlayer(dwID) then
				id = MY_Recount_UI.bGroupSameNpc and MY_Recount_DS.GetNameAusID(data, dwID) or dwID
				tRec = tResult[id]
			end
			if tRec then -- 同名合并数据
				tRec.nValue = tRec.nValue + (rec[DK_REC_STAT.TOTAL] or 0)
				tRec.nEffectValue = tRec.nEffectValue + (rec[DK_REC_STAT.TOTAL_EFFECT] or 0)
			else -- 新数据
				tRec = {
					id           = id                                      ,
					szName       = MY_Recount_DS.GetNameAusID(data, dwID)  ,
					dwForceID    = MY_Recount_DS.GetForceAusID(data, dwID) ,
					nValue       = rec[DK_REC_STAT.TOTAL] or 0             ,
					nEffectValue = rec[DK_REC_STAT.TOTAL_EFFECT] or 0      ,
					nTimeCount   = math.max( -- 计算战斗时间 防止计算DPS时除以0
						MY_Recount_UI.bAwayMode
							and MY_Recount_DS.GeneFightTime(data, eTimeChannel, dwID) -- 删去死亡时间
							or nTimeCount,
						1), -- 不删去暂离时间
				}
				tResult[id] = tRec
				table.insert(aResult, tRec)
			end
		end
	end
	-- 全程没数据的队友
	if X.IsInParty() and MY_Recount_UI.bShowNodataTeammate then
		local list = GetClientTeam().GetTeamMemberList()
		for _, dwID in ipairs(list) do
			local info = GetClientTeam().GetMemberInfo(dwID)
			if not tResult[dwID] then
				table.insert(aResult, {
					id             = dwID              ,
					szName         = info.szName       ,
					dwForceID      = info.dwForceID    ,
					nValue         = 0                 ,
					nEffectValue   = 0                 ,
					nTimeCount     = math.max(nTimeCount, 1),
				})
				tResult[dwID] = aResult
			end
		end
	end

	-- 计算平均值、最大值
	for _, tRec in ipairs(aResult) do
		if MY_Recount_UI.bShowPerSec then -- 计算平均值
			tRec.nValuePS       = tRec.nValue / tRec.nTimeCount
			tRec.nEffectValuePS = tRec.nEffectValue / tRec.nTimeCount
			nMaxValue = math.max(nMaxValue, tRec.nValuePS, tRec.nEffectValuePS)
		else
			nMaxValue = math.max(nMaxValue, tRec.nValue, tRec.nEffectValue)
		end
	end

	-- 列表排序
	local szSortKey = 'nValue'
	if MY_Recount_UI.bShowEffect and MY_Recount_UI.bShowPerSec then
		szSortKey = 'nEffectValuePS'
	elseif MY_Recount_UI.bShowEffect then
		szSortKey = 'nEffectValue'
	elseif MY_Recount_UI.bShowPerSec then
		szSortKey = 'nValuePS'
	end
	table.sort(aResult, function(p1, p2)
		return p1[szSortKey] > p2[szSortKey]
	end)

	-- 渲染列表
	local hList = frame:Lookup('Wnd_Main', 'Handle_List')
	for i, p in pairs(aResult) do
		-- 自己的记录
		if p.id == X.GetClientPlayerID() then
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
		-- 排名
		if RANK_FRAME[i] then
			hItem:Lookup('Text_Rank'):Hide()
			hItem:Lookup('Image_Rank'):Show()
			hItem:Lookup('Image_Rank'):SetFrame(RANK_FRAME[i])
		else
			hItem:Lookup('Text_Rank'):SetText(i .. '.')
			hItem:Lookup('Text_Rank'):Show()
			hItem:Lookup('Image_Rank'):Hide()
		end
		-- 色块长度
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
		-- 死亡/离线 特殊颜色
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
		-- 数值显示
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

	-- 渲染底部自己的统计
	local hItem = frame:Lookup('Wnd_Main', 'Handle_Me')
	-- 初始化颜色
	if not hItem.bInited then
		hItem.OnItemRefreshTip = D.OnItemRefreshTip
		local dwForceID = (X.GetClientInfo() or {}).dwForceID
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
		-- 左侧战斗计时
		hItem:Lookup('Text_Me_L'):SetText('[' .. tMyRec.nRank .. '] ' .. szTimeCount)
		-- 右侧文字
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

-- 周期重绘
function D.OnFrameBreathe()
	if this.nLastRedrawFrame
	and GetLogicFrameCount() - this.nLastRedrawFrame > 0
	and GetLogicFrameCount() - this.nLastRedrawFrame < MY_Recount_UI.nDrawInterval then
		return
	end
	this.nLastRedrawFrame = GetLogicFrameCount()

	-- 查看历史、不进战时不需要刷新UI
	if select(2, MY_Recount.GetDisplayData()) or not X.GetFightUUID() then
		return
	end
	D.UpdateUI(this)
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	O.anchor = GetFrameAnchor(this)
end

function D.OnFrameDragSetPosEnd()
	this:CorrectPos()
end

function D.OnItemLButtonClick()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = X.GetClientPlayerID()
		name = 'Handle_LI_' .. X.GetClientPlayerID()
	end
	if id and name:find('Handle_LI_') == 1 then
		MY_Recount_DT_Open(id, MY_Recount_UI.nChannel)
	end
end

function D.OnItemRefreshTip()
	local id = this.id
	local name = this:GetName()
	if name == 'Handle_Me' then
		id = X.GetClientPlayerID()
		name = 'Handle_LI_' .. X.GetClientPlayerID()
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
				table.insert(t, {
					szEffectID = szEffectID,
					szName = szName,
					rec = p,
					bAnonymous = X.IsEmpty(szName) or szName:sub(1, 1) == '#',
				})
			end
			table.sort(t, function(p1, p2)
				return p1.rec[DK_REC_STAT_SKILL.TOTAL] > p2.rec[DK_REC_STAT_SKILL.TOTAL]
			end)
			for _, p in ipairs(t) do
				local bShowZeroVal = MY_Recount_UI.bShowZeroVal
					or MY_Recount.IsImportantEffect(p.szEffectID)
					or MY_Recount.IsImportantEffect(p.rec.tEffectID)
				if (bShowZeroVal or p.rec[DK_REC_STAT_SKILL.TOTAL] > 0)
				and (not MY_Recount_UI.bHideAnonymous or not p.bAnonymous) then
					szXml = szXml .. GetFormatText(p.szName, nil, 255, 150, 0)
					if IsCtrlKeyDown() then
						szXml = szXml .. GetFormatText('\t' .. p.szEffectID, nil, 255, 255, 0)
					else
						szXml = szXml .. GetFormatText('\n', nil, 255, 150, 0)
					end
					szXml = szXml .. GetFormatText(_L['Total: '] .. p.rec[DK_REC_STAT_SKILL.TOTAL]
						.. ' ' .. _L['effect: '] .. p.rec[DK_REC_STAT_SKILL.TOTAL_EFFECT] .. '\n')
					for _, nSkillResult in ipairs({
						{ SKILL_RESULT.ABSORB, SKILL_RESULT.HIT },
						SKILL_RESULT.INSIGHT ,
						SKILL_RESULT.CRITICAL,
						SKILL_RESULT.MISS    ,
					}) do
						if X.IsTable(nSkillResult) then
							for i, v in ipairs(nSkillResult) do
								if p.rec[DK_REC_STAT_SKILL.DETAIL][v] or i == #nSkillResult then
									nSkillResult = v
									break
								end
							end
						end
						local nCount = 0
						if p.rec[DK_REC_STAT_SKILL.DETAIL][nSkillResult] then
							nCount = not bShowZeroVal
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
					'Away count: %d, away time: %ds',
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
		for i, v in ipairs(STAT_TYPE_LIST) do
			if STAT_TYPE[v] == MY_Recount_UI.nChannel then
				MY_Recount_UI.nChannel = STAT_TYPE[STAT_TYPE_LIST[((i + 1) - 1) % #STAT_TYPE_LIST + 1]]
				break
			end
		end
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Left' then
		for i, v in ipairs(STAT_TYPE_LIST) do
			if STAT_TYPE[v] == MY_Recount_UI.nChannel then
				MY_Recount_UI.nChannel = STAT_TYPE[STAT_TYPE_LIST[((i - 1) + #STAT_TYPE_LIST - 1) % #STAT_TYPE_LIST + 1]]
				break
			end
		end
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Option' then
		X.UI.PopupMenu(MY_Recount.GetMenu())
	elseif name == 'Btn_History' then
		X.UI.PopupMenu(MY_Recount.GetHistoryMenu())
	elseif name == 'Btn_Empty' then
		MY_Recount_DS.Flush()
		MY_Recount.SetDisplayData('CURRENT')
		D.DrawUI(this:GetRoot())
	elseif name == 'Btn_Issuance' then
		X.UI.PopupMenu(MY_Recount.GetPublishMenu())
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

--------------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Recount_UI',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				FORCE_BAR_CSS = FORCE_BAR_CSS,
				DISPLAY_MODE = DISPLAY_MODE,
				'Open',
				'Close',
				'CheckOpen',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nCss',
				'nChannel',
				'bAwayMode',
				'bSysTimeMode',
				'bGroupSameNpc',
				'bGroupSameEffect',
				'bHideAnonymous',
				'bShowPerSec',
				'bShowEffect',
				'bShowZeroVal',
				'nDisplayMode',
				'nDrawInterval',
				'bShowNodataTeammate',
				'anchor',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nCss',
				'nChannel',
				'bAwayMode',
				'bSysTimeMode',
				'bGroupSameNpc',
				'bGroupSameEffect',
				'bHideAnonymous',
				'bShowPerSec',
				'bShowEffect',
				'bShowZeroVal',
				'nDisplayMode',
				'nDrawInterval',
				'bShowNodataTeammate',
				'anchor',
			},
			triggers = {
				bEnable = function() D.CheckOpen() end,
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
MY_Recount_UI = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_FORCE_COLOR_UPDATE', 'MY_Recount_UI', function()
	D.OnForceColorUpdate()
end)

X.RegisterUserSettingsInit('MY_Recount_UI', function()
	D.CheckOpen()
	D.OnForceColorUpdate()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
