--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具 - 重伤记录
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
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools_DeathLog'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local D = {}
local SZ_INI = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_TeamTools_DeathLog.ini'
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE
local GetCurrentTime = GetCurrentTime
local MY_IsParty, MY_GetSkillName, MY_GetBuffName = LIB.IsParty, LIB.GetSkillName, LIB.GetBuffName

local MAX_COUNT  = 5
local PLAYER_ID  = 0
local DAMAGE_LOG = {}
local DEATH_LOG  = {}
local INFO_CACHE = {}
local RT_SELECT_DEATH

local RT_SKILL_TYPE = {
	[0]  = 'PHYSICS_DAMAGE',
	[1]  = 'SOLAR_MAGIC_DAMAGE',
	[2]  = 'NEUTRAL_MAGIC_DAMAGE',
	[3]  = 'LUNAR_MAGIC_DAMAGE',
	[4]  = 'POISON_DAMAGE',
	[5]  = 'REFLECTIED_DAMAGE',
	[6]  = 'THERAPY',
	[7]  = 'STEAL_LIFE',
	[8]  = 'ABSORB_THERAPY',
	[9]  = 'ABSORB_DAMAGE',
	[10] = 'SHIELD_DAMAGE',
	[11] = 'PARRY_DAMAGE',
	[12] = 'INSIGHT_DAMAGE',
	[13] = 'EFFECTIVE_DAMAGE',
	[14] = 'EFFECTIVE_THERAPY',
	[15] = 'TRANSFER_LIFE',
	[16] = 'TRANSFER_MANA',
}

local function OnSkillEffectLog(dwCaster, dwTarget, nEffectType, dwSkillID, dwLevel, bCriticalStrike, nCount, tResult)
	if not tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] then -- 没有反弹的情况下
		if not IsPlayer(dwTarget) or not MY_IsParty(dwTarget) and dwTarget ~= PLAYER_ID then -- 目标不是队友也不是自己
			return
		end
	else
		if not IsPlayer(dwCaster) or not MY_IsParty(dwCaster) and dwCaster ~= PLAYER_ID then -- 目标不是队友也不是自己
			return
		end
	end
	local KCaster = IsPlayer(dwCaster) and GetPlayer(dwCaster) or GetNpc(dwCaster)
	local KTarget = IsPlayer(dwTarget) and GetPlayer(dwTarget) or GetNpc(dwTarget)

	local szSkill = nEffectType == SKILL_EFFECT_TYPE.SKILL and MY_GetSkillName(dwSkillID, dwLevel) or MY_GetBuffName(dwSkillID, dwLevel)
		-- 五类伤害
	if IsPlayer(dwTarget)
		and tResult[SKILL_RESULT_TYPE.PHYSICS_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE]
		or tResult[SKILL_RESULT_TYPE.POISON_DAMAGE]
	then
		local szCaster
		if KCaster then
			if IsPlayer(dwCaster) then
				szCaster = KCaster.szName
			else
				szCaster = LIB.GetObjectName(KCaster)
			end
		else
			szCaster = _L['OUTER GUEST']
		end
		local key = dwTarget == PLAYER_ID and 'self' or dwTarget
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		insert(DAMAGE_LOG[key], 1, {
			nCurrentTime    = GetCurrentTime(),
			szKiller        = szCaster,
			szSkill         = szSkill .. (nEffectType == SKILL_EFFECT_TYPE.BUFF and '(BUFF)' or ''),
			tResult         = tResult,
			bCriticalStrike = bCriticalStrike,
		})
	end
	-- 有反弹伤害
	if tResult[SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] and IsPlayer(dwCaster) then
		local szTarget
		if KTarget then
			if IsPlayer(dwTarget) then
				szTarget = KTarget.szName
			else
				szTarget = LIB.GetObjectName(KTarget)
			end
		else
			szTarget = _L['OUTER GUEST']
		end

		local key = dwCaster == PLAYER_ID and 'self' or dwCaster
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		insert(DAMAGE_LOG[key], 1, {
			nCurrentTime    = GetCurrentTime(),
			szKiller        = szTarget,
			szSkill         = szSkill .. (nEffectType == SKILL_EFFECT_TYPE.BUFF and '(BUFF)' or ''),
			tResult         = tResult,
			bCriticalStrike = bCriticalStrike,
		})
	end
end

