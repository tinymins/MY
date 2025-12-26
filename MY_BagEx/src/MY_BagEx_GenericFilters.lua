--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 仓库背包增强（搜索/对比）
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_GenericFilters'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_GenericFilters'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_BagEx_GenericFilters', { remake = true })
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['Generic package searcher and filters'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
		szRestriction = 'MY_BagEx_GenericFilters',
	},
})
local D = {}

local l_tItemText = {}

local l_szBagFilter = ''

local l_szBankFilter = ''
local l_bCompareBank = false
local l_bBankTimeLtd = false

local l_szGuildBankFilter = ''
local l_bCompareGuild = false

local function GetItemText(item)
	if item then
		if GetItemTip then
			local szKey = item.dwTabType .. ',' .. item.dwIndex
			if not l_tItemText[szKey] then
				l_tItemText[szKey] = ''
				l_tItemText[szKey] = X.GetPureText(X.GetItemTip(item), 'LUA')
			end
			return l_tItemText[szKey]
		else
			return item.szName
		end
	else
		return ''
	end
end

local SimpleMatch = X.StringSimpleMatch
local function FilterBags(szTreePath, szFilter, bTimeLtd)
	if szFilter then
		szFilter = szFilter:gsub('[%[%]]', '')
		if szFilter == '' then
			szFilter = nil
		end
	end
	local me = X.GetClientPlayer()
	if not szFilter and not bTimeLtd then
		X.UI(szTreePath):Find('.Box'):Alpha(255)
	else
		X.UI(szTreePath):Find('.Box'):Each(function(ui)
			if this.bBag then
				return
			end
			local bMatch = true
			local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
			if szBoxType == UI_OBJECT_ITEM then
				local item = X.GetInventoryItem(X.GetClientPlayer(), dwBox, dwX)
				if item then
					if bTimeLtd and item.GetLeftExistTime() == 0 then
						bMatch = false
					end
					if szFilter and not SimpleMatch(GetItemText(item), szFilter) then
						bMatch = false
					end
				end
			end
			if bMatch then
				this:SetAlpha(255)
			else
				this:SetAlpha(50)
			end
		end)
	end
end

local function DoFilterBag(bForce)
	if IsBagInSort and IsBagInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szBagFilter then
		FilterBags('Normal/BigBagPanel', l_szBagFilter)
		if l_szBagFilter == '' then
			l_szBagFilter = nil
		end
	end
end

local function DoFilterBank(bForce)
	if IsBankInSort and IsBankInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szBankFilter or l_bBankTimeLtd then
		FilterBags('Normal/BigBankPanel', l_szBankFilter, l_bBankTimeLtd)
		if l_szBankFilter == '' then
			l_szBankFilter = nil
		end
	end
end

local function DoFilterGuildBank(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szGuildBankFilter then
		FilterBags('Normal/GuildBankPanel', l_szGuildBankFilter)
		if l_szGuildBankFilter == '' then
			l_szGuildBankFilter = nil
		end
	end
end

local function DoCompare(ui1, ui2)
	local itemlist1 = {}
	local itemlist2 = {}

	ui1:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist1[dwTabType .. ',' .. dwIndex] = true
		end
	end)
	ui2:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist2[dwTabType .. ',' .. dwIndex] = true

			if itemlist1[dwTabType .. ',' .. dwIndex] then
				e:Alpha(255)
			else
				e:Alpha(50)
			end
		end
	end)
	ui1:Find('.Box'):Each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			if itemlist2[dwTabType .. ',' .. dwIndex] then
				e:Alpha(255)
			else
				e:Alpha(50)
			end
		end
	end)
end

