--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : KeyPanel
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/KeyPanel')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local MODULE_NAME = X.NSFormatString('{$NS}_KeyPanel')
local PLUGIN_NAME = X.NSFormatString('{$NS}_KeyPanel')
local PLUGIN_ROOT = X.PACKET_INFO.FRAMEWORK_ROOT
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/KeyPanel/')

local D = {}

function D.OnKeyPanelBtnLButtonUp()
	if not X.SECRET['HASH::AUTH_KEY_CODE'] then
		return
	end
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
	local szCorrect = tostring(MD5(X.GetClientPlayerName() .. X.SECRET['HASH::AUTH_KEY_CODE'])):sub(-6)
	local bCorrect = false
	for _, szCRC in ipairs(aCRC) do
		if szCRC == szCorrect then
			bCorrect = true
			break
		end
	end
	if not bCorrect then
		return
	end
	local nExpire = tonumber(aParam[3] or '')
	if not nExpire or (nExpire ~= 0 and nExpire < GetCurrentTime()) then
		return
	end
	local szCmd = aParam[4]
	if szCmd == 'R' then
		for _, szKey in ipairs(aParam[5]) do
			X.SetRestricted(szKey, false)
		end
	end
	frame:Destroy()
	PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
end

function D.HookKeyPanel()
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
	HookTableFunc(btn, 'OnLButtonUp', D.OnKeyPanelBtnLButtonUp)
end

function D.UnhookPanel()
	local frame = Station.SearchFrame('KeyPanel')
	if not frame then
		return
	end
	local btn = frame:Lookup('Btn_Sure')
	local edit = frame:Lookup('Edit_Key')
	if not btn or not edit then
		return
	end
	UnhookTableFunc(btn, 'OnLButtonUp', D.OnKeyPanelBtnLButtonUp)
end

--------------------------------------------------------------------------------
-- Ãæ°å×¢²á
--------------------------------------------------------------------------------

local PS = {}

function PS.IsRestricted()
	return not X.IsDebugging('Dev_KeyPanel') or not X.SECRET['HASH::AUTH_KEY_CODE']
end

function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nX, nY = 10, 10
	local nW, nH = ui:Size()

	local uiNames, uiExpire, uiRestricts, uiResult, uiResultInfo
	local function onChange()
		local aCRC = {}
		local aName = {}
		for _, szName in ipairs(X.SplitString(uiNames:Text(), ',')) do
			table.insert(aName, szName)
			table.insert(aCRC, tostring(MD5(szName .. X.SECRET['HASH::AUTH_KEY_CODE'])):sub(-6))
		end
		local szCRC = table.concat(aCRC, ',')

		local nExpire = tonumber(uiExpire:Text())
		if nExpire ~= 0 then
			nExpire = (nExpire or 0) + GetCurrentTime()
		end

		local szCmd = 'R'
		local aKey = {}
		for _, szKey in ipairs(X.SplitString(uiRestricts:Text(), ',')) do
			table.insert(aKey, szKey)
		end

		local szData = X.EncodeLUAData({X.PACKET_INFO.NAME_SPACE, szCRC, nExpire, szCmd, aKey})
		local szEncrypt = X.EncryptString(szData):gsub('^2,', '')

		uiResult:Text(szEncrypt)

		local aInfo = {}
		table.insert(aInfo, 'Names: ' .. table.concat(aName, ','))
		table.insert(aInfo, 'ExpireTime: ' .. (nExpire == 0 and 'Forever' or X.FormatTime(nExpire, '%yyyy/%MM/%dd %hh:%mm:%ss')))
		table.insert(aInfo, 'Restricted: ' .. table.concat(aKey, ','))
		uiResultInfo:Text(table.concat(aInfo, '\n'))
	end

	nY = nY + ui:Append('Text', {
		x = nX, y = nY,
		w = nW - 20,
		text = _L['Input role names, split by comma:'],
	}):Height() + 3
	uiNames = ui:Append('WndEditBox', {
		x = nX, y = nY,
		w = nW - 20, h = 50,
		multiline = true,
		onChange = onChange,
	})
	nY = nY + uiNames:Height() + 5

	nY = nY + ui:Append('Text', {
		x = nX, y = nY,
		w = nW - 20,
		text = _L['Input expire seconds, 0 for no expire:'],
	}):Height() + 3
	uiExpire = ui:Append('WndEditBox', {
		x = nX, y = nY,
		w = nW - 20, h = 50,
		multiline = true,
		onChange = onChange,
	})
	nY = nY + uiExpire:Height() + 5

	nY = nY + ui:Append('Text', {
		x = nX, y = nY,
		w = nW - 20,
		text = _L['Input restrict keys, split by comma:'],
	}):Height() + 3
	uiRestricts = ui:Append('WndEditBox', {
		x = nX, y = nY,
		w = nW - 20, h = 50,
		multiline = true,
		onChange = onChange,
	})
	nY = nY + uiRestricts:Height() + 5

	nY = nY + ui:Append('Text', {
		x = nX, y = nY,
		w = nW - 20,
		font = 27,
		text = _L['Result:'],
	}):Height() + 3
	uiResult = ui:Append('WndEditBox', {
		x = nX, y = nY,
		w = nW - 20, h = 50,
		multiline = true,
	})
	nY = nY + uiResult:Height() + 5

	uiResultInfo = ui:Append('Text', {
		x = nX, y = nY,
		w = nW - 20, h = 30,
		font = 27,
		multiline = true,
		alignVertical = 0
	})
end

X.Panel.Register(_L['Development'], 'KeyPanel', _L['KeyPanel'], 'ui/Image/UICommon/ActivityList1.UITex|51', PS)

--------------------------------------------------------------------------------
-- ÊÂ¼þ×¢²á
--------------------------------------------------------------------------------

X.RegisterFrameCreate('KeyPanel', 'LIB.KeyPanel_Restriction', D.HookKeyPanel)
X.RegisterInit('LIB.KeyPanel_Restriction', D.HookKeyPanel)
X.RegisterReload('LIB.KeyPanel_Restriction', D.UnhookPanel)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
