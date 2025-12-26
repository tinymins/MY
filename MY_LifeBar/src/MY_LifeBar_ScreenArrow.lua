--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 头顶箭头
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @ref      : William Chan (Webster)
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar_ScreenArrow'
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar_ScreenArrow'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
X.RegisterRestriction('MY_LifeBar_ScreenArrow', { ['*'] = true, intl = false })
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_LifeBar_ScreenArrow', _L['Raid'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Enable'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	fUIScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['UI scale'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Number,
		xDefaultValue = 0.8,
	},
	fTextScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Text scale'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Number,
		xDefaultValue = 1.35,
	},
	bAlert = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Less life/mana head alert'],
			_L['Enable'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bOnlySelf = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Less life/mana head alert'],
			_L['Only monitor self'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	fLifePer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Less life/mana head alert'],
			_L['While HP less than'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Number,
		xDefaultValue = 0.3,
	},
	fManaPer = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Less life/mana head alert'],
			_L['While MP less than'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Number,
		xDefaultValue = 0.1,
	},
	nFont = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Less life/mana head alert'],
			g_tStrings.FONT,
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Number,
		xDefaultValue = 186,
	},
	bDrawColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_LifeBar'],
		szDescription = X.MakeCaption({
			_L['MY_LifeBar_ScreenArrow'],
			_L['Draw School Color'],
		}),
		szRestriction = 'MY_LifeBar_ScreenArrow',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	tCache = {
		['Life'] = {},
		['Mana'] = {},
	}
}
local Config = MY_LifeBar_Config

local UI_SCALE = 1
local FORCE_DRAW = false
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
		['BUFF'   ] = { 255, 128, 0   },
		['DEBUFF' ] = { 255, 0,   255 },
		['Life'   ] = { 130, 255, 130 },
		['Mana'   ] = { 255, 255, 128 },
		['NPC'    ] = { 0,   255, 255 },
		['CASTING'] = { 150, 200, 255 },
		['DOODAD' ] = { 200, 200, 255 },
		['TIME'   ] = { 128, 255, 255 },
	},
	ARROW = {
		['BUFF'   ] = { 0,   255, 0   },
		['DEBUFF' ] = { 255, 0,   0   },
		['Life'   ] = { 255, 0,   0   },
		['Mana'   ] = { 0,   0,   255 },
		['NPC'    ] = { 0,   128, 255 },
		['CASTING'] = { 255, 128, 0   },
		['DOODAD' ] = { 200, 200, 255 },
		['TIME'   ] = { 255, 0,   0   },
	}
}
do
	local mt = { __index = function() return { 255, 128, 0 } end }
	setmetatable(SA_COLOR.FONT,  mt)
	setmetatable(SA_COLOR.ARROW, mt)
end

local BASE_SA_POINT_C = { 25, 25, 180 }
local BASE_SA_POINT = {
	{ 15, 0,  100 },
	{ 35, 0,  100 },
	{ 35, 25, 180 },
	{ 43, 25, 255 },
	{ 25, 50, 180 },
	{ 7,  25, 255 },
	{ 15, 25, 180 },
}

local BASE_WIDTH
local BASE_HEIGHT
local BASE_PEAK
local BASE_EDGE
local SA_POINT_C = {}
local SA_POINT = {}
local BASE_POINT_START
local function SetUIScale()
	local fScale = Station.GetMaxUIScale() * (D.bReady and O.fUIScale or 0.8)
	UI_SCALE = Station.GetUIScale()
	FORCE_DRAW = true
	BASE_PEAK = -60 * fScale * 0.5
	BASE_WIDTH = 100 * fScale
	BASE_HEIGHT = 12 * fScale
	BASE_EDGE = fScale * 1.2
	BASE_POINT_START = 15 * fScale
	SA_POINT_C = {}
	SA_POINT = {}
	for k, v in ipairs(BASE_SA_POINT_C) do
		if k ~= 3 then
			SA_POINT_C[k] = v * fScale
		else
			SA_POINT_C[k] = v
		end
	end
	for k, v in ipairs(BASE_SA_POINT) do
		SA_POINT[k] = {}
		for kk, vv in ipairs(v) do
			if kk ~= 3 then
				SA_POINT[k][kk] = vv * fScale
			else
				SA_POINT[k][kk] = vv
			end
		end
	end
