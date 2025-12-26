--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 全局浮动条界面
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
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
	bDetach = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		szDescription = X.MakeCaption({
			_L['FloatBar'],
			_L['Detach mode'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		szDescription = X.MakeCaption({
			_L['FloatBar'],
			_L['Combined anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 160, y = 18, s = 'TOPLEFT', r = 'TOPLEFT' },
	},
	tAnchors = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['Global config'],
		szDescription = X.MakeCaption({
			_L['FloatBar'],
			_L['Detach mode anchor'],
		}),
		bDataSet = true,
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = -0xffff, y = -0xffff, s = 'TOPLEFT', r = 'TOPLEFT' },
	},
})
local D = {}
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/FloatBar.ini'
local FLOAT_BAR_LIST = {}
local FRAME_NAME = X.NSFormatString('{$NS}_FloatBar')
local REDRAW_FLOAT_BAR = X.NSFormatString('{$NS}_REDRAW_FLOAT_BAR')
local UPDATE_FLOAT_BAR = X.NSFormatString('{$NS}_UPDATE_FLOAT_BAR')

--------------------------------------------------------------------------------
-- 对外接口
--------------------------------------------------------------------------------
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
			tAnchor = tInfo.tAnchor,
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
	D.CreateAllFrame()
	FireUIEvent(REDRAW_FLOAT_BAR, szKey)
end

function D.UpdateFloatBar(szKey)
	FireUIEvent(UPDATE_FLOAT_BAR, szKey)
end

--------------------------------------------------------------------------------
-- 内部实现
--------------------------------------------------------------------------------
function D.CreateFrame(szKey)
	local szFrameName = FRAME_NAME
	if szKey then
		szFrameName = szFrameName .. '__' .. szKey
	end
	local frame = Station.SearchFrame(szFrameName)
	if not frame then
		frame = X.UI.OpenFrame(INI_PATH, FRAME_NAME)
		if szFrameName ~= FRAME_NAME then
			frame:SetName(szFrameName)
			frame.szKey = szKey
		end
	end
	return frame
end

function D.CreateAllFrame()
	if O.bDetach then
		for i, v in ipairs(FLOAT_BAR_LIST) do
			D.CreateFrame(v.szKey)
		end
	else
		D.CreateFrame()
	end
end

function D.SetAnchor(szKey, anchor)
	if szKey then
		O.tAnchors[szKey] = anchor
	else
		O.anchor = anchor
	end
end

function D.GetAnchor(szKey)
	if not szKey then
		return O.anchor
	end
	local anchor = O.tAnchors[szKey]
	if anchor.x == -0xffff then
		for _, v in ipairs(FLOAT_BAR_LIST) do
			if v.szKey == szKey then
				anchor = v.tAnchor or O.anchor
				break
			end
		end
	end
	return anchor
end

function D.UpdateFrameSize(frame)
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
	X.UI.SetFrameAnchor(frame, D.GetAnchor(frame.szKey))
end

function D.RedrawFrame(frame)
	if O.bDetach == not frame.szKey then
		X.UI.CloseFrame(frame)
		return
	end
	local container = frame:Lookup('WndContainer_FloatBar')
	container:Clear()
	for i, v in ipairs(FLOAT_BAR_LIST) do
		if not frame.szKey or frame.szKey == v.szKey then
			local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Item')
			wnd:SetName('Wnd_Item_' .. v.szKey)
			X.SafeCall(v.fnCreate, wnd)
			X.SafeCall(v.fnRender, wnd)
		end
	end
	D.UpdateFrameSize(frame)
end

function D.UpdateWnd(frame, szKey)
	local tInfo
	for i, v in ipairs(FLOAT_BAR_LIST) do
		if v.szKey == szKey then
			tInfo = v
		end
	end
	if not tInfo then
		return
	end
	local wnd = frame:Lookup('WndContainer_FloatBar/Wnd_Item_' .. szKey)
	if not wnd then
		return
	end
	X.SafeCall(tInfo.fnRender, wnd)
	D.UpdateFrameSize(frame)
end

--------------------------------------------------------------------------------
-- 界面函数
--------------------------------------------------------------------------------
function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent(REDRAW_FLOAT_BAR)
	this:RegisterEvent(UPDATE_FLOAT_BAR)
end

function D.OnEvent(event)
	this:BringToTop()
	if event == 'LOADING_END' then
		local frame = this
		X.DelayCall(3000, function() frame:BringToTop() end)
	elseif event == 'UI_SCALED' then
		X.UI.SetFrameAnchor(this, D.GetAnchor(this.szKey))
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['FloatBar'])
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		D.SetAnchor(this.szKey, X.UI.GetFrameAnchor(this))
		UpdateCustomModeWindow(this, _L['FloatBar'])
	elseif event == REDRAW_FLOAT_BAR then
		if arg0 == this.szKey or not this.szKey or not arg0 then
			D.RedrawFrame(this)
		end
	elseif event == UPDATE_FLOAT_BAR then
		if arg0 == this.szKey or not this.szKey then
			D.UpdateWnd(this, arg0)
		end
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX = nPaddingX
	nY = nLFY
	ui:Append('Text', {
		x = nPaddingX - 10, y = nY,
		text = _L['FloatBar'],
		color = { 255, 255, 0 },
	}):AutoWidth()
	nY = nY + 30
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 100, h = 25,
		text = _L['Detach mode'],
		checked = O.bDetach,
		onCheck = function(bChecked)
			O.bDetach = bChecked
			D.CreateAllFrame()
			FireUIEvent(REDRAW_FLOAT_BAR)
		end,
	}):AutoWidth():Width() + 5

	nLFY = nY + nLH
	return nX, nY, nLFY
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
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
	},
}
_G[FRAME_NAME] = X.CreateModule(settings)
end

X.UI.RegisterFloatBar = D.RegisterFloatBar
X.UI.UpdateFloatBar = D.UpdateFloatBar

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit(MODULE_NAME, function()
	D.CreateAllFrame()
	FireUIEvent(REDRAW_FLOAT_BAR)
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
