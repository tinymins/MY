--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 保存喊话
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_TeamAD'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamAD'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {}
local O = {
	szDataFile = {'userdata/team_advertising.jx3dat', X.PATH_TYPE.GLOBAL},
	tItem = {
		{ dwTabType = 5, dwIndex = 24430, nUiId = 153192 },
		{ dwTabType = 5, dwIndex = 23988, nUiId = 152748 },
		{ dwTabType = 5, dwIndex = 23841, nUiId = 152596 },
		{ dwTabType = 5, dwIndex = 22939, nUiId = 151677 },
		{ dwTabType = 5, dwIndex = 23759, nUiId = 152512 },
		{ dwTabType = 5, dwIndex = 22084, nUiId = 150827 },
		{ dwTabType = 5, dwIndex = 22085, nUiId = 150828 },
		{ dwTabType = 5, dwIndex = 22086, nUiId = 150829 },
		{ dwTabType = 5, dwIndex = 22087, nUiId = 150830 },
		{ dwTabType = 5, dwIndex = 25831, nUiId = 153898 },
		{ dwTabType = 5, dwIndex = 33450, nUiId = 162223 },
	}
}

function D.LoadLUAData()
	O.tADList = X.LoadLUAData(O.szDataFile, { passphrase = false, crc = false }) or {}
end

function D.SaveLUAData()
	X.SaveLUAData(O.szDataFile, O.tADList, { encoder = 'luatext', indent = '\t', passphrase = false, crc = false })
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 20, 20
	local nW, nH = ui:Size()
	local nX, nY = nPaddingX, nPaddingY
	D.LoadLUAData()

	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['Save Talk'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = nPaddingX + 10
	nX = ui:Append('WndButton', { x = nX, y = nY + 10, text = _L['Save Advertising'], buttonStyle = 'FLAT' }):Click(function(bChecked)
		local edit = X.GetChatInput()
		local txt, data = edit:GetText(), edit:GetTextStruct()
		if X.TrimString(txt) == '' then
			X.Alert(_L['Chat box is empty'])
		else
			GetUserInput(_L['Save Advertising Name'],function(text)
				table.insert(O.tADList, { key = text, text = txt, ad = data })
				D.SaveLUAData()
				X.Panel.SwitchTab('MY_TeamAD', true)
			end, nil, nil, nil, nil, 5)
		end
	end):Pos('BOTTOMRIGHT')
	nX, nY = ui:Append('Text', { x = nX + 5, y = nY + 10, text = _L['Advertising Tips'] }):Pos('BOTTOMRIGHT')

	nX = nPaddingX
	nX, nY = ui:Append('Text', { x = nX, y = nY + 5, text = _L['Gadgets'], font = 27 }):Pos('BOTTOMRIGHT')
	for k, v in ipairs(O.tItem) do
		if GetItemInfo(v.dwTabType, v.dwIndex) then
			nX = ui:Append('Box', { x = (k - 1) * 48 + nPaddingX + 10, y = nY + 10, w = 38, h = 38 }):ItemInfo(X.ENVIRONMENT.CURRENT_ITEM_VERSION, v.dwTabType, v.dwIndex):Pos('BOTTOMRIGHT')
		end
	end

	nX = nPaddingX
	nY = nY + 58
	nX, nY = ui:Append('Text', { x = nX, y = nY, text = _L['Advertising List'], font = 27 }):Pos('BOTTOMRIGHT')

	nX = nPaddingX + 10
	nY = nY + 10
	for k, v in ipairs(O.tADList) do
		if nX + 80 > nW then
			nX = nPaddingX + 10
			nY = nY + 28
		end
		nX = ui:Append('WndButton', {
			x = nX, y = nY, w = 80, text = v.key,
			buttonStyle = 'FLAT',
			onLClick = function()
				X.SetChatInput(v.ad)
				X.FocusChatInput()
			end,
			menuRClick = function()
				local menu = {{
					szOption = _L['Delete'],
					fnAction = function()
						table.remove(O.tADList, k)
						D.SaveLUAData()
						X.Panel.SwitchTab('MY_TeamAD', true)
					end,
				}}
				return menu
			end,
			onHover = function(bIn)
				if bIn then
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputTip(GetFormatText(v.text), 550, { x, y, w, h })
				else
					HideTip()
				end
			end,
		}):Pos('BOTTOMRIGHT') + 10
	end
end
X.Panel.Register(_L['Raid'], 'MY_TeamAD', _L['MY_TeamAD'], 5958, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
