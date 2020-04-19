--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 记住动态技能栏上次位置
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
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_DynamicActionBarPos'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------

local D = {}
local O = {
	-- 设置项
	bEnable = true,
	tAnchors = {},
}
RegisterCustomData('MY_DynamicActionBarPos.bEnable')
RegisterCustomData('MY_DynamicActionBarPos.tAnchors')

local HOOK_FRAME_NAME = {
	'DynamicActionBar', -- 各种动态技能栏
	'IdentityDynActBar', -- 身份开启栏
}

local REMPOS_FRAME_TYPE = LIB.FlipObjectKV({
	'DynamicMutualBar',
	'DynamicActionBar2', -- 右下角特殊技能栏
	-- 'DynamicPetBar', -- 御兽技能栏
	-- 'DynamicCarrierBar', -- 射箭塔技能栏
	-- 'DashBoard',
	'IdentityDynActBar',
})

function D.UpdateAnchor(szName)
	local frame = UI.LookupFrame(szName)
	if not frame then
		return
	end
	local szType = D.GetFrameType(frame)
	if not szType or not REMPOS_FRAME_TYPE[szType] then
		return
	end
	local an = O.tAnchors[szType]
	if not an then
		return
	end
	if frame.__MY_SetPoint then
		frame:__MY_SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	else
		frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	end
	frame:CorrectPos()
end

function D.SaveAnchor(szName)
	local frame = UI.LookupFrame(szName)
	if not frame then
		return
	end
	local szType = D.GetFrameType(frame)
	if not szType or not REMPOS_FRAME_TYPE[szType] then
		return
	end
	O.tAnchors[szType] = GetFrameAnchor(frame, 'TOP_LEFT')
end

function D.GetFrameType(frame)
	if frame:GetName() == 'DynamicActionBar' then
		local el = frame:Lookup('Wnd_Left', 'Image_Leftbg')
		if el then
			local szImage, nFrame = el:GetImagePath()
			if szImage:lower() == 'ui\\image\\jianghu\\jianghu06.uitex' and nFrame == 1 then
				return 'DynamicActionBar2'
			end
		end
		if frame:Lookup('Wnd_Left', 'Handle_Pet/Box_Pet') then
			return 'DynamicPetBar'
		end
	end
	return frame:GetName()
end

function D.Hook(szName)
	local function OnFrameCreate(frame)
		if not frame then
			return
		end
		local szType = D.GetFrameType(frame)
		if not REMPOS_FRAME_TYPE[szType] then
			return
		end
		if not frame.__MY_OnFrameDragEnd then
			frame.__MY_OnFrameDragEnd = frame.OnFrameDragEnd
			frame.OnFrameDragEnd = function()
				D.SaveAnchor(szName)
			end
		end
		if not frame.__MY_SetPoint then
			frame.__MY_SetPoint = frame.SetPoint
			frame.SetPoint = function(...)
				if IsEmpty(O.tAnchors[szType]) then
					frame.__MY_SetPoint(...)
				end
			end
		end
	end
	LIB.RegisterFrameCreate(szName .. '.MY_DynamicActionBarPos', function()
		OnFrameCreate(arg0)
		D.UpdateAnchor(szName)
	end)
	LIB.RegisterFrameCreate('UI_SCALED.MY_DynamicActionBarPos__' .. szName, function()
		D.UpdateAnchor(szName)
	end)
	LIB.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE.MY_DynamicActionBarPos__' .. szName, function()
		D.SaveAnchor(szName)
	end)
	OnFrameCreate(UI.LookupFrame(szName))
end

function D.Unhook(szName)
	local frame = UI.LookupFrame(szName)
	if frame then
		if frame.__MY_OnFrameDragEnd then
			frame.OnFrameDragEnd = frame.__MY_OnFrameDragEnd
			frame.__MY_OnFrameDragEnd = nil
		end
		if frame.__MY_SetPoint then
			frame.SetPoint = frame.__MY_SetPoint
			frame.__MY_SetPoint = nil
		end
	end
	LIB.RegisterFrameCreate(szName .. '.MY_DynamicActionBarPos', false)
	LIB.RegisterFrameCreate('UI_SCALED.MY_DynamicActionBarPos__' .. szName, false)
	LIB.RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE.MY_DynamicActionBarPos__' .. szName, false)
end

function D.CheckEnable()
	for _, szName in ipairs(HOOK_FRAME_NAME) do
		if O.bEnable then
			D.Hook(szName)
		else
			D.Unhook(szName)
		end
	end
end

LIB.RegisterReload('MY_DynamicActionBarPos', function()
	for _, szName in ipairs(HOOK_FRAME_NAME) do
		D.Unhook(szName)
	end
end)
LIB.RegisterInit('MY_DynamicActionBarPos', D.CheckEnable)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y)
	ui:Append('WndCheckBox', {
		x = x, y = y, w = 130,
		text = _L['Restore dynamic action bar pos'],
		checked = MY_DynamicActionBarPos.bEnable,
		oncheck = function()
			MY_DynamicActionBarPos.bEnable = not MY_DynamicActionBarPos.bEnable
		end,
	}):AutoWidth()
	y = y + 25
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
				tAnchors = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable = true,
				tAnchors = true,
			},
			triggers = {
				bEnable = D.CheckEnable,
			},
			root = O,
		},
	},
}
MY_DynamicActionBarPos = LIB.GeneGlobalNS(settings)
end
