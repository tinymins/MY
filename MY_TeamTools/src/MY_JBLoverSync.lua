--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 情缘同步
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBLoverSync'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBLoverSync'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local D = {}

local function OnBgTalk(_, aData, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not MY_Love or MY_Love.IsShielded() then
		return
	end
	if not bSelf then
		if not X.CanUseOnlineRemoteStorage() then
			X.SendBgMsg(szTalkerName, 'MY_JB_LOVER_SYNC', {'DATA_NOT_SYNC'})
			return
		end
		local szKey, data = aData[1], aData[2]
		if szKey == 'SYNC' then
			local lover = MY_Love.GetLover()
			local tFellowship = X.GetFellowshipInfo(dwTalkerID)
			if lover and tFellowship and lover.xID == tFellowship.xID then
				X.Confirm(_L('[%s] want to sync lover relation to jx3box, do you agree?', szTalkerName), function()
					if X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) or X.IsSafeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) then
						X.OutputSystemAnnounceMessage(_L['Sync lover is a sensitive action, please unlock to continue.'])
						return false
					end
					X.SendBgMsg(szTalkerName, 'MY_JB_LOVER_SYNC', {'SYNC_ANS', X.GetClientPlayerGlobalID()})
				end)
			else
				X.SendBgMsg(szTalkerName, 'MY_JB_LOVER_SYNC', {'SYNC_ANS_NOT_LOVER'})
			end
		elseif szKey == 'SYNC_ANS' then
			D.SyncLover(szTalkerName, data)
		elseif szKey == 'SYNC_ANS_NOT_LOVER' then
			X.Alert(_L['Peer is not your lover, please check, or do fix lover first.'])
		elseif szKey == 'DATA_NOT_SYNC' then
			X.Alert(_L('[%s] disabled ui config sync, unable to read data.', szTalkerName))
		end
	end
end
X.RegisterBgMsg('MY_JB_LOVER_SYNC', OnBgTalk)

function D.SyncLover(szLoverName, szLoverUUID, resolve, reject)
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/role/bind/love',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			role1 = X.GetClientPlayerGlobalID(),
			role2 = szLoverUUID,
		},
		signature = X.SECRET['J3CX::LOVER_SYNC'],
		success = function(szHTML)
			local res = X.DecodeJSON(szHTML)
			if X.Get(res, {'code'}) == 0 then
				X.Alert((X.Get(res, {'msg'}, _L['Sync success.'])))
				X.SafeCall(resolve)
			else
				X.Alert((X.Get(res, {'msg'}, _L['Request failed.'])))
				X.SafeCall(reject)
			end
		end,
	})
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	-- 情缘同步
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2, w = 'auto',
		buttonStyle = 'FLAT', text = _L['Sync lover'],
		onClick = function()
			local lover = MY_Love.GetLover()
			if lover then
				X.OutputSystemAnnounceMessage(_L['Sync lover request sent, please wait for peer to agree.'])
				X.SendBgMsg(lover.szName, 'MY_JB_LOVER_SYNC', {'SYNC'})
			else
				D.SyncLover('', '')
			end
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
	name = 'MY_JBLoverSync',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_JBLoverSync = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
