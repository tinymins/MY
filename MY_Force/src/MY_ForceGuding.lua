--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 五毒仙王蛊鼎显示
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Force/MY_ForceGuding'
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Force'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ForceGuding', _L['Target'], {
	bEnable = { -- 总开关
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Display GUDING of teammate, change color'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bAutoSay = { -- 摆鼎后自动说话
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Auto talk in team channel after puting GUDING'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	szSay = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Talk message'],
		}),
		xSchema = X.Schema.String,
		xDefaultValue = _L['I have put the GUDING, hurry to eat if you lack of mana. *la la la*'],
	},
	color = { -- 名称颜色，默认绿色
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Name color'],
		}),
		xSchema = X.Schema.Tuple(X.Schema.Number, X.Schema.Number, X.Schema.Number),
		xDefaultValue = { 255, 0, 128 },
	},
	bUseMana = { -- 路过时自动吃毒锅
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Automatic eat GUDING when'],
		}),
		szRestriction = 'MY_ForceGuding',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nManaMp = { -- 自动吃的 MP 百分比
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Automatic eat GUDING when'],
			_L['Mana Mp'],
		}),
		szRestriction = 'MY_ForceGuding',
		xSchema = X.Schema.Number,
		xDefaultValue = 80,
	},
	nManaHp = { -- 自动吃的 HP 百分比
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ForceGuding'],
			_L['Automatic eat GUDING when'],
			_L['Mana Hp'],
		}),
		szRestriction = 'MY_ForceGuding',
		xSchema = X.Schema.Number,
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
function D.OutputDebugMessage(szMsg)
	X.OutputDebugMessage(_L['MY_ForceGuding'], szMsg, X.DEBUG_LEVEL.LOG)
