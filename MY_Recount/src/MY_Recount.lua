--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 战斗统计
-- @author   : 茗伊 @双梦镇 @追风蹑影
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

local STAT_TYPE = { -- 统计类型
	DPS  = 1, -- 输出统计
	HPS  = 2, -- 治疗统计
	BDPS = 3, -- 承伤统计
	BHPS = 4, -- 承疗统计
}
local STAT_TYPE_KEY = { -- 统计类型数组名
	[STAT_TYPE.DPS ] = 'Damage',
	[STAT_TYPE.HPS ] = 'Heal',
	[STAT_TYPE.BDPS] = 'BeDamage',
	[STAT_TYPE.BHPS] = 'BeHeal',
}
local STAT_TYPE_NAME = {
	[STAT_TYPE.DPS ] = g_tStrings.STR_DAMAGE_STATISTIC    , -- 伤害统计
	[STAT_TYPE.HPS ] = g_tStrings.STR_THERAPY_STATISTIC   , -- 治疗统计
	[STAT_TYPE.BDPS] = g_tStrings.STR_BE_DAMAGE_STATISTIC , -- 承伤统计
	[STAT_TYPE.BHPS] = g_tStrings.STR_BE_THERAPY_STATISTIC, -- 承疗统计
}
local PUBLISH_MODE = {
	EFFECT = 1, -- 只显示有效值
	TOTAL  = 2, -- 只显示总数值
	BOTH   = 3, -- 同时显示有效和总数
}
local SKILL_RESULT = {
	HIT     = 0, -- 命中
	BLOCK   = 1, -- 格挡
	SHIELD  = 2, -- 无效
	MISS    = 3, -- 偏离
	DODGE   = 4, -- 闪避
	CRITICAL= 5, -- 会心
	INSIGHT = 6, -- 识破
}
local SZ_SKILL_RESULT = {
	[SKILL_RESULT.HIT     ] = g_tStrings.STR_HIT_NAME     ,
	[SKILL_RESULT.BLOCK   ] = g_tStrings.STR_IMMUNITY_NAME,
	[SKILL_RESULT.SHIELD  ] = g_tStrings.STR_SHIELD_NAME  ,
	[SKILL_RESULT.MISS    ] = g_tStrings.STR_MSG_MISS     ,
	[SKILL_RESULT.DODGE   ] = g_tStrings.STR_MSG_DODGE    ,
	[SKILL_RESULT.CRITICAL] = g_tStrings.STR_CS_NAME      ,
	[SKILL_RESULT.INSIGHT ] = g_tStrings.STR_MSG_INSIGHT  ,
}

local D = {}
local O = {
	nPublishMode = PUBLISH_MODE.EFFECT, -- 发布模式
}
RegisterCustomData('MY_Recount.nPublishMode')

local DataDisplay

function D.GetTargetShowName(szName, bPlayer)
	szName = szName:gsub('#.*', '')
	if bPlayer and MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
		szName = MY_ChatMosaics.MosaicsString(szName)
	end
	return szName
end

-- 设置当前显示记录
-- D.SetDisplayData(number nHistory): 显示第nHistory条历史记录 当nHistory等于0时显示当前记录
-- D.SetDisplayData(table  data): 显示数据为data的历史记录
function D.SetDisplayData(data)
	if IsNumber(data) then
		data = MY_Recount_DS.Get(data)
	end
	D.bHistoryMode = data ~= MY_Recount_DS.Get(0)

	if IsTable(data) then
		DataDisplay = data
		FireUIEvent('MY_RECOUNT_DISP_DATA_UPDATE')
	end
end

-- 获取当前显示记录
function D.GetDisplayData()
	return DataDisplay, D.bHistoryMode
end

