---------------------------------------------------
-- @Author: Webster
-- @Date:   2015-12-04 20:17:03
-- @Last Modified by:   Emil Zhai (root@derzh.com)
-- @Last Modified time: 2018-05-30 22:56:37
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi = math.huge, math.pi
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetDoodad, IsPlayer, PostThreadCall = GetDoodad, IsPlayer, PostThreadCall
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
local TARGET = TARGET
MY_SA = {
	bAlert     = false,
	bOnlySelf  = true,
	fLifePer   = 0.3,
	fManaPer   = 0.1,
	nFont      = 203,
	bDrawColor = false,
}
MY.RegisterCustomData('MY_SA')

local _L = MY.LoadLangPack()
local MARK_NAME = MY.GetMarkName()
local UI_SCALED = 1
local HANDLE
local CACHE = {
	[TARGET.DOODAD] = {},
	[TARGET.PLAYER] = {},
	[TARGET.NPC]    = {},
}
local SA = {}
SA.__index = SA
local SA_COLOR = {
	FONT = {
		['BUFF']    = { 255, 128, 0   },
		['DEBUFF']  = { 255, 0,   255 },
		['Life']    = { 130, 255, 130 },
		['Mana']    = { 255, 255, 128 },
		['NPC']     = { 0,   255, 255 },
		['CASTING'] = { 150, 200, 255 },
		['DOODAD']  = { 200, 200, 255 },
		['TIME']    = { 128, 255, 255 },
	},
	ARROW = {
		['BUFF']    = { 0,   255, 0   },
		['DEBUFF']  = { 255, 0,   0   },
		['Life']    = { 255, 0,   0   },
		['Mana']    = { 0,   0,   255 },
		['NPC']     = { 0,   128, 255 },
		['CASTING'] = { 255, 128, 0   },
		['DOODAD']  = { 200, 200, 255 },
		['TIME']    = { 255, 0,   0   },
	}
}
do
	local mt = { __index = function() return { 255, 128, 0 } end }
	setmetatable(SA_COLOR.FONT,  mt)
	setmetatable(SA_COLOR.ARROW, mt)
end

local SA_POINT_C = { 25, 25, 180 }
local SA_POINT = {
	{ 15, 0,  100 },
	{ 35, 0,  100 },
	{ 35, 25, 180 },
	{ 43, 25, 255 },
	{ 25, 50, 180 },
	{ 7,  25, 255 },
	{ 15, 25, 180 },
}

-- 一些例外需要显示头顶的NPC模板ID
local SPECIAL_NPC = {
	-- 大小攻防需要头顶显示的NPC列表
	[7786] = true, [16905] = true, -- 王遗风
	[7776] = true, [16898] = true, -- 谢渊
	[7785] = true, [16904] = true, -- 莫雨
	[7775] = true, [16897] = true, -- 影
	[7784] = true, [16903] = true, -- 烟
	[7770] = true, [16896] = true, -- 月弄痕
	[7783] = true, [16902] = true, -- 肖药儿
	[7766] = true, [16893] = true, -- 司空仲平
	[7779] = true, [16900] = true, -- 米丽古丽
	[7765] = true, [16892] = true, -- 可人
	[7777] = true, [16899] = true, -- 陶寒亭
	[7767] = true, [16894] = true, -- 张桎辕
	[8957] = true, [17239] = true, -- 张一洋
	[8953] = true, [17235] = true, -- 周峰
	[8956] = true, [17238] = true, -- 吕沛杰
	[8954] = true, [17234] = true, -- 陶杰
	[8955] = true, [17240] = true, -- 陶国栋
	[8952] = true, [17236] = true, -- 郑鸥
	[6233] = true, [17237] = true, -- 顾延恶
	[6230] = true, [17233] = true, -- 谢烟客
	[30310] = true, -- 小攻防 恶人谷大将
	[30322] = true, -- 小攻防 浩气盟大将
	[46268] = true, -- 大攻防 物资车
}

-- for i=1, 2 do FireUIEvent('MY_SA_CREATE', 'TIME', GetClientPlayer().dwID, { col = { 255, 255, 255 }, txt = 'test' })end
local function CreateScreenArrow(szClass, dwID, tArgs)
	tArgs = tArgs or {}
	SA:ctor(szClass, dwID, tArgs)
end

local ScreenArrow = {
	tCache = {
		['Life'] = {},
		['Mana'] = {},
	}
}

