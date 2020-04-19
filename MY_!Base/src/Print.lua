--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 系统输出
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
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil, modf = math.min, math.max, math.floor, math.ceil, math.modf
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()

-- 显示本地信息 LIB.Sysmsg(oTitle, oContent, eTheme)
--   LIB.Sysmsg({'Error!', wrap = true}, 'MY', CONSTANT.MSG_THEME.ERROR)
--   LIB.Sysmsg({'New message', r = 0, g = 0, b = 0, wrap = true}, 'MY')
--   LIB.Sysmsg({{'New message', r = 0, g = 0, b = 0, rich = false}, wrap = true}, 'MY')
--   LIB.Sysmsg('New message', {'MY', 'DB', r = 0, g = 0, b = 0})
-- 显示中央信息 LIB.Topmsg(oTitle, oContent, eTheme)
--   参见 LIB.Sysmsg 参数解释
do
local THEME_LIST = {
	-- [CONSTANT.MSG_THEME.NORMAL ] = { r = 255, g = 255, b =   0 },
	[CONSTANT.MSG_THEME.ERROR  ] = { r = 255, g =  86, b =  86 },
	[CONSTANT.MSG_THEME.WARNING] = { r = 255, g = 170, b = 170 },
	[CONSTANT.MSG_THEME.SUCCESS] = { r =   0, g = 255, b = 127 },
}
local function StringifySysmsgObject(aMsg, oContent, cfg, bTitle)
	local cfgContent = setmetatable({}, { __index = cfg })
	if IsTable(oContent) then
		cfgContent.rich, cfgContent.wrap = oContent.rich, oContent.wrap
		cfgContent.r, cfgContent.g, cfgContent.b, cfgContent.f = oContent.r, oContent.g, oContent.b, oContent.f
	else
		oContent = {oContent}
	end
	-- 格式化输出正文
	for _, v in ipairs(oContent) do
		local tContent, aPart = setmetatable(IsTable(v) and Clone(v) or {v}, { __index = cfgContent }), {}
		for _, oPart in ipairs(tContent) do
			insert(aPart, tostring(oPart))
		end
		if tContent.rich then
			insert(aMsg, concat(aPart))
		else
			local szContent = concat(aPart, bTitle and '][' or '')
			if szContent ~= '' and bTitle then
				szContent = '[' .. szContent .. ']'
			end
			insert(aMsg, GetFormatText(szContent, tContent.f, tContent.r, tContent.g, tContent.b))
		end
	end
	if cfgContent.wrap and not bTitle then
		insert(aMsg, GetFormatText('\n', cfgContent.f, cfgContent.r, cfgContent.g, cfgContent.b))
	end
end
local function OutputMessageEx(szType, szTheme, oTitle, oContent)
	local aMsg = {}
	-- 字体颜色优先级：单个节点 > 根节点定义 > 预设样式 > 频道设置
	-- 频道设置
	local cfg = {
		rich = false,
		wrap = true,
		f = GetMsgFont(szType),
	}
	cfg.r, cfg.g, cfg.b = GetMsgFontColor(szType)
	-- 预设样式
	local tTheme = szTheme and THEME_LIST[szTheme]
	if tTheme then
		cfg.r = tTheme.r or cfg.r
		cfg.g = tTheme.g or cfg.g
		cfg.b = tTheme.b or cfg.b
		cfg.f = tTheme.f or cfg.f
	end
	-- 根节点定义
	if IsTable(oContent) then
		cfg.r = oContent.r or cfg.r
		cfg.g = oContent.g or cfg.g
		cfg.b = oContent.b or cfg.b
		cfg.f = oContent.f or cfg.f
	end

	-- 处理数据
	StringifySysmsgObject(aMsg, oTitle, cfg, true)
	StringifySysmsgObject(aMsg, oContent, cfg, false)
	OutputMessage(szType, concat(aMsg), true)
end

