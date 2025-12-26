--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 系统函数库·弹框
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.MessageBox')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do -- 二次封装 MessageBox 相关事件
local function OnMessageBoxOpen()
	local szName, frame, aMsg = arg0, arg1, {}
	if not frame then
		return
	end
	local wndAll = frame:Lookup('Wnd_All')
	if not wndAll then
		return
	end
	for i = 1, 5 do
		local btn = wndAll:Lookup('Btn_Option' .. i)
		if btn and btn.IsVisible and btn:IsVisible() then
			local nIndex, szOption = btn.nIndex, btn.szOption
			if btn.fnAction then
				HookTableFunc(btn, 'fnAction', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			if btn.fnCountDownEnd then
				HookTableFunc(btn, 'fnCountDownEnd', function()
					FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'TIME_OUT', szOption, nIndex)
				end, { bAfterOrigin = true })
			end
			aMsg[i] = { nIndex = nIndex, szOption = szOption }
		end
	end

	HookTableFunc(frame, 'fnAction', function(i)
		local msg = aMsg[i]
		if not msg then
			return
		end
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'ACTION', msg.szOption, msg.nIndex)
	end, { bAfterOrigin = true })

	HookTableFunc(frame, 'fnCancelAction', function()
		FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'CANCEL')
	end, { bAfterOrigin = true })

	if frame.fnAutoClose then
		HookTableFunc(frame, 'fnAutoClose', function()
			FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_ACTION'), szName, 'AUTO_CLOSE')
		end, { bAfterOrigin = true })
	end

	FireUIEvent(X.NSFormatString('{$NS}_MESSAGE_BOX_OPEN'), arg0, arg1)
end
X.RegisterEvent('ON_MESSAGE_BOX_OPEN', OnMessageBoxOpen)
end

-- 弹出对话框
-- X.MessageBox([szKey, ]tMsg)
-- X.MessageBox([szKey, ]tMsg)
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param tMsg {object} 更多参见官方 MessageBox 文档
-- 	@param tMsg.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.MessageBox(szKey, tMsg)
	if X.IsTable(szKey) then
		szKey, tMsg = nil, szKey
	end
	if not szKey then
		szKey = X.GetUUID():gsub('-', '')
	end
	tMsg.szName = X.NSFormatString('{$NS}_MessageBox#') .. GetStringCRC(szKey)
	if not tMsg.x or not tMsg.y then
		local nW, nH = Station.GetClientSize()
		tMsg.x = nW / 2
		tMsg.y = nH / 3
	end
	if not tMsg.szAlignment then
		tMsg.szAlignment = 'CENTER'
	end
	if tMsg.fnCancelAction == 'FORBIDDEN' then
		tMsg.fnCancelAction = function()
			X.DelayCall(function()
				X.MessageBox(szKey, tMsg)
			end)
		end
	end
	MessageBox(tMsg)
	return szKey
end