function ScreenArrow.OnSort()
	local t = {}
	for k, v in pairs(HANDLE:GetAllItem(true)) do
		PostThreadCall(function(v, xScreen, yScreen)
			v.nIndex = yScreen or 0
		end, v, 'Scene_GetCharacterTopScreenPos', v.dwID)
		insert(t, { handle = v, index = v.nIndex or 0 })
	end
	sort(t, function(a, b) return a.index < b.index end)
	for i = #t, 1, -1 do
		if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
			t[i].handle:ExchangeIndex(i - 1)
		end
	end
end

function ScreenArrow.OnBreathe()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local team = GetClientTeam()
	local tTeamMark = team.dwTeamID > 0 and team.GetTeamMark() or EMPTY_TABLE
	for dwType, tab in pairs(CACHE) do
		for dwID, v in pairs(tab) do
			local object, tInfo = select(2, ScreenArrow.GetObject(dwType, dwID))
			if object then
				local obj = ScreenArrow.GetAction(dwType, dwID)
				local fLifePer = obj.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentLife / max(tInfo.nMaxLife, tInfo.nCurrentLife, 1)
				local fManaPer = obj.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentMana / max(tInfo.nMaxMana, tInfo.nCurrentMana, 1)
				local szName
				if dwType == TARGET.DOODAD then
					szName = tInfo.szName
					if szName == '' then szName = object.dwTemplateID end
				else
					szName = MY.GetObjectName(object)
				end
				-- szName = obj.szName or szName
				szName = object.szName or szName
				if tTeamMark[dwID] then
					szName = szName .. _L('[%s]', MARK_NAME[tTeamMark[dwID]])
				end
				local txt = ''
				if obj.szClass == 'BUFF' or obj.szClass == 'DEBUFF' then
					local KBuff = MY.GetBuff(object, obj.dwBuffID) -- 只判断dwID 反正不可能同时获得不同lv
					if KBuff then
						local nSec = MY.GetEndTime(KBuff.GetEndTime())
						local szSec = MY.FormatTimeCount(nSec >= 60 and 'M\'ss' or 'ss', min(nSec, 5999))
						if KBuff.nStackNum > 1 then
							-- txt = string.format('%s(%d)_%s', obj.txt or MY.GetBuffName(KBuff.dwID, KBuff.nLevel), KBuff.nStackNum, szSec)
							txt = string.format('%s(%d)_%s', MY.GetBuffName(KBuff.dwID, KBuff.nLevel), KBuff.nStackNum, szSec)
						else
							-- txt = string.format('%s_%s', obj.txt or MY.GetBuffName(KBuff.dwID, KBuff.nLevel), szSec)
							txt = string.format('%s_%s', MY.GetBuffName(KBuff.dwID, KBuff.nLevel), szSec)
						end
					else
						return obj:Free()
					end
				elseif obj.szClass == 'Life' or obj.szClass == 'Mana' then
					if object.nMoveState == MOVE_STATE.ON_DEATH then
						return obj:Free()
					end
					if obj.szClass == 'Life' then
						if fLifePer > MY_SA.fLifePer then
							return obj:Free()
						end
						txt = g_tStrings.STR_SKILL_H_LIFE_COST .. string.format('%d/%d', tInfo.nCurrentLife, tInfo.nMaxLife)
					elseif obj.szClass == 'Mana' then
						if fManaPer > MY_SA.fManaPer then
							return obj:Free()
						end
						txt = g_tStrings.STR_SKILL_H_MANA_COST .. string.format('%d/%d', tInfo.nCurrentMana, tInfo.nMaxMana)
					end
				elseif obj.szClass == 'CASTING' then
					local bIsPrepare, dwSkillID, dwSkillLevel, fPer = object.GetSkillPrepareState()
					if bIsPrepare then
						-- txt = obj.txt or MY.GetSkillName(dwSkillID, dwSkillLevel)
						txt = MY.GetSkillName(dwSkillID, dwSkillLevel)
						fManaPer = fPer
					else
						return obj:Free()
					end
				elseif obj.szClass == 'NPC' or obj.szClass == 'DOODAD' then
					-- txt = obj.txt or txt
				elseif obj.szClass == 'TIME' then
					if (GetTime() - obj.nNow) / 1000 > 3 then
						return obj:Free()
					end
					txt = obj.txt or _L['Call Alert']
				end
				if not obj.init then
					obj:DrawBackGround()
				end
				obj:DrawLifeBar(fLifePer, fManaPer):DrawText(txt, szName):DrowArrow()
			else
				for _, vv in pairs(v) do
					vv:Free()
				end
			end
		end
	end
end

