--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKP'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_GKP', _L['General'], {
	bOn = { -- enable
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Popup Record for Distributor'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bMoneyTalk = { -- 金钱变动喊话
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Enable Money Trend'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bMoneyTalkOnlyDistributor = { -- 金钱变动喊话仅分配者
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Money trend only distributor'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAlertMessage = { -- 进入秘境提醒清空数据
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Remind Wipe Data When Enter Dungeon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bMoneySystem = { -- 记录系统金钱变动
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Track Money Trend in the System'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bDisplayEmptyRecords = { -- show 0 record
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Clause with 0 Gold as Record'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoSync = { -- 自动接收分配者的同步信息
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Automatic Reception with Record From Distributor'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bShowGoldBrick = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Show Gold Brick'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	aSubsidies = { -- 补贴方案
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Allowance Protocols'],
		}),
		xSchema = X.Schema.Collection(X.Schema.Tuple(
			X.Schema.String,
			X.Schema.OneOf(X.Schema.String, X.Schema.Number),
			X.Schema.Boolean
		)),
		xDefaultValue = {
			{ _L['Treasure Chests'], '', true},
			-- { X.GetItemNameByUIID(73214), '', true},
			{ _L['Boss'], '', true},
			{ _L['Banquet Allowance'], -1000, true},
			{ _L['Fines'], '', true},
			{ _L['Other'], '', true},
		},
	},
	aScheme = { -- 拍卖方案
		ePathType = X.PATH_TYPE.GLOBAL,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Auction Protocols'],
		}),
		xSchema = X.Schema.Collection(X.Schema.Tuple(
			X.Schema.Number,
			X.Schema.Number,
			X.Schema.Boolean
		)),
		xDefaultValue = {
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
	},
	bSyncSystem = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Sync system reception'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bNewBidding = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKP'],
		szDescription = X.MakeCaption({
			_L['Prefer use new bidding panel'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

---------------------------------------------------------------------->
-- 数据处理
----------------------------------------------------------------------<
function D.LoadConfig()
	local szPath = X.FormatPath({'config/gkp.cfg.jx3dat', X.PATH_TYPE.GLOBAL})
	local Config = X.LoadLUAData(szPath)
	if Config then
		CPath.DelFile(szPath)
		X.SafeCall(X.Set, O, 'aSubsidies', Config.Subsidies)
		X.SafeCall(X.Set, O, 'aScheme', Config.Scheme2 or O.aScheme)
	end
end

function D.OutputSystemMessage(szMsg)
	X.OutputSystemMessage(_L['MY GKP'], szMsg)
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
			return GetFormatText(math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		else
			nGold = nGold * -1
			return GetFormatText('-' .. math.floor(nGold / 10000), 41, r, g, b) .. GetFormatImage(szUitex, 27) .. GetFormatText(math.floor(nGold % 10000), 41, r, g, b) .. GetFormatImage(szUitex, 0)
		end
	else
		return GetFormatText(nGold, 41, r, g, b) .. GetFormatImage(szUitex, 0)
	end
end

-- 发放工资
function D.Bidding(nMoney)
	local team = GetClientTeam()
	if not X.IsClientPlayerTeamDistributor() then
		return X.Alert(_L['You are not the distrubutor.'])
	end
	local nGold = nMoney
	if nGold <= 0 then
		return X.Alert(_L['Auction Money <=0.'])
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
	local LeaderAddMoney = X.UI.OpenFrame('GoldTeamAddMoney')
	local fx, fy = Station.GetClientSize()
	local w2, h2 = LeaderAddMoney:GetSize()
	LeaderAddMoney:SetAbsPos((fx - w2) / 2, (fy - h2) / 2)
	LeaderAddMoney:Lookup('Edit_PriceB'):SetText(math.floor(nGold / 10000))
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
		table.insert(tTeam, { szName = info.szName, dwID = v, dwForce = info.dwForceID, bIsOnLine = info.bIsOnLine})
	end
	local dwID = X.GetClientPlayerID()
	table.sort(tTeam, function(a, b) return a.dwForce < b.dwForce end)
	for _, v in ipairs(tTeam) do
		if v.dwID ~= dwID or bSelf then
			local szIcon, nFrame = GetForceImage(v.dwForce)
			table.insert(menu, {
				szOption = v.szName,
				szLayer  = 'ICON_RIGHTMOST',
				bDisable = bDisable and not v.bIsOnLine,
				szIcon   = szIcon,
				nFrame   = nFrame,
				rgb      = { X.GetForceColor(v.dwForce) },
				fnAction = function()
					fnAction(v)
					X.UI.ClosePopupMenu()
				end
			})
		end
	end
	return menu
end

function D.GetHistoryFiles()
	local aFiles = {}
	local szPath = X.FormatPath({'userdata/gkp/', X.PATH_TYPE.ROLE}):gsub('/', '\\')
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
			table.insert(aFiles, {
				year, month, day, hour, minute, second, index,
				filename = filename:sub(1, -12),
				fullname = filename,
				fullpath = szPath .. filename,
			})
		end
	end
	local function sortFile(a, b)
		local n = math.max(#a, #b)
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
	table.sort(aFiles, sortFile)
	return aFiles
end

function D.LimitHistoryFile()
	local aFiles = D.GetHistoryFiles()
	for i = 22, #aFiles do
		local szFile = aFiles[i].fullname
		local szPath = X.FormatPath({'userdata/gkp/' .. szFile, X.PATH_TYPE.ROLE}):gsub('/', '\\')
		CPath.DelFile(szPath)
	end
end

X.RegisterInit('MY_GKP', function()
	D.LoadConfig()
end)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_GKP',
	exports = {
		{
			fields = {
				'Sysmsg',
				'GetTimeString',
				'GetMoneyCol',
				'GetFormatLink',
				'GetMoneyTipText',
				'Bidding',
				'GetTeamMemberMenu',
				'GetHistoryFiles',
				'DistributionItem',
			},
			root = D,
		},
		{
			fields = {
				'bOn',
				'bMoneyTalk',
				'bMoneyTalkOnlyDistributor',
				'bAlertMessage',
				'bMoneySystem',
				'bDisplayEmptyRecords',
				'bAutoSync',
				'bShowGoldBrick',
				'aSubsidies',
				'aScheme',
				'bSyncSystem',
				'bNewBidding',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'DistributionItem',
			},
			root = D,
		},
		{
			fields = {
				'bOn',
				'bMoneyTalk',
				'bMoneyTalkOnlyDistributor',
				'bAlertMessage',
				'bMoneySystem',
				'bDisplayEmptyRecords',
				'bAutoSync',
				'bShowGoldBrick',
				'aSubsidies',
				'aScheme',
				'bSyncSystem',
				'bNewBidding',
			},
			triggers = {
				bDisplayEmptyRecords = function()
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'AUCTION')
				end,
				bShowGoldBrick = function()
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'AUCTION')
					FireUIEvent('MY_GKP_DATA_UPDATE', '', 'PAYMENT')
				end,
			},
			root = O,
		},
	},
}
MY_GKP = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