end

local function RGB2Dword(nR, nG, nB, nA) return (nA or 255) * 16777216 + nR * 65536 + nG * 256 + nB end

-- for i=1, 2 do FireUIEvent('MY_LIFEBAR_COUNTDOWN', GetClientPlayer().dwID, 'TIME', { col = { 255, 255, 255 }, szText = 'test' })end
local function CreateScreenArrow(dwID, szType, tArgs)
	if not D.IsEnabled() then
		return
	end
	tArgs = tArgs or {}
	if SA:ctor(dwID, szType, tArgs) then
		return true
	end
	return false
end

function D.IsEnabled()
	return D.bReady and O.bEnable and not X.IsRestricted('MY_LifeBar_ScreenArrow')
end

function D.ProcessCountdown(dwID, szType, szKey, tArgs)
	if CreateScreenArrow(dwID, szType, tArgs) then
		return true
	end
	return false
end

function D.OnSort()
	local t = {}
	for k, v in pairs(HANDLE:GetAllItem(true)) do
		PostThreadCall(function(v, xScreen, yScreen)
			v.nIndex = yScreen or 0
		end, v, 'Scene_GetCharacterTopScreenPos', v.dwID)
		table.insert(t, { handle = v, index = v.nIndex or 0 })
	end
	table.sort(t, function(a, b) return a.index < b.index end)
	for i = #t, 1, -1 do
		if t[i].handle and t[i].handle:GetIndex() ~= i - 1 then
		t[i].handle:ExchangeIndex(i - 1)
		end
	end
end