-- 显示本地信息
function LIB.Sysmsg(...)
	local argc, oTitle, oContent, eTheme = select('#', ...), nil
	if argc == 1 then
		oContent = ...
		oTitle, eTheme = nil
	elseif argc == 2 then
		if IsNumber(select(2, ...)) then
			oContent, eTheme = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			eTheme = nil
		end
	elseif argc == 3 then
		oTitle, oContent, eTheme = ...
	end
	if not oTitle then
		oTitle = PACKET_INFO.SHORT_NAME
	end
	if not IsNumber(eTheme) then
		eTheme = CONSTANT.MSG_THEME.NORMAL
	end
	return OutputMessageEx('MSG_SYS', eTheme, oTitle, oContent)
end

-- 显示中央信息
function LIB.Topmsg(...)
	local argc, oTitle, oContent, eTheme = select('#', ...), nil
	if argc == 1 then
		oContent = ...
		oTitle, eTheme = nil
	elseif argc == 2 then
		if IsNumber(select(2, ...)) then
			oContent, eTheme = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			eTheme = nil
		end
	elseif argc == 3 then
		oTitle, oContent, eTheme = ...
	end
	if not oTitle then
		oTitle = CONSTANT.EMPTY_TABLE
	end
	if not IsNumber(eTheme) then
		eTheme = CONSTANT.MSG_THEME.NORMAL
	end
	local szType = eTheme == CONSTANT.MSG_THEME.ERROR
		and 'MSG_ANNOUNCE_RED'
		or 'MSG_ANNOUNCE_YELLOW'
	return OutputMessageEx(szType, eTheme, oTitle, oContent)
end
end

function LIB.Systopmsg(...)
	LIB.Topmsg(...)
	LIB.Sysmsg(...)
end

-- 输出一条密聊信息
function LIB.OutputWhisper(szMsg, szHead)
	szHead = szHead or PACKET_INFO.SHORT_NAME
	OutputMessage('MSG_WHISPER', '[' .. szHead .. ']' .. g_tStrings.STR_TALK_HEAD_WHISPER .. szMsg .. '\n')
	PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

-- Debug输出
-- (void)LIB.Debug(szTitle, oContent, nLevel)
-- szTitle  Debug头
-- oContent Debug信息
-- nLevel   Debug级别[低于当前设置值将不会输出]
function LIB.Debug(...)
	local argc, oTitle, oContent, nLevel, szTitle, szContent, eTheme = select('#', ...), nil
	if argc == 1 then
		oContent = ...
		oTitle, nLevel = nil
	elseif argc == 2 then
		if IsNumber(select(2, ...)) then
			oContent, nLevel = ...
			oTitle = nil
		else
			oTitle, oContent = ...
			nLevel = nil
		end
	elseif argc == 3 then
		oTitle, oContent, nLevel = ...
	end
	if not oTitle then
		oTitle = PACKET_INFO.NAME_SPACE .. '_DEBUG'
	end
	if not IsNumber(nLevel) then
		nLevel = DEBUG_LEVEL.WARNING
	end
	if IsTable(oTitle) then
		szTitle = concat(oTitle, '\n')
	else
		szTitle = tostring(oTitle)
	end
	if IsTable(oContent) then
		szContent = concat(oContent, '\n')
	else
		szContent = tostring(oContent)
	end
	if nLevel >= PACKET_INFO.DEBUG_LEVEL then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. szContent)
		if nLevel == DEBUG_LEVEL.LOG then
			eTheme = CONSTANT.MSG_THEME.SUCCESS
		elseif nLevel == DEBUG_LEVEL.WARNING then
			eTheme = CONSTANT.MSG_THEME.WARNING
		elseif nLevel == DEBUG_LEVEL.ERROR then
			eTheme = CONSTANT.MSG_THEME.ERROR
		else
			eTheme = CONSTANT.MSG_THEME.NORMAL
		end
		LIB.Sysmsg(szTitle, oContent, eTheme)
	elseif nLevel >= PACKET_INFO.DELOG_LEVEL then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. szContent)
	end
end
