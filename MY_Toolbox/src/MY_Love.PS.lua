--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 剑侠情缘设置界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local byte, char, len, find, format = string.byte, string.char, string.len, string.find, string.format
local gmatch, gsub, dump, reverse = string.gmatch, string.gsub, string.dump, string.reverse
local match, rep, sub, upper, lower = string.match, string.rep, string.sub, string.upper, string.lower
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, randomseed = math.huge, math.pi, math.random, math.randomseed
local min, max, floor, ceil, abs = math.min, math.max, math.floor, math.ceil, math.abs
local mod, modf, pow, sqrt = math['mod'] or math['fmod'], math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat = table.insert, table.remove, table.concat
local pack, unpack = table['pack'] or function(...) return {...} end, table['unpack'] or unpack
local sort, getn = table.sort, table['getn'] or function(t) return #t end
-- jx3 apis caching
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, GLOBAL, CONSTANT = LIB.UI, LIB.GLOBAL, LIB.CONSTANT
local PACKET_INFO, DEBUG_LEVEL, PATH_TYPE = LIB.PACKET_INFO, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local wsub, count_c, lodash = LIB.wsub, LIB.count_c, LIB.lodash
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Love'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------

local D = {
	GetLover = MY_Love.GetLover,
	SetLover = MY_Love.SetLover,
	FixLover = MY_Love.FixLover,
	BackupLover = MY_Love.BackupLover,
	RestoreLover = MY_Love.RestoreLover,
	RemoveLover = MY_Love.RemoveLover,
	FormatLoverString = MY_Love.FormatLoverString,
}
local O = {
	bPanelActive = false,
}

-- refresh ps
function D.RefreshPS()
	if O.bPanelActive and MY.IsPanelOpened() then
		MY.SwitchTab('MY_Love', true)
	end
end
LIB.RegisterEvent('MY_LOVE_UPDATE.MY_Love__PS', D.RefreshPS)

-------------------------------------
-- 设置界面
-------------------------------------
local PS = { IsShielded = MY_Love.IsShielded }

-- 获取可情缘好友列表
function D.GetLoverMenu(nType)
	local me, m0 = GetClientPlayer(), {}
	local aGroup = me.GetFellowshipGroupInfo() or {}
	insert(aGroup, 1, {id = 0, name = g_tStrings.STR_FRIEND_GOOF_FRIEND})
	for _, v in ipairs(aGroup) do
		local aFriend = me.GetFellowshipInfo(v.id) or {}
		for _, vv in ipairs(aFriend) do
			if vv.attraction >= MY_Love.nLoveAttraction and (nType ~= 1 or vv.attraction >= MY_Love.nDoubleLoveAttraction) then
				insert(m0, {
					szOption = vv.name,
					fnDisable = function() return not vv.isonline end,
					fnAction = function()
						D.SetLover(vv.id, nType)
					end
				})
			end
		end
	end
	if #m0 == 0 then
		insert(m0, { szOption = _L['<Non-avaiable>'] })
	end
	return m0
end

