--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 好友助手
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
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^4.0.0') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_SocialRequest.ini'
local O = LIB.CreateUserSettingsModule('MY_SocialRequest', _L['MY_TeamTools'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_SocialRequest'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

local REQUEST_MSG = {}
local REQUEST_LIST = {}

for k, v in pairs({
	['ADD_FRIEND_FELLOWSHIP'] = g_tStrings.STR_FRIEND_NEED_ADD_FRIEND_FELLOWSHIP,
	['ADD_FRIEND'           ] = g_tStrings.STR_FRIEND_NEED_ADD_FRIEND,
}) do
	REQUEST_MSG[k] = v:gsub('<D0>', '^(.-)')
end

function D.GetMenu()
	local menu = {
		szOption = _L['MY_SocialRequest'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = MY_SocialRequest.bEnable,
			fnAction = function()
				MY_SocialRequest.bEnable = not MY_SocialRequest.bEnable
			end,
		},
	}
	return menu
end

function D.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Accept' then
		D.AcceptRequest(this:GetParent().info)
	elseif name == 'Btn_Refuse' then
		D.RefuseRequest(this:GetParent().info)
	end
end

function D.OnRButtonClick()
	if this.info then
		PopupMenu(LIB.GetTargetContextMenu(TARGET.PLAYER, this.info.szName, this.info.dwID))
	end
end

function D.OnMouseEnter()
	if this.info then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szTip = GetFormatText(this.info.szDesc)
		OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	end
end

function D.OnMouseLeave()
	if this.info then
		HideTip()
	end
end

function D.AcceptRequest(info)
	REQUEST_LIST[info.szName] = nil
	UI.RemoveRequest('MY_SocialRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	REQUEST_LIST[info.szName] = nil
	UI.RemoveRequest('MY_SocialRequest', info.szName)
	info.fnRefuse()
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	if not O.bEnable or not frame or not frame:IsValid() then
		return
	end
	if szMsgName == 'NeedAddFriend' then
		local hContent = frame:Lookup('Wnd_All', 'Handle_Message')
		local txt = hContent and hContent:Lookup(0)
		local szMsg, szType, szName = txt and txt:GetType() == 'Text' and txt:GetText()
		for k, szMsgTpl in pairs(REQUEST_MSG) do
			szName = szMsg:match(szMsgTpl)
			if szName then
				szType = k
				break
			end
		end
		if szType then
			local fnAccept = Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
			local fnRefuse = Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
			if fnAccept and fnRefuse then
				local info = REQUEST_LIST[szName]
				if not info then
					info = {}
					REQUEST_LIST[szName] = info
				end
				info.szType = szType
				info.szName = szName
				info.szDesc = szMsg
				info.fnAccept = function()
					REQUEST_LIST[szName] = nil
					Call(fnAccept)
				end
				info.fnRefuse = function()
					REQUEST_LIST[szName] = nil
					Call(fnRefuse)
				end
				-- 获取dwID
				local tar = LIB.GetObject(TARGET.PLAYER, szName)
				if not info.dwID and tar then
					info.dwID = tar.dwID
				end
				if not info.dwID and MY_Farbnamen and MY_Farbnamen.Get then
					local data = MY_Farbnamen.Get(szName)
					if data then
						info.dwID = data.dwID
					end
				end
				UI.ReplaceRequest('MY_SocialRequest', info.szName, info)
				-- 关闭对话框
				frame.fnAutoClose = nil
				frame.fnCancelAction = nil
				frame.szCloseSound = nil
				Wnd.CloseWindow(frame)
			end
		end
	end
end

LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN.MY_SocialRequest' , D.OnMessageBoxOpen)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	x = x + ui:Append('WndComboBox', {
		x = x, y = y, w = 120,
		text = _L['MY_SocialRequest'],
		menu = D.GetMenu,
		tip = _L['Optimize social friend request'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
	}):Width() + 5

	x = X
	y = y + 20
	return x, y
end

-- Global exports
do
local settings = {
	name = 'MY_SocialRequest',
	exports = {
		{
			fields = {
				'bEnable',
				'OnPanelActivePartial',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_SocialRequest = LIB.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 注册邀请
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'FromIconID',
	nIconFrame = 2118,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(INI_PATH, 'Wnd_Request')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('', 'Text_Name'):SetText(info.szName)

	local ui = UI(wnd)
	ui:Append('WndButton', {
		name = 'Btn_Accept',
		x = 326, y = 9, w = 60, h = 34,
		buttonstyle = 'FLAT',
		text = _L['Add'],
		onclick = D.OnLButtonClick,
	})
	ui:Append('WndButton', {
		name = 'Btn_Refuse',
		x = 393, y = 9, w = 60, h = 34,
		buttonstyle = 'FLAT',
		text = _L['Ignore'],
		onclick = D.OnLButtonClick,
	})

	return wnd
end

function R.GetTip(info)
	return GetFormatText(info.szDesc)
end

function R.GetMenu()
	return D.GetMenu()
end

function R.OnClear()
	REQUEST_LIST = {}
end

UI.RegisterRequest('MY_SocialRequest', R)
