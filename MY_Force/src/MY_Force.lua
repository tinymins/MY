--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 职业特色增强
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Force/MY_Force'
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Force'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_Force', { ['*'] = false })
X.RegisterRestriction('MY_ForceGuding', { ['*'] = true, intl = false })
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_Force', _L['Target'], {
	bAlertPet = { -- 五毒宠物消失提醒
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Alert when pet disappear unexpectedly (for 5D)'],
		}),
		xSchema = X.Schema.Boolean,
		szVersion = '20221109',
		xDefaultValue = false,
	},
	bMarkPet = { -- 五毒宠物标记
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Mark pet'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFeedHorse = { -- 提示喂马
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Alert when horse is hungry'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bWarningDebuff = { -- 警告 debuff 类型
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Alert when my same type of debuff reached a certain number '],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nDebuffNum = { -- debuff 类型达到几个时警告
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Alert when my same type of debuff reached a certain number '],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 3,
	},
	bAlertWanted = { -- 在线被悬赏时提醒自己
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['Alert when I am wanted publishing online'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {
	nFrameXJ = 0, -- 献祭、各种召唤跟宠的帧数
}

-- check pet of 5D （XJ：2226）
function D.OnAlertPetChange()
	local bAlertPet = O.bAlertPet
	if bAlertPet then
		X.RegisterEvent('NPC_LEAVE_SCENE', 'MY_Force__AlertPet', function()
			local me = X.GetClientPlayer()
			if me and me.dwForceID == FORCE_TYPE.WU_DU then
				local pet = me.GetPet()
				if pet and pet.dwID == arg0 and (GetLogicFrameCount() - D.nFrameXJ) >= 32 then
					OutputWarningMessage('MSG_WARNING_YELLOW', _L('Your pet [%s] disappeared!',  pet.szName))
					PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
				end
			end
		end)
		X.RegisterEvent('DO_SKILL_CAST', 'MY_Force__AlertPet', function()
			if arg0 == X.GetClientPlayerID() then
				-- 献祭、各种召唤：2965，2221 ~ 2226
				if arg1 == 2965 or (arg1 >= 2221 and arg1 <= 2226) then
					D.nFrameXJ = GetLogicFrameCount()
				end
			end
		end)
	else
		X.RegisterEvent('NPC_LEAVE_SCENE', 'MY_Force__AlertPet', false)
		X.RegisterEvent('DO_SKILL_CAST', 'MY_Force__AlertPet', false)
	end
end

-- check to mark pet
do
local function UpdatePetMark(bMark)
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local pet = me.GetPet()
	if pet then
		local dwEffect = 13
		if not bMark then
			dwEffect = 0
		end
		SceneObject_SetTitleEffect(TARGET.NPC, pet.dwID, dwEffect)
	end
end
function D.OnMarkPetChange()
	local bMarkPet = O.bMarkPet
	if bMarkPet then
		X.RegisterEvent({'NPC_ENTER_SCENE', 'NPC_DISPLAY_DATA_UPDATE'}, 'MY_Force__MarkPet', function()
			local pet = X.GetClientPlayer().GetPet()
			if pet and arg0 == pet.dwID then
				X.DelayCall(500, function()
					UpdatePetMark(true)
				end)
			else
				local npc = X.GetNpc(arg0)
				if npc.dwTemplateID == 46297 and npc.dwEmployer == X.GetClientPlayerID() then
					SceneObject_SetTitleEffect(TARGET.NPC, npc.dwID, 13)
				end
			end
		end)
	else
		X.RegisterEvent({'NPC_ENTER_SCENE', 'NPC_DISPLAY_DATA_UPDATE'}, 'MY_Force__MarkPet', false)
	end
	UpdatePetMark(bMarkPet)
end
end

-- check feed horse
function D.OnFeedHorseChange()
	local bFeedHorse = O.bFeedHorse
	if bFeedHorse then
		X.RegisterEvent('SYS_MSG', 'MY_Force__FeedHorse', function()
			local me = X.GetClientPlayer()
			-- 读条技能
			if arg0 == 'UI_OME_SKILL_CAST_LOG' and O.bFeedHorse and arg1 == me.dwID
			and (arg2 == 433 or arg2 == 53 or Table_GetSkillName(arg2, 1) == Table_GetSkillName(53, 1)) then -- on prepare 骑乘
				local it = me.GetEquippedHorse()
				if it then
					local nFullLevel = it.GetHorseFullLevel()
					if nFullLevel ~= FULL_LEVEL.FULL then
						local itemInfo = GetItemInfo(it.dwTabType, it.dwIndex)
						local tDisplay = Table_GetRideSubDisplay(itemInfo.nDetail)
						local szFullMeasure = tDisplay['szFullMeasure' .. (nFullLevel + 1)]
						OutputWarningMessage('MSG_WARNING_YELLOW', Table_GetItemName(it.nUiId) .. ': ' .. szFullMeasure)
						PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
					end
				end
			end
		end)
	else
		X.RegisterEvent('SYS_MSG', 'MY_Force__FeedHorse', false)
	end
end

-- check warning buff type
function D.OnWarningDebuffChange()
	local bWarningDebuff = O.bWarningDebuff
	if bWarningDebuff then
		X.RegisterEvent('BUFF_UPDATE', 'MY_Force__WarningDebuff', function()
			-- buff update：
			-- arg0：dwPlayerID，arg1：bDelete，arg2：nIndex，arg3：bCanCancel
			-- arg4：dwBuffID，arg5：nStackNum，arg6：nEndFrame，arg7：？update all?
			-- arg8：nLevel，arg9：dwSkillSrcID
			local me = X.GetClientPlayer()
			if arg0 ~= me.dwID or not O.bWarningDebuff or (not arg7 and arg3) then
				return
			end
			local t, t2 = {}, {}
			for _, buff in X.ipairs_c(X.GetBuffList(me)) do
				if not buff.bCanCancel and not t2[buff.dwID] then
					local info = GetBuffInfo(buff.dwID, buff.nLevel, {})
					if info and info.nDetachType > 2 then
						if not t[info.nDetachType] then
							t[info.nDetachType] = 1
						else
							t[info.nDetachType] = t[info.nDetachType] + 1
						end
						t2[buff.dwID] = true
					end
				end
			end
			for nType, nNum in pairs(t) do
				if nNum >= O.nDebuffNum then
					local szText = _L('Your debuff of type [%s] reached [%d]', g_tStrings.tBuffDetachType[nType], nNum)
					OutputWarningMessage('MSG_WARNING_GREEN', szText)
					PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
				end
			end
		end)
	else
		X.RegisterEvent('BUFF_UPDATE', 'MY_Force__WarningDebuff', false)
	end
end

-- check on wanted msg
do
local function OnMsgAnnounce(szMsg)
	local _, _, sM, sN = string.find(szMsg, _L['Now somebody pay (%d+) gold to buy life of (.-)'])
	if sM and sN == X.GetClientPlayer().szName then
		local fW = function()
			OutputWarningMessage('MSG_WARNING_RED', _L('Congratulations, you offered a reward [%s] gold!', sM))
			PlaySound(SOUND.UI_SOUND, g_sound.CloseAuction)
		end
		SceneObject_SetTitleEffect(TARGET.PLAYER, X.GetClientPlayerID(), 47)
		fW()
		X.DelayCall(2000, fW)
		X.DelayCall(4000, fW)
		D.bHasWanted = true
	end
end
function D.OnAlertWantedChange()
	local bAlertWanted = O.bAlertWanted
	if bAlertWanted then
		-- 变化时更新头顶效果
		X.RegisterEvent('PLAYER_STATE_UPDATE', 'MY_Force__AlertWanted', function()
			if arg0 == X.GetClientPlayerID() then
				if D.bHasWanted then
					SceneObject_SetTitleEffect(TARGET.PLAYER, arg0, 47)
				end
			end
		end)
		-- 重伤后删除头顶效果
		X.RegisterEvent('SYS_MSG', 'MY_Force__AlertWanted', function()
			if arg0 == 'UI_OME_DEATH_NOTIFY' then
				if D.bHasWanted and arg1 == X.GetClientPlayerID() then
					D.bHasWanted = nil
					SceneObject_SetTitleEffect(TARGET.PLAYER, arg1, 0)
				end
			end
		end)
		RegisterMsgMonitor(OnMsgAnnounce, {'MSG_GM_ANNOUNCE'})
	else
		X.RegisterEvent('PLAYER_STATE_UPDATE', 'MY_Force__AlertWanted', false)
		X.RegisterEvent('SYS_MSG', 'MY_Force__AlertWanted', false)
		UnRegisterMsgMonitor(OnMsgAnnounce, {'MSG_GM_ANNOUNCE'})
	end
end
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('LOADING_END', 'MY_Force', function()
	local buff = Table_GetBuff(374, 1)
	if buff then
		buff.bShowTime = 1
	end
end)

X.RegisterUserSettingsInit('MY_Force', function()
	D.OnAlertPetChange()
	D.OnMarkPetChange()
	D.OnFeedHorseChange()
	D.OnWarningDebuffChange()
	D.OnAlertWantedChange()
end)

-------------------------------------
-- 设置界面
-------------------------------------
local PS = { szRestriction = 'MY_Force' }
function PS.OnPanelActive(frame)
	local ui = X.UI(frame)
	local nPaddingX, nPaddingY = 25, 25
	local nX, nY = nPaddingX, nPaddingY
	local nW, nH = ui:Size()
	-- wu du
	---------------
	ui:Append('Text', { text = g_tStrings.tForceTitle[X.CONSTANT.FORCE_TYPE.WU_DU], x = nX, y = nY, font = 27 })
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	-- disappear
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Alert when pet disappear unexpectedly (for 5D)'],
		checked = O.bAlertPet,
		onCheck = function(bChecked)
			O.bAlertPet = bChecked
			D.OnAlertPetChange()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	-- mark pet
	ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Mark pet'],
		checked = O.bMarkPet,
		onCheck = function(bChecked)
			O.bMarkPet = bChecked
			D.OnMarkPetChange()
		end,
	}):AutoWidth()
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	-- guding
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Display GUDING of teammate, change color'],
		checked = MY_ForceGuding.bEnable,
		onCheck = function(bChecked)
			MY_ForceGuding.bEnable = bChecked
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 2
	nX = ui:Append('Shadow', {
		x = nX, y = nY + 2, w = 18, h = 18,
		color = MY_ForceGuding.color,
		onClick = function()
			local ui = X.UI(this)
			OpenColorTablePanel(function(r, g, b)
				ui:Color(r, g, b)
				MY_ForceGuding.color = { r, g, b }
			end)
		end,
	}):Pos('BOTTOMRIGHT') + 10
	ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Auto talk in team channel after puting GUDING'],
		checked = MY_ForceGuding.bAutoSay,
		autoEnable = function() return MY_ForceGuding.bEnable end,
		onCheck = function(bChecked)
			MY_ForceGuding.bAutoSay = bChecked
		end,
	})
	nX = nPaddingX + 10
	nY = nY + 28
	ui:Append('WndEditBox', {
		x = nX, y = nY, w = nW - nX * 2, h = 50,
		multiline = true, limit = 512,
		text = MY_ForceGuding.szSay,
		autoEnable = function() return MY_ForceGuding.bAutoSay end,
		onChange = function(szText)
			MY_ForceGuding.szSay = szText
		end,
	})
	-- crlf
	nY = nY + 54
	if not X.IsRestricted('MY_ForceGuding') then
		-- crlf
		nX = nPaddingX + 10
		nX = ui:Append('WndCheckBox', {
			x = nX, y = nY,
			checked = MY_ForceGuding.bUseMana,
			text = _L['Automatic eat GUDING when mana below '],
			onCheck = function(bChecked)
				MY_ForceGuding.bUseMana = bChecked
			end,
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		nX = ui:Append('WndSlider', {
			x = nX, y = nY, w = 70, h = 25,
			range = {0, 100, 50},
			value = MY_ForceGuding.nManaMp,
			onChange = function(nVal) MY_ForceGuding.nManaMp = nVal end,
			autoEnable = function() return MY_ForceGuding.bUseMana end,
		}):Pos('BOTTOMRIGHT') + 65
		nX = ui:Append('Text', {
			x = nX, y = nY - 3,
			text = _L[', or life below '],
		}):AutoWidth():Pos('BOTTOMRIGHT') + 5
		nX = ui:Append('WndSlider', {
			x = nX, y = nY, w = 70, h = 25,
			range = {0, 100, 50},
			value = MY_ForceGuding.nManaHp,
			onChange = function(nVal) MY_ForceGuding.nManaHp = nVal end,
			autoEnable = function() return MY_ForceGuding.bUseMana end,
		}):Pos('BOTTOMRIGHT')
		nY = nY + 36
	end
	-- other
	---------------
	nX = nPaddingX
	ui:Append('Text', { text = _L['Others'], x = nX, y = nY, font = 27 })
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	-- hungry
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Alert when horse is hungry'],
		checked = O.bFeedHorse,
		onCheck = function(bChecked)
			O.bFeedHorse = bChecked
			D.OnFeedHorseChange()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	-- be wanted alert
	ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Alert when I am wanted publishing online'],
		checked = O.bAlertWanted,
		onCheck = function(bChecked)
			O.bAlertWanted = bChecked
			D.OnAlertWantedChange()
		end,
	})
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	-- debuff type num
	nX = ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Alert when my same type of debuff reached a certain number '],
		checked = O.bWarningDebuff,
		onCheck = function(bChecked)
			O.bWarningDebuff = bChecked
			D.OnWarningDebuffChange()
		end,
	}):AutoWidth():Pos('BOTTOMRIGHT') + 10
	ui:Append('WndComboBox', {
		x = nX, y = nY, w = 50, h = 25,
		autoEnable = function() return O.bWarningDebuff end,
		text = tostring(O.nDebuffNum),
		menu = function()
			local ui = X.UI(this)
			local m0 = {}
			for i = 1, 10 do
				table.insert(m0, {
					szOption = tostring(i),
					fnAction = function()
						O.nDebuffNum = i
						ui:Text(tostring(i))
					end,
				})
			end
			return m0
		end,
	})
	-- crlf
	nX = nPaddingX + 10
	nY = nY + 28
	nX, nY = MY_ChangGeShadow.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
end
X.Panel.Register(_L['Target'], 'MY_Force', _L['MY_Force'], 327, PS)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
