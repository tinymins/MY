--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 集中渲染阴影
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/UI.Shadows')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local D = {}
local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/Shadows.ini'
local FRAME_NAME = X.NSFormatString('{$NS}_Shadows')

function D.OnFrameCreate()
	this:RegisterEvent('LOADING_END')
	this:RegisterEvent('COINSHOP_ON_OPEN')
	this:RegisterEvent('COINSHOP_ON_CLOSE')
	this:RegisterEvent('ENTER_STORY_MODE')
	this:RegisterEvent('LEAVE_STORY_MODE')
	this:RegisterEvent('ON_FRAME_CREATE')
	X.UI(this):BringToBottom()
end

do
local VISIBLE = true
function D.OnFrameBreathe()
	if not Station then
		return
	end
	if Station.IsVisible() then
		if not VISIBLE then
			local h = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				h:Lookup(i):SetVisible(true)
			end
			VISIBLE = true
		end
	else
		if VISIBLE then
			local h, hh = this:Lookup('', '')
			for i = 0, h:GetItemCount() - 1 do
				hh = h:Lookup(i)
				hh:SetVisible(hh.bShowWhenUIHide or false)
			end
			VISIBLE = false
		end
	end
end
end

function D.OnEvent(event)
	if event == 'LOADING_END' then
		this:Show()
	elseif event == 'COINSHOP_ON_OPEN' or event == 'ENTER_STORY_MODE' then
		this:HideWhenUIHide()
	elseif event == 'COINSHOP_ON_CLOSE' or event == 'LEAVE_STORY_MODE' then
		this:ShowWhenUIHide()
	elseif event == 'ON_FRAME_CREATE' then
		X.UI(this):BringToBottom()
	end
end

local SH_FUNC = {
	ShowWhenUIHide = function(sh)
		sh.bShowWhenUIHide = true
	end,
	HideWhenUIHide = function(sh)
		sh.bShowWhenUIHide = nil
	end,
}

function X.UI.GetShadowHandle(szName)
	local frame = Station.SearchFrame(FRAME_NAME)
	if frame and not X.IsElement(frame) then -- 关闭无效的 frame 句柄
		X.UI.CloseFrame(FRAME_NAME)
		frame = nil
	end
	if not frame then
		frame = X.UI.OpenFrame(INI_PATH, FRAME_NAME)
	end
	local sh = frame:Lookup('', szName)
	if sh and not X.IsElement(sh) then -- 关闭无效的 sh 句柄
		frame:Lookup('', ''):Remove(sh)
		sh = nil
	end
	if not sh then
		frame:Lookup('', ''):AppendItemFromString(string.format('<handle> name="%s" </handle>', szName))
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('UI', 'Create sh # ' .. szName, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		sh = frame:Lookup('', szName)
	end
	if not sh.bInit then
		for k, v in pairs(SH_FUNC) do
			sh[k] = v
		end
		sh.bInit = true
	end
	return sh
end

function X.UI.ClearShadowHandle(szName)
	local frame = Station.SearchFrame(FRAME_NAME)
	if not frame then
		return
	end
	local sh = frame:Lookup('', szName)
	if not sh then
		return
	end
	sh:Clear()
end

function X.UI.SetShadowHandleVisible(szName, bVisible)
	local frame = Station.SearchFrame(FRAME_NAME)
	if not frame then
		return
	end
	if szName == '*' then
		frame:SetVisible(bVisible)
		return
	end
	local sh = frame:Lookup('', szName)
	if not sh then
		return
	end
	sh:SetVisible(bVisible)
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

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
