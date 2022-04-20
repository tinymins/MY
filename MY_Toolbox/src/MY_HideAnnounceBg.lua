--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Òþ²Ø¹«¸æÀ¸±³¾°
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0 ') then
	return
end
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_HideAnnounceBg', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.Apply()
	if D.bReady and O.bEnable then
		local h = Station.Lookup('Topmost2/GMAnnouncePanel', 'Handle_MsgBg')
		if h then
			h:Hide()
		end
	end
end

X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_HideAnnounceBg', function()
	D.bReady = true
	D.Apply()
end)
X.RegisterFrameCreate('GMAnnouncePanel', 'MY_HideAnnounceBg', D.Apply)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Hide announce bg'],
		checked = MY_HideAnnounceBg.bEnable,
		onCheck = function(bChecked)
			MY_HideAnnounceBg.bEnable = bChecked
		end,
	}):AutoWidth():Width() + 5
	-- x, y = X, y + 25
	return nX, nY
end

-- Global exports
do
local settings = {
	name = 'MY_HideAnnounceBg',
	exports = {
		{
			fields = {
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			triggers = {
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_HideAnnounceBg = X.CreateModule(settings)
end