local function DoCompareBank(bForce)
	if l_bCompareBank then
		local frmBag = Station.Lookup('Normal/BigBagPanel')
		local frmBank = Station.Lookup('Normal/BigBankPanel')

		if frmBag and frmBank and frmBank:IsVisible() then
			X.UI('Normal/BigBagPanel/CheckBox_Totle'):Check(true):Check(false)
			DoCompare(X.UI(frmBag), X.UI(frmBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterBank(bForce)
	end
end

local function DoCompareGuildBank(bForce)
	if l_bCompareGuild then
		local frmBag = Station.Lookup('Normal/BigBagPanel')
		local frmGuildBank = Station.Lookup('Normal/GuildBankPanel')

		if frmBag and frmGuildBank and frmGuildBank:IsVisible() then
			X.UI('Normal/BigBagPanel/CheckBox_Totle'):Check(true):Check(false)
			DoCompare(X.UI(frmBag), X.UI(frmGuildBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterGuildBank(bForce)
	end
end

local function OnFrameKeyDown()
	local szKey = GetKeyName(Station.GetMessageKey())
	if IsCtrlKeyDown() and szKey == 'F' then
		local el = this:Lookup('WndEditBox_KeyWord/WndEdit_Default')
			or this:Lookup('WndContainer_Other/Wnd_Search/Edit_Search')
		if el then
			Station.SetFocusWindow(el:GetTreePath())
			return 1
		end
	end
	return 0
end

local function Hook()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		local nX, nY, nH = 60, 30, 21
		if X.UI.IS_GLASSMORPHISM then
			nX, nY, nH = 45, 7, 25
		end
		if not frame:Lookup('WndContainer_Other/Wnd_Search') then
			X.UI(frame):Append('WndEditBox', {
				name = 'WndEditBox_KeyWord',
				w = 80 + nH, h = nH, x = nX, y = nY,
				appearance = 'SEARCH_LEFT',
				text = l_szBagFilter,
				placeholder = _L['Search'],
				alignVertical = X.UI.ALIGN_VERTICAL.MIDDLE,
				onChange = function(txt)
					local nLen = txt:len()
					nLen = math.max(nLen, 8)
					nLen = math.min(nLen, 16)
					X.UI(this):Width(nLen * 10 + nH)
					l_szBagFilter = txt
					DoFilterBag()
				end,
			})
		end

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	local frame = Station.Lookup('Normal/BigBankPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true

		local nPaddingX = 277
		local img = Station.Lookup('Normal/BigBankPanel', 'Image_BagBox6')
		if img then
			nPaddingX = img:GetRelX() + img:GetW() + 5
		end

		local ui = X.UI(frame)
		local nX = nPaddingX
		local bOfficial = not not frame:Lookup('WndContainer_Other/Wnd_Search')

		if not bOfficial then
			nX = nX + ui:Append('WndCheckBox', {
				name = 'CheckBox_TimeLtd',
				x = nX, y = 56, alpha = 200,
				text = _L['Time Limited'],
				checked = l_bBankTimeLtd,
				onCheck = function(bChecked)
					if bChecked then
						X.UI('Normal/BigBankPanel/WndCheckBox_Compare'):Check(false)
					end
					l_bBankTimeLtd = bChecked
					DoFilterBank(true)
				end
			}):Width() + 3
		end

		nX = nX + ui:Append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			x = bOfficial and 560 or nX, y = bOfficial and 52 or 56,
			text = _L['Compare with bag'],
			checked = l_bCompareBank,
			onCheck = function(bChecked)
				if bChecked then
					X.UI('Normal/BigBankPanel/CheckBox_TimeLtd'):Check(false)
				end
				l_bCompareBank = bChecked
				DoCompareBank(true)
			end
		}):Width() + 3

		local nW = nX - nPaddingX
		nX = nPaddingX

		if not bOfficial then
			if not frame:Lookup('WndContainer_Other/Wnd_Search') then
				ui:Append('WndEditBox', {
					name = 'WndEditBox_KeyWord',
					x = nX + 3, y = 80, w = nW, h = 21,
					text = l_szBankFilter,
					placeholder = _L['Search'],
					onChange = function(txt)
						local nLen = txt:len()
						nLen = math.max(nLen, 15)
						nLen = math.min(nLen, 25)
						X.UI(this):Width(nLen * 10)
						l_szBankFilter = txt
						DoFilterBank(true)
					end,
				})
			end
		end

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	local frame = Station.Lookup('Normal/GuildBankPanel')
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		X.UI('Normal/GuildBankPanel'):Append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			x = X.IS_REMAKE and 20 or 60, y = 25,
			w = 100, h = 21,
			text = l_szGuildBankFilter,
			placeholder = _L['Search'],
			onChange = function(txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 25)
				X.UI(this):Width(nLen * 10)
				l_szGuildBankFilter = txt
				DoFilterGuildBank(true)
			end,
		})

		local nY = 475
		local btn = Station.Lookup('Normal/GuildBankPanel/Btn_Refresh')
		if btn then
			nY = btn:GetRelY()
		end

		X.UI('Normal/GuildBankPanel'):Append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 20, y = nY,
			text = _L['Compare with bag'],
			checked = l_bCompareGuild,
			onCheck = function(bChecked)
				l_bCompareGuild = bChecked
				DoCompareGuildBank(true)
			end
		})

		HookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown, { bHookReturn = true })
	end

	X.RegisterEvent('EXECUTE_BINDING', 'MY_BAGEX', function(e)
		local szName, bDown = arg0, arg1
		if Cursor.IsVisible()
		and szName == 'OPENORCLOSEALLBAGS' and not bDown then
			local hFrame = Station.Lookup('Normal/BigBagPanel')
			if hFrame and hFrame:IsVisible() then
				Station.SetFocusWindow(hFrame)
			end
		end
	end)

	DoFilterBank()
	DoCompareBank()
	DoFilterGuildBank()
	DoCompareGuildBank()