-- 意外摔伤 会触发这个日志
local function OnCommonHealthLog(dwCharacterID, nDeltaLife)
	-- 过滤非玩家和治疗日志
	if not IsPlayer(dwCharacterID) or nDeltaLife >= 0 then
		return
	end
	local p = GetPlayer(dwCharacterID)
	if not p then
		return
	end
	if MY_IsParty(dwCharacterID) or dwCharacterID == PLAYER_ID then
		local key = dwCharacterID == PLAYER_ID and 'self' or dwCharacterID
		if not DAMAGE_LOG[key] then
			DAMAGE_LOG[key] = {}
		elseif DAMAGE_LOG[key][MAX_COUNT] then
			DAMAGE_LOG[key][MAX_COUNT] = nil
		end
		insert(DAMAGE_LOG[key], 1, { nCurrentTime = GetCurrentTime(), nCount = nDeltaLife * -1 })
	end
end

local function OnSkill(dwCaster, dwSkillID, dwLevel)
	local p = GetPlayer(dwCaster)
	if not p then return end

	local key = dwCaster == PLAYER_ID and 'self' or dwCaster
	if not DAMAGE_LOG[key] then
		DAMAGE_LOG[key] = {}
	elseif DAMAGE_LOG[key][MAX_COUNT] then
		DAMAGE_LOG[key][MAX_COUNT] = nil
	end
	insert(DAMAGE_LOG[key], 1, {
		nCurrentTime = GetCurrentTime(),
		szKiller     = p.szName,
		szSkill      = MY_GetSkillName(dwSkillID, dwLevel),
	})
end
-- 这里的szKiller有个很大的坑
-- 因为策划不喜欢写模板名称 导致NPC名字全是空的 摔死和淹死也是空
-- 这就特别郁闷
local function OnDeath(dwID, dwKiller)
	if IsPlayer(dwID) and (MY_IsParty(dwID) or dwID == PLAYER_ID) then
		local key = dwID == PLAYER_ID
			and 'self'
			or dwID
		if not DEATH_LOG[key] then
			DEATH_LOG[key] = {}
		end
		if not INFO_CACHE[dwID] then
			if key == 'self' then
				local me = GetClientPlayer()
				INFO_CACHE[dwID] = {
					szName = me.szName,
					dwForceID = me.dwForceID,
					dwMountKungfuID = UI_GetPlayerMountKungfuID(),
				}
			else
				local team = GetClientTeam()
				local info = team.GetMemberInfo(dwID)
				if info then
					INFO_CACHE[dwID] = {
						szName = info.szName,
						dwForceID = info.dwForceID,
						dwMountKungfuID = info.dwMountKungfuID,
					}
				end
			end
		end
		local szKiller = LIB.GetObjectName(IsPlayer(dwKiller) and TARGET.PLAYER or TARGET.NPC, dwKiller, 'never')
		insert(DEATH_LOG[key], {
			nCurrentTime = GetCurrentTime(),
			data         = DAMAGE_LOG[key] or { szCaster = szKiller },
			szKiller     = szKiller,
		})
		DAMAGE_LOG[key] = nil
		FireUIEvent('MY_TEAMTOOLS_DEATHLOG', key)
	end
end

LIB.RegisterEvent('LOADING_END', function()
	DAMAGE_LOG = {}
	PLAYER_ID  = UI_GetClientPlayerID()
end)

LIB.RegisterEvent('SYS_MSG', function()
	if arg0 == 'UI_OME_DEATH_NOTIFY' then -- 死亡记录
		OnDeath(arg1, arg2)
	elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then -- 技能记录
		OnSkillEffectLog(arg1, arg2, arg4, arg5, arg6, arg7, arg8, arg9)
	elseif arg0 == 'UI_OME_COMMON_HEALTH_LOG' then
		OnCommonHealthLog(arg1, arg2)
	end
end)

LIB.RegisterEvent('DO_SKILL_CAST', function()
	if arg1 == 608 and IsPlayer(arg0) then -- 自觉经脉
		OnSkill(arg0, arg1, arg2)
	end
end)

function D.ClearDeathLog()
	DEATH_LOG = {}
	INFO_CACHE = {}
	FireUIEvent('MY_TEAMTOOLS_DEATHLOG')
end

