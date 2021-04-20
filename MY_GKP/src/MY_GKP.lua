--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {
	bOn                  = true,  -- enable
	bMoneyTalk           = false, -- 金钱变动喊话
	bAlertMessage        = true,  -- 进入秘境提醒清空数据
	bMoneySystem         = false, -- 记录系统金钱变动
	bDisplayEmptyRecords = true,  -- show 0 record
	bAutoSync            = true,  -- 自动接收分配者的同步信息
	bShowGoldBrick       = true,
	bShow2ndKungfuLoot   = true,  -- 显示第二心法装备推荐提示图标
	aSubsidies = { -- 补贴方案
		{ _L['Treasure Chests'], '', true},
		-- { LIB.GetItemNameByUIID(73214), '', true},
		{ _L['Boss'], '', true},
		{ _L['Banquet Allowance'], -1000, true},
		{ _L['Fines'], '', true},
		{ _L['Other'], '', true},
	},
	aScheme = { -- 拍卖方案
		{ 100, 100, true },
		{ 1000, 1000, true },
		{ 2000, 1000, true },
		{ 3000, 1000, true },
		{ 4000, 1000, true },
		{ 5000, 1000, true },
		{ 6000, 1000, true },
		{ 7000, 1000, true },
		{ 8000, 1000, true },
		{ 9000, 1000, true },
		{ 10000, 2000, true },
		{ 20000, 2000, true },
		{ 50000, 2000, true },
		{ 100000, 5000, true },
	},
	bSyncSystem = true,
	bNewBidding = true,
}
RegisterCustomData('MY_GKP.bOn')
RegisterCustomData('MY_GKP.bMoneyTalk')
RegisterCustomData('MY_GKP.bAlertMessage')
RegisterCustomData('MY_GKP.bMoneySystem')
RegisterCustomData('MY_GKP.bDisplayEmptyRecords')
RegisterCustomData('MY_GKP.bAutoSync')
RegisterCustomData('MY_GKP.bShowGoldBrick')
RegisterCustomData('MY_GKP.bShow2ndKungfuLoot')
RegisterCustomData('MY_GKP.bSyncSystem')
RegisterCustomData('MY_GKP.bNewBidding')

---------------------------------------------------------------------->
-- 数据处理
----------------------------------------------------------------------<
function D.SaveConfig()
	local Config = {
		Subsidies = O.aSubsidies,
		Scheme2 = O.aScheme,
	}
	LIB.SaveLUAData({'config/gkp.cfg', PATH_TYPE.GLOBAL}, Config)
end

function D.LoadConfig()
	local Config = LIB.LoadLUAData({'config/gkp.cfg', PATH_TYPE.GLOBAL})
	if Config then
		O.aSubsidies = Config.Subsidies
		O.aScheme = Config.Scheme2 or O.aScheme
	end
end

function D.Sysmsg(szMsg)
	LIB.Sysmsg(_L['MY GKP'], szMsg)
end

function D.GetTimeString(nTime, year)
	if year then
		return FormatTime('%H:%M:%S', nTime)
	else
		return FormatTime('%Y-%m-%d %H:%M:%S', nTime)
	end
end

function D.GetMoneyCol(Money)
	local Money = tonumber(Money)
	if Money then
		if Money < 0 then
			return 0, 128, 255
		elseif Money < 1000 then
			return 255, 255, 255
		elseif Money < 10000 then
			return 255, 255, 164
		elseif Money < 100000 then
			return 255, 255, 0
		elseif Money < 1000000 then
			return 255, 192, 0
		elseif Money < 10000000 then
			return 255, 92, 0
		else
			return 255, 0, 0
		end
	else
		return 255, 255, 255
	end
end

function D.GetFormatLink(item, bName)
	if type(item) == 'string' then
		if bName then
			return { type = 'name', name = item, text = '[' .. item ..']' }
		else
			return { type = 'text', text = item }
		end
	else
		if item.nGenre == ITEM_GENRE.BOOK then
			return { type = 'book', tabtype = item.dwTabType, index = item.dwIndex, bookinfo = item.nBookID, version = item.nVersion, text = '' }
		else
			return { type = 'iteminfo', version = item.nVersion, tabtype = item.dwTabType, index = item.dwIndex, text = '' }
		end
	end
end

