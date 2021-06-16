--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 界面工具库
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local LIB = Boilerplate
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
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SaveCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')

function UI.GetTreePath(raw)
	local tTreePath = {}
	if IsTable(raw) and raw.GetTreePath then
		insert(tTreePath, (raw:GetTreePath()):sub(1, -2))
		while(raw and raw:GetType():sub(1, 3) ~= 'Wnd') do
			local szName = raw:GetName()
			if not szName or szName == '' then
				insert(tTreePath, 2, raw:GetIndex())
			else
				insert(tTreePath, 2, szName)
			end
			raw = raw:GetParent()
		end
	else
		insert(tTreePath, tostring(raw))
	end
	return concat(tTreePath, '/')
end

do
local ui, cache
function UI.GetTempElement(szType)
	if not IsString(szType) then
		return
	end
	local szKey = nil
	local nPos = StringFindW(szType, '.')
	if nPos then
		szKey = sub(szType, nPos + 1)
		szType = sub(szType, 1, nPos - 1)
	end
	if not IsString(szKey) then
		szKey = 'Default'
	end
	if not cache or not ui or ui:Count() == 0 then
		cache = {}
		ui = UI.CreateFrame(NSFormatString('{$NS}#TempElement'), { empty = true }):Hide()
	end
	local szName = szType .. '_' .. szKey
	local raw = cache[szName]
	if not raw then
		raw = ui:Append(szType, {
			name = szName,
		})[1]
		cache[szName] = raw
	end
	return raw
end
end

function UI.ScrollIntoView(el, scrollY, nOffsetY, scrollX, nOffsetX)
	local elParent, nParentW, nParentH = el:GetParent()
	local nX, nY = el:GetAbsX() - elParent:GetAbsX(), el:GetAbsY() - elParent:GetAbsY()
	if elParent:GetType() == 'WndContainer' then
		nParentW, nParentH = elParent:GetAllContentSize()
	else
		nParentW, nParentH = elParent:GetAllItemSize()
	end
	if nOffsetY then
		nY = nY + nOffsetY
	end
	if scrollY then
		scrollY:SetScrollPos(nY / nParentH * scrollY:GetStepCount())
	end
	if nOffsetX then
		nX = nX + nOffsetX
	end
	if scrollX then
		scrollX:SetScrollPos(nX / nParentW * scrollX:GetStepCount())
	end
end

function UI.LookupFrame(szName)
	for _, v in ipairs(UI.LAYER_LIST) do
		local frame = Station.Lookup(v .. '/' .. szName)
		if frame then
			return frame
		end
	end
end

-- FORMAT_WMSG_RET
function UI.FormatWMsgRet(stop, callFrame)
	local ret = 0
	if stop then
		ret = ret + 1 --01
	end
	if callFrame then
		ret = ret + 2 --10
	end
	return ret
end

UI.UpdateItemInfoBoxObject = _G.UpdateItemInfoBoxObject or UpdataItemInfoBoxObject