-- 重伤记录
function D.UpdatePage(page)
	local hDeathList = page:Lookup('Wnd_DeathLog/Scroll_Player_List', '')
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local aList = {}
	for k, v in pairs(DEATH_LOG) do
		insert(aList, {
			dwID   = k,
			nCount = #v,
		})
	end
	sort(aList, function(a, b) return a.nCount > b.nCount end)
	hDeathList:Clear()
	for _, v in ipairs(aList) do
		local dwID = v.dwID == 'self' and me.dwID or v.dwID
		local info = INFO_CACHE[dwID]
		if info then
			local h = hDeathList:AppendItemFromData(page.hDeathPlayer, 'Handle_DeathPlayer')
			local icon = select(2, MY_GetSkillName(info.dwMountKungfuID))
			local szName = info.szName
			h.dwID = dwID
			h.szName = szName
			h:Lookup('Image_DeathIcon'):FromIconID(icon)
			h:Lookup('Text_DeathName'):SetText(szName)
			h:Lookup('Text_DeathName'):SetFontColor(LIB.GetForceColor(info.dwForceID))
			h:Lookup('Text_DeathCount'):SetText(v.nCount)
			h:Lookup('Image_Select'):SetVisible(dwID == RT_SELECT_DEATH)
		end
	end
	hDeathList:FormatAllItemPos()
	D.UpdateList(page, RT_SELECT_DEATH)
end

function D.OnShowDeathInfo()
	local dwID, i = this:GetName():match('(%d+)_(%d+)')
	if dwID then
		dwID, i = tonumber(dwID), tonumber(i)
	else
		dwID = 'self'
		i = tonumber(this:GetName():match('self_(%d+)'))
	end
	local tDeath = DEATH_LOG
	if tDeath[dwID] and tDeath[dwID][i] then
		local tab = tDeath[dwID][i]
		local xml = {}
		insert(xml, GetFormatText(_L['Last 5 skill damage'] .. '\n\n' , 59))
		for k, v in ipairs(tab.data) do
			if v.szKiller then
				insert(xml, GetFormatText(v.szKiller .. g_tStrings.STR_COLON, 41, 255, 128, 0))
			else
				insert(xml, GetFormatText(_L['OUTER GUEST'] .. g_tStrings.STR_COLON, 41, 255, 128, 0))
			end
			if v.szSkill then
				insert(xml, GetFormatText(v.szSkill .. (v.bCriticalStrike and g_tStrings.STR_SKILL_CRITICALSTRIKE or ''), 41, 255, 128, 0))
			else
				insert(xml, GetFormatText(g_tStrings.STR_UNKOWN_SKILL, 41, 255, 128, 0))
			end
			local t = TimeToDate(v.nCurrentTime)
			insert(xml, GetFormatText('\t' .. format('%02d:%02d:%02d', t.hour, t.minute, t.second), 41))
			if v.tResult then
				for kk, vv in pairs(v.tResult) do
					if vv > 0 then
						insert(xml, GetFormatText(_L[RT_SKILL_TYPE[kk]] .. g_tStrings.STR_COLON, 157))
						insert(xml, GetFormatText(vv .. '\n', 41))
					end
				end
			elseif v.nCount then
				insert(xml, GetFormatText(_L['EFFECTIVE_DAMAGE'] .. g_tStrings.STR_COLON, 157))
				insert(xml, GetFormatText(v.nCount .. '\n', 41))
			end
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputTip(concat(xml), 400, { x, y, w, h })
	end
end

function D.OnAppendEdit()
	local handle = this:GetParent()
	local edit = LIB.GetChatInput()
	edit:ClearText()
	for i = this:GetIndex(), handle:GetItemCount() do
		local h = handle:Lookup(i)
		local szText = h:GetText()
		if szText == '\n' then
			break
		end
		if h:GetName() == 'namelink' then
			edit:InsertObj(szText, { type = 'name', text = szText, name = sub(szText, 2, -2) })
		else
			edit:InsertObj(szText, { type = 'text', text = szText })
		end
	end
	Station.SetFocusWindow(edit)
end