function ScreenArrow.GetAction(dwType, dwID)
	local tab = CACHE[dwType][dwID]
	if #tab > 1 then
		for k, v in ipairs(CACHE[dwType][dwID]) do
			v:Hide()
		end
	end
	local obj = CACHE[dwType][dwID][#CACHE[dwType][dwID]]
	return obj:Show()
end

function ScreenArrow.GetObject(szClass, dwID)
	local dwType, object, tInfo
	if szClass == 'DOODAD' or szClass == TARGET.DOODAD then
		dwType = TARGET.DOODAD
		object = GetDoodad(dwID)
	elseif IsPlayer(dwID) then
		dwType = TARGET.PLAYER
		local me = GetClientPlayer()
		if dwID == me.dwID then
			object = me
		elseif MY.IsParty(dwID) then
			object = GetPlayer(dwID)
			tInfo  = GetClientTeam().GetMemberInfo(dwID)
		else
			object = GetPlayer(dwID)
		end
	else
		dwType = TARGET.NPC
		object = GetNpc(dwID)
	end
	tInfo = tInfo and tInfo or object
	return dwType, object, tInfo
end

function ScreenArrow.RegisterFight()
	if arg0 and MY_SA.bAlert then
		MY.BreatheCall('ScreenArrow_Fight', ScreenArrow.OnBreatheFight)
	else
		ScreenArrow.KillBreathe()
	end
end

function ScreenArrow.KillBreathe()
	MY.BreatheCall('ScreenArrow_Fight', false)
	ScreenArrow.tCache['Mana'] = {}
	ScreenArrow.tCache['Life'] = {}
end

function ScreenArrow.OnBreatheFight()
	local me = GetClientPlayer()
	if not me then return end
	if not me.bFightState then -- kill fix bug
		return ScreenArrow.KillBreathe()
	end
	local team = GetClientTeam()
	local list = {}
	if me.IsInParty() and not MY_SA.bOnlySelf then
		list = team.GetTeamMemberList()
	else
		list[1] = me.dwID
	end
	for k, v in ipairs(list) do
		local p, info = select(2, ScreenArrow.GetObject(TARGET.PLAYER, v))
		if p and info then
			if p.nMoveState == MOVE_STATE.ON_DEATH then
				ScreenArrow.tCache['Mana'][v] = nil
				ScreenArrow.tCache['Life'][v] = nil
			else
				local fLifePer = info.nCurrentLife / max(info.nMaxLife, info.nCurrentLife, 1)
				local fManaPer = info.nCurrentMana / max(info.nMaxMana, info.nCurrentMana, 1)
				if fLifePer < MY_SA.fLifePer then
					if not ScreenArrow.tCache['Life'][v] then
						ScreenArrow.tCache['Life'][v] = true
						CreateScreenArrow('Life', v)
					end
				else
					ScreenArrow.tCache['Life'][v] = nil
				end
				if fManaPer < MY_SA.fManaPer and (p.dwForceID < 7 or p.dwForceID == 22) then
					if not ScreenArrow.tCache['Mana'][v] then
						ScreenArrow.tCache['Mana'][v] = true
						CreateScreenArrow('Mana', v)
					end
				else
					ScreenArrow.tCache['Mana'][v] = nil
				end
			end
		end
	end
end

function SA:ctor(szClass, dwID, tArgs)
	local dwType, object = ScreenArrow.GetObject(szClass, dwID)
	if MY.IsShieldedVersion() and not MY.IsInDungeon()
	and dwType == TARGET.NPC and object.bDialogFlag and not SPECIAL_NPC[object.dwTemplateID] then
		return
	end
	local oo = {}
	setmetatable(oo, self)
	local ui      = HANDLE:New()
	oo.szName   = tArgs.szName
	oo.txt      = tArgs.text
	oo.col      = {MY.HumanColor2RGB(tArgs.col or SA_COLOR.ARROW[szClass])}
	oo.dwBuffID = tArgs.dwID
	oo.szClass  = szClass

	oo.Arrow    = ui:Lookup(0)
	oo.Text     = ui:Lookup(1)
	oo.BGB      = ui:Lookup(2)
	oo.BGI      = ui:Lookup(3)
	oo.Life     = ui:Lookup(4)
	oo.Mana     = ui:Lookup(5)

	oo.ui       = ui
	oo.ui.dwID  = dwID
	oo.init     = false
	oo.bUp      = false
	oo.nTop     = 10
	oo.dwID     = dwID
	oo.dwType   = dwType
	if szClass == 'TIME' then
		oo.nNow = GetTime()
	end
	oo.Text:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	for k, v in pairs({ oo.BGB, oo.BGI, oo.Life, oo.Mana, oo.Arrow }) do
		v:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		v:SetD3DPT(D3DPT.TRIANGLEFAN)
	end
	CACHE[dwType][dwID] = CACHE[dwType][dwID] or {}
	insert(CACHE[dwType][dwID], oo)
	return oo
end

-- 从下至上 依次绘制
function SA:DrawText( ... )
	self.Text:ClearTriangleFanPoint()
	local nTop = -62
	local r, g, b = unpack(SA_COLOR.FONT[self.szClass])
	local i = 1
	for k, v in ipairs({ ... }) do
		if v and v ~= '' then
			local top = nTop + i * -23 * UI_SCALED
			if self.dwType == TARGET.DOODAD then
				self.Text:AppendDoodadID(self.dwID, r, g, b, 240, { 0, 0, 0, 0, top }, MY_SA.nFont, v, 1, 1)
			else
				if MY_SA.bDrawColor and self.dwType == TARGET.PLAYER and k ~= 1 then
					local p = select(2, ScreenArrow.GetObject(self.szClass, self.dwID))
					if p then
						r, g, b = MY.GetForceColor(p.dwForceID, 'background')
					end
				end
				self.Text:AppendCharacterID(self.dwID, true, r, g, b, 240, { 0, 0, 0, 0, top }, MY_SA.nFont, v, 1, 1)
			end
			i = i + 1
		end
	end
	return self
end

function SA:DrawBackGround()
	for k, v in pairs({ self.BGB, self.BGI }) do
		v:ClearTriangleFanPoint()
	end
	local bcX, bcY = -50, -60
	if self.dwType == TARGET.DOODAD then
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + 100, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + 100, bcY + 12 })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + 12 })
		bcX, bcY = -49, -59
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + 100 - 2, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + 100 - 2, bcY + 12 - 2 })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + 12 - 2})
	else
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + 100, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + 100, bcY + 12 })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + 12 })
		bcX, bcY = -49, -59
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + 100 - 2, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + 100 - 2, bcY + 12 - 2 })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + 12 - 2})
	end
	self.init = true
	return self
