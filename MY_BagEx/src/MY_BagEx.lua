-----------------------------------------------
-- @Desc  : 仓库背包增强（搜索/对比）
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2014-11-25 10:40:14
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-01-23 11:18:00
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BagEx/lang/")

MY_BagEx = {}
MY_BagEx.bEnable = true
RegisterCustomData("MY_BagEx.bEnable")

local l_tItemText = {}

local l_szBagFilter = ""

local l_szBankFilter = ""
local l_bCompareBank = false
local l_bBankTimeLtd = false

local l_szGuildBankFilter = ""
local l_bCompareGuild = false

local function GetItemText(item)
	if item then
		if GetItemTip then
			local szKey = item.dwTabType .. ',' .. item.dwIndex
			if not l_tItemText[szKey] then
				l_tItemText[szKey] = ""
				l_tItemText[szKey] = MY.Xml.GetPureText(GetItemTip(item))
			end
			return l_tItemText[szKey]
		else
			return item.szName
		end
	else
		return ''
	end
end

local SimpleMatch = MY.String.SimpleMatch
local function FilterBags(szTreePath, szFilter, bTimeLtd)
	if szFilter then
		szFilter = szFilter:gsub('[%[%]]', '')
		if szFilter == "" then
			szFilter = nil
		end
	end
	local me = GetClientPlayer()
	if not szFilter and not bTimeLtd then
		XGUI(szTreePath):find(".Box"):alpha(255)
	else
		XGUI(szTreePath):find(".Box"):each(function(ui)
			if this.bBag then
				return
			end
			local bMatch = true
			local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
			if szBoxType == UI_OBJECT_ITEM then
				local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
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
	if bForce or l_szBagFilter or l_bBagTimeLtd then
		FilterBags("Normal/BigBagPanel", l_szBagFilter, l_bBagTimeLtd)
		if l_szBagFilter == "" then
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
		FilterBags("Normal/BigBankPanel", l_szBankFilter, l_bBankTimeLtd)
		if l_szBankFilter == "" then
			l_szBankFilter = nil
		end
	end
end

local function DoFilterGuildBank(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or l_szGuildBankFilter then
		FilterBags("Normal/GuildBankPanel", l_szGuildBankFilter)
		if l_szGuildBankFilter == "" then
			l_szGuildBankFilter = nil
		end
	end
end

local function DoCompare(ui1, ui2)
	local itemlist1 = {}
	local itemlist2 = {}
	
	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist1[dwTabType .. ',' .. dwIndex] = true
		end
	end)
	ui2:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist2[dwTabType .. ',' .. dwIndex] = true
			
			if itemlist1[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			if itemlist2[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
end

local function DoCompareBank(bForce)
	if l_bCompareBank then
		local frmBag = Station.Lookup("Normal/BigBagPanel")
		local frmBank = Station.Lookup("Normal/BigBankPanel")
		
		if frmBag and frmBank and frmBank:IsVisible() then
			MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true):check(false)
			DoCompare(MY.UI(frmBag), MY.UI(frmBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterBank(bForce)
	end
end

local function DoCompareGuildBank(bForce)
	if l_bCompareGuild then
		local frmBag = Station.Lookup("Normal/BigBagPanel")
		local frmGuildBank = Station.Lookup("Normal/GuildBankPanel")
		
		if frmBag and frmGuildBank and frmGuildBank:IsVisible() then
			MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true):check(false)
			DoCompare(MY.UI(frmBag), MY.UI(frmGuildBank))
		end
	else
		DoFilterBag(bForce)
		DoFilterGuildBank(bForce)
	end
end

local function OnFrameKeyDown()
	local szKey = GetKeyName(Station.GetMessageKey())
	if IsCtrlKeyDown() and szKey == "F" then
		Station.SetFocusWindow("Normal/BigBagPanel/WndEditBox_KeyWord/WndEdit_Default")
		return 1
	end
	return 0
end

local function Hook()
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		MY.UI(frame):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 30,
			text = l_szBagFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 20)
				XGUI(raw):width(nLen * 10)
				l_szBagFilter = txt
				DoFilterBag()
			end,
		})
		
		HookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown, false, true)
	end
	
	local frame = Station.Lookup("Normal/BigBankPanel")
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		MY.UI(frame):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 150, h = 21, x = 280, y = 80,
			text = l_szBankFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 15)
				nLen = math.min(nLen, 25)
				XGUI(raw):width(nLen * 10)
				l_szBankFilter = txt
				DoFilterBank(true)
			end,
		})
		
		MY.UI(frame):append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 340, y = 56,
			text = _L['compare with bag'],
			checked = l_bCompareBank,
			oncheck = function(bChecked)
				if bChecked then
					MY.UI("Normal/BigBankPanel/CheckBox_TimeLtd"):check(false)
				end
				l_bCompareBank = bChecked
				DoCompareBank(true)
			end
		})
		
		MY.UI(frame):append('WndCheckBox', {
			name = 'CheckBox_TimeLtd',
			w = 60, x = 277, y = 56, alpha = 200,
			text = _L['Time Limited'],
			checked = l_bBankTimeLtd,
			oncheck = function(bChecked)
				if bChecked then
					MY.UI("Normal/BigBankPanel/WndCheckBox_Compare"):check(false)
				end
				l_bBankTimeLtd = bChecked
				DoFilterBank(true)
			end
		})
		
		HookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown, false, true)
	end
	
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if frame and not frame.bMYBagExHook then
		frame.bMYBagExHook = true
		MY.UI("Normal/GuildBankPanel"):append('WndEditBox', {
			name = 'WndEditBox_KeyWord',
			w = 100, h = 21, x = 60, y = 25,
			text = l_szGuildBankFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 25)
				XGUI(raw):width(nLen * 10)
				l_szGuildBankFilter = txt
				DoFilterGuildBank(true)
			end,
		})
		
		MY.UI("Normal/GuildBankPanel"):append('WndCheckBox', {
			name = 'WndCheckBox_Compare',
			w = 100, x = 20, y = 475,
			text = _L['compare with bag'],
			checked = l_bCompareGuild,
			oncheck = function(bChecked)
				l_bCompareGuild = bChecked
				DoCompareGuildBank(true)
			end
		})
		
		HookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown, false, true)
	end
	
	MY.RegisterEvent("EXECUTE_BINDING.MY_BAGEX", function(e)
		local szName, bDown = arg0, arg1
		if Cursor.IsVisible()
		and szName == "OPENORCLOSEALLBAGS" and not bDown then
			local hFrame = Station.Lookup("Normal/BigBagPanel")
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
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup("WndEditBox_KeyWord"):Destroy()
		UnhookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown)
	end
	
	local frame = Station.Lookup("Normal/BigBankPanel")
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup("CheckBox_TimeLtd"):Destroy()
		frame:Lookup("WndEditBox_KeyWord"):Destroy()
		frame:Lookup("WndCheckBox_Compare"):Destroy()
		UnhookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown)
	end
	
	local frame = Station.Lookup("Normal/GuildBankPanel")
	if frame and frame.bMYBagExHook then
		frame.bMYBagExHook = nil
		frame:Lookup("WndEditBox_KeyWord"):Destroy()
		frame:Lookup("WndCheckBox_Compare"):Destroy()
		UnhookTableFunc(frame, "OnFrameKeyDown", OnFrameKeyDown)
	end
	
	MY.RegisterEvent("EXECUTE_BINDING.MY_BAGEX")
end

local function Apply(bEnable)
	if bEnable == nil then
		bEnable = MY_BagEx.bEnable
	end
	if bEnable then
		Hook()
		MY.RegisterEvent("ON_FRAME_CREATE.MY_BAGEX", Hook)
	else
		Unhook()
		MY.RegisterEvent("ON_FRAME_CREATE.MY_BAGEX")
	end
end

function MY_BagEx.Enable(bEnable)
	MY_BagEx.bEnable = bEnable
	Apply()
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
MY.RegisterEvent({"BAG_ITEM_UPDATE", "GUILD_BANK_PANEL_UPDATE"}, function()
	if not MY_BagEx.bEnable then
		return
	end
	MY.DelayCall('MY_BagEx', 100, OnBagItemUpdate)
end)
end

MY.RegisterInit("MY_BAGEX", function() Apply() end)
MY.RegisterReload("MY_BAGEX", function() Apply(false) end)