function D.GetMoneyTipText(nGold)
	local szUitex = 'ui/image/common/money.UITex'
	local r, g, b = D.GetMoneyCol(nGold)
	if MY_GKP.bShowGoldBrick then
		if nGold >= 0 then
			return GetFormatText(floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		else
			nGold = nGold * -1
			return GetFormatText('-' .. floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		end
	else
		return GetFormatText(nGold, 41, r, g, b) .. GetFormatImage(szUitex, 0)
	end
end

-- 发放工资
function D.Bidding(nMoney)
	local team = GetClientTeam()
	if not LIB.IsDistributer() then
		return LIB.Alert(_L['You are not the distrubutor.'])
	end
	local nGold = nMoney
	if nGold <= 0 then
		return LIB.Alert(_L['Auction Money <=0.'])
	end
	local t, fnAction = {}, nil
	InsertDistributeMenu(t, false)
	for k, v in ipairs(t[1]) do
		if v.szOption == g_tStrings.STR_LOOTMODE_GOLD_BID_RAID then
			fnAction = v.fnAction
			break
		end
	end
	team.SetTeamLootMode(PARTY_LOOT_MODE.BIDDING)
	local LeaderAddMoney = Wnd.OpenWindow('GoldTeamAddMoney')
	local fx, fy = Station.GetClientSize()
	local w2, h2 = LeaderAddMoney:GetSize()
	LeaderAddMoney:SetAbsPos((fx - w2) / 2, (fy - h2) / 2)
	LeaderAddMoney:Lookup('Edit_PriceB'):SetText(floor(nGold / 10000))
	LeaderAddMoney:Lookup('Edit_Price'):SetText(nGold % 10000)
	LeaderAddMoney:Lookup('Edit_Reason'):SetText(_L['Auto append'])
	LeaderAddMoney:Lookup('Btn_Ok').OnLButtonUp = function()
		fnAction()
		OpenGoldTeam()
		Station.SetActiveFrame('GoldTeam')
		Station.Lookup('Normal/GoldTeam/PageSet_Total'):ActivePage(1)
	end
end

function D.GetTeamMemberMenu(fnAction, bDisable, bSelf)
	local tTeam, menu = {}, {}
	for _, v in ipairs(GetClientTeam().GetTeamMemberList()) do
		local info = GetClientTeam().GetMemberInfo(v)
		insert(tTeam, { szName = info.szName, dwID = v, dwForce = info.dwForceID, bIsOnLine = info.bIsOnLine})
	end
	local dwID = UI_GetClientPlayerID()
	sort(tTeam, function(a, b) return a.dwForce < b.dwForce end)
	for _, v in ipairs(tTeam) do
		if v.dwID ~= dwID or bSelf then
			local szIcon, nFrame = GetForceImage(v.dwForce)
			insert(menu, {
				szOption = v.szName,
				szLayer  = 'ICON_RIGHTMOST',
				bDisable = bDisable and not v.bIsOnLine,
				szIcon   = szIcon,
				nFrame   = nFrame,
				rgb      = { LIB.GetForceColor(v.dwForce) },
				fnAction = function()
					fnAction(v)
					UI.ClosePopupMenu()
				end
			})
		end
	end
	return menu
end

function D.GetHistoryFiles()
	local aFiles = {}
	local szPath = LIB.FormatPath({'userdata/gkp/', PATH_TYPE.ROLE}):gsub('/', '\\')
	for _, filename in ipairs(CPath.GetFileList(szPath)) do
		local year, month, day, hour, minute, second, index = filename:match('^(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+).-%.gkp.jx3dat')
		if not year then
			year, month, day, hour, minute, second = filename:match('^(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%d+).-%.gkp.jx3dat')
		end
		if not year then
			year, month, day = filename:match('^(%d+)%-(%d+)%-(%d+)%.gkp.jx3dat')
		end
		if year then
			if year then
				year = tonumber(year)
			end
			if month then
				month = tonumber(month)
			end
			if day then
				day = tonumber(day)
			end
			if hour then
				hour = tonumber(hour)
			end
			if minute then
				minute = tonumber(minute)
			end
			if second then
				second = tonumber(second)
			end
			if index then
				index = tonumber(index)
			end
			insert(aFiles, {
				year, month, day, hour, minute, second, index,
				filename = filename:sub(1, -12),
				fullname = filename,
				fullpath = szPath .. filename,
			})
		end
	end
	local function sortFile(a, b)
		local n = max(#a, #b)
		for i = 1, n do
			if not a[i] then
				return true
			elseif not b[i] then
				return false
			elseif a[i] ~= b[i] then
				return a[i] > b[i]
			end
		end
		return false
	end
	sort(aFiles, sortFile)
	return aFiles
end

function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = 22, #aFiles do
		local szFile = aFiles[i].fullname
		local szPath = LIB.FormatPath({'userdata/gkp/' .. szFile, PATH_TYPE.ROLE}):gsub('/', '\\')
		CPath.DelFile(szPath)
	end
end

LIB.RegisterInit('MY_GKP', function()
	D.LoadConfig()
end)

-------------------------------------------------------------------------------------------------------
-- 全局导出
-------------------------------------------------------------------------------------------------------
-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				Sysmsg = D.Sysmsg,
				GetTimeString = D.GetTimeString,
				GetMoneyCol = D.GetMoneyCol,
				GetFormatLink = D.GetFormatLink,
				GetMoneyTipText = D.GetMoneyTipText,
				Bidding = D.Bidding,
				GetTeamMemberMenu = D.GetTeamMemberMenu,
				GetHistoryFiles = D.GetHistoryFiles,
			},
		},
		{
			fields = {
				bOn = true,
				bMoneyTalk = true,
				bAlertMessage = true,
				bMoneySystem = true,
				bDisplayEmptyRecords = true,
				bAutoSync = true,
				bShowGoldBrick = true,
				bShow2ndKungfuLoot = true,
				aSubsidies = true,
				aScheme = true,
				bSyncSystem = true,
				bNewBidding = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bOn = true,
				bMoneyTalk = true,
				bAlertMessage = true,
				bMoneySystem = true,
				bDisplayEmptyRecords = true,
				bAutoSync = true,
				bShowGoldBrick = true,
				bShow2ndKungfuLoot = true,
				aSubsidies = true,
				aScheme = true,
				bSyncSystem = true,
				bNewBidding = true,
			},
			triggers = {
				bDisplayEmptyRecords = function()
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'AUCTION')
				end,
				bShowGoldBrick = function()
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'AUCTION')
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'PAYMENT')
				end,
				aSubsidies = D.SaveConfig,
				aScheme = D.SaveConfig,
			},
			root = O,
		},
	},
}
MY_GKP = LIB.GeneGlobalNS(settings)
end
