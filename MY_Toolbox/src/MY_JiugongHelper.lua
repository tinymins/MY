--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 试炼之地九宫助手
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	bEnable = true,
}
RegisterCustomData('MY_JiugongHelper.bEnable')

function D.Apply()
	LIB.RegisterEvent('OPEN_WINDOW.JIUGONG_HELPER', function(event)
		if LIB.IsShieldedVersion('MY_JiugongHelper') then
			return
		end
		-- 确定当前对话对象是醉逍遥（18707）
		local target = GetTargetHandle(GetClientPlayer().GetTarget())
		if target and target.dwTemplateID ~= 18707 then
			return
		end
		local szText = arg1
		-- 匹配字符串
		gsub(szText, '<T1916><(T%d+)><T1926><(T%d+)><T1928><(T%d+)><T1924>.+<T1918><(T%d+)><T1931><(T%d+)><T1933><(T%d+)><T1935>.+<T1920><(T%d+)><T1937><(T%d+)><T1938><(T%d+)><T1939>', function(n1,n2,n3,n4,n5,n6,n7,n8,n9)
			local tNumList = {
				T1925 = 1, T1927 = 2, T1929 = 3,
				T1930 = 4, T1932 = 5, T1934 = 6,
				T1936 = 7, T1922 = 8, T1923 = 9,
				T1940 = false,
			}
			local tDefaultSolution = {
				{8,1,6,3,5,7,4,9,2},
				{6,1,8,7,5,3,2,9,4},
				{4,9,2,3,5,7,8,1,6},
				{2,9,4,7,5,3,6,1,8},
				{6,7,2,1,5,9,8,3,4},
				{8,3,4,1,5,9,6,7,2},
				{2,7,6,9,5,1,4,3,8},
				{4,3,8,9,5,1,2,7,6},
			}

			n1,n2,n3,n4,n5,n6,n7,n8,n9 = tNumList[n1],tNumList[n2],tNumList[n3],tNumList[n4],tNumList[n5],tNumList[n6],tNumList[n7],tNumList[n8],tNumList[n9]
			local tQuestion = {n1,n2,n3,n4,n5,n6,n7,n8,n9}
			local tSolution
			for _, solution in ipairs(tDefaultSolution) do
				local bNotMatch = false
				for i, v in ipairs(solution) do
					if tQuestion[i] and tQuestion[i] ~= v then
						bNotMatch = true
						break
					end
				end
				if not bNotMatch then
					tSolution = solution
					break
				end
			end
			local szText = _L['The kill sequence is: ']
			if tSolution then
				for i, v in ipairs(tQuestion) do
					if not tQuestion[i] then
						szText = szText .. NumberToChinese(tSolution[i]) .. ' '
					end
				end
			else
				szText = szText .. _L['Failed to calc.']
			end
			LIB.Sysmsg(szText)
			OutputWarningMessage('MSG_WARNING_RED', szText, 10)
		end)
	end)
end
LIB.RegisterInit('MY_JiugongHelper', D.Apply)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	return x, y
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				bEnable = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
			},
			triggers = {
				bEnable = D.Apply,
			},
			root = O,
		},
	},
}
MY_JiugongHelper = LIB.GeneGlobalNS(settings)
end
