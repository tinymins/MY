--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 快捷入团
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBTeam'
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
local O = {}

function D.ApplyAPI(szAction, szTeam, resolve, reject)
	local dwID = X.GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		X.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	local me = X.GetClientPlayer()
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/team/' .. (szAction == 'join' and 'join' or 'quit'),
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			team = szTeam,
			cguid = X.GetClientGUID(),
			jx3id = X.GetClientPlayerGlobalID(),
			server = X.GetServerOriginName(),
			id = dwID,
			name = X.GetClientPlayerName(),
			mount = me.GetKungfuMount().dwMountType,
			body_type = me.nRoleType,
		},
		signature = szAction == 'join' and X.SECRET['J3CX::TEAM_JOIN'] or X.SECRET['J3CX::TEAM_QUIT'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if X.Get(res, {'code'}) == 0 then
				X.SafeCall(resolve)
			else
				X.SafeCall(reject, X.ReplaceSensitiveWord(X.Get(res, {'msg'}, _L['Request failed.'])))
			end
		end,
	})
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	-- 快捷入团
	nX = nPaddingX
	nY = nLFY
	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Quick team'], font = 27 }):Height() + 2

	nX = nPaddingX + 10
	local bLoading
	nX = nX + ui:Append('Text', { x = nX, y = nY, w = 'auto', text = _L['Team name/id:'] }):Width()
	local uiInput = ui:Append('WndEditBox', { x = nX, y = nY + 2, w = 150, h = 25 })
	nX = nX + uiInput:Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonStyle = 'FLAT', text = _L['Apply join team'],
		onClick = function()
			if bLoading then
				return X.OutputSystemAnnounceMessage(_L['Processing, please wait.'])
			end
			local szTeam = uiInput:Text()
			if X.IsEmpty(szTeam) then
				return X.Alert(_L['Please input team name/id.'])
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return X.OutputAnnounceMessage(_L['Please unlock equip lock first!'], X.CONSTANT.MSG_THEME.ERROR)
			end
			X.Confirm(_L('Sure to apply join team %s?', szTeam), function()
				bLoading = true
				D.ApplyAPI(
					'join',
					szTeam,
					function()
						bLoading = false
						X.Alert(_L['Apply succeed!'])
						uiInput:Text('')
					end,
					function(szMsg)
						bLoading = false
						X.Alert(_L['Apply failed!'] .. szMsg)
					end)
			end)
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2,
		buttonStyle = 'FLAT', text = _L['Apply quit team'],
		onClick = function()
			if bLoading then
				return X.OutputSystemAnnounceMessage('Processing, please wait.')
			end
			local szTeam = uiInput:Text()
			if X.IsEmpty(szTeam) then
				return X.Alert(_L['Please input team name/id.'])
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return X.OutputAnnounceMessage(_L['Please unlock equip lock first!'], X.CONSTANT.MSG_THEME.ERROR)
			end
			X.Confirm(_L('Sure to apply quit team %s?', szTeam), function()
				bLoading = true
				D.ApplyAPI(
					'quit',
					szTeam,
					function()
						bLoading = false
						X.Alert(_L['Quit succeed!'])
						uiInput:Text('')
					end,
					function(szMsg)
						bLoading = false
						X.Alert(_L['Quit failed!'] .. szMsg)
					end)
			end)
		end,
	}):Width() + 5
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 5, w = 20, h = 20,
		buttonStyle = 'QUESTION',
		onClick = function()
			X.UI.OpenBrowser(MY_RSS.PAGE_BASE_URL .. '/jx3box/team/about')
		end,
	}):Width()

	nLFY = nY + nLH
	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_JBTeam',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_JBTeam = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
