--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·界面函数
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
---@type Boilerplate
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.UI')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- register global esc key down action
-- (void) X.RegisterEsc(szID, fnCondition, fnAction, bTopmost) -- register global esc event handle
-- (void) X.RegisterEsc(szID, nil, nil, bTopmost)              -- unregister global esc event handle
-- (string)szID        -- an UUID (if this UUID has been register before, the old will be recovered)
-- (function)fnCondition -- a function returns if fnAction will be execute
-- (function)fnAction    -- inf fnCondition() is true then fnAction will be called
-- (boolean)bTopmost    -- this param equals true will be called in high priority
function X.RegisterEsc(szID, fnCondition, fnAction, bTopmost)
	if fnCondition and fnAction then
		if RegisterGlobalEsc then
			RegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szID, fnCondition, fnAction, bTopmost)
		end
	else
		if UnRegisterGlobalEsc then
			UnRegisterGlobalEsc(X.PACKET_INFO.NAME_SPACE .. '#' .. szID, bTopmost)
		end
	end
end

do
local bCustomMode = false
function X.IsInCustomUIMode()
	return bCustomMode
end
X.RegisterEvent('ON_ENTER_CUSTOM_UI_MODE', function() bCustomMode = true  end)
X.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE', function() bCustomMode = false end)
end

function X.GetUIScale()
	return Station.GetUIScale()
end

function X.GetOriginUIScale()
	-- 线性拟合出来的公式 -- 不知道不同机器会不会不一样
	-- 源数据
	-- 0.63, 0.7
	-- 0.666, 0.75
	-- 0.711, 0.8
	-- 0.756, 0.85
	-- 0.846, 0.95
	-- 0.89, 1
	-- return math.floor((1.13726 * Station.GetUIScale() / Station.GetMaxUIScale() - 0.011) * 100 + 0.5) / 100 -- +0.5为了四舍五入
	-- 不同显示器GetMaxUIScale都不一样 太麻烦了 放弃 直接读配置项
	return GetUserPreferences(3775, 'c') / 100 -- TODO: 不同步设置就GG了 要通过实时数值反向计算 缺少API
end

-- X.OpenBrowser(szAddr, 'auto')
-- X.OpenBrowser(szAddr, 'outer')
-- X.OpenBrowser(szAddr, 'inner')
function X.OpenBrowser(szAddr, szMode)
	if not szMode then
		szMode = 'auto'
	end
	if szMode == 'auto' or szMode == 'outer' then
		local OpenBrowser = X.GetGameAPI('OpenBrowser')
		if OpenBrowser then
			OpenBrowser(szAddr)
			return
		end
		if szMode == 'outer' then
			X.UI.OpenTextEditor(szAddr)
			return
		end
	end
	X.UI.OpenBrowser(szAddr)
end

-- 打开事件链接
---@param szLinkInfo string @需要打开的事件链接内容
function X.OpenEventLink(szLinkInfo)
	if IsCtrlKeyDown() then
		X.BreatheCall(function()
			if IsCtrlKeyDown() then
				return
			end
			X.OpenEventLink(szLinkInfo)
			return 0
		end)
		return
	end
	local h = X.UI.GetTempElement('Handle', 'LIB#OpenEventLink')
	if not h then
		return
	end
	h:Clear()
	h:AppendItemFromString(GetFormatText(
		'',
		10, 255, 255, 255, nil,
		'this.szLinkInfo=' .. X.EncodeLUAData(szLinkInfo),
		'eventlink',
		nil,
		szLinkInfo
	))
	local hItem = h:Lookup(0)
	if not hItem then
		return
	end
	OnItemLinkDown(hItem)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
