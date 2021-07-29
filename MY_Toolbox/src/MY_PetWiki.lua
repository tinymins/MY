--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 宠物百科
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_PetWiki', _L['General'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nW = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Number,
		xDefaultValue = 850,
	},
	nH = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Toolbox'],
		xSchema = Schema.Number,
		xDefaultValue = 610,
	},
})
local D = {}

function D.OnWebSizeChange()
	O.nW, O.nH = this:GetSize()
end

function D.Open(dwPetIndex)
	local tPet = Table_GetFellowPet(dwPetIndex)
	if not tPet then
		return
	end
	local szURL = 'https://page.j3cx.com/pet/' .. dwPetIndex .. '?'
		.. LIB.EncodePostData(LIB.UrlEncode({
			l = AnsiToUTF8(GLOBAL.GAME_LANG),
			L = AnsiToUTF8(GLOBAL.GAME_EDITION),
			player = AnsiToUTF8(GetUserRoleName()),
		}))
	local szKey = 'PetsWiki_' .. dwPetIndex
	local szTitle = tPet.szName .. ' - ' .. LIB.XMLGetPureText(tPet.szDesc)
	szKey = UI.OpenBrowser(szURL, {
		key = szKey,
		title = szTitle,
		w = O.nW, h = O.nH,
		readonly = true,
	})
	UI(UI.LookupBrowser(szKey)):Size(D.OnWebSizeChange)
end

function D.OnPetItemLButtonClick()
	local name = this:GetName()
	if name == 'Handle_Prefer' then
		if O.bEnable and this.tPet and not IsCtrlKeyDown() and not IsAltKeyDown() and this:Lookup('Image_PreferSelect'):IsVisible() then
			D.Open(this.tPet.dwPetIndex)
			return
		end
	elseif name == 'Box_PetItem' or name:find('Box_MedalPet_') then
		if O.bEnable and this.tPet and not IsCtrlKeyDown() and not IsAltKeyDown() and this:IsObjectSelected() then
			D.Open(this.tPet.dwPetIndex)
			return
		end
	end
	return UI.FormatWMsgRet(false, true)
end

function D.OnPetAppendItem(res, hList)
	local hItem = res[1]
	if not hItem then
		return
	end
	LIB.DelayCall(function()
		local boxPet = hItem:IsValid() and hItem:Lookup('Box_PetItem')
		if not boxPet then
			return
		end
		boxPet:RegisterEvent(ITEM_EVENT.LBUTTONCLICK)
		UnhookTableFunc(boxPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick)
		HookTableFunc(boxPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick)
	end)
end

function D.OnPetAppendList(res, hTotal)
	local hGroup = res[1]
	if not hGroup then
		return
	end
	local hList = hGroup and hGroup:Lookup((hGroup:GetName():gsub('Handle_Pets', 'Handle_List')))
	if not hList then
		return
	end
	for i = 0, hList:GetItemCount() - 1 do
		D.OnPetAppendItem({hList:Lookup(i)}, hList)
	end
	UnhookTableFunc(hList, 'AppendItemFromIni', D.OnPetAppendItem)
	HookTableFunc(hList, 'AppendItemFromIni', D.OnPetAppendItem, { bAfterOrigin = true, bPassReturn = true })
end

function D.HookPetHandle(h)
	if not h then
		return
	end
	for i = 0, h:GetItemCount() - 1 do
		D.OnPetAppendList({h:Lookup(i)}, h)
	end
	UnhookTableFunc(h, 'AppendItemFromIni', D.OnPetAppendList)
	HookTableFunc(h, 'AppendItemFromIni', D.OnPetAppendList, { bAfterOrigin = true, bPassReturn = true })
end

function D.HookPetFrame(frame)
	local hMedalPets = frame:Lookup('PageSet_All/Page_MedalCollected/Wnd_MedalCollect', 'Handle_MedalPets')
	if hMedalPets then
		for nNum = 1, 10 do
			local hMedal = hMedalPets:Lookup('Handle_MedalPet_' .. nNum)
			if hMedal then
				for nIndex = 1, nNum do
					local boxPet = hMedal:Lookup('Box_MedalPet_' .. nNum .. '_' .. nIndex)
					if boxPet then
						boxPet:RegisterEvent(ITEM_EVENT.LBUTTONCLICK)
						UnhookTableFunc(boxPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick)
						HookTableFunc(boxPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick, { bAfterOrigin = true, bPassReturn = true, bHookReturn = true })
					end
				end
			end
		end
	end
	local hPreferList = frame:Lookup('PageSet_All/Page_MyPet/WndScroll_Pets/WndContainer_Pets/Wnd_Prefer', '')
	if hPreferList then
		for i = 0, hPreferList:GetItemCount() - 1 do
			local hPet = hPreferList:Lookup(i)
			hPet:RegisterEvent(ITEM_EVENT.LBUTTONCLICK)
			UnhookTableFunc(hPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick)
			HookTableFunc(hPet, 'OnItemLButtonClick', D.OnPetItemLButtonClick, { bAfterOrigin = true, bPassReturn = true, bHookReturn = true })
		end
	end
	D.HookPetHandle(frame:Lookup('PageSet_All/Page_MyPet/WndScroll_Pets/WndContainer_Pets/Wnd_Pets', ''))
end

LIB.RegisterInit('MY_PetWiki', function()
	local frame = Station.Lookup('Normal/NewPet')
	if not frame then
		return
	end
	D.HookPetFrame(frame)
end)

LIB.RegisterFrameCreate('NewPet', 'MY_PetWiki', function(name, frame)
	D.HookPetFrame(frame)
end)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Pet wiki'],
		tip = _L['Click icon on pet panel to view pet wiki'],
		tippostype = UI.TIP_POSITION.BOTTOM_TOP,
		checked = MY_PetWiki.bEnable,
		oncheck = function(bChecked)
			MY_PetWiki.bEnable = bChecked
		end,
	}):Width() + 5
	return x, y
end

-- Global exports
do
local settings = {
	name = 'MY_PetWiki',
	exports = {
		{
			fields = {
				'Open',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'nW',
				'nH',
			},
			root = O,
		},
	},
}
MY_PetWiki = LIB.CreateModule(settings)
end
