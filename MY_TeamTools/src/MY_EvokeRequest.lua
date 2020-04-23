--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : ÕÙÇëÖúÊÖ
-- @author   : ÜøÒÁ @Ë«ÃÎÕò @×··çõæÓ°
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
local mod, modf, pow, sqrt = math.mod or math.fmod, math.modf, math.pow, math.sqrt
local sin, cos, tan, atan, atan2 = math.sin, math.cos, math.tan, math.atan, math.atan2
local insert, remove, concat, unpack = table.insert, table.remove, table.concat, table.unpack or unpack
local pack, sort, getn = table.pack or function(...) return {...} end, table.sort, table.getn
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
-- lib apis caching
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local wsub, count_c = LIB.wsub, LIB.count_c
local pairs_c, ipairs_c, ipairs_r = LIB.pairs_c, LIB.ipairs_c, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local D = {}
local PR_INI_PATH = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_EvokeRequest.ini'
local PR_EVOKE_MSG = {
	['A2M'] = g_tStrings.MENTOR_APPRENTICE_EVOKE_MSG,
	['M2A'] = g_tStrings.MENTOR_MENTOR_EVOKE_MSG,
	['FRIEND'] = g_tStrings.MENTOR_FRIEND_EVOKE_MSG,
	['TONG'] = g_tStrings.MENTOR_TONG_EVOKE_MSG,
	['TONGALL'] = g_tStrings.MENTOR_TONGALL_EVOKE_MSG,
	['TONGALLS'] = g_tStrings.MENTOR_TONGALLS_EVOKE_MSG,
	['ZUIYUAN'] = g_tStrings.MENTOR_QINGMINGJIE_ZUIYUAN_EVOKE_MSG_MSG,
	['PARTY'] = g_tStrings.MENTOR_PARTY_EVOKE_MSG,
}
local EVOKE_LIST = {}

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
	EVOKE_LIST[info.szName] = nil
	MY_Request.Remove('MY_EvokeRequest', info.szName)
	info.fnAccept()
end

function D.RefuseRequest(info)
	EVOKE_LIST[info.szName] = nil
	MY_Request.Remove('MY_EvokeRequest', info.szName)
	info.fnRefuse()
end

function D.OnMessageBoxOpen()
	local szMsgName, frame = arg0, arg1
	if not frame or not frame:IsValid() then
		return
	end
	if szMsgName:find('^A_E_M_') then
		local szName = szMsgName:sub(7)
		local hContent = frame:Lookup('Wnd_All', 'Handle_Message')
		local txt = hContent and hContent:Lookup(0)
		local szMsg, szType = txt and txt:GetType() == 'Text' and txt:GetText()
		for k, szMsgTpl in pairs(PR_EVOKE_MSG) do
			if FormatString(szMsgTpl, szName) == szMsg then
				szType = k
				break
			end
		end
		if szType then
			local fnAccept = Get(frame:Lookup('Wnd_All/Btn_Option1'), 'fnAction')
			local fnRefuse = Get(frame:Lookup('Wnd_All/Btn_Option2'), 'fnAction')
			if fnAccept and fnRefuse then
				local info = EVOKE_LIST[szName]
				if not info then
					info = {}
					EVOKE_LIST[szName] = info
				end
				info.szName = szName
				info.szDesc = szMsg
				info.fnAccept = function()
					EVOKE_LIST[szName] = nil
					Call(fnAccept)
				end
				info.fnRefuse = function()
					EVOKE_LIST[szName] = nil
					Call(fnRefuse)
				end
				-- »ñÈ¡dwID
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
				MY_Request.Replace('MY_EvokeRequest', info.szName, info)
				-- ¹Ø±Õ¶Ô»°¿ò
				frame.fnAutoClose = nil
				frame.fnCancelAction = nil
				frame.szCloseSound = nil
				Wnd.CloseWindow(frame)
			end
		end
	end
end

LIB.RegisterEvent('ON_MESSAGE_BOX_OPEN.MY_EvokeRequest' , D.OnMessageBoxOpen)

--------------------------------------------------------------------------------
-- ×¢²áÑûÇë
--------------------------------------------------------------------------------
local R = {
	szIconUITex = 'ui\\Image\\button\\SystemButton.UITex',
	nIconFrame = 55,
}

function R.Drawer(container, info)
	local wnd = container:AppendContentFromIni(PR_INI_PATH, 'Wnd_EvokeRequest')
	wnd.info = info
	wnd.OnMouseEnter = D.OnMouseEnter
	wnd.OnMouseLeave = D.OnMouseLeave
	wnd:Lookup('', 'Text_Name'):SetText(info.szName)
	wnd:Lookup('Btn_Accept').OnLButtonClick = D.OnLButtonClick
	wnd:Lookup('Btn_Accept', 'Text_Accept'):SetText(g_tStrings.STR_ACCEPT)
	wnd:Lookup('Btn_Refuse').OnLButtonClick = D.OnLButtonClick
	wnd:Lookup('Btn_Refuse', 'Text_Refuse'):SetText(g_tStrings.STR_REFUSE)
	return wnd
end

function R.GetTip(info)
	return GetFormatText(info.szDesc)
end

function R.OnClear()
	EVOKE_LIST = {}
end

MY_Request.Register('MY_EvokeRequest', R)
