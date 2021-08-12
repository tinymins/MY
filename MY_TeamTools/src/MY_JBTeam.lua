--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 快捷入团
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBBind'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
--------------------------------------------------------------------------
local D = {}
local O = {}

function D.ApplyAPI(szAction, szTeam, resolve, reject)
	local dwID = UI_GetClientPlayerID()
	if IsRemotePlayer(dwID) then
		X.Alert(_L['You are crossing server, please do this after backing.'])
		return
	end
	local me = GetClientPlayer()
	local szURL = 'https://push.j3cx.com/team/'
		.. (szAction == 'join' and 'join' or 'quit')
		.. '?'
		.. X.EncodePostData(X.UrlEncode(X.SignPostData({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			team = AnsiToUTF8(szTeam),
			cguid = X.GetClientGUID(),
			jx3id = AnsiToUTF8(X.GetClientUUID()),
			server = AnsiToUTF8(X.GetRealServer(2)),
			id = AnsiToUTF8(dwID),
			name = AnsiToUTF8(X.GetUserRoleName()),
			mount = me.GetKungfuMount().dwMountType,
			body_type = me.nRoleType,
		}, szAction == 'join' and '3a0e8712-db2e-4dd5-a089-169fe2b4093b' or '26f76228-1f64-479a-a6d3-2cff034fcf08')))
	X.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = szURL,
		charset = 'utf8',
		success = function(szHTML)
			local res = X.JsonDecode(szHTML)
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
		buttonstyle = 'FLAT', text = _L['Apply join team'],
		onclick = function()
			if bLoading then
				return X.Systopmsg(_L['Processing, please wait.'])
			end
			local szTeam = uiInput:Text()
			if X.IsEmpty(szTeam) then
				return X.Alert(_L['Please input team name/id.'])
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return X.Topmsg(_L['Please unlock equip lock first!'], CONSTANT.MSG_THEME.ERROR)
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
		buttonstyle = 'FLAT', text = _L['Apply quit team'],
		onclick = function()
			if bLoading then
				return X.Systopmsg('Processing, please wait.')
			end
			local szTeam = uiInput:Text()
			if X.IsEmpty(szTeam) then
				return X.Alert(_L['Please input team name/id.'])
			end
			if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
				return X.Topmsg(_L['Please unlock equip lock first!'], CONSTANT.MSG_THEME.ERROR)
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
		buttonstyle = 'QUESTION',
		onclick = function()
			UI.OpenBrowser('https://page.j3cx.com/jx3box/team/about')
		end,
	}):Width()

	nLFY = nY + nLH
	return nX, nY, nLFY
end

-- Global exports
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