end

function SA:DrawLifeBar(fLifePer, fManaPer)
	if fLifePer ~= self.fLifePer then
		self.Life:ClearTriangleFanPoint()
		if fLifePer > 0 then
			local bcX, bcY = -49, -59
			local r, g ,b = 220, 40, 0
			if self.dwType == TARGET.DOODAD then
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (98 * fLifePer), bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (98 * fLifePer), bcY + 5 })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + 5 })
			else
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (98 * fLifePer), bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (98 * fLifePer), bcY + 5 })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + 5 })
			end
		end
		self.fLifePer = fLifePer
	end
	if fManaPer ~= self.fManaPer then
		self.Mana:ClearTriangleFanPoint()
		if fManaPer > 0 then
			local bcX, bcY = -49, -54
			local r, g ,b = 50, 100, 255
			if self.szClass == 'CASTING' then
				r, g ,b = 255, 128, 0
			end
			if self.dwType == TARGET.DOODAD then
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (98 * fManaPer), bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (98 * fManaPer), bcY + 5 })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + 5 })
			else
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (98 * fManaPer), bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (98 * fManaPer), bcY + 5 })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + 5 })
			end
		end
		self.fManaPer = fManaPer
	end
	return self
end

function SA:DrowArrow()
	local cX, cY, cA = unpack(SA_POINT_C)
	cX, cY = cX * 0.7, cY * 0.7
	local fX, fY = 15, 50
	if self.bUp then
		self.nTop = self.nTop + 2
		if self.nTop >= 10 then
			self.bUp = false
		end
	else
		self.nTop = self.nTop - 2
		if self.nTop <= 0 then
			self.bUp = true
		end
	end
	fY = fY - self.nTop

	self.Arrow:ClearTriangleFanPoint()
	local r, g, b = unpack(self.col)
	if self.dwType == TARGET.DOODAD then
		self.Arrow:AppendDoodadID(self.dwID, r, g, b, cA, { 0, 0, 0, cX - fX, cY - fY })
		for k, v in ipairs(SA_POINT) do
			local x, y, a = unpack(v)
			x, y = x * 0.7, y * 0.7
			self.Arrow:AppendDoodadID(self.dwID, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
		end
		local x, y, a = unpack(SA_POINT[1])
		self.Arrow:AppendDoodadID(self.dwID, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
	else
		self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, cA, { 0, 0, 0, cX - fX, cY - fY })
		for k, v in ipairs(SA_POINT) do
			local x, y, a = unpack(v)
			x, y = x * 0.7, y * 0.7
			self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, x - fX, y - fY })
		end
		local x, y, a = unpack(SA_POINT[1])
		self.Arrow:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, x- fX, y - fY })
	end
	return self
