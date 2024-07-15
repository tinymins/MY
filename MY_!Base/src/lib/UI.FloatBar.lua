--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 全局浮动条界面
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.FloatBar')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local MODULE_NAME = X.NSFormatString('{$NS}_FloatBar')
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/FloatBar/')
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['System'], {
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 200, y = 250, s = 'TOPLEFT', r = 'TOPLEFT' },
	},
})
local D = {}
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/FloatBar.ini'
local FLOAT_BAR_LIST = {}
local FRAME_NAME = X.NSFormatString('{$NS}_FloatBar')

function D.GetFrame()
	return Station.SearchFrame(FRAME_NAME)
end

function D.Open()
	local frame = D.GetFrame()
	if not frame then
		frame = X.UI.OpenFrame(INI_PATH, FRAME_NAME)
	end
	return frame
end

function D.Close()
	X.UI.CloseFrame(D.GetFrame())
end

function D.RegisterFloatBar(szKey, tInfo)
	for i, v in ipairs(FLOAT_BAR_LIST) do
		if v.szKey == szKey then
			table.remove(FLOAT_BAR_LIST, i)
			break
		end
	end
	if tInfo then
		table.insert(FLOAT_BAR_LIST, {
			szKey = szKey,
			nPriority = tInfo.nPriority,
			fnCreate = tInfo.fnCreate,
			fnRender = tInfo.fnRender,
		})
		table.sort(FLOAT_BAR_LIST, function(a, b)
			if not a.nPriority then
				return false
			end
			if not b.nPriority then
				return true
			end
			return a.nPriority < b.nPriority
		end)
	end
	D.RedrawAll()
end

function D.UpdateSize(frame)
	local container = frame:Lookup('WndContainer_FloatBar')
	local nPaddingW, nPaddingH = 3, 3
	local nW, nH = nPaddingW, 0
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		wnd:SetRelX(nW)
		nW = nW + wnd:GetW()
		nH = math.max(nH, wnd:GetH())
	end
	nW = nW + nPaddingW
	nH = nH + nPaddingH * 2
	for i = 0, container:GetAllContentCount() - 1 do
		local wnd = container:LookupContent(i)
		wnd:SetRelY((nH - wnd:GetH()) / 2)
	end
	container:SetSize(nW, nH)
	frame:SetSize(nW, nH)
	frame:Lookup('', 'Image_Bg'):SetSize(nW, nH)
	frame:BringToTop()
	X.UI.SetFrameAnchor(frame, O.anchor)
end

function D.RedrawAll()
	local frame = #FLOAT_BAR_LIST > 0
		and D.Open()
		or D.Close()
	if not frame then
		return
	end
	local container = frame:Lookup('WndContainer_FloatBar')
	container:Clear()
	for i, v in ipairs(FLOAT_BAR_LIST) do
		local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
		wnd:SetName('Wnd_Item_' .. i)
		X.SafeCall(v.fnCreate, wnd)
		X.SafeCall(v.fnRender, wnd)
	end
	D.UpdateSize(frame)
end

function D.UpdateFloatBar(szKey)
	local frame = #FLOAT_BAR_LIST > 0
		and D.Open()
		or D.Close()
	if not frame then
		return
	end
	local container = frame:Lookup('WndContainer_FloatBar')
	local nIndex, tInfo
	for i, v in ipairs(FLOAT_BAR_LIST) do
		if v.szKey == szKey then
			nIndex = i
			tInfo = v
		end
	end
	if not nIndex or not tInfo then
		return
	end
	local wnd = container:Lookup('Wnd_Item_' .. nIndex)
	X.SafeCall(tInfo.fnRender, wnd)
	D.UpdateSize(frame)
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	D.RedrawAll()
end

function D.OnEvent(event)
	if event == 'UI_SCALED' then
		X.UI.SetFrameAnchor(this, O.anchor)
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['FloatBar'])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		O.anchor = X.UI.GetFrameAnchor(this)
		UpdateCustomModeWindow(this, _L['FloatBar'])
	end
	this:BringToTop()
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = FRAME_NAME,
	exports = {
		{
			preset = 'UIEvent',
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

X.UI.RegisterFloatBar = D.RegisterFloatBar
X.UI.UpdateFloatBar = D.UpdateFloatBar

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
