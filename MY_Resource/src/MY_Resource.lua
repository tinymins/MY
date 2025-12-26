--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 二进制资源
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_Resource')
local MODULE_NAME = X.NSFormatString('{$NS}_Resource')
local PLUGIN_NAME = X.NSFormatString('{$NS}_Resource')
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local C, D = {}, {}

C.aSound = {
	-- {
	-- 	type = _L['Wuer'],
	-- 	{ id = 2, file = 'WE/voice-52001.ogg' },
	-- 	{ id = 3, file = 'WE/voice-52002.ogg' },
	-- },
}

do
local root = PLUGIN_ROOT .. '/audio/'
local function GetSoundList(tSound)
	local t = {}
	if tSound.type then
		t.szType = tSound.type
	elseif tSound.id then
		t.dwID = tSound.id
		t.szName = _L[tSound.file]
		t.szPath = root .. tSound.file
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundList(v)
		if t1 then
			table.insert(t, t1)
		end
	end
	return t
end

function D.GetSoundList()
	return GetSoundList(C.aSound)
end
end

do
local BUTTON_STYLE_CONFIG = {
	FLAT = X.FreezeTable({
		nWidth = 100,
		nHeight = 25,
		nPaddingTop = 3,
		nPaddingRight = 8,
		nPaddingBottom = 3,
		nPaddingLeft = 8,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 8,
		nMouseOverGroup = 9,
		nMouseDownGroup = 10,
		nDisableGroup = 11,
	}),
	FLAT_LACE_BORDER = X.FreezeTable({
		nWidth = 148,
		nHeight = 33,
		nPaddingTop = 3,
		nPaddingRight = 13,
		nPaddingBottom = 3,
		nPaddingLeft = 13,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 0,
		nMouseOverGroup = 1,
		nMouseDownGroup = 2,
		nDisableGroup = 3,
	}),
	SKEUOMORPHISM = X.FreezeTable({
		nWidth = 148,
		nHeight = 33,
		nPaddingTop = 3,
		nPaddingRight = 10,
		nPaddingBottom = 3,
		nPaddingLeft = 10,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 4,
		nMouseOverGroup = 5,
		nMouseDownGroup = 6,
		nDisableGroup = 7,
	}),
	SKEUOMORPHISM_LACE_BORDER = X.FreezeTable({
		nWidth = 224,
		nHeight = 64,
		nPaddingTop = 2,
		nPaddingRight = 15,
		nPaddingBottom = 10,
		nPaddingLeft = 15,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 12,
		nMouseOverGroup = 13,
		nMouseDownGroup = 14,
		nDisableGroup = 15,
	}),
	QUESTION = X.FreezeTable({
		nWidth = 20,
		nHeight = 20,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 16,
		nMouseOverGroup = 17,
		nMouseDownGroup = 18,
		nDisableGroup = 19,
	}),
	UNDERLINE_LINK = X.FreezeTable({
		nWidth = 60,
		nHeight = 26,
		nMarginTop = 14,
		nMarginBottom = 2,
		nPaddingTop = -14,
		nPaddingBottom = -2,
		szImage = PLUGIN_ROOT .. '/img/WndButton.UITex',
		nNormalGroup = 20,
		nMouseOverGroup = 21,
		nMouseDownGroup = 22,
		nDisableGroup = 23,
		nNormalFont = 162,
		nMouseOverFont = 0,
		nMouseDownFont = 162,
		nDisableFont = 161,
		fAnimateScale = 1.2,
	}),
}
if X.UI.IS_GLASSMORPHISM then
	BUTTON_STYLE_CONFIG.FLAT = BUTTON_STYLE_CONFIG.DEFAULT
	BUTTON_STYLE_CONFIG.FLAT_LACE_BORDER = BUTTON_STYLE_CONFIG.DEFAULT
	BUTTON_STYLE_CONFIG.SKEUOMORPHISM = BUTTON_STYLE_CONFIG.DEFAULT
	BUTTON_STYLE_CONFIG.SKEUOMORPHISM_LACE_BORDER = BUTTON_STYLE_CONFIG.DEFAULT
end
function D.GetWndButtonStyleName(szImage, nNormalGroup)
	szImage = X.StringLowerW(X.NormalizePath(szImage))
	for e, p in pairs(BUTTON_STYLE_CONFIG) do
		if X.StringLowerW(X.NormalizePath(p.szImage)) == szImage and p.nNormalGroup == nNormalGroup then
			return e
		end
	end
end
function D.GetWndButtonStyleConfig(eStyle)
	return BUTTON_STYLE_CONFIG[eStyle]
end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = MODULE_NAME,
	exports = {
		{
			fields = {
				'GetSoundList',
				'GetWndButtonStyleName',
				'GetWndButtonStyleConfig',
			},
			root = D,
		},
	},
}
_G[MODULE_NAME] = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
