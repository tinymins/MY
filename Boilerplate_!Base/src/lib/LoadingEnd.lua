--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础库加载完成处理
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/LoadingEnd')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local PROXY = {}
if IsDebugClient() then
function PROXY.DebugSetVal(szKey, oVal)
	PROXY[szKey] = oVal
end
end

for k, v in pairs(X) do
	PROXY[k] = v
	X[k] = nil
end
setmetatable(X, {
	__metatable = true,
	__index = PROXY,
	__newindex = function() assert(false, X.NSFormatString('DO NOT modify {$NS} after initialized!!!')) end,
	__tostring = function(t) return X.NSFormatString('{$NS} (base library)') end,
})
FireUIEvent(X.NSFormatString('{$NS}_BASE_LOADING_END'))

X.RegisterInit(X.NSFormatString('{$NS}#AUTHOR_TIP'), function()
	local Farbnamen = _G.MY_Farbnamen
	if Farbnamen and Farbnamen.RegisterHeader then
		for dwID, szName in X.pairs_c(X.PACKET_INFO.AUTHOR_ROLES) do
			Farbnamen.RegisterHeader(szName, dwID, X.PACKET_INFO.AUTHOR_HEADER)
		end
		for szName, _ in X.pairs_c(X.PACKET_INFO.AUTHOR_PROTECT_NAMES) do
			Farbnamen.RegisterHeader(szName, '*', X.PACKET_INFO.AUTHOR_FAKE_HEADER)
		end
	end
end)

do
local function OnKeyPanelBtnLButtonUp()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	local szText = X.DecryptString('2,' .. edit:GetText())
	if not szText then
		return
	end
	local aParam = X.DecodeLUAData(szText)
	if not X.IsTable(aParam) then
		return
	end
	if aParam[1] ~= X.PACKET_INFO.NAME_SPACE then
		return
	end
	local aCRC = X.SplitString(aParam[2], ',')
	local szCorrect = tostring(MD5(X.GetUserRoleName() .. X.SECRET['HASH::AUTH_KEY_CODE'])):sub(-6)
	if not X.lodash.includes(aCRC, szCorrect) then
		return
	end
	local nExpire = tonumber(aParam[3] or '')
	if not nExpire or (nExpire ~= 0 and nExpire < GetCurrentTime()) then
		return
	end
	local szCmd = aParam[4]
	if szCmd == 'R' then
		for _, szKey in ipairs(aParam[5]) do
			X.IsRestricted(szKey, false)
		end
	end
	frame:Destroy()
	PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
end
local function HookKeyPanel()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	edit:SetLimit(-1)
	HookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
local function UnhookPanel()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	UnhookTableFunc(btn, 'OnLButtonUp', OnKeyPanelBtnLButtonUp)
end
X.RegisterFrameCreate('KeyPanel', 'LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterInit('LIB.KeyPanel_Restriction', HookKeyPanel)
X.RegisterReload('LIB.KeyPanel_Restriction', UnhookPanel)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
