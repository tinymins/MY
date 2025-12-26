--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·快捷键
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Hotkey')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do local HOTKEY_CACHE = {}
-- 增加系统快捷键
-- (void) X.RegisterHotKey(string szName, string szTitle, func fnDown, func fnUp)   -- 增加系统快捷键
function X.RegisterHotKey(szName, szTitle, fnDown, fnUp)
	table.insert(HOTKEY_CACHE, { szName = szName, szTitle = szTitle, fnDown = fnDown, fnUp = fnUp })
end

-- 获取快捷键名称
-- (string) X.GetHotKeyDisplay(string szName, boolean bBracket, boolean bShort)      -- 取得快捷键名称
function X.GetHotKeyDisplay(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	local szDisplay = GetKeyShow(nKey, bShift, bCtrl, bAlt, bShort == true)
	if szDisplay ~= '' and bBracket then
		szDisplay = '(' .. szDisplay .. ')'
	end
	return szDisplay
end

-- 获取快捷键
-- (table) X.GetHotKey(string szName, true , true )       -- 取得快捷键
-- (number nKey, boolean bShift, boolean bCtrl, boolean bAlt) X.GetHotKey(string szName, true , fasle)        -- 取得快捷键
function X.GetHotKey(szName, bBracket, bShort)
	local nKey, bShift, bCtrl, bAlt = Hotkey.Get(szName)
	if nKey==0 then return nil end
	if bBracket then
		return { nKey = nKey, bShift = bShift, bCtrl = bCtrl, bAlt = bAlt }
	else
		return nKey, bShift, bCtrl, bAlt
	end
end

-- 设置快捷键/打开快捷键设置面板    -- HM里面抠出来的
-- (void) X.SetHotKey()                               -- 打开快捷键设置面板
-- (void) X.SetHotKey(string szGroup)     -- 打开快捷键设置面板并定位到 szGroup 分组（不可用）
-- (void) X.SetHotKey(string szCommand, number nKey )     -- 设置快捷键
-- (void) X.SetHotKey(string szCommand, number nIndex, number nKey [, boolean bShift [, boolean bCtrl [, boolean bAlt] ] ])       -- 设置快捷键
function X.SetHotKey(szCommand, nIndex, nKey, bShift, bCtrl, bAlt)
	if nIndex then
		if not nKey then
			nIndex, nKey = 1, nIndex
		end
		Hotkey.Set(szCommand, nIndex, nKey, bShift == true, bCtrl == true, bAlt == true)
	else
		local szGroup = szCommand or X.PACKET_INFO.NAME

		local frame = Station.Lookup('Topmost/HotkeyPanel')
		if not frame then
			frame = X.UI.OpenFrame('HotkeyPanel')
		elseif not frame:IsVisible() then
			frame:Show()
		end
		if not szGroup then return end
		-- load aKey
		local aKey, nI, bindings = nil, 0, Hotkey.GetBinding(false)
		for k, v in pairs(bindings) do
			if v.szHeader ~= '' then
				if aKey then
					break
				elseif v.szHeader == szGroup then
					aKey = {}
				else
					nI = nI + 1
				end
			end
			if aKey then
				if not v.Hotkey1 then
					v.Hotkey1 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				if not v.Hotkey2 then
					v.Hotkey2 = {nKey = 0, bShift = false, bCtrl = false, bAlt = false}
				end
				table.insert(aKey, v)
			end
		end
		if not aKey then return end
		local hP = frame:Lookup('', 'Handle_List')
		local hI = hP:Lookup(nI)
		if hI.bSel then return end
		-- update list effect
		for i = 0, hP:GetItemCount() - 1 do
			local hB = hP:Lookup(i)
			if hB.bSel then
				hB.bSel = false
				if hB.IsOver then
					hB:Lookup('Image_Sel'):SetAlpha(128)
					hB:Lookup('Image_Sel'):Show()
				else
					hB:Lookup('Image_Sel'):Hide()
				end
			end
		end
		hI.bSel = true
		hI:Lookup('Image_Sel'):SetAlpha(255)
		hI:Lookup('Image_Sel'):Show()
		-- update content keys [hI.nGroupIndex]
		local hK = frame:Lookup('', 'Handle_Hotkey')
		local szIniFile = 'UI/Config/default/HotkeyPanel.ini'
		Hotkey.SetCapture(false)
		hK:Clear()
		hK.nGroupIndex = hI.nGroupIndex
		hK:AppendItemFromIni(szIniFile, 'Text_GroupName')
		hK:Lookup(0):SetText(szGroup)
		hK:Lookup(0).bGroup = true
		for k, v in ipairs(aKey) do
			hK:AppendItemFromIni(szIniFile, 'Handle_Binding')
			local hI = hK:Lookup(k)
			hI.bBinding = true
			hI.nIndex = k
			hI.szTip = v.szTip
			hI:Lookup('Text_Name'):SetText(v.szDesc)
			for i = 1, 2, 1 do
				local hK = hI:Lookup('Handle_Key'..i)
				hK.bKey = true
				hK.nIndex = i
				local hotkey = v['Hotkey'..i]
				hotkey.bUnchangeable = v.bUnchangeable
				hK.bUnchangeable = v.bUnchangeable
				local text = hK:Lookup('Text_Key'..i)
				text:SetText(GetKeyShow(hotkey.nKey, hotkey.bShift, hotkey.bCtrl, hotkey.bAlt))
				-- update btn
				if hK.bUnchangeable then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hK.bDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bRDown then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bSel then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(55)
				elseif hK.bOver then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				elseif hotkey.bChange then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(56)
				elseif hotkey.bConflict then
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(54)
				else
					hK:Lookup('Image_Key'..hK.nIndex):SetFrame(53)
				end
			end
		end
		-- update content scroll
		hK:FormatAllItemPos()
		local wAll, hAll = hK:GetAllItemSize()
		local w, h = hK:GetSize()
		local scroll = frame:Lookup('Scroll_Key')
		local nCountStep = math.ceil((hAll - h) / 10)
		scroll:SetStepCount(nCountStep)
		scroll:SetScrollPos(0)
		if nCountStep > 0 then
			scroll:Show()
			scroll:GetParent():Lookup('Btn_Up'):Show()
			scroll:GetParent():Lookup('Btn_Down'):Show()
		else
			scroll:Hide()
			scroll:GetParent():Lookup('Btn_Up'):Hide()
			scroll:GetParent():Lookup('Btn_Down'):Hide()
		end
		-- update list scroll
		local scroll = frame:Lookup('Scroll_List')
		if scroll:GetStepCount() > 0 then
			local _, nH = hI:GetSize()
			local nStep = math.ceil((nI * nH) / 10)
			if nStep > scroll:GetStepCount() then
				nStep = scroll:GetStepCount()
			end
			scroll:SetScrollPos(nStep)
		end
	end
end

X.RegisterInit(X.NSFormatString('{$NS}#BIND_HOTKEY'), function()
	-- hotkey
	Hotkey.AddBinding(X.NSFormatString('{$NS}_Total'), _L['Toggle main panel'], X.PACKET_INFO.NAME, X.Panel.Toggle, nil)
	for _, v in ipairs(HOTKEY_CACHE) do
		Hotkey.AddBinding(v.szName, v.szTitle, '', v.fnDown, v.fnUp)
	end
	for i = 1, 5 do
		Hotkey.AddBinding(X.NSFormatString('{$NS}_HotKey_Null_')..i, _L['None-function hotkey'], '', function() end, nil)
	end
end)
if X.PACKET_INFO.DEBUG_LEVEL <= X.DEBUG_LEVEL.DEBUG then
	local aFrame = {}
	for _, v in pairs({
		'Normal',
		'Normal1',
		'Lowest2',
	}) do
		for _, k in X.pairs_c(X.CONSTANT.CHAT_PANEL_INDEX_LIST) do
			table.insert(aFrame, v .. '/ChatPanel' .. k)
			table.insert(aFrame, v .. '/ChatPanel_Normal' .. k)
		end
		table.insert(aFrame, v .. '/EditBox')
		table.insert(aFrame, v .. '/' .. X.PACKET_INFO.NAME_SPACE)
	end
	X.RegisterHotKey(X.NSFormatString('{$NS}_STAGE_CHAT'), _L['Display only chat panel'], function()
		if Station.IsVisible() then
			for _, v in ipairs(aFrame) do
				local frame = Station.Lookup(v)
				if frame then
					frame:ShowWhenUIHide()
				end
			end
			Station.Hide()
		else
			for _, v in ipairs(aFrame) do
				local frame = Station.Lookup(v)
				if frame then
					frame:HideWhenUIHide()
				end
			end
			Station.Show()
		end
	end)
end
X.RegisterHotKey(X.NSFormatString('{$NS}_STOP_CASTING'), _L['Stop cast skill'], function() X.GetClientPlayer().StopCurrentAction() end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
