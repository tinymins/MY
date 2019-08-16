--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 试炼之地九宫助手
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local HUGE, PI, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, wstring.find, StringReplaceW
local GetTime, GetLogicFrameCount, GetCurrentTime = GetTime, GetLogicFrameCount, GetCurrentTime
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE, PACKET_INFO = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE, LIB.PACKET_INFO
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local ipairs_r, count_c, pairs_c, ipairs_c = LIB.ipairs_r, LIB.count_c, LIB.pairs_c, LIB.ipairs_c
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(PACKET_INFO.ROOT..'MY_Toolbox/lang/')
if not LIB.AssertVersion('MY_Toolbox', _L['MY_Toolbox'], 0x2011800) then
	return
end

local D = {}
local O = {
	bEnable = true,
}
RegisterCustomData('MY_JiugongHelper.bEnable')

function D.Apply()
	LIB.RegisterEvent('OPEN_WINDOW.JIUGONG_HELPER', function(event)
		if LIB.IsShieldedVersion() then
			return
		end
		-- 确定当前对话对象是醉逍遥（18707）
		local target = GetTargetHandle(GetClientPlayer().GetTarget())
		if target and target.dwTemplateID ~= 18707 then
			return
		end
		local szText = arg1
		-- 匹配字符串
		string.gsub(szText, '<T1916><(T%d+)><T1926><(T%d+)><T1928><(T%d+)><T1924>.+<T1918><(T%d+)><T1931><(T%d+)><T1933><(T%d+)><T1935>.+<T1920><(T%d+)><T1937><(T%d+)><T1938><(T%d+)><T1939>', function(n1,n2,n3,n4,n5,n6,n7,n8,n9)
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
				szText = szText .. _L['failed to calc.']
			end
			LIB.Sysmsg({szText})
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
