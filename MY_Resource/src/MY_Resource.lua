--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 二进制资源
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
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
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Resource/lang/')
if not MY.AssertVersion('MY_Resource', _L['MY_Resource'], 0x2011800) then
	return
end

local C, D = {}, {}

C.aSound = {
	{
		type = _L['Wuer'],
		{ id = 2, file = 'WE/voice-52001.ogg' },
		{ id = 3, file = 'WE/voice-52002.ogg' },
		{ id = 4, file = 'WE/voice-52003.ogg' },
		{ id = 5, file = 'WE/voice-52004.ogg' },
		{ id = 6, file = 'WE/voice-52005.ogg' },
		{ id = 7, file = 'WE/voice-52006.ogg' },
		{ id = 8, file = 'WE/voice-52007.ogg' },
		{ id = 9, file = 'WE/voice-52008.ogg' },
		{ id = 10, file = 'WE/voice-52009.ogg' },
		{ id = 11, file = 'WE/voice-52010.ogg' },
		{ id = 12, file = 'WE/voice-52011.ogg' },
		{ id = 13, file = 'WE/voice-52012.ogg' },
		{ id = 14, file = 'WE/voice-52013.ogg' },
		{ id = 15, file = 'WE/voice-52014.ogg' },
		{ id = 16, file = 'WE/voice-52015.ogg' },
		{ id = 17, file = 'WE/voice-52016.ogg' },
		{ id = 18, file = 'WE/voice-52017.ogg' },
		{ id = 19, file = 'WE/voice-52018.ogg' },
		{ id = 20, file = 'WE/voice-52019.ogg' },
		{ id = 21, file = 'WE/voice-52020.ogg' },
		{ id = 22, file = 'WE/voice-52021.ogg' },
		{ id = 23, file = 'WE/voice-52023.ogg' },
		{ id = 24, file = 'WE/voice-52024.ogg' },
		{ id = 25, file = 'WE/voice-52025.ogg' },
		{ id = 26, file = 'WE/voice-52026.ogg' },
		{ id = 27, file = 'WE/voice-52027.ogg' },
		{ id = 28, file = 'WE/voice-52028.ogg' },
		{ id = 29, file = 'WE/voice-52029.ogg' },
		{ id = 30, file = 'WE/voice-52030.ogg' },
		{ id = 31, file = 'WE/voice-52031.ogg' },
		{ id = 32, file = 'WE/voice-52032.ogg' },
		{ id = 33, file = 'WE/voice-52033.ogg' },
		{ id = 34, file = 'WE/voice-52034.ogg' },
		{ id = 35, file = 'WE/voice-52035.ogg' },
		{ id = 36, file = 'WE/voice-53001.ogg' },
		{ id = 37, file = 'WE/voice-53002.ogg' },
		{ id = 38, file = 'WE/voice-53003.ogg' },
		{ id = 39, file = 'WE/voice-53004.ogg' },
		{ id = 40, file = 'WE/voice-53005.ogg' },
		{ id = 41, file = 'WE/voice-53006.ogg' },
		{ id = 42, file = 'WE/voice-53007.ogg' },
	},
	{
		type = _L['Xiaoman'],
		{ id = 1001, file = 'XM/buff-XMsound-00001.ogg' },
		{ id = 1002, file = 'XM/buff-XMsound-00002.ogg' },
		{ id = 1004, file = 'XM/buff-XMsound-00004.ogg' },
		{ id = 1005, file = 'XM/buff-XMsound-00005.ogg' },
		{ id = 1007, file = 'XM/buff-XMsound-00007.ogg' },
		{ id = 1008, file = 'XM/buff-XMsound-00008.ogg' },
		{ id = 1010, file = 'XM/buff-XMsound-000010.ogg' },
		{ id = 1011, file = 'XM/buff-XMsound-000011.ogg' },
		{ id = 1012, file = 'XM/buff-XMsound-000012.ogg' },
		{ id = 1013, file = 'XM/buff-XMsound-000013.ogg' },
		{ id = 1014, file = 'XM/buff-XMsound-000014.ogg' },
		{ id = 1015, file = 'XM/buff-XMsound-000015.ogg' },
		{ id = 1016, file = 'XM/buff-XMsound-000016.ogg' },
		{ id = 1017, file = 'XM/buff-XMsound-000017.ogg' },
		{ id = 1018, file = 'XM/buff-XMsound-000018.ogg' },
		{ id = 1019, file = 'XM/buff-XMsound-000019.ogg' },
		{ id = 1020, file = 'XM/buff-XMsound-000020.ogg' },
		{ id = 1021, file = 'XM/buff-XMsound-000021.ogg' },
		{ id = 1022, file = 'XM/buff-XMsound-000022.ogg' },
		{ id = 1023, file = 'XM/buff-XMsound-000023.ogg' },
		{ id = 1024, file = 'XM/buff-XMsound-000024.ogg' },
		{ id = 1025, file = 'XM/buff-XMsound-000025.ogg' },
		{ id = 1026, file = 'XM/buff-XMsound-000026.ogg' },
		{ id = 1027, file = 'XM/buff-XMsound-000027.ogg' },
		{ id = 1028, file = 'XM/buff-XMsound-000028.ogg' },
	},
	{
		type = _L['Chenwei'],
		{ id = 2001, file = 'CW/buff-CWsound-00001.ogg' },
		{ id = 2002, file = 'CW/buff-CWsound-00002.ogg' },
		{ id = 2003, file = 'CW/buff-CWsound-00003.ogg' },
		{ id = 2004, file = 'CW/buff-CWsound-00004.ogg' },
		{ id = 2005, file = 'CW/buff-CWsound-00005.ogg' },
		{ id = 2006, file = 'CW/buff-CWsound-00006.ogg' },
		{ id = 2007, file = 'CW/buff-CWsound-00007.ogg' },
		{ id = 2008, file = 'CW/buff-CWsound-00008.ogg' },
		{ id = 2009, file = 'CW/buff-CWsound-00009.ogg' },
		{ id = 2010, file = 'CW/buff-CWsound-00010.ogg' },
		{ id = 2011, file = 'CW/buff-CWsound-00011.ogg' },
		{ id = 2012, file = 'CW/buff-CWsound-00012.ogg' },
		{ id = 2013, file = 'CW/buff-CWsound-00013.ogg' },
		{ id = 2014, file = 'CW/buff-CWsound-00014.ogg' },
		{ id = 2015, file = 'CW/buff-CWsound-00015.ogg' },
		{ id = 2016, file = 'CW/buff-CWsound-00016.ogg' },
		{ id = 2017, file = 'CW/buff-CWsound-00017.ogg' },
		{ id = 2018, file = 'CW/buff-CWsound-00018.ogg' },
		{ id = 2019, file = 'CW/buff-CWsound-00019.ogg' },
		{ id = 2020, file = 'CW/buff-CWsound-00020.ogg' },
		{ id = 2021, file = 'CW/buff-CWsound-00021.ogg' },
		{ id = 2022, file = 'CW/buff-CWsound-00022.ogg' },
		{ id = 2023, file = 'CW/buff-CWsound-00023.ogg' },
		{ id = 2024, file = 'CW/buff-CWsound-00024.ogg' },
		{ id = 2025, file = 'CW/buff-CWsound-00025.ogg' },
		{ id = 2026, file = 'CW/buff-CWsound-00026.ogg' },
		{ id = 2027, file = 'CW/buff-CWsound-00027.ogg' },
		{ id = 2028, file = 'CW/buff-CWsound-00028.ogg' },
		{ id = 2029, file = 'CW/buff-CWsound-00029.ogg' },
		{ id = 2030, file = 'CW/buff-CWsound-00030.ogg' },
		{ id = 2031, file = 'CW/buff-CWsound-00031.ogg' },
		{ id = 2032, file = 'CW/buff-CWsound-00032.ogg' },
		{ id = 2033, file = 'CW/buff-CWsound-00033.ogg' },
		{ id = 2034, file = 'CW/buff-CWsound-00034.ogg' },
		{ id = 2035, file = 'CW/buff-CWsound-00035.ogg' },
		{ id = 2036, file = 'CW/buff-CWsound-00036.ogg' },
	},
	{
		type = _L['Yanshu'],
		{ id = 3001, file = 'YS/buff-YSsound-00001.ogg' },
		{ id = 3002, file = 'YS/buff-YSsound-00002.ogg' },
		{ id = 3003, file = 'YS/buff-YSsound-00003.ogg' },
		{ id = 3004, file = 'YS/buff-YSsound-00004.ogg' },
		{ id = 3005, file = 'YS/buff-YSsound-00005.ogg' },
		{ id = 3006, file = 'YS/buff-YSsound-00006.ogg' },
		{ id = 3007, file = 'YS/buff-YSsound-00007.ogg' },
		{ id = 3008, file = 'YS/buff-YSsound-00008.ogg' },
		{ id = 3009, file = 'YS/buff-YSsound-00009.ogg' },
		{ id = 3010, file = 'YS/buff-YSsound-00010.ogg' },
		{ id = 3011, file = 'YS/buff-YSsound-00011.ogg' },
		{ id = 3012, file = 'YS/buff-YSsound-00012.ogg' },
		{ id = 3013, file = 'YS/buff-YSsound-00013.ogg' },
		{ id = 3014, file = 'YS/buff-YSsound-00014.ogg' },
		{ id = 3015, file = 'YS/buff-YSsound-00015.ogg' },
		{ id = 3016, file = 'YS/buff-YSsound-00016.ogg' },
		{ id = 3017, file = 'YS/buff-YSsound-00017.ogg' },
		{ id = 3018, file = 'YS/buff-YSsound-00018.ogg' },
		{ id = 3019, file = 'YS/buff-YSsound-00019.ogg' },
		{ id = 3020, file = 'YS/buff-YSsound-00020.ogg' },
		{ id = 3021, file = 'YS/buff-YSsound-00021.ogg' },
		{ id = 3022, file = 'YS/buff-YSsound-00022.ogg' },
		{ id = 3023, file = 'YS/buff-YSsound-00023.ogg' },
		{ id = 3026, file = 'YS/buff-YSsound-00026.ogg' },
		{ id = 3024, file = 'YS/buff-YSsound-00024.ogg' },
		{ id = 3025, file = 'YS/buff-YSsound-00025.ogg' },
		{ id = 3026, file = 'YS/buff-YSsound-00026.ogg' },
		{ id = 3027, file = 'YS/buff-YSsound-00027.ogg' },
		{ id = 3028, file = 'YS/buff-YSsound-00028.ogg' },
		{ id = 3029, file = 'YS/buff-YSsound-00029.ogg' },
		{ id = 3030, file = 'YS/buff-YSsound-00030.ogg' },
		{ id = 3031, file = 'YS/buff-YSsound-00031.ogg' },
		{ id = 3032, file = 'YS/buff-YSsound-00032.ogg' },
		{ id = 3033, file = 'YS/buff-YSsound-00033.ogg' },
		{ id = 3034, file = 'YS/buff-YSsound-00034.ogg' },
		{ id = 3035, file = 'YS/buff-YSsound-00035.ogg' },
		{ id = 3036, file = 'YS/buff-YSsound-00036.ogg' },
		{ id = 3037, file = 'YS/buff-YSsound-00037.ogg' },
		{ id = 3038, file = 'YS/buff-YSsound-00038.ogg' },
		{ id = 3039, file = 'YS/buff-YSsound-00039.ogg' },
		{ id = 3040, file = 'YS/buff-YSsound-00040.ogg' },
		{ id = 3041, file = 'YS/buff-YSsound-00041.ogg' },
		{ id = 3042, file = 'YS/buff-YSsound-00042.ogg' },
	},
}

do
local root = MY.GetAddonInfo().szRoot .. 'MY_Resource/audio/'
local function GetSoundList(tSound)
	local t = {}
	if tSound.type then
		t.szType = tSound.type
	elseif tSound.id then
		t.dwID = tSound.id
		t.szName = _L[tSound.file]
		t.szPath = root .. tSound.file
	end
	for _, v in ipairs(tSound) do
		local t1 = GetSoundList(v)
		if t1 then
			insert(t, t1)
		end
	end
	return t
end

function D.GetSoundList()
	return GetSoundList(C.aSound)
end
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				GetSoundList = D.GetSoundList,
			},
		},
	},
}
MY_Resource = MY.GeneGlobalNS(settings)
end