-- init
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local W, H = ui:Size()
	local X, Y = 20, 20
	local nX, nY = X, Y
	local lover = D.GetLover()

	ui:Append('Text', { text = _L['Heart lover'], x = X, y = nY, font = 27 })
	-- lover info
	nY = nY + 36
	if not LIB.IsRemoteStorage() then
		nX = X + 10
		nY = nY + ui:Append('Text', {
			x = nX, y = nY, w = W - nX, h = 120,
			text = _L['Please enable sync common ui config first'],
			font = 19, r = 255, g = 255, b = 0, multiline = true,
		}):AutoHeight():Height() + 25
		nY = nY + ui:Append('WndButton', {
			x = (W - 100) / 2, y = nY, w = 100, h = 30,
			text = _L['Refresh'],
			onclick = function()
				D.RefreshPS()
			end,
		}):Height() + 20
	else
		if not lover or not lover.dwID or lover.dwID == 0 then
			nX = X + 10
			nX = ui:Append('Text', { text = _L['No lover :-('], font = 19, x = nX, y = nY }):Pos('BOTTOMRIGHT')
			nX = ui:Append('Text', {
				text = _L['[Restore]'], x = nX + 10, y = nY,
				onclick = function()
					local szFilePath = GetOpenFileName(
						_L['Please select lover backup data file:'],
						'JX3 Lover File(*.lover.jx3dat)\0*.jx3dat\0JX3 File(*.jx3dat)\0*.jx3dat\0All Files(*.*)\0*.*\0\0',
						LIB.FormatPath({ 'export/lover_backup/', PATH_TYPE.GLOBAL })
					)
					if szFilePath == '' then
						return
					end
					D.RestoreLover(szFilePath)
				end,
			}):AutoWidth():Pos('BOTTOMRIGHT')
			-- create lover
			nX = X + 10
			nY = nY + 36
			nX = ui:Append('Text', { text = _L['Mutual love friend Lv.6: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
			nX = ui:Append('WndComboBox', {
				x = nX + 5, y = nY, w = 200, h = 25,
				text = _L['- Select plz -'],
				menu = function() return D.GetLoverMenu(1) end,
			}):Pos('BOTTOMRIGHT')
			ui:Append('Text', { text = _L['(4-feets, with specific fireworks)'], x = nX + 5, y = nY })
			nX = X + 10
			nY = nY + 28
			nX = ui:Append('Text', { text = _L['Blind love friend Lv.2: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
			nX = ui:Append('WndComboBox', {
				x = nX + 5, y = nY, w = 200, h = 25,
				text = _L['- Select plz -'],
				menu = function() return D.GetLoverMenu(0) end,
			}):Pos('BOTTOMRIGHT')
			ui:Append('Text', { text = _L['(Online required, notify anonymous)'], x = nX + 5, y = nY })
		else
			-- sync social data
			Wnd.OpenWindow('SocialPanel')
			Wnd.CloseWindow('SocialPanel')
			-- show lover
			nX = X + 10
			nX = ui:Append('Text', { text = lover.szName, font = 19, x = nX, y = nY, r = 255, g = 128, b = 255 }):AutoWidth():Pos('BOTTOMRIGHT')
			local map = lover.bOnline and LIB.GetMapInfo(lover.dwMapID)
			if not IsEmpty(lover.szLoverTitle) then
				nX = ui:Append('Text', { text = '<' .. lover.szLoverTitle .. '>', x = nX, y = nY, font = 80, r = 255, g = 128, b = 255 }):AutoWidth():Pos('BOTTOMRIGHT')
			end
			if map and map.szName then
				ui:Append('Text', { text = '(' .. g_tStrings.STR_GUILD_ONLINE .. ': ' .. map.szName .. ')', font = 80, x = nX + 10, y = nY })
			else
				ui:Append('Text', { text = '(' .. g_tStrings.STR_GUILD_OFFLINE .. ')', font = 62, x = nX + 10, y = nY })
			end
			nX = X + 10
			nY = nY + 36
			nX = ui:Append('Text', { text = D.FormatLoverString('{$type}{$time}', lover), font = 2, x = nX, y = nY }):AutoWidth():Pos('BOTTOMRIGHT')
			if lover.nLoverType == 1 then
				nX = ui:Append('Text', {
					x = nX + 10, y = nY,
					text = _L['[Light firework]'],
					onclick = function()
						D.SetLover(lover.dwID, -1)
					end,
				}):AutoWidth():Pos('BOTTOMRIGHT')
			end
			nX = ui:Append('Text', { text = _L['[Break love]'], x = nX + 10, y = nY, onclick = D.RemoveLover }):AutoWidth():Pos('BOTTOMRIGHT')
			if lover.nLoverType == 1 then
				nX = ui:Append('Text', { text = _L['[Recovery]'], x = nX + 10, y = nY, onclick = D.FixLover }):AutoWidth():Pos('BOTTOMRIGHT')
				nX = ui:Append('Text', { text = _L['[Backup]'], x = nX + 10, y = nY, onclick = D.BackupLover }):AutoWidth():Pos('BOTTOMRIGHT')
			end
			ui:Append('WndCheckBox', {
				x = nX + 10, y = nY + 2,
				text = _L['Auto focus lover'],
				checked = MY_Love.bAutoFocus,
				oncheck = function(bChecked)
					MY_Love.bAutoFocus = bChecked
				end,
			})
			nY = nY + 10
		end
		-- local setting
		nX = X + 10
		nY = nY + 28
		nX = ui:Append('Text', { text = _L['Non-love display: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
		nX = ui:Append('WndEditBox', {
			x = nX + 5, y = nY, w = 198, h = 25,
			limit = 20, text = MY_Love.szNone,
			onchange = function(szText) MY_Love.szNone = szText end,
		}):Pos('BOTTOMRIGHT')
		ui:Append('WndCheckBox', {
			x = nX + 5, y = nY,
			text = _L['Enable quiet mode'],
			checked = MY_Love.bQuiet,
			oncheck = function(bChecked) MY_Love.bQuiet = bChecked end,
		})
		-- jabber
		nX = X + 10
		nY = nY + 28
		nX = ui:Append('Text', { text = _L['Quick to accost text: '], x = nX, y = nY }):Pos('BOTTOMRIGHT')
		ui:Append('WndEditBox', {
			x = nX + 5, y = nY, w = 340, h = 25,
			limit = 128, text = MY_Love.szJabber,
			onchange = function(szText) MY_Love.szJabber = szText end,
		})
		-- signature
		nX = X + 10
		nY = nY + 36
		nX = ui:Append('Text', { text = _L['Love signature: '], x = nX, y = nY, font = 27 }):Pos('BOTTOMRIGHT')
		ui:Append('WndEditBox', {
			x = nX + 5, y = nY, w = 340, h = 48,
			limit = 42,  multi = true,
			text = MY_Love.szSign,
			onchange = function(szText)
				MY_Love.szSign = LIB.ReplaceSensitiveWord(szText)
			end,
		})
		nY = nY + 54
	end
	ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, w = 200,
		text = _L['Enable player view panel hook'],
		checked = MY_Love.bHookPlayerView,
		oncheck = function(bChecked) MY_Love.bHookPlayerView = bChecked end,
	}):AutoWidth()
	nY = nY + 25
	ui:Append('WndCheckBox', {
		x = nX + 5, y = nY, w = 200,
		text = _L['Other view my lover without ask'],
		checked = MY_Love.bAutoReplyLover,
		oncheck = function(bChecked) MY_Love.bAutoReplyLover = bChecked end,
	}):AutoWidth()

	-- tips
	nY = nY + 28
	ui:Append('Text', { text = _L['Tips'], x = X, y = nY, font = 27 })
	nX = X + 10
	nY = nY + 35

	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['1. You can break love one-sided.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['2. Data was stored in official data segment.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['3. Please do not enable config async, that may cause data lose.'],
		}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['4. To recove lover data, please ask you lover click fix button.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['5. Lover must be toway friend, so delete friend will cause both side none-lover.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['6. Lover can see each other\'s location, delete friend can prevent this.'],
	}):AutoHeight():Height() + 3
	nY = nY + ui:Append('Text', {
		x = nX, y = nY, w = W - nX * 2, multiline = true, valign = 0,
		text = _L['7. Backup lover requires both online and teamed up, backup data can be used to restore data while server merge or player crossing server.'],
	}):AutoHeight():Height() + 3
	O.bPanelActive = true
end

-- deinit
function PS.OnPanelDeactive()
	O.bPanelActive = false
end

LIB.RegisterPanel(_L['Target'], 'MY_Love', _L['MY_Love'], 329, PS)
