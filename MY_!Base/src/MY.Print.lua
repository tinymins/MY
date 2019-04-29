--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 系统输出
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, clone, empty, ipairs_r = LIB.var2str, LIB.str2var, LIB.clone, LIB.empty, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetPatch, ApplyPatch = LIB.GetPatch, LIB.ApplyPatch
local Get, Set, RandomChild, GetTraceback = LIB.Get, LIB.Set, LIB.RandomChild, LIB.GetTraceback
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()

-- 显示本地信息
-- LIB.Sysmsg(oContent, oTitle, szType)
-- LIB.Sysmsg({'Error!', wrap = true}, 'MY', 'MSG_SYS.ERROR')
-- LIB.Sysmsg({'New message', r = 0, g = 0, b = 0, wrap = true}, 'MY')
-- LIB.Sysmsg({{'New message', r = 0, g = 0, b = 0, rich = false}, wrap = true}, 'MY')
-- LIB.Sysmsg('New message', {'MY', 'DB', r = 0, g = 0, b = 0})
do local THEME_LIST = {
	['ERROR'] = { r = 255, g = 0, b = 0 },
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
		local tContent, aPart = setmetatable(IsTable(v) and clone(v) or {v}, { __index = cfgContent }), {}
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
function LIB.Sysmsg(oContent, oTitle, szType)
	if not szType then
		szType = 'MSG_SYS'
	end
	if not oTitle then
		oTitle = LIB.GetAddonInfo().szShortName
	end
	local nPos, szTheme = (StringFindW(szType, '.'))
	if nPos then
		szTheme = sub(szType, nPos + 1)
		szType = sub(szType, 1, nPos - 1)
	end
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
end

-- 没有头的中央信息 也可以用于系统信息
function LIB.Topmsg(szText, szType)
	LIB.Sysmsg(szText, {}, szType or 'MSG_ANNOUNCE_YELLOW')
end

-- 输出一条密聊信息
function LIB.OutputWhisper(szMsg, szHead)
	szHead = szHead or LIB.GetAddonInfo().szShortName
	OutputMessage('MSG_WHISPER', '[' .. szHead .. ']' .. g_tStrings.STR_TALK_HEAD_WHISPER .. szMsg .. '\n')
	PlaySound(SOUND.UI_SOUND, g_sound.Whisper)
end

-- Debug输出
-- (void)LIB.Debug(oContent, szTitle, nLevel)
-- oContent Debug信息
-- szTitle  Debug头
-- nLevel   Debug级别[低于当前设置值将不会输出]
function LIB.Debug(oContent, szTitle, nLevel)
	if not IsNumber(nLevel) then
		nLevel = DEBUG_LEVEL.WARNING
	end
	if not IsString(szTitle) then
		szTitle = 'MY DEBUG'
	end
	if not IsTable(oContent) then
		oContent = { oContent }
	end
	if not oContent.r then
		if nLevel == DEBUG_LEVEL.LOG then
			oContent.r, oContent.g, oContent.b =   0, 255, 127
		elseif nLevel == DEBUG_LEVEL.WARNING then
			oContent.r, oContent.g, oContent.b = 255, 170, 170
		elseif nLevel == DEBUG_LEVEL.ERROR then
			oContent.r, oContent.g, oContent.b = 255,  86,  86
		else
			oContent.r, oContent.g, oContent.b = 255, 255, 0
		end
	end
	if nLevel >= LIB.GetAddonInfo().nDebugLevel then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. concat(oContent, '\n'))
		LIB.Sysmsg(oContent, szTitle)
	elseif nLevel >= LIB.GetAddonInfo().nLogLevel then
		Log('[DEBUG_LEVEL][LEVEL_' .. nLevel .. '][' .. szTitle .. ']' .. concat(oContent, '\n'))
	end
end