function D.OnBreathe()
	if not D.bReady then
		return
	end
	local me = GetClientPlayer()
	if not me then
		return
	end
	local team = GetClientTeam()
	local tTeamMark = team.dwTeamID > 0 and team.GetTeamMark() or EMPTY_TABLE
	for dwType, tab in pairs(CACHE) do
		for dwID, v in pairs(tab) do
			local kTarget, tInfo = select(2, D.GetObject(dwType, dwID))
			if kTarget then
				local oo = D.GetAction(dwType, dwID)
				local fLifePer = oo.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentLife / math.max(tInfo.nMaxLife, tInfo.nCurrentLife, 1)
				local fManaPer = oo.dwType == TARGET.DOODAD and 1 or tInfo.nCurrentMana / math.max(tInfo.nMaxMana, tInfo.nCurrentMana, 1)
				local szName = oo.szName
				if not szName then
					if dwType == TARGET.DOODAD then
						szName = tInfo.szName
					elseif dwType == TARGET.NPC then
						szName = X.GetNpcTemplateName(kTarget.dwTemplateID)
					else
						szName = X.GetTargetName(dwType, dwID)
						szName = X.ExtractPlayerBaseName(szName)
					end
					oo.szName = szName
				end
				if tTeamMark[dwID] then
					szName = szName .. _L('[%s]', X.CONSTANT.TEAM_MARK_NAME[tTeamMark[dwID]])
				end
				local txt = ''
				if oo.szType == 'BUFF' or oo.szType == 'DEBUFF' then
					-- local KBuff = GetBuff(obj.dwBuffID, object) -- 只判断dwID 反正不可能同时获得不同lv
					local KBuff = kTarget.GetBuff(oo.dwBuffID, 0) -- 只判断dwID 反正不可能同时获得不同lv
					if KBuff then
						local nSec = X.GetEndTime(KBuff.GetEndTime())
						local szDuration = X.FormatDuration(math.min(nSec, 5999), 'PRIME')
						if KBuff.nStackNum > 1 then
							txt = string.format('%s(%d)_%s', oo.txt or X.GetBuffName(KBuff.dwID, KBuff.nLevel), KBuff.nStackNum, szDuration)
						else
							txt = string.format('%s_%s', oo.txt or X.GetBuffName(KBuff.dwID, KBuff.nLevel), szDuration)
						end
					else
						return oo:Free()
					end
				elseif oo.szType == 'Life' or oo.szType == 'Mana' then
					if kTarget.nMoveState == MOVE_STATE.ON_DEATH then
						return oo:Free()
					end
					if oo.szType == 'Life' then
						if fLifePer > O.fLifePer then
							return oo:Free()
						end
						txt = g_tStrings.STR_SKILL_H_LIFE_COST .. string.format('%d/%d', tInfo.nCurrentLife, tInfo.nMaxLife)
					elseif oo.szType == 'Mana' then
						if fManaPer > O.fManaPer then
							return oo:Free()
						end
						txt = g_tStrings.STR_SKILL_H_MANA_COST .. string.format('%d/%d', tInfo.nCurrentMana, tInfo.nMaxMana)
					end
				elseif oo.szType == 'CASTING' then
					local nType, dwSkillID, dwSkillLevel, fCastPercent = X.GetCharacterOTActionState(kTarget)
					if nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
					or nType == X.CONSTANT.CHARACTER_OTACTION_TYPE.ANCIENT_ACTION_PREPARE then
						txt = oo.txt or X.GetSkillName(dwSkillID, dwSkillLevel)
						fManaPer = fCastPercent
					else
						return oo:Free()
					end
				elseif oo.szType == 'NPC' or oo.szType == 'DOODAD' then
					txt = oo.txt or txt
				elseif oo.szType == 'TIME' then
					if (GetTime() - oo.nNow) / 1000 > 5 then
						return oo:Free()
					end
					txt = oo.txt or _L['Call Alert']
				end
				if not oo.init or FORCE_DRAW then
					oo:DrawBackGround()
				end
				oo:DrawLifeBar(fLifePer, fManaPer):DrawText(txt, szName):DrawArrow()
				if dwType == TARGET.PLAYER then
					local dwMountKungfuID = -1
					if dwID == X.GetClientPlayerID() then
						dwMountKungfuID = UI_GetPlayerMountKungfuID()
					else
						local info = X.GetTeamMemberInfo(dwID)
						if info and not X.IsEmpty(info.dwActualMountKungfuID) then
							dwMountKungfuID = info.dwActualMountKungfuID
						else
							local kungfu = kTarget.GetKungfuMount()
							if kungfu then
								dwMountKungfuID = kungfu.dwSkillID
							end
						end
					end
					rlcmd(string.format("set caption kungfu icon %u %u %u", dwID, 1, dwMountKungfuID))
				end
				-- 这里要想办法覆盖C++的颜色设置 C++代码上有个强制逻辑 优先级比rlcmd还高 估计是两个人写的
				local szRelation = X.GetCharacterRelation(UI_GetClientPlayerID(), dwID)
				local aColor = Config('get', 'Color', szRelation, IsPlayer(dwID) and 'Player' or 'Npc')
				if aColor then
					rlcmd(string.format("set plugin caption color %u %u %u", dwID, 1, RGB2Dword(unpack(aColor))))
				end
			else
				for _, vv in pairs(v) do
					vv:Free()
				end
			end
		end
	end
	FORCE_DRAW = false
end

