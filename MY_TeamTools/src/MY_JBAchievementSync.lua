--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 成就同步
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_JBAchievementSync'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_JBAchievementSync'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/jx3box/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
local O = X.CreateUserSettingsModule('MY_JBAchievementSync', _L['Raid'], {
	bAuto = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_TeamTools'],
		szDescription = X.MakeCaption({
			_L['MY_JBAchievementSync'],
			_L['Auto sync achievement on exit'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.EncodeAchievement()
	local me = X.GetClientPlayer()
	local Achievement = X.GetGameTable('Achievement', true)
	local achi = Achievement and Achievement:GetRow(Achievement:GetRowCount())
	local nMaxIndex = achi and achi.dwID
	local aByte = {}
	local aBit = {0, 0, 0, 0, 0, 0, 0, 0}
	local nIndex = 0
	while nIndex <= nMaxIndex do
		for nOffset = 0, 7 do
			aBit[nOffset + 1] = me.IsAchievementAcquired(nIndex + nOffset) or 0
		end
		table.insert(aByte, string.char(X.Bitmap2Number(aBit)))
		nIndex = nIndex + 8
	end
	local szBin = table.concat(aByte)
	local szCompressBin = X.Deflate:CompressZlib(szBin)
	local szCompressBinBase64 = X.EncodeBase64(szCompressBin)
	return szCompressBinBase64
end

function D.Sync(bSilent, resolve, reject)
	X.Ajax({
		url = MY_RSS.PUSH_BASE_URL .. '/api/achievements',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			jx3id = X.GetClientPlayerGlobalID(),
			achievements = D.EncodeAchievement(),
		},
		signature = X.SECRET['J3CX::ACHIEVEMENT_SYNC'],
		success = function(szHTML)
			if bSilent then
				return
			end
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
	-- 成就同步
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 2, w = 'auto',
		buttonStyle = 'FLAT', text = _L['Sync achievement'],
		onClick = function()
			D.Sync()
		end,
	}):Width()
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY + 2, w = 'auto',
		text = _L['Auto sync achievement on exit'],
		checked = MY_JBAchievementSync.bAuto,
		onCheck = function(bChecked)
			MY_JBAchievementSync.bAuto = bChecked
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
	name = 'MY_JBAchievementSync',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				'bAuto',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bAuto',
			},
			triggers = {
				bAuto = function(_, v)
					if v then
						D.Sync(true)
					end
				end,
			},
			root = O,
		},
	},
}
MY_JBAchievementSync = X.CreateModule(settings)
end

X.RegisterFrameCreate('ExitPanel', 'MY_JBAchievementSync', function()
	if O.bAuto then
		D.Sync(true)
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