function D.UpdateList(page, dwID)
	local hDeathMsg = page:Lookup('Wnd_DeathLog/Scroll_Death_Info', '')
	local me = GetClientPlayer()
	local team = GetClientTeam()
	local aRec = {}
	local key = dwID == me.dwID and 'self' or dwID
	local aDeathLog = Clone(DEATH_LOG)
	for k, v in pairs(aDeathLog) do
		if not dwID or k == key then
			for kk, vv in ipairs(v) do
				if k == 'self' then
					vv.dwID = me.dwID
				else
					vv.dwID = k
				end
				vv.nIndex = kk
				insert(aRec, vv)
			end
		end
	end
	sort(aRec, function(a, b) return a.nCurrentTime > b.nCurrentTime end)
	hDeathMsg:Clear()
	for _, data in ipairs(aRec) do
		local info = INFO_CACHE[data.dwID]
		if info then
			local key = data.dwID == me.dwID and 'self' or data.dwID
			local t = TimeToDate(data.nCurrentTime)
			local xml = {}
			insert(xml, GetFormatText(_L[' * '] .. format('[%02d:%02d:%02d]', t.hour, t.minute, t.second), 10, 255, 255, 255, 16, 'this.OnItemLButtonClick = MY_TeamTools_DeathLog.OnAppendEdit'))
			local r, g, b = LIB.GetForceColor(info.dwForceID)
			insert(xml, GetFormatText('[' .. info.szName ..']', 10, r, g, b, 16, 'this.OnItemLButtonClick = function() OnItemLinkDown(this) end', 'namelink'))
			insert(xml, GetFormatText(g_tStrings.TRADE_BE, 10, 255, 255, 255))
			if data.szKiller == '' and data.data[1].szKiller ~= '' then
				insert(xml, GetFormatText('[' .. _L['OUTER GUEST'] .. g_tStrings.STR_OR .. data.data[1].szKiller ..']', 10, 13, 150, 70, 256, 'this.OnItemMouseEnter = MY_TeamTools_DeathLog.OnShowDeathInfo', key .. '_' .. data.nIndex))
			else
				insert(xml, GetFormatText('[' .. (data.szKiller ~= '' and data.szKiller or  _L['OUTER GUEST']) ..']', 10, 255, 128, 0, 256, 'this.OnItemMouseEnter = MY_TeamTools_DeathLog.OnShowDeathInfo', key .. '_' .. data.nIndex))
			end
			insert(xml, GetFormatText(g_tStrings.STR_KILL .. g_tStrings.STR_FULL_STOP, 10, 255, 255, 255))
			insert(xml, GetFormatText('\n'))
			hDeathMsg:AppendItemFromString(concat(xml))
		end
	end
	hDeathMsg:FormatAllItemPos()
end

function D.OnInitPage()
	local frameTemp = Wnd.OpenWindow(SZ_INI, 'MY_TeamTools_DeathLog')
	local wnd = frameTemp:Lookup('Wnd_DeathLog')
	wnd:Lookup('Btn_All', 'Text_BtnAll'):SetText(_L['Show all'])
	wnd:Lookup('Btn_Clear', 'Text_BtnClear'):SetText(_L['Clear record'])
	wnd:ChangeRelation(this, true, true)
	Wnd.CloseWindow(frameTemp)

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_TEAMTOOLS_DEATHLOG')
	frame:RegisterEvent('ON_MY_MOSAICS_RESET')
	this.hDeathPlayer = frame:CreateItemData(SZ_INI, 'Handle_Item_DeathPlayer')
end

function D.OnActivePage()
	D.UpdatePage(this)
end

function D.OnEvent(event)
	if event == 'MY_TEAMTOOLS_DEATHLOG' then
		D.UpdatePage(this)
	elseif event == 'ON_MY_MOSAICS_RESET' then
		D.UpdatePage(this)
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_All' then
		RT_SELECT_DEATH = nil
		D.UpdatePage(this:GetParent():GetParent())
	elseif szName == 'Btn_Clear' then
		LIB.Confirm(_L['Clear record'], D.ClearDeathLog)
	end
end

function D.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_DeathPlayer' then
		if IsCtrlKeyDown() then
			LIB.EditBox_AppendLinkPlayer(this.szName)
		else
			RT_SELECT_DEATH = this.dwID
			D.UpdatePage(this:GetParent():GetParent():GetParent():GetParent())
		end
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_DeathPlayer' then
		if this and this:Lookup('Image_Cover') and this:Lookup('Image_Cover'):IsValid() then
			this:Lookup('Image_Cover'):Hide()
		end
	end
	HideTip()
end

-- Module exports
do
local settings = {
	exports = {
		{
			fields = {
				OnInitPage = D.OnInitPage,
			},
		},
		{
			root = D,
			preset = 'UIEvent'
		},
	},
}
MY_TeamTools.RegisterModule('DeathLog', _L['MY_TeamTools_DeathLog'], LIB.GeneGlobalNS(settings))
end

-- Global exports
do
local settings = {
	exports = {
		{
			fields = {
				OnShowDeathInfo = D.OnShowDeathInfo,
				OnAppendEdit = D.OnAppendEdit,
			},
		},
	},
}
MY_TeamTools_DeathLog = LIB.GeneGlobalNS(settings)
end