function D.GetAction(dwType, dwID)
	local tab = CACHE[dwType][dwID]
	if #tab > 1 then
		for k, v in ipairs(CACHE[dwType][dwID]) do
			v:Hide()
		end
	end
	local obj = CACHE[dwType][dwID][#CACHE[dwType][dwID]]
	return obj:Show()
end

function D.GetObject(szType, dwID)
	local dwType, kTarget, tInfo
	if szType == 'DOODAD' or szType == TARGET.DOODAD then
		dwType = TARGET.DOODAD
		kTarget = GetDoodad(dwID)
	elseif IsPlayer(dwID) then
		dwType = TARGET.PLAYER
		local me = GetClientPlayer()
		if dwID == me.dwID then
			kTarget = me
		elseif X.IsTeammate(dwID) then
			kTarget = GetPlayer(dwID)
			tInfo  = GetClientTeam().GetMemberInfo(dwID)
		else
			kTarget = GetPlayer(dwID)
		end
	else
		dwType = TARGET.NPC
		kTarget = GetNpc(dwID)
	end
	tInfo = tInfo and tInfo or kTarget
	return dwType, kTarget, tInfo
end

function D.RegisterFight()
	if arg0 and O.bAlert then
		X.BreatheCall('ScreenArrow_Fight', D.OnBreatheFight)
	else
		D.KillBreathe()
	end
end

function D.KillBreathe()
	X.BreatheCall('ScreenArrow_Fight', false)
	D.tCache['Mana'] = {}
	D.tCache['Life'] = {}
end

function D.OnBreatheFight()
	local me = GetClientPlayer()
	if not me then return end
	if not me.bFightState then -- kill fix bug
		return D.KillBreathe()
	end
	local team = GetClientTeam()
	local list = {}
	if me.IsInParty() and not O.bOnlySelf then
		list = team.GetTeamMemberList()
	else
		list[1] = me.dwID
	end
	for k, v in ipairs(list) do
		local kTarget, tInfo = select(2, D.GetObject(TARGET.PLAYER, v))
		if kTarget and tInfo then
			if kTarget.nMoveState == MOVE_STATE.ON_DEATH then
				D.tCache['Mana'][v] = nil
				D.tCache['Life'][v] = nil
			else
				local fLifePer = tInfo.nCurrentLife / math.max(tInfo.nMaxLife, tInfo.nCurrentLife, 1)
				local fManaPer = tInfo.nCurrentMana / math.max(tInfo.nMaxMana, tInfo.nCurrentMana, 1)
				if fLifePer < O.fLifePer then
					if not D.tCache['Life'][v] then
						D.tCache['Life'][v] = true
						CreateScreenArrow(v, 'Life')
					end
				else
					D.tCache['Life'][v] = nil
				end
				if fManaPer < O.fManaPer and (kTarget.dwForceID < 7 or kTarget.dwForceID == 22) then
					if not D.tCache['Mana'][v] then
						D.tCache['Mana'][v] = true
						CreateScreenArrow(v, 'Mana')
					end
				else
					D.tCache['Mana'][v] = nil
				end
			end
		end
	end
end

function SA:ctor(dwID, szType, tArgs)
	local dwType, kTarget = D.GetObject(szType, dwID)
	if not X.IsDebugging() and not X.IsInDungeonMap(true) then
		if dwType == TARGET.NPC and kTarget.bDialogFlag then
			return
		end
	end
	local ui = HANDLE:New()
	local col = tArgs.col
	if col then
		col = {X.HumanColor2RGB(tArgs.col)}
	else
		col = SA_COLOR.ARROW[szType]
	end

	local oo = {}
	setmetatable(oo, self)
	oo.szName   = tArgs.szName
	oo.txt      = tArgs.szText
	oo.col      = col
	oo.dwBuffID = tArgs.dwBuffID
	oo.szType   = szType

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
	if szType == 'TIME' then
		oo.nNow = GetTime()
	end
	oo.Text:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	for k, v in pairs({ oo.BGB, oo.BGI, oo.Life, oo.Mana, oo.Arrow }) do
		v:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		v:SetD3DPT(D3DPT.TRIANGLEFAN)
	end
	CACHE[dwType][dwID] = CACHE[dwType][dwID] or {}
	table.insert(CACHE[dwType][dwID], oo)
	return oo
end

-- 从下至上 依次绘制
function SA:DrawText( ... )
	self.Text:ClearTriangleFanPoint()
	local nTop = BASE_PEAK - (BASE_EDGE * 2)
	-- local r, g, b = unpack(SA_COLOR.FONT[self.szType])
	local r, g, b = unpack(self.col)
	local i = 1
	for k, v in ipairs({ ... }) do
		if v and v ~= '' then
			local top = nTop + i * -18 * O.fTextScale * UI_SCALE
			if self.dwType == TARGET.DOODAD then
				self.Text:AppendDoodadID(self.dwID, r, g, b, 240, { 0, 0, 0, 0, top }, O.nFont, v, 1, O.fTextScale)
			else
				if O.bDrawColor and self.dwType == TARGET.PLAYER and k ~= 1 then
					local kTarget = select(2, D.GetObject(self.szType, self.dwID))
					if kTarget then
						r, g, b = X.GetForceColor(kTarget.dwForceID, 'foreground')
					end
				end
				self.Text:AppendCharacterID(self.dwID, true, r, g, b, 240, { 0, 0, 0, 0, top }, O.nFont, v, 1, O.fTextScale)
			end
			i = i + 1
		end
	end
	return self
end

function SA:DrawBackGround()
	local bcX, bcY = -BASE_WIDTH / 2, BASE_PEAK
	local doubleEdge = BASE_EDGE * 2
	self.BGB:ClearTriangleFanPoint()
	self.BGI:ClearTriangleFanPoint()
	if self.dwType == TARGET.DOODAD then
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY + BASE_HEIGHT })
		self.BGB:AppendDoodadID(self.dwID, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + BASE_HEIGHT })
		bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY + BASE_HEIGHT - doubleEdge })
		self.BGI:AppendDoodadID(self.dwID, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + BASE_HEIGHT - doubleEdge})
	else
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX + BASE_WIDTH, bcY + BASE_HEIGHT })
		self.BGB:AppendCharacterID(self.dwID, true, 255, 255, 255, 200, { 0, 0, 0, bcX, bcY + BASE_HEIGHT })
		bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX + BASE_WIDTH - doubleEdge, bcY + BASE_HEIGHT - doubleEdge })
		self.BGI:AppendCharacterID(self.dwID, true, 120, 120, 120, 80, { 0, 0, 0, bcX, bcY + BASE_HEIGHT - doubleEdge})
	end
	self.init = true
	return self
