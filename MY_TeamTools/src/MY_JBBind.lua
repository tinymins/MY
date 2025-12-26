--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 绑定 JX3BOX
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBBind'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}
local O = {
	uid = nil,
	pending = false,
}

function D.FetchBindStatus(resolve, reject)
	if X.IsNil(O.uid) then
		O.pending = true
		X.Ajax({
			url = MY_RSS.PULL_BASE_URL .. '/role/query',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				jx3id = X.GetClientPlayerGlobalID(),
			},
			signature = X.SECRET['J3CX::ROLE_QUERY'],
			success = function(szHTML)
				O.pending = false
				local res = X.DecodeJSON(szHTML)
				local code = X.Get(res, {'code'})
				if code == 0 then
					O.uid = X.Get(res, {'data', 'uid'})
					X.SafeCall(resolve, O.uid)
				elseif code == 404 then
					O.uid = 0
					X.SafeCall(resolve, O.uid)
				else
					X.SafeCall(reject)
				end
			end,
			error = function()
				O.pending = false
				X.SafeCall(reject)
			end,
		})
	else
		X.SafeCall(resolve, O.uid)
	end
end

function D.Bind(szToken, resolve, reject)
	local dwID = X.GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		X.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	local me = X.GetClientPlayer()
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/role/bind',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			token = szToken,
			cguid = X.GetClientGUID(),
			jx3id = X.GetClientPlayerGlobalID(),
			server = X.GetServerOriginName(),
			id = dwID,
			name = X.GetClientPlayerName(),
			mount = me.GetKungfuMount().dwMountType,
			type = me.nRoleType,
		},
		signature = X.SECRET['J3CX::ROLE_BIND'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if X.Get(res, {'code'}) == 0 then
				O.uid = nil
				X.SafeCall(resolve, O.uid)
			else
				X.Alert((X.Get(res, {'msg'}, _L['Request failed.'])))
				X.SafeCall(reject)
			end
		end,
	})
end

function D.Unbind(resolve, reject)
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/role/unbind',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetClientPlayerGlobalID(),
		},
		signature = X.SECRET['J3CX::ROLE_UNBIND'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if X.Get(res, {'code'}) == 0 then
				O.uid = nil
				X.SafeCall(resolve)
			else
				X.Alert((X.Get(res, {'msg'}, _L['Request failed.'])))
				X.SafeCall(reject)
			end
		end,
	})
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	-- 角色认证
	local uiCCStatus, uiBtnCCStatus, uiBtnCCLink
	local function UpdateUI()
		if uiCCStatus:Count() == 0 or uiBtnCCStatus:Count() == 0 or uiBtnCCLink:Count() == 0 then
			return
		end
		if O.pending then
			uiCCStatus:Text(_L['Loading'])
			uiBtnCCStatus:Text(_L['Click fetch'])
		elseif X.IsNil(O.uid) then
			uiCCStatus:Text(_L['Unknown'])
			uiBtnCCStatus:Text(_L['Click fetch'])
		elseif X.IsEmpty(O.uid) then
			uiCCStatus:Text(_L['Not bind'])
			uiBtnCCStatus:Text(_L['Click bind'])
		else
			uiCCStatus:Text(_L('Binded (ID: %s)', O.uid))
			uiBtnCCStatus:Text(_L['Click unbind'])
		end
		uiCCStatus:AutoWidth()
		uiBtnCCStatus:Enable(not O.pending)
		uiBtnCCStatus:Left(uiCCStatus:Left() + uiCCStatus:Width() + 20)
		uiBtnCCLink:Left(uiBtnCCStatus:Left() + uiBtnCCStatus:Width() + 10)
	end

	nX = nPaddingX
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Character Certification'], font = 27 }):Height() + 2

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L('Current character: %s', X.GetClientPlayerName()) }):Width() + 20
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Status: '] }):Width()
	uiCCStatus = ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Loading'] })
	nX = nX + uiCCStatus:Width()
	uiBtnCCStatus = ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonStyle = 'FLAT', text = _L['Bind'], enable = false,
		onClick = function()
			if O.pending or X.IsNil(O.uid) then
				D.FetchBindStatus(UpdateUI, UpdateUI)
			elseif X.IsEmpty(O.uid) then
				GetUserInput(_L['Please input certification code:'], function(szText)
					uiBtnCCStatus:Enable(false)
					D.Bind(
						szText,
						function()
							X.Alert(_L['Bind succeed!'])
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end,
						function()
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end)
				end)
			elseif X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				X.OutputAnnounceMessage(_L['Please unlock equip lock first!'], X.CONSTANT.MSG_THEME.ERROR)
			else
				X.Confirm(_L['Sure to unbind character certification?'], function()
					uiBtnCCStatus:Enable(false)
					D.Unbind(
						function()
							X.Alert(_L['Unbind succeed!'])
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end,
						function()
							D.FetchBindStatus(UpdateUI, UpdateUI)
						end)
				end)
			end
		end,
	})
	nX = nX + uiBtnCCStatus:Width()
	uiBtnCCLink = ui:Append('WndButton', {
		x = nX, y = nY + 2, w = 120,
		buttonStyle = 'FLAT', text = _L['Login team platform'],
		onClick = function()
			X.OpenBrowser(MY_RSS.PAGE_BASE_URL .. '/jx3box/team/platform')
		end,
	})
	nX = nX + uiBtnCCLink:Width()

	UpdateUI()
	D.FetchBindStatus(UpdateUI, UpdateUI)

	nLFY = nY + nLH
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_JBBind',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_JBBind = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