end
--[[#DEBUG END]]

-- add to list
function D.AddToList(tar, dwCaster, dwTime, szEvent)
	D.tList[tar.dwID] = { dwCaster = dwCaster, dwTime = dwTime }
	-- bg notify
	local me = X.GetClientPlayer()
	if szEvent == 'DO_SKILL_CAST' and me.IsInParty() then
		X.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_GUDING_NOTIFY', {tar.dwID, dwCaster}, true)
	end
	if O.bAutoSay and me.dwID == dwCaster then
		local nChannel = PLAYER_TALK_CHANNEL.RAID
		if not me.IsInParty() then
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		end
		X.SendChat(nChannel, O.szSay)
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
	local player = X.GetPlayer(dwCaster)
	if player and dwSkillID == D.dwSkillID and (dwCaster == X.GetClientPlayerID() or X.IsTeammate(dwCaster)) then
		table.insert(D.tCast, { dwCaster = dwCaster, dwTime = GetTime(), szEvent = szEvent })
		--[[#DEBUG BEGIN]]
		D.OutputDebugMessage('[' .. player.szName .. '] cast [' .. X.GetSkillName(dwSkillID, dwLevel) .. '#' .. szEvent .. ']')
		--[[#DEBUG END]]
	end
end

-- doodad enter
function D.OnDoodadEnter()
	local tar = X.GetDoodad(arg0)
	if not tar or D.tList[arg0] or tar.dwTemplateID ~= D.dwTemplateID then
		return
	end
	--[[#DEBUG BEGIN]]
	D.OutputDebugMessage('[' .. tar.szName .. '] enter scene')
	--[[#DEBUG END]]
	-- find caster
	for k, v in ipairs(D.tCast) do
		local nTime = GetTime() - v.dwTime
		--[[#DEBUG BEGIN]]
		D.OutputDebugMessage('checking [#' .. v.dwCaster .. '], delay [' .. nTime .. ']')
		--[[#DEBUG END]]
		if nTime < D.nMaxDelay then
			table.remove(D.tCast, k)
			D.AddToList(tar, v.dwCaster, v.dwTime, v.szEvent)
			--[[#DEBUG BEGIN]]
			D.OutputDebugMessage('matched [' .. tar.szName .. '] casted by [#' .. v.dwCaster .. ']')
			--[[#DEBUG END]]
			return
		end
	end
	-- purge
	for k, v in pairs(D.tCast) do
		if (GetTime() - v.dwTime) > D.nMaxDelay then
			table.remove(D.tCast, k)
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
			D.OutputDebugMessage('received notify from [#' .. data[2] .. ']')
			--[[#DEBUG END]]
		end
	end
end

function D.OnEnableChange()
	local bEnable = D.bReady and O.bEnable
	local h = X.UI.GetShadowHandle('MY_ForceGuding')
	h:Clear()
	if bEnable then
		h:AppendItemFromString('<shadow>name="Shadow_Label"</shadow>')
		D.pLabel = h:Lookup('Shadow_Label')
		X.RegisterEvent('SYS_MSG', 'MY_ForceGuding', function()
			if arg0 == 'UI_OME_SKILL_HIT_LOG' then
				D.OnSkillCast(arg1, arg4, arg5, arg0)
			elseif arg0 == 'UI_OME_SKILL_EFFECT_LOG' then
				D.OnSkillCast(arg1, arg5, arg6, arg0)
			end
		end)
		X.RegisterEvent('DO_SKILL_CAST', 'MY_ForceGuding', function(event)
			D.OnSkillCast(arg0, arg1, arg2, event)
		end)
		X.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_ForceGuding', function()
			D.OnDoodadEnter()
		end)
		X.RegisterBgMsg('MY_GUDING_NOTIFY', 'MY_ForceGuding', D.OnSkillNotify)
		X.BreatheCall('MY_ForceGuding', function()
			-- skip frame
			local nFrame = GetLogicFrameCount()
			if nFrame >= D.nFrame and (nFrame - D.nFrame) < 8 then
				return
			end
			D.nFrame = nFrame
			-- check empty
			local sha, me = D.pLabel, X.GetClientPlayer()
			if not me or not MY_ForceGuding.bEnable or X.IsEmpty(D.tList) then
				return sha:Hide()
			end
			-- color, alpha
			local r, g, b = unpack(MY_ForceGuding.color)
			local a = 200
			local buff = X.GetBuff(me, 3488)
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
					local tar = X.GetDoodad(k)
					if tar then
						--  show name
						local szText = _L['-'] .. math.floor(nLeft / 1000)
						local player = X.GetPlayer(v.dwCaster)
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
		X.RegisterEvent('SYS_MSG', 'MY_ForceGuding', false)
		X.RegisterEvent('DO_SKILL_CAST', 'MY_ForceGuding', false)
		X.RegisterEvent('DOODAD_ENTER_SCENE', 'MY_ForceGuding', false)
		X.RegisterBgMsg('MY_GUDING_NOTIFY', 'MY_ForceGuding', false)
		X.BreatheCall('MY_ForceGuding', false)
	end
end

function D.OnUseManaChange()
	local bUseMana = D.bReady and O.bUseMana
	if bUseMana and not X.IsRestricted('MY_ForceGuding') then
		X.BreatheCall('MY_ForceGuding__UseMana', function()
			local nFrame = GetLogicFrameCount()
			-- check to use mana
			if not O.bUseMana or (D.nManaFrame and D.nManaFrame > (nFrame - 4)) then
				return
			end
			-- 没鼎
			local aList = D.tList
			if X.IsEmpty(aList) then
				return
			end
			-- 没自己
			local me = X.GetClientPlayer()
			if not me then
				return
			end
			local fCurrentLife, fMaxLife = X.GetCharacterLife(me)
			-- 不在地上
			if me.bOnHorse or me.nMoveState ~= MOVE_STATE.ON_STAND then
				return
			end
			-- 血蓝很足
			if (me.nCurrentMana / me.nMaxMana) > (O.nManaMp / 100) and (fCurrentLife / fMaxLife) > (O.nManaHp / 100) then
				return
			end
			-- 在读条
			if X.GetCharacterOTActionState(me) ~= X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_IDLE then
				return
			end
			-- 吃不了
			local buff = X.GetBuff(me, 3448)
			if buff and not buff.bCanCancel then
				return
			end
			-- 找鼎
			for k, _ in pairs(aList) do
				local doo = X.GetDoodad(k)
				if doo and X.GetCharacterDistance(me, doo) < 6 then
					D.nManaFrame = GetLogicFrameCount()
					X.InteractDoodad(doo.dwID)
					X.OutputSystemMessage(_L['Auto eat GUDING'])
					break
				end
			end
		end)
	else
		X.BreatheCall('MY_ForceGuding__UseMana', false)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
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
MY_ForceGuding = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_ForceGuding', function()
	D.bReady = true
	D.OnEnableChange()
	D.OnUseManaChange()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
