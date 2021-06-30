--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 五毒仙王蛊鼎显示
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
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Force'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^5.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_ForceGuding', _L['Target'], {
	bEnable = { -- 总开关
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoSay = { -- 摆鼎后自动说话
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	szSay = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.String,
		xDefaultValue = _L['I have put the GUDING, hurry to eat if you lack of mana. *la la la*'],
	},
	color = { -- 名称颜色，默认绿色
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 255, 0, 128 },
	},
	bUseMana = { -- 路过时自动吃毒锅
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nManaMp = { -- 自动吃的 MP 百分比
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Number,
		xDefaultValue = 80,
	},
	nManaHp = { -- 自动吃的 HP 百分比
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = Schema.Number,
		xDefaultValue = 80,
	},
})
local D = {
	nMaxDelay = 500, -- 释放和出现的最大时差，单位毫秒
	nMaxTime = 60000, -- 存在的最大时间，单位毫秒
	dwSkillID = 2234,
	dwTemplateID = 2418,
	tList = {}, -- 显示记录 (#ID => nTime)
	tCast = {}, -- 技能释放记录
	nFrame = 0, -- 上次自动吃鼎、绘制帧次
}

--[[#DEBUG BEGIN]]
-- debug
function D.Debug(szMsg)
	LIB.Debug(_L['MY_ForceGuding'], szMsg, DEBUG_LEVEL.LOG)
end
--[[#DEBUG END]]

-- add to list
function D.AddToList(tar, dwCaster, dwTime, szEvent)
	D.tList[tar.dwID] = { dwCaster = dwCaster, dwTime = dwTime }
	-- bg notify
	local me = GetClientPlayer()
	if szEvent == 'DO_SKILL_CAST' and me.IsInParty() then
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GUDING_NOTIFY', {tar.dwID, dwCaster}, true)
	end
	if O.bAutoSay and me.dwID == dwCaster then
		local nChannel = PLAYER_TALK_CHANNEL.RAID
		if not me.IsInParty() then
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		end
		LIB.SendChat(nChannel, O.szSay)
	end
end

-- remove record
function D.RemoveFromList(dwID)
	D.tList[dwID] = nil
end

-------------------------------------
-- 事件处理函数
-------------------------------------
-- skill cast log
function D.OnSkillCast(dwCaster, dwSkillID, dwLevel, szEvent)
	local player = GetPlayer(dwCaster)
	if player and dwSkillID == D.dwSkillID and (dwCaster == UI_GetClientPlayerID() or LIB.IsParty(dwCaster)) then
		insert(D.tCast, { dwCaster = dwCaster, dwTime = GetTime(), szEvent = szEvent })
		--[[#DEBUG BEGIN]]
		D.Debug('[' .. player.szName .. '] cast [' .. LIB.GetSkillName(dwSkillID, dwLevel) .. '#' .. szEvent .. ']')
		--[[#DEBUG END]]
	end
end

-- doodad enter
function D.OnDoodadEnter()
	local tar = GetDoodad(arg0)
	if not tar or D.tList[arg0] or tar.dwTemplateID ~= D.dwTemplateID then
		return
	end
	--[[#DEBUG BEGIN]]
	D.Debug('[' .. tar.szName .. '] enter scene')
	--[[#DEBUG END]]
	-- find caster
	for k, v in ipairs(D.tCast) do
		local nTime = GetTime() - v.dwTime
		--[[#DEBUG BEGIN]]
		D.Debug('checking [#' .. v.dwCaster .. '], delay [' .. nTime .. ']')
		--[[#DEBUG END]]
		if nTime < D.nMaxDelay then
			remove(D.tCast, k)
			D.AddToList(tar, v.dwCaster, v.dwTime, v.szEvent)
			--[[#DEBUG BEGIN]]
			D.Debug('matched [' .. tar.szName .. '] casted by [#' .. v.dwCaster .. ']')
			--[[#DEBUG END]]
			return
		end
	end
	-- purge
	for k, v in pairs(D.tCast) do
		if (GetTime() - v.dwTime) > D.nMaxDelay then
			remove(D.tCast, k)
		end
	end
end

-- notify
function D.OnSkillNotify(_, data, nChannel, dwTalkerID, szTalkerName, bSelf)
	if not bSelf then
		local dwID = tonumber(data[1])
		if not D.tList[dwID] then
			D.tList[dwID] = { dwCaster = tonumber(data[2]), dwTime = GetTime() }
			--[[#DEBUG BEGIN]]
			D.Debug('received notify from [#' .. data[2] .. ']')
			--[[#DEBUG END]]
		end
	end
end

function D.OnEnableChange()
	local bEnable = D.bReady and O.bEnable
	local h = UI.GetShadowHandle('MY_ForceGuding')
	h:Clear()
	if bEnable then
		h:AppendItemFromString('<shadow>name="Shadow_Label"</shadow>')
		D.pLabel = h:Lookup('Shadow_Label')
		LIB.RegisterEvent('SYS_MSG', 'MY_ForceGuding', function()
			if arg0 == 'UI_OME_SKILL_HIT_LOG' then
				D.OnSkillCast(arg1, arg4, arg5, arg0)
			elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
				D.OnSkillCast(arg1, arg5, arg6, arg0)
			end
		end)
		LIB.RegisterEvent('DO_SKILL_CAST', 'MY_ForceGuding', function(event)
			D.OnSkillCast(arg0, arg1, arg2, event)
		end)
		LIB.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_ForceGuding', function()
			D.OnDoodadEnter()
		end)
		LIB.RegisterBgMsg('MY_GUDING_NOTIFY', 'MY_ForceGuding', D.OnSkillNotify)
		LIB.BreatheCall('MY_ForceGuding', function()
			-- skip frame
			local nFrame = GetLogicFrameCount()
			if nFrame >= D.nFrame and (nFrame - D.nFrame) < 8 then
				return
			end
			D.nFrame = nFrame
			-- check empty
			local sha, me = D.pLabel, GetClientPlayer()
			if not me or not MY_ForceGuding.bEnable or IsEmpty(D.tList) then
				return sha:Hide()
			end
			-- color, alpha
			local r, g, b = unpack(MY_ForceGuding.color)
			local a = 200
			local buff = LIB.GetBuff(me, 3488)
			if buff and not buff.bCanCancel then
				a = 120
			end
			-- shadow text
			sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
			sha:ClearTriangleFanPoint()
			sha:Show()
			for k, v in pairs(D.tList) do
				local nLeft = v.dwTime + D.nMaxTime - GetTime()
				if nLeft < 0 then
					D.RemoveFromList(k)
				else
					local tar = GetDoodad(k)
					if tar then
						--  show name
						local szText = _L['-'] .. floor(nLeft / 1000)
						local player = GetPlayer(v.dwCaster)
						if player then
							szText = player.szName .. szText
						else
							szText = tar.szName .. szText
						end
						sha:AppendDoodadID(tar.dwID, r, g, b, a, 192, 199, szText, 0, 1)
					end
				end
			end
		end)
	else
		LIB.RegisterEvent('SYS_MSG', 'MY_ForceGuding', false)
		LIB.RegisterEvent('DO_SKILL_CAST', 'MY_ForceGuding', false)
		LIB.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_ForceGuding', false)
		LIB.RegisterBgMsg('MY_GUDING_NOTIFY', 'MY_ForceGuding', false)
		LIB.BreatheCall('MY_ForceGuding', false)
	end
end

function D.OnUseManaChange()
	local bUseMana = D.bReady and O.bUseMana
	if bUseMana and not LIB.IsShieldedVersion('MY_ForceGuding') then
		LIB.BreatheCall('MY_ForceGuding__UseMana', function()
			local nFrame = GetLogicFrameCount()
			-- check to use mana
			if not O.bUseMana or (D.nManaFrame and D.nManaFrame > (nFrame - 4)) then
				return
			end
			-- 没鼎
			local aList = D.tList
			if IsEmpty(aList) then
				return
			end
			-- 没自己
			local me = GetClientPlayer()
			if not me then
				return
			end
			local fCurrentLife, fMaxLife = LIB.GetObjectLife(me)
			-- 不在地上
			if me.bOnHorse or me.nMoveState ~= MOVE_STATE.ON_STAND then
				return
			end
			-- 血蓝很足
			if (me.nCurrentMana / me.nMaxMana) > (O.nManaMp / 100) and (fCurrentLife / fMaxLife) > (O.nManaHp / 100) then
				return
			end
			-- 在读条
			if LIB.GetOTActionState(me) ~= CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_IDLE then
				return
			end
			-- 吃不了
			local buff = LIB.GetBuff(me, 3448)
			if buff and not buff.bCanCancel then
				return
			end
			-- 找鼎
			for k, _ in pairs(aList) do
				local doo = GetDoodad(k)
				if doo and LIB.GetDistance(doo) < 6 then
					D.nManaFrame = GetLogicFrameCount()
					LIB.InteractDoodad(doo.dwID)
					LIB.Sysmsg(_L['Auto eat GUDING'])
					break
				end
			end
		end)
	else
		LIB.BreatheCall('MY_ForceGuding__UseMana', false)
	end
end

LIB.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ForceGuding', function()
	D.bReady = true
	D.OnEnableChange()
	D.OnUseManaChange()
end)

-------------------------------------
-- 全局导出接口
-------------------------------------
do
local settings = {
	name = 'MY_ForceGuding',
	exports = {
		{
			fields = {
				'bEnable',
				'bAutoSay',
				'szSay',
				'color',
				'bUseMana',
				'nManaMp',
				'nManaHp',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'bEnable',
				'bAutoSay',
				'szSay',
				'color',
				'bUseMana',
				'nManaMp',
				'nManaHp',
			},
			triggers = {
				bEnable  = D.OnEnableChange,
				bUseMana = D.OnUseManaChange,
			},
			root = O,
		},
	},
}
MY_ForceGuding = LIB.CreateModule(settings)
end