end

function SA:DrawLifeBar(fLifePer, fManaPer)
	local height = BASE_HEIGHT / 2 - BASE_EDGE
	local width = BASE_WIDTH - (BASE_EDGE * 2)
	if fLifePer ~= self.fLifePer or FORCE_DRAW then
		self.Life:ClearTriangleFanPoint()
		if fLifePer > 0 then
			local bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + BASE_EDGE
			local r, g ,b = 220, 40, 0
			if self.dwType == TARGET.DOODAD then
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY + height })
				self.Life:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			else
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fLifePer), bcY + height })
				self.Life:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			end
		end
		self.fLifePer = fLifePer
	end
	if fManaPer ~= self.fManaPer or FORCE_DRAW then
		self.Mana:ClearTriangleFanPoint()
		if fManaPer > 0 then
			local bcX, bcY = -BASE_WIDTH / 2 + BASE_EDGE, BASE_PEAK + height + BASE_EDGE
			local r, g ,b = 50, 100, 255
			if self.szType == 'CASTING' then
				r, g ,b = 255, 128, 0
			end
			if self.dwType == TARGET.DOODAD then
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY + height })
				self.Mana:AppendDoodadID(self.dwID, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			else
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX + (width * fManaPer), bcY + height })
				self.Mana:AppendCharacterID(self.dwID, true, r, g, b, 225, { 0, 0, 0, bcX, bcY + height })
			end
		end
		self.fManaPer = fManaPer
	end
	return self
end

function SA:DrawArrow()
	local cX, cY, cA = unpack(SA_POINT_C)
	cX, cY = cX * 0.7, cY * 0.7
	local fX, fY = BASE_POINT_START, -BASE_PEAK - BASE_HEIGHT
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
	rlcmd(string.format("set caption kungfu icon %u %u", self.dwID, 0))
	rlcmd(string.format("reset caption %u", self.dwID))

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