end

local function Unhook()
	local frame = Station.Lookup('Normal/BigBagPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		if frame:Lookup('WndEditBox_KeyWord') then
			frame:Lookup('WndEditBox_KeyWord'):Destroy()
		end
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	local frame = Station.Lookup('Normal/BigBankPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		for _, v in ipairs({
			'CheckBox_TimeLtd',
			'WndEditBox_KeyWord',
			'WndCheckBox_Compare',
		}) do
			local el = frame:Lookup(v)
			if el then
				el:Destroy()
			end
		end
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	local frame = Station.Lookup('Normal/GuildBankPanel')
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		for _, v in ipairs({
			'WndEditBox_KeyWord',
			'WndCheckBox_Compare',
		}) do
			local el = frame:Lookup(v)
			if el then
				el:Destroy()
			end
		end
		UnhookTableFunc(frame, 'OnFrameKeyDown', OnFrameKeyDown)
	end

	X.RegisterEvent('EXECUTE_BINDING', 'MY_BAGEX')
end

local function Apply(bEnable)
	if bEnable and not X.IsRestricted('MY_BagEx_GenericFilters') then
		Hook()
		X.RegisterFrameCreate('BigBagPanel', 'MY_BAGEX', Hook)
		X.RegisterFrameCreate('BigBankPanel', 'MY_BAGEX', Hook)
		X.RegisterFrameCreate('GuildBankPanel', 'MY_BAGEX', Hook)
	else
		Unhook()
		X.RegisterFrameCreate('BigBagPanel', 'MY_BAGEX', false)
		X.RegisterFrameCreate('BigBankPanel', 'MY_BAGEX', false)
		X.RegisterFrameCreate('GuildBankPanel', 'MY_BAGEX', false)
	end
end

function D.Enable(bEnable)
	O.bEnable = bEnable
	Apply(bEnable)
end

do
local function OnBagItemUpdate()
	if l_bCompareBank then
		DoCompareBank()
	elseif l_bCompareGuild then
		DoCompareGuildBank()
	else
		DoFilterBag()
		DoFilterBank()
		DoFilterGuildBank()
	end
end
X.RegisterEvent({'BAG_ITEM_UPDATE', 'GUILD_BANK_PANEL_UPDATE', 'LOADING_END'}, function()
	if not O.bEnable then
		return
	end
	X.DelayCall('MY_BagEx_GenericFilters', 100, OnBagItemUpdate)
end)
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	if not X.IsRestricted('MY_BagEx_GenericFilters') then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 200,
			text = _L['Generic package searcher and filters'],
			checked = O.bEnable,
			onCheck = function(bChecked)
				D.Enable(bChecked)
			end,
		}):AutoWidth():Width() + 5
		nX = nPaddingX
		nY = nY + nLH
	end
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_GenericFilters',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_BagEx_GenericFilters = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------
X.RegisterUserSettingsInit('MY_BAGEX', function()
	Apply(O.bEnable)
end)
X.RegisterReload('MY_BAGEX', function() Apply(false) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