end

function SA:Show()
	self.ui:Show()
	return self
end

function SA:Hide()
	self.ui:Hide()
	return self
end

function SA:Free()
	local tab = CACHE[self.dwType][self.dwID]
	if #tab == 1 then
		CACHE[self.dwType][self.dwID] = nil
	else
		for k, v in pairs(tab) do
			if v.ui == self.ui then
				table.remove(tab, k)
				break
			end
		end
	end
	HANDLE:Free(self.ui)
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = XGUI(wnd)
	local X, Y = 10, 10
	local x, y = X, Y

	x = X + 10
	y = y + ui:append('Text', { x = X, y = y, text = _L['Screen head alarm'], font = 27 }, true):height() + 10

	y = y + ui:append('WndCheckBox', {
		x = 10, y = y,
		text = _L['Draw school color'],
		checked = MY_SA.bDrawColor,
		oncheck = function(bChecked)
			MY_SA.bDrawColor = bChecked
		end,
	}, true):height() + 5

	x = X + 10
	y = y + ui:append('Text', { x = X, y = y, text = _L['Low life/mana head alert'], font = 27 }, true):height() + 10

	x = x + ui:append('WndCheckBox',{
		x = 10, y = y, text = _L['Enable'],
		checked = MY_SA.bAlert,
		oncheck = function(bChecked)
			MY_SA.bAlert = bChecked
			local me = GetClientPlayer()
			if bChecked and me.bFightState then
				MY.BreatheCall('ScreenArrow_Fight', ScreenArrow.OnBreatheFight)
			else
				ScreenArrow.KillBreathe()
			end
		end,
	}, true):autoWidth():width() + 5

	y = y + ui:append('WndCheckBox', {
		x = x, y = y,
		text = _L['Only monitor self'],
		checked = MY_SA.bOnlySelf,
		oncheck = function(bChecked)
			MY_SA.bOnlySelf = bChecked
		end,
		autoenable = function() return MY_SA.bAlert end,
	}, true):height()

	x = X + 10
	y = y + ui:append('WndSliderBox', {
		x = x, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {0, 100},
		value = MY_SA.fLifePer * 100,
		textfmt = function(val) return _L('While HP less than %d.', val) end,
		onchange = function(nVal)
			MY_SA.fLifePer = nVal / 100
		end,
		autoenable = function() return MY_SA.bAlert end,
	}, true):height()

	y = y + ui:append('WndSliderBox', {
		x = x, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {0, 100},
		value = MY_SA.fManaPer * 100,
		textfmt = function(val) return _L('While MP less than %d.', val) end,
		onchange = function(nVal)
			MY_SA.fManaPer = nVal / 100
		end,
		autoenable = function() return MY_SA.bAlert end,
	}, true):height()

	x = X + 10
	y = y + 5
	x = x + ui:append('WndButton2', {
		x = x, y = y,
		text = g_tStrings.FONT,
		onclick = function()
			XGUI.OpenFontPicker(function(nFont)
				MY_SA.nFont = nFont
			end)
		end,
	}, true):width() + 10

	y = y + ui:append('WndButton2', {
		text = _L['Preview'],
		x = x, y = y,
		onclick = function()
			CreateScreenArrow('TIME', GetClientPlayer().dwID, { text = _L('%s, welcome to use mingyi plugins!', GetUserRoleName()) })
		end,
	}, true):height()
end
MY.RegisterPanel('MY_SA', _L['Screen head alarm'], _L['System'], 431, {255, 255, 255}, PS)

function ScreenArrow.Init()
	HANDLE = XGUI.HandlePool(XGUI.GetShadowHandle('MY_ScreenArrow'), FormatHandle(string.rep('<shadow></shadow>', 6)))
	MY.BreatheCall('ScreenArrow_Sort', 500, ScreenArrow.OnSort)
end

MY.BreatheCall('ScreenArrow', ScreenArrow.OnBreathe)
MY.RegisterEvent('LOGIN_GAME', ScreenArrow.Init)
MY.RegisterEvent('FIGHT_HINT', ScreenArrow.RegisterFight)
MY.RegisterEvent('UI_SCALED', function() UI_SCALED = Station.GetUIScale() end)
MY.RegisterEvent('MY_SA_CREATE', function() CreateScreenArrow(arg0, arg1, arg2) end)