-- 获取设置菜单
function D.GetMenu()
	local t = {
		szOption = _L['fight recount'],
		{
			szOption = _L['enable'],
			bCheck = true,
			bChecked = LIB.GetStorage('BoolValues.MY_Recount_Enable'),
			fnAction = function()
				local bEnable = not LIB.GetStorage('BoolValues.MY_Recount_Enable')
				if bEnable then
					MY_Recount_UI.Open()
				else
					MY_Recount_UI.Close()
				end
				LIB.SetStorage('BoolValues.MY_Recount_Enable', bEnable)
			end,
		}, {
			szOption = _L['display as per second'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowPerSec,
			fnAction = function()
				MY_Recount_UI.bShowPerSec = not MY_Recount_UI.bShowPerSec
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['display effective value'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowEffect,
			fnAction = function()
				MY_Recount_UI.bShowEffect = not MY_Recount_UI.bShowEffect
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['uncount awaytime'],
			bCheck = true,
			bChecked = MY_Recount_UI.bAwayMode,
			fnAction = function()
				MY_Recount_UI.bAwayMode = not MY_Recount_UI.bAwayMode
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['show nodata teammate'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowNodataTeammate,
			fnAction = function()
				MY_Recount_UI.bShowNodataTeammate = not MY_Recount_UI.bShowNodataTeammate
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['use system time count'],
			bCheck = true,
			bChecked = MY_Recount_UI.bSysTimeMode,
			fnAction = function()
				MY_Recount_UI.bSysTimeMode = not MY_Recount_UI.bSysTimeMode
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['Group npc with same name'],
			bCheck = true,
			bChecked = MY_Recount_UI.bGroupSameNpc,
			fnAction = function()
				MY_Recount_UI.bGroupSameNpc = not MY_Recount_UI.bGroupSameNpc
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['distinct effect id with same name'],
			bCheck = true,
			bChecked = MY_Recount_DS.bDistinctEffectID,
			fnAction = function()
				MY_Recount_DS.bDistinctEffectID = not MY_Recount_DS.bDistinctEffectID
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['record anonymous effect'],
			bCheck = true,
			bChecked = MY_Recount_DS.bRecAnonymous,
			fnAction = function()
				MY_Recount_DS.bRecAnonymous = not MY_Recount_DS.bRecAnonymous
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['show zero value effect'],
			bCheck = true,
			bChecked = MY_Recount_UI.bShowZeroVal,
			fnAction = function()
				MY_Recount_UI.bShowZeroVal = not MY_Recount_UI.bShowZeroVal
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}, {
			szOption = _L['Record everything'],
			bCheck = true,
			bChecked = MY_Recount_DS.bRecEverything,
			fnAction = function()
				MY_Recount_DS.bRecEverything = not MY_Recount_DS.bRecEverything
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		},
		{   -- 切换统计类型
			szOption = _L['switch recount mode'],
			{
				szOption = _L['display only npc record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.NPC,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.NPC
				end,
			}, {
				szOption = _L['display only player record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.PLAYER,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.PLAYER
				end,
			}, {
				szOption = _L['display all record'],
				bCheck = true, bMCheck = true,
				bChecked = MY_Recount_UI.nDisplayMode == MY_Recount_UI.DISPLAY_MODE.BOTH,
				fnAction = function()
					MY_Recount_UI.nDisplayMode = MY_Recount_UI.DISPLAY_MODE.BOTH
				end,
			}
		}
	}

	-- 过滤短时间记录
	local t1 = {
		szOption = _L['filter short fight'],
		fnDisable = function()
			return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
		end,
	}
	for _, i in pairs({ -1, 10, 30, 60, 90, 120, 180 }) do
		local szOption
		if i < 0 then
			szOption = _L['no time limit']
		elseif i < 60 then
			szOption = _L('less than %d second', i)
		elseif i == 90 then
			szOption = _L('less than %d minute and a half', i / 60)
		else
			szOption = _L('less than %d minute', i / 60)
		end
		insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_DS.nMinFightTime == i,
			fnAction = function()
				MY_Recount_DS.nMinFightTime = i
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		})
	end
	insert(t, t1)

	-- 风格选择
	local t1 = {
		szOption = _L['theme'],
		fnDisable = function()
			return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
		end,
	}
	for i, _ in ipairs(MY_Recount_UI.FORCE_BAR_CSS) do
		local t2 = {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_UI.nCss == i,
			fnAction = function()
				MY_Recount_UI.nCss = i
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		}
		if i == 1 then
			t2.szOption = _L['Global Color']
			t2.szIcon = 'ui/Image/UICommon/CommonPanel2.UITex'
			t2.nFrame = 105
			t2.nMouseOverFrame = 106
			t2.szLayer = 'ICON_RIGHT'
			t2.fnClickIcon = function()
				LIB.ShowPanel()
				LIB.FocusPanel()
				LIB.SwitchTab('GlobalColor')
			end
		end
		insert(t1, t2)
	end
	insert(t, t1)

	-- 数值刷新周期
	local t1 = {
		szOption = _L['redraw interval'],
		fnDisable = function()
			return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
		end,
	}
	for _, i in ipairs({1, GLOBAL.GAME_FPS / 2, GLOBAL.GAME_FPS, GLOBAL.GAME_FPS * 2}) do
		local szOption
		if i == 1 then
			szOption = _L['realtime refresh']
		else
			szOption = _L('every %.1f second', i / GLOBAL.GAME_FPS)
		end
		insert(t1, {
			szOption = szOption,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_UI.nDrawInterval == i,
			fnAction = function()
				MY_Recount_UI.nDrawInterval = i
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		})
	end
	insert(t, t1)

	-- 最大历史记录
	local t1 = {
		szOption = _L['max history'],
		fnDisable = function()
			return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
		end,
	}
	for i = 1, 20 do
		insert(t1, {
			szOption = i,
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount_DS.nMaxHistory == i,
			fnAction = function()
				MY_Recount_DS.nMaxHistory = i
			end,
			fnDisable = function()
				return not LIB.GetStorage('BoolValues.MY_Recount_Enable')
			end,
		})
	end
	insert(t, t1)

	return t
end

-- 获取历史记录菜单
function D.GetHistoryMenu()
	local t = {{
		szOption = _L['current fight'],
		rgb = (MY_Recount_DS.Get(0) == DataDisplay and {255, 255, 0}) or nil,
		fnAction = function()
			if IsCtrlKeyDown() then
				MY_Recount_FP_Open(MY_Recount_DS.Get(0))
			else
				D.SetDisplayData(0)
			end
		end,
	}}

	for _, data in ipairs(MY_Recount_DS.Get()) do
		if data.UUID and data.nTimeDuring then
			local t1 = {
				szOption = (data.szBossName or ''):gsub('#.*', '') .. ' (' .. LIB.FormatTimeCounter(data.nTimeDuring, '%M:%ss') .. ')',
				rgb = (data == DataDisplay and {255, 255, 0}) or nil,
				fnAction = function()
					if IsCtrlKeyDown() then
						MY_Recount_FP_Open(data)
					else
						D.SetDisplayData(data)
					end
				end,
				szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
				nFrame = 49,
				nMouseOverFrame = 51,
				nIconWidth = 17,
				nIconHeight = 17,
				szLayer = 'ICON_RIGHTMOST',
				fnClickIcon = function()
					MY_Recount_DS.Del(data)
					Wnd.CloseWindow('PopupMenuPanel')
				end,
			}
			insert(t, t1)
		end
	end

	insert(t, { bDevide = true })
	insert(t, {
		szOption = _L['auto save data while exit game'],
		bCheck = true, bChecked = MY_Recount_DS.bSaveHistory,
		fnAction = function()
			MY_Recount_DS.bSaveHistory = not MY_Recount_DS.bSaveHistory
		end,
	})

	return t
end

-- 获取发布菜单
function D.GetPublishMenu()
	local t = {}

	-- 发布类型
	insert(t, {
		szOption = _L['publish mode'],
		{
			szOption = _L['only effect value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.EFFECT
			end,
		}, {
			szOption = _L['only total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.TOTAL
			end,
		}, {
			szOption = _L['effect and total value'],
			bCheck = true, bMCheck = true,
			bChecked = MY_Recount.nPublishMode == PUBLISH_MODE.BOTH,
			fnAction = function()
				MY_Recount.nPublishMode = PUBLISH_MODE.BOTH
			end,
		}
	})

	local function Publish(nChannel, nLimit)
		local frame = Station.Lookup('Normal/MY_Recount')
		if not frame then
			return
		end
		LIB.Talk(
			nChannel,
			'[' .. PACKET_INFO.SHORT_NAME .. ']'
			.. _L['fight recount'] .. ' - '
			.. frame:Lookup('Wnd_Title', 'Text_Title'):GetText()
			.. ' ' .. ((DataDisplay.szBossName and ' - ' .. DataDisplay.szBossName) or '')
			.. '(' .. LIB.FormatTimeCounter(DataDisplay.nTimeDuring, '%M:%ss') .. ')',
			nil,
			true
		)
		LIB.Talk(nChannel, '------------------------')
		local hList      = frame:Lookup('Wnd_Main', 'Handle_List')
		local szUnit     = (' ' .. hList.szUnit) or ''
		local nTimeCount = hList.nTimeCount or 0
		local aResult = {} -- 收集数据
		local nMaxNameLen = 0
		for i = 0, min(hList:GetItemCount(), nLimit) - 1 do
			local hItem = hList:Lookup(i)
			insert(aResult, hItem.data)
			nMaxNameLen = math.max(nMaxNameLen, wstring.len(hItem.data.szName))
		end
		if not MY_Recount_UI.bShowPerSec then
			nTimeCount = 1
			szUnit = ''
		end
		-- 发布数据
		for i, p in ipairs(aResult) do
			local szText = string.format('%02d', i) .. '.[' .. p.szName .. ']'
			for i = wstring.len(p.szName), nMaxNameLen - 1 do
				szText = szText .. g_tStrings.STR_ONE_CHINESE_SPACE
			end
			if MY_Recount.nPublishMode == PUBLISH_MODE.BOTH then
				szText = szText .. _L('%7d%s(Effect) %7d%s(Total)',
					p.nEffectValue / nTimeCount, szUnit,
					p.nValue / nTimeCount, szUnit
				)
			elseif MY_Recount.nPublishMode == PUBLISH_MODE.EFFECT then
				szText = szText .. _L('%7d%s(Effect)',
					p.nEffectValue / nTimeCount, szUnit
				)
			elseif MY_Recount.nPublishMode == PUBLISH_MODE.TOTAL then
				szText = szText .. _L('%7d%s(Total)',
					p.nValue / nTimeCount, szUnit
				)
			end

			LIB.Talk(nChannel, szText, nil, p.id == p.szName)
		end

		LIB.Talk(nChannel, '------------------------')
	end
	for nChannel, szChannel in pairs({
		[PLAYER_TALK_CHANNEL.RAID] = 'MSG_TEAM',
		[PLAYER_TALK_CHANNEL.TEAM] = 'MSG_PARTY',
		[PLAYER_TALK_CHANNEL.TONG] = 'MSG_GUILD',
	}) do
		local t1 = {
			szOption = g_tStrings.tChannelName[szChannel],
			bCheck = true, -- 不设置成可选框不能点╭∩╮(︶︿︶）╭∩╮垃圾
			fnAction = function()
				Publish(nChannel, HUGE)
				Wnd.CloseWindow('PopupMenuPanel')
			end,
			rgb = GetMsgFontColor(szChannel, true),
		}
		for _, nLimit in ipairs({1, 2, 3, 4, 5, 8, 10, 15, 20, 30, 50, 100}) do
			insert(t1, {
				szOption = _L('top %d', nLimit),
				fnAction = function() Publish(nChannel, nLimit) end,
			})
		end
		insert(t, t1)
	end

	return t
end

LIB.RegisterAddonMenu('MY_RECOUNT_MENU', D.GetMenu)

-- 新的战斗数据时
LIB.RegisterEvent('MY_RECOUNT_NEW_FIGHT', function()
	if not D.bHistoryMode then
		D.SetDisplayData(0)
	end
end)

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				SetDisplayData = D.SetDisplayData,
				GetDisplayData = D.GetDisplayData,
				GetMenu = D.GetMenu,
				GetHistoryMenu = D.GetHistoryMenu,
				GetPublishMenu = D.GetPublishMenu,
				GetTargetShowName = D.GetTargetShowName,
				STAT_TYPE = STAT_TYPE,
				STAT_TYPE_KEY = STAT_TYPE_KEY,
				STAT_TYPE_NAME = STAT_TYPE_NAME,
				PUBLISH_MODE = PUBLISH_MODE,
				SKILL_RESULT = SKILL_RESULT,
				SKILL_RESULT_NAME = SZ_SKILL_RESULT,
			},
		},
		{
			fields = {
				nPublishMode = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				nPublishMode = true,
			},
			root = O,
		},
	},
}
MY_Recount = LIB.GeneGlobalNS(settings)
end