local PS = { nPriority = 13, szRestriction = 'MY_LifeBar_ScreenArrow' }
function PS.OnPanelActive(wnd)
	local ui = X.UI(wnd)
	local nPaddingX, nPaddingY = 30, 30
	local nX, nY = nPaddingX, nPaddingY

	nY = nY + ui:Append('Text', { x = nX, y = nY, text = _L['Screen head alarm'], font = 27 }):Height() + 5
	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox',{
		x = nX, y = nY,
		text = _L['Enable'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
		end
	}):Width()
	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Draw School Color'],
		checked = O.bDrawColor,
		onCheck = function(bChecked)
			O.bDrawColor = bChecked
		end,
		autoEnable = function() return O.bEnable end,
	}):Height() + 5

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = nY,
		text = _L['UI scale'],
		autoEnable = function() return O.bEnable end,
	}):Width()
	nY = nY + ui:Append('WndSlider', {
		x = nX, y = nY, sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE, range = { 0, 400 },
		text = function(value) return _L('%.1f%%', value) end,
		value = O.fUIScale * 100,
		onChange = function(value)
			O.fUIScale = value / 100
			SetUIScale()
		end,
		autoEnable = function() return O.bEnable end,
	}):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Text scale'],
		autoEnable = function() return O.bEnable end,
	}):Width()
	nY = nY + ui:Append('WndSlider', {
		x = nX, y = nY, sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE, range = { 0, 400 },
		text = function(value) return _L('%.1f%%', value) end,
		value = O.fTextScale * 100,
		onChange = function(value)
			O.fTextScale = value / 100
			SetUIScale()
		end,
		autoEnable = function() return O.bEnable end,
	}):Height()

	nX = nPaddingX
	nY = nY + 10
	nY = nY + ui:Append('Text', { x = nX, y = nY + 5, text = _L['Less life/mana head alert'], font = 27 }):Height() + 10
	nX = nPaddingX + 10
	nX = nX + ui:Append('WndCheckBox',{
		x = nX, y = nY,
		text = _L['Enable'],
		checked = O.bAlert,
		onCheck = function(bChecked)
			O.bAlert = bChecked
			local me = GetClientPlayer()
			if bChecked and me.bFightState then
				X.BreatheCall('ScreenArrow_Fight', D.OnBreatheFight)
			else
				D.KillBreathe()
			end
		end,
		autoEnable = function() return O.bEnable end,
	}):Width() + 10
	nY = nY + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Only monitor self'],
		checked = O.bOnlySelf,
		onCheck = function(bChecked)
			O.bOnlySelf = bChecked
		end,
		autoEnable = function() return O.bEnable and O.bAlert end,
	}):Height() + 5

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = nY,
		text = _L['While HP less than'],
		autoEnable = function() return O.bEnable and O.bAlert end,
	}):Width() + 10
	nY = nY + ui:Append('WndSlider', {
		x = nX, y = nY + 3,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {0, 100},
		text = function(value) return value .. '%' end,
		value = O.fLifePer * 100,
		onChange = function(nVal) O.fLifePer = nVal / 100 end,
		autoEnable = function() return O.bEnable and O.bAlert end,
	}):Height()

	nX = nPaddingX + 10
	nX = nX + ui:Append('Text', {
		x = nX, y = nY,
		text = _L['While MP less than'],
		autoEnable = function() return O.bEnable and O.bAlert end,
	}):Width()
	nX = nX + 10
	nY = nY + ui:Append('WndSlider', {
		x = nX, y = nY + 3,
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		range = {0, 100},
		text = function(value) return value .. '%' end,
		value = O.fManaPer * 100,
		onChange = function(nVal) O.fManaPer = nVal / 100 end,
		autoEnable = function() return O.bEnable and O.bAlert end,
	}):Height()

	nX = nPaddingX
	nY = nY + 10
	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY + 5,
		text = g_tStrings.FONT,
		onClick =  function()
			X.UI.OpenFontPicker(function(nFont)
				O.nFont = nFont
			end)
		end,
		autoEnable = function() return O.bEnable end,
	}):Width()
	nX = nX + 10
	ui:Append('WndButton', {
		x = nX, y = nY + 5,
		text = _L['Preview'],
		onClick = function()
			CreateScreenArrow(GetClientPlayer().dwID, 'TIME', { szText = _L['PVE everyday, Xuanjing everyday!'] })
		end,
		autoEnable = function() return O.bEnable end,
	})
end
X.Panel.Register(_L['Raid'], 'MY_LifeBar_ScreenArrow', _L['MY_LifeBar_ScreenArrow'], 431, PS)

function D.Init()
	HANDLE = X.UI.HandlePool(X.UI.GetShadowHandle('ScreenArrow'), FormatHandle(string.rep('<shadow></shadow>', 6)))
	SetUIScale()
	X.BreatheCall('ScreenArrow_Sort', 500, D.OnSort)
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_LifeBar_ScreenArrow',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'IsEnabled',
				'ProcessCountdown'
			},
			root = D,
		},
	},
}
MY_LifeBar_ScreenArrow = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.BreatheCall('MY_LifeBar_ScreenArrow', D.OnBreathe)
X.RegisterEvent('FIGHT_HINT', 'MY_LifeBar_ScreenArrow', D.RegisterFight)
X.RegisterEvent('LOGIN_GAME', 'MY_LifeBar_ScreenArrow', D.Init)
X.RegisterEvent('UI_SCALED' , 'MY_LifeBar_ScreenArrow', SetUIScale)

X.RegisterUserSettingsInit('MY_LifeBar_ScreenArrow', function()
	D.bReady = true
end)
X.RegisterUserSettingsRelease('MY_LifeBar_ScreenArrow', function()
	D.bReady = false
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
