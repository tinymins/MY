---------------------------------------------------
-- @Author: Emil Zhai (root@derzh.com)
-- @Date:   2018-04-10 09:46:03
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-04-18 17:28:51
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------

MY_Notify = {}
MY_Notify.bShowTip = true
MY_Notify.bPlaySound = true
MY_Notify.anchor = { x = -100, y = -150, s = "BOTTOMRIGHT", r = "BOTTOMRIGHT" }
RegisterCustomData('MY_Notify.bShowTip')
RegisterCustomData('MY_Notify.bPlaySound')
RegisterCustomData('MY_Notify.anchor')

local _L = MY.LoadLangPack()
local D = {}
local NOTIFY_LIST = {}
local INI_PATH = MY.GetAddonInfo().szFrameworkRoot .. "ui/MY_Notify.ini"
local ENTRY_INI_PATH = MY.GetAddonInfo().szFrameworkRoot .. "ui/MY_NotifyIcon.ini"

function MY_Notify.Create(szKey, szMsg, fnAction)
	if MY_Notify.bPlaySound then
		MY.PlaySound("Notify.ogg")
	end
	insert(NOTIFY_LIST, {
		szKey = szKey,
		szMsg = szMsg,
		bUnread = true,
		fnAction = fnAction,
	})
	D.UpdateEntry()
	D.DrawNotifies()
	D.ShowTip(szMsg)
	return szKey
end
MY.CreateNotify = MY_Notify.Create

function MY_Notify.Dismiss(szKey, bOnlyData)
	for i, v in ipairs_r(NOTIFY_LIST) do
		if v.szKey == szKey then
			remove(NOTIFY_LIST, i)
		end
	end
	if bOnlyData then
		return
	end
	D.UpdateEntry()
	D.DrawNotifies(true)
end
MY.DismissNotify = MY_Notify.Dismiss

function MY_Notify.OpenPanel()
	Wnd.OpenWindow(INI_PATH, "MY_Notify")
end

function MY_Notify.LoadConfig()
	MY_Notify.bShowEntry = MY.LoadLUAData({"config/show_notify.jx3dat", MY_DATA_PATH.GLOBAL})
	if MY_Notify.bShowEntry == nil then
		MY_Notify.bShowEntry = IsLocalFileExist(MY.GetLUADataPath({"config/realname.jx3dat", MY_DATA_PATH.ROLE}))
		MY_Notify.SaveConfig()
	end
end

function MY_Notify.SaveConfig()
	if MY_Notify.bShowEntry == nil then
		return
	end
	MY.SaveLUAData({"config/show_notify.jx3dat", MY_DATA_PATH.GLOBAL}, MY_Notify.bShowEntry)
end

function MY_Notify.ToggleEntry(bShowEntry)
	if bShowEntry == nil then
		bShowEntry = not MY_Notify.bShowEntry
	end
	MY_Notify.bShowEntry = bShowEntry
	MY_Notify.SaveConfig()
	D.UpdateEntry()
end

function D.UpdateEntry()
	local container = Station.Lookup("Normal/TopMenu/WndContainer_List")
	if not container then
		return
	end
	local nUnread = 0
	for i, v in ipairs(NOTIFY_LIST) do
		if v.bUnread then
			nUnread = nUnread + 1
		end
	end
	local wItem = container:Lookup("Wnd_MY_NotifyIcon")
	if not MY_Notify.bShowEntry or #NOTIFY_LIST == 0 then
		if wItem then
			-- container:SetW(container:GetW() - wItem:GetW())
			wItem:Destroy()
			container:FormatAllContentPos()
		end
	else
		if not wItem then
			wItem = container:AppendContentFromIni(ENTRY_INI_PATH, "Wnd_MY_NotifyIcon")
			-- container:SetW(container:GetW() + wItem:GetW())
			local h = wItem:Lookup("Wnd_MY_NotifyIcon_Inner", "")
			h:Lookup("Image_MY_NotifyIcon"):SetAlpha(230)
			h.OnItemMouseEnter = function() this:Lookup("Image_MY_NotifyIcon"):SetAlpha(255) end
			h.OnItemMouseLeave = function() this:Lookup("Image_MY_NotifyIcon"):SetAlpha(230) end
			h.OnItemLButtonDown = function() this:Lookup("Image_MY_NotifyIcon"):SetAlpha(230) end
			h.OnItemLButtonUp = function() this:Lookup("Image_MY_NotifyIcon"):SetAlpha(255) end
			h.OnItemLButtonClick = function() MY_Notify.OpenPanel() end
			container:FormatAllContentPos()
		end
		wItem:Lookup("Wnd_MY_NotifyIcon_Inner", "Handle_MY_NotifyIcon_Num"):SetVisible(nUnread > 0)
		wItem:Lookup("Wnd_MY_NotifyIcon_Inner", "Handle_MY_NotifyIcon_Num/Text_MY_NotifyIcon_Num"):SetText(nUnread)
	end