-- 弹出对话框 - 单按钮确认
-- X.Alert([szKey, ]szMsg[, fnResolve])
-- X.Alert([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.x {number} 出现位置x坐标
-- 	@param tOpt.y {number} 出现位置y坐标
-- 	@param tOpt.szResolve {string} 按钮文案
-- 	@param tOpt.fnResolve {function} 按钮回调
-- 	@param tOpt.nResolveCountDown {number} 确定按钮倒计时
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Alert(szKey, szMsg, fnResolve)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve = nil, szKey, szMsg
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = { fnResolve = fnResolve }
	end
	return X.MessageBox(szKey, {
		x = tOpt.x, y = tOpt.y,
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		fnAutoClose = tOpt.fnAutoClose,
		{
			szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE,
			fnAction = tOpt.fnResolve,
			bDelayCountDown = tOpt.nResolveCountDown and true or false,
			nCountDownTime = tOpt.nResolveCountDown,
		},
	})
end

-- 弹出对话框 - 双按钮二次确认
-- X.Confirm([szKey, ]szMsg[, fnResolve[, fnReject[, fnCancel]]])
-- X.Confirm([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.x {number} 出现位置x坐标
-- 	@param tOpt.y {number} 出现位置y坐标
-- 	@param tOpt.szResolve {string} 确定按钮文案
-- 	@param tOpt.fnResolve {function} 确定回调
-- 	@param tOpt.szReject {string} 取消按钮文案
-- 	@param tOpt.fnReject {function} 取消回调
-- 	@param tOpt.fnCancel {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Confirm(szKey, szMsg, fnResolve, fnReject, fnCancel)
	if not X.IsString(szMsg) then
		szKey, szMsg, fnResolve, fnReject = nil, szKey, szMsg, fnResolve
	end
	local tOpt = fnResolve
	if not X.IsTable(tOpt) then
		tOpt = {
			fnResolve = fnResolve,
			fnReject = fnReject,
			fnCancel = fnCancel,
		}
	end
	return X.MessageBox(szKey, {
		x = tOpt.x, y = tOpt.y,
		szMessage = szMsg,
		fnCancelAction = tOpt.fnCancel,
		fnAutoClose = tOpt.fnAutoClose,
		{ szOption = tOpt.szResolve or g_tStrings.STR_HOTKEY_SURE, fnAction = tOpt.fnResolve },
		{ szOption = tOpt.szReject or g_tStrings.STR_HOTKEY_CANCEL, fnAction = tOpt.fnReject },
	})
end

-- 弹出对话框 - 自定义按钮
-- X.Dialog([szKey, ]szMsg[, aOptions[, fnCancelAction]])
-- X.Dialog([szKey, ]szMsg[, tOpt])
-- 	@param szKey {string} 唯一标识符，不传自动生成
-- 	@param szMsg {string} 正文
-- 	@param tOpt.aOptions {array} 按钮列表，参见 MessageBox 用法
-- 	@param tOpt.fnCancelAction {function} ESC 关闭回调，可传入“FORBIDDEN”禁止手动关闭
-- 	@return {string} 唯一标识符
function X.Dialog(szKey, szMsg, aOptions, fnCancelAction)
	if not X.IsString(szMsg) then
		szKey, szMsg, aOptions, fnCancelAction = nil, szKey, szMsg, aOptions
	end
	local tMsg = {
		szMessage = szMsg,
		fnCancelAction = fnCancelAction,
	}
	for i, p in ipairs(aOptions) do
		local tOption = {
			szOption = p.szOption,
			fnAction = p.fnAction,
		}
		if not tOption.szOption then
			if i == 1 then
				tOption.szOption = g_tStrings.STR_HOTKEY_SURE
			elseif i == #aOptions then
				tOption.szOption = g_tStrings.STR_HOTKEY_CANCEL
			end
		end
		table.insert(tMsg, tOption)
	end
	return X.MessageBox(szKey, tMsg)
end

function X.FetchMessageBoxButton(frameOrName, vIndexOrText)
	local hFrame
	if X.IsString(frameOrName) then
		hFrame = Station.SearchFrame('MB_' .. frameOrName)
	elseif X.IsElement(frameOrName) then
		hFrame = frameOrName
	end
	if not hFrame then
		return
	end
	if X.IsNumber(vIndexOrText) then
		return hFrame:Lookup('Wnd_All/Btn_Option' .. vIndexOrText)
			or hFrame:Lookup('Wnd_All/WndFlexContainer_Msg/WndFlexContainer_Opt/Btn_Option' .. vIndexOrText)
	end
	local hBtn = X.FetchMessageBoxButton(hFrame, 1)
	while hBtn do
		local nIndex = hBtn:GetIndex() + 1
		local hText = hBtn:Lookup('', 'Text_Option' .. nIndex)
		local szText = hText:GetText()
		if szText == vIndexOrText then
			return hBtn
		end
		hBtn = hBtn:GetNext()
	end
end

function X.GetMessageBoxButtonAction(frameOrName, vIndexOrText)
	local hBtn = X.FetchMessageBoxButton(frameOrName, vIndexOrText)
	return hBtn and hBtn.fnAction
end

function X.GetMessageBoxContentHandle(frameOrName)
	local hFrame
	if X.IsString(frameOrName) then
		hFrame = Station.SearchFrame('MB_' .. frameOrName)
	elseif X.IsElement(frameOrName) then
		hFrame = frameOrName
	end
	if not hFrame then
		return
	end
	return hFrame:Lookup('Wnd_All', 'Handle_Message')
		or hFrame:Lookup('Wnd_All/WndFlexContainer_Msg/Wnd_Msg', '')
end

function X.DoMessageBox(frameOrName, nIndex)
	if not nIndex then
		nIndex = 1
	end
	local hBtn = X.FetchMessageBoxButton(frameOrName, nIndex)
	if hBtn and hBtn:IsEnabled() then
		local hFrame = hBtn:GetRoot()
		local szName = hFrame:GetName():sub(4)
		if hBtn.fnAction then
			if hFrame.args then
				hBtn.fnAction(X.Unpack(hFrame.args))
			else
				hBtn.fnAction()
			end
		elseif hFrame.fnAction then
			if hFrame.args then
				hFrame.fnAction(i, X.Unpack(hFrame.args))
			else
				hFrame.fnAction(i)
			end
		end
		hFrame.OnFrameDestroy = nil
		CloseMessageBox(szName)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