end
MY.RegisterInit("MY_Notify", D.UpdateEntry)

function D.RemoveEntry()
	local container = Station.Lookup("Normal/TopMenu/WndContainer_List")
	if not container then
		return
	end
	local wItem = container:Lookup("Wnd_MY_NotifyIcon")
	if wItem then
		wItem:Destroy()
		container:FormatAllContentPos()
	end
end
MY.RegisterReload("MY_Notify", D.RemoveEntry)

function D.DrawNotifies(bAutoClose)
	if bAutoClose and #NOTIFY_LIST == 0 then
		return Wnd.CloseWindow("MY_Notify")
	end
	local hList = Station.Lookup("Normal/MY_Notify/Window_Main/WndScroll_Notify", "Handle_Notifies")
	if not hList then
		return
	end
	hList:Clear()
	for i, notify in ipairs(NOTIFY_LIST) do
		local hItem = hList:AppendItemFromIni(INI_PATH, "Handle_Notify")
		hItem:Lookup("Handle_Notify_Msg"):AppendItemFromString(notify.szMsg)
		hItem:Lookup("Handle_Notify_Msg"):FormatAllItemPos()
		hItem:Lookup("Handle_Notify_View"):SetVisible(not not notify.fnAction)
		hItem:Lookup("Image_Notify_Unread"):SetVisible(notify.bUnread)
		hItem.notify = notify
	end
	hList:FormatAllItemPos()
end

function MY_Notify.OnFrameCreate()
	D.DrawNotifies()
	this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
end

function MY_Notify.OnItemLButtonClick()
	local name = this:GetName()
	if name == "Handle_Notify"
	or name == "Handle_Notify_View"
	or name == "Handle_Notify_Dismiss" then
		local bDismiss, notify
		if name == "Handle_Notify" then
			notify = this.notify
			bDismiss = not notify.fnAction or notify.fnAction(notify.szKey)
		elseif name == "Handle_Notify_View" then
			notify = this:GetParent().notify
			bDismiss = not notify.fnAction or notify.fnAction(notify.szKey)
		elseif name == "Handle_Notify_Dismiss" then
			notify = this:GetParent().notify
			bDismiss = true
		end
		if bDismiss then
			MY_Notify.Dismiss(notify.szKey, true)
		end
		notify.bUnread = false
		D.UpdateEntry()
		D.DrawNotifies(true)
	end
end

function MY_Notify.OnLButtonClick()
	local name = this:GetName()
	if name == "Btn_Close" then
		Wnd.CloseWindow(this:GetRoot())
	end
end

do
local l_uiFrame, l_uiTipBoard
function D.ShowTip(szMsg)
	if not MY_Notify.bShowTip then
		return
	end
	l_uiTipBoard:clear():append(szMsg)
	l_uiFrame:fadeTo(500, 255)
	local szHoverFrame = Station.GetMouseOverWindow() and Station.GetMouseOverWindow():GetRoot():GetName()
	if szHoverFrame == 'MY_NotifyTip' then
		MY.DelayCall('MY_NotifyTip_Hide', 5000)
	else
		MY.DelayCall('MY_NotifyTip_Hide', 5000, function()
			l_uiFrame:fadeOut(500)
		end)
	end
end

local function OnInit()
	if l_uiFrame then
		return
	end
	-- init tip frame
	l_uiFrame = MY.UI.CreateFrame('MY_NotifyTip', {
		level = 'Topmost', empty = true,
		w = 250, h = 150, visible = false,
		events = {{ "UI_SCALED", function() l_uiFrame:anchor(MY_Notify.anchor) end }},
	})
	:customMode(_L["MY_Notify"], function()
		MY.DelayCall('MY_NotifyTip_Hide')
		l_uiFrame:show():alpha(255)
	end, function()
		MY_Notify.anchor = l_uiFrame:anchor()
		l_uiFrame:alpha(0):hide()
	end)
	:anchor(MY_Notify.anchor)
	-- init tip panel handle and bind animation function
	l_uiTipBoard = l_uiFrame:append("WndScrollBox", {
		handlestyle = 3, x = 0, y = 0, w = 250, h = 150,
		onclick = function()
			if MY.IsInCustomUIMode() then
				return
			end
			MY_Notify.OpenPanel()
			l_uiFrame:fadeOut(500)
		end,
		onhover = function(bIn)
			if MY.IsInCustomUIMode() then
				return
			end
			if bIn then
				MY.DelayCall('MY_NotifyTip_Hide')
				l_uiFrame:fadeIn(500)
			else
				MY.DelayCall('MY_NotifyTip_Hide', function()
					l_uiFrame:fadeOut(500)
				end, 5000)
			end
		end,
	}, true)
end
MY.RegisterInit('MY_NotifyTip', OnInit)
end
