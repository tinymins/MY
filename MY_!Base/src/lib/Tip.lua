--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : Tip相关逻辑
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Tip')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-- 将输入转为 Rect 数组
local function ConvRectEl(Rect, ePos)
	if X.IsTable(Rect) and X.IsUserdata(Rect.___id) then
		if not ePos then
			if Rect:GetRoot():GetName() == 'PopupMenu' then
				ePos = ALW.RIGHT_LEFT
			else
				ePos = ALW.TOP_BOTTOM
			end
		end
		local x, y = Rect:GetAbsPos()
		local w, h = Rect:GetSize()
		Rect = { x, y, w, h }
	end
	return Rect, ePos
end

-- 智能布局，抄官方的
local function AdjustFramePos(frame, Rect, nPosType)
	if not nPosType then
		nPosType = ALW.CENTER
	end

	if Rect then
		if Rect[5] then
			frame:SetPoint("BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", -52, -90)
			local x, y = frame:GetAbsPos()
			local w, h = frame:GetSize()
			local bX = (x > Rect[1] and x < Rect[1] + Rect[3]) or (x + w > Rect[1] and x + w < Rect[1] + Rect[3]) or (Rect[1] > x and Rect[1] < x + w) or (Rect[1] + Rect[3] > x and Rect[1] + Rect[3] < x + w)
			local bY = (y > Rect[2] and y < Rect[2] + Rect[4]) or (y + h > Rect[2] and y + h < Rect[2] + Rect[4]) or (Rect[2] > y and Rect[2] < y + h) or (Rect[2] + Rect[4] > y and Rect[2] + Rect[4] < y + h)
			if bX and bY then
				local w, h = Station.GetClientSize()
				if not bY and bX then
					frame:SetPoint("BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", Rect[1] - w, -90)
				else
					frame:SetPoint("BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", -52, Rect[2] - h)
				end
			end
		else
			Rect[3] = math.max(Rect[3], 40)
			Rect[4] = math.max(Rect[4], 40)

			frame:CorrectPos(Rect[1], Rect[2], Rect[3], Rect[4], nPosType)
		end
	else
		frame:SetPoint("BOTTOMRIGHT", 0, 0, "BOTTOMRIGHT", -52, -90)
	end
end

-- nFont 为 true 表示传入的是Xml字符串 否则表示格式化的字体
function X.OutputTip(Rect, szText, nFont, ePos, nMaxWidth)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, szText, nFont, ePos, nMaxWidth = nil, Rect, szText, nFont, ePos
	end
	if nFont ~= true then
		szText = GetFormatText(szText, nFont or 18)
	end
	Rect, ePos = ConvRectEl(Rect, ePos)
	return OutputTip(szText, nMaxWidth or 800, Rect, ePos)
end

function X.OutputBuffTip(Rect, dwID, nLevel, nTime, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwID, nLevel, nTime, szExtraXml = nil, Rect, dwID, nLevel, nTime
	end
	local t = {}

	table.insert(t, GetFormatText(Table_GetBuffName(dwID, nLevel) .. '\t', 65))
	local buffInfo = GetBuffInfo(dwID, nLevel, {})
	if buffInfo and buffInfo.nDetachType and g_tStrings.tBuffDetachType[buffInfo.nDetachType] then
		table.insert(t, GetFormatText(g_tStrings.tBuffDetachType[buffInfo.nDetachType] .. '\n', 106))
	else
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
	end

	local szDesc = GetBuffDesc(dwID, nLevel, 'desc')
	if szDesc then
		table.insert(t, GetFormatText(szDesc .. g_tStrings.STR_FULL_STOP, 106))
	end

	if nTime then
		if nTime == 0 then
			table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(t, GetFormatText(g_tStrings.STR_BUFF_H_TIME_ZERO, 102))
		else
			local H, M, S = '', '', ''
			local h = math.floor(nTime / 3600)
			local m = math.floor(nTime / 60) % 60
			local s = math.floor(nTime % 60)
			if h > 0 then
				H = h .. g_tStrings.STR_BUFF_H_TIME_H .. ' '
			end
			if h > 0 or m > 0 then
				M = m .. g_tStrings.STR_BUFF_H_TIME_M_SHORT .. ' '
			end
			S = s..g_tStrings.STR_BUFF_H_TIME_S
			if h < 720 then
				table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
				table.insert(t, GetFormatText(FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, H, M, S), 102))
			end
		end
	end

	if szExtraXml then
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, szExtraXml)
	end
	-- For test
	if IsCtrlKeyDown() then
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP, 102))
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, GetFormatText('ID:     ' .. dwID, 102))
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, GetFormatText('Level:  ' .. nLevel, 102))
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, GetFormatText('IconID: ' .. tostring(Table_GetBuffIconID(dwID, nLevel)), 102))
	end
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 300, Rect)
end

function X.OutputSkillTip(Rect, dwSkilID, dwSkillLevel)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwSkilID, dwSkillLevel = nil, Rect, dwSkilID
	end
	Rect = ConvRectEl(Rect)
	OutputSkillTip(dwSkilID, dwSkillLevel, Rect, false)
end

function X.OutputTeamMemberTip(Rect, dwID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local team = GetClientTeam()
	local tMemberInfo = team.GetMemberInfo(dwID)
	if not tMemberInfo then
		return
	end
	local r, g, b = X.GetForceColor(tMemberInfo.dwForceID, 'foreground')
	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	local xml = {}
	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(X.ExtractPlayerBaseName(tMemberInfo.szName), true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(xml, GetFormatText(szPinyin .. '\n', 80, r, g, b))
		end
	end
	-- 门派
	table.insert(xml, GetFormatImage(szPath, nFrame, 22, 22))
	-- 名字
	table.insert(xml, GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, tMemberInfo.szName), 80, r, g, b))
	if tMemberInfo.bIsOnLine then
		local p = X.GetPlayer(dwID)
		if p and p.dwTongID > 0 then
			if X.GetTongName(p.dwTongID) then
				table.insert(xml, GetFormatText('[' .. X.GetTongName(p.dwTongID) .. ']\n', 41))
			end
		end
		table.insert(xml, GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, tMemberInfo.nLevel), 82))
		table.insert(xml, GetFormatText(X.GetSkillName(tMemberInfo.dwActualMountKungfuID, 1) .. '\n', 82))
		local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
		if szMapName then
			table.insert(xml, GetFormatText(szMapName .. '\n', 82))
		end
		table.insert(xml, GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[tMemberInfo.nCamp] .. '\n', 82))
	else
		table.insert(xml, GetFormatText(g_tStrings.STR_FRIEND_NOT_ON_LINE .. '\n', 82, 128, 128, 128))
	end
	if szExtraXml then
		table.insert(xml, szExtraXml)
	end
	if IsCtrlKeyDown() then
		table.insert(xml, GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, dwID), 102))
		local szGUID = X.IsDebugging() and X.GetPlayerGlobalID(dwID)
		if szGUID then
			table.insert(xml, GetFormatText('GUID: ' .. szGUID .. '\n', 102))
		end
	end
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(xml), 345, Rect)
end

function X.OutputPlayerTip(Rect, dwID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local player = X.GetPlayer(dwID)
	if not player then
		return
	end
	local me, t = X.GetClientPlayer(), {}
	local r, g, b = GetForceFontColor(dwID, me.dwID)

	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(X.ExtractPlayerBaseName(player.szName), true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(t, GetFormatText(szPinyin .. '\n', 80, r, g, b))
		end
	end
	-- 名字
	table.insert(t, GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, player.szName), 80, r, g, b))
	-- 称号
	if player.szTitle ~= '' then
		table.insert(t, GetFormatText('<' .. player.szTitle .. '>\n', 0))
	end
	-- 帮会
	if player.dwTongID ~= 0 then
		local szName = X.GetTongName(player.dwTongID, 1)
		if szName and szName ~= '' then
			table.insert(t, GetFormatText('[' .. szName .. ']\n', 0))
		end
	end
	-- 等级
	if player.nLevel - me.nLevel > 10 and not me.IsPlayerInMyParty(dwID) then
		table.insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	else
		table.insert(t, GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, player.nLevel), 82))
	end
	-- 声望
	if X.CONSTANT.FORCE_TYPE_LABEL[player.dwForceID] then
		table.insert(t, GetFormatText(X.CONSTANT.FORCE_TYPE_LABEL[player.dwForceID] .. '\n', 82))
	end
	-- 所在地图
	if IsParty(dwID, me.dwID) then
		local team = GetClientTeam()
		local tMemberInfo = team.GetMemberInfo(dwID)
		if tMemberInfo then
			local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
			if szMapName then
				table.insert(t, GetFormatText(szMapName .. '\n', 82))
			end
		end
	end
	-- 阵营
	if player.bCampFlag then
		table.insert(t, GetFormatText(g_tStrings.STR_TIP_CAMP_FLAG .. '\n', 163))
	end
	table.insert(t, GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[player.nCamp], 82))
	-- 角色备注
	if _G.MY_Anmerkungen and _G.MY_Anmerkungen.GetPlayerNote then
		local note = _G.MY_Anmerkungen.GetPlayerNote(player.dwID)
		if note and note.szContent ~= '' then
			table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(t, GetFormatText(note.szContent, 0))
		end
	end
	-- 自定义项
	if szExtraXml then
		table.insert(t, X.CONSTANT.XML_LINE_BREAKER)
		table.insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, player.dwID), 102))
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, player.dwModelID), 102))
		table.insert(t, GetFormatText(X.EncodeLUAData(player.GetRepresentID(), '  '), 102))
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 345, Rect)
end

function X.OutputNpcTemplateTip(Rect, dwNpcTemplateID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwNpcTemplateID, szExtraXml = nil, Rect, dwNpcTemplateID
	end
	local npc = GetNpcTemplate(dwNpcTemplateID)
	if not npc then
		return
	end
	local t = {}

	local szName = X.GetNpcTemplateName(dwNpcTemplateID) or tostring(dwNpcTemplateID)
	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(szName, true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(t, GetFormatText(szPinyin .. '\n', 80, 255, 255, 0))
		end
	end
	-- 名字
	table.insert(t, GetFormatText(szName .. '\n', 80, 255, 255, 0))
	-- 等级
	if npc.nLevel - X.GetClientPlayer().nLevel > 10 then
		table.insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	else
		table.insert(t, GetFormatText(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel), 0))
	end
	-- 模版ID
	table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, npc.nIntensity or 1), 101))
	-- 自定义项
	if szExtraXml then
		table.insert(t, szExtraXml)
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 345, Rect)
end

function X.OutputNpcTip(Rect, dwID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local npc = X.GetNpc(dwID)
	if not npc then
		return
	end

	local me = X.GetClientPlayer()
	local r, g, b = GetForceFontColor(dwID, me.dwID)
	local t = {}

	local szName = X.GetNpcName(npc.dwID)
	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(szName, true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(t, GetFormatText(szPinyin .. '\n', 80, r, g, b))
		end
	end
	-- 名字
	table.insert(t, GetFormatText(szName .. '\n', 80, r, g, b))
	-- 称号
	if npc.szTitle ~= '' then
		table.insert(t, GetFormatText('<' .. npc.szTitle .. '>\n', 0))
	end
	-- 等级
	if npc.nLevel - me.nLevel > 10 then
		table.insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	elseif npc.nLevel > 0 then
		table.insert(t, GetFormatText(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel), 0))
	end
	-- 势力
	if g_tReputation and g_tReputation.tReputationTable[npc.dwForceID] then
		table.insert(t, GetFormatText(g_tReputation.tReputationTable[npc.dwForceID].szName .. '\n', 0))
	end
	-- 任务信息
	if GetNpcQuestTip then
		table.insert(t, GetNpcQuestTip(npc.dwTemplateID))
	end
	-- 自定义项
	if szExtraXml then
		table.insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_NPC_ID, npc.dwID), 102))
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, npc.nIntensity), 102))
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, npc.dwModelID), 102))
		if IsShiftKeyDown() and GetNpcQuestState then
			local tState = GetNpcQuestState(npc, true)
			for szKey, tQuestList in pairs(tState) do
				tState[szKey] = table.concat(tQuestList, ',')
			end
			table.insert(t, GetFormatText(X.EncodeLUAData(tState, '  '), 102))
		end
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 345, Rect)
end

function X.OutputDoodadTemplateTip(Rect, dwTemplateID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwTemplateID, szExtraXml = nil, Rect, dwTemplateID
	end
	local doodad = GetDoodadTemplate(dwTemplateID)
	if not doodad then
		return
	end
	local t = {}
	local szName = doodad.szName ~= '' and doodad.szName or dwTemplateID
	if doodad.nKind == DOODAD_KIND.CORPSE then
		szName = szName .. g_tStrings.STR_DOODAD_CORPSE
	end
	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(szName, true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(t, GetFormatText(szPinyin .. '\n', 65))
		end
	end
	-- 名字
	table.insert(t, GetFormatText(szName .. '\n', 65))
	table.insert(t, GetDoodadQuestTip(dwTemplateID))
	-- 模版ID
	table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID), 101))
	if IsCtrlKeyDown() then
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID), 102))
	end
	-- 自定义项
	if szExtraXml then
		table.insert(t, szExtraXml)
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 300, Rect)
end

function X.OutputDoodadTip(Rect, dwDoodadID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwDoodadID, szExtraXml = nil, Rect, dwDoodadID
	end
	local doodad = X.GetDoodad(dwDoodadID)
	if not doodad then
		return
	end

	local player, t = X.GetClientPlayer(), {}
	local szDoodadName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
	if doodad.nKind == DOODAD_KIND.CORPSE then
		szDoodadName = szDoodadName .. g_tStrings.STR_DOODAD_CORPSE
	end
	-- 拼音
	if IsCtrlKeyDown() then
		local szPinyin = X.Han2TonePinyin(szDoodadName, true)[1]
		if not X.IsEmpty(szPinyin) then
			table.insert(t, GetFormatText(szPinyin .. '\n', 37))
		end
	end
	-- 名字
	table.insert(t, GetFormatText(szDoodadName .. '\n', 37))
	-- 采集信息
	if (doodad.nKind == DOODAD_KIND.CORPSE and not doodad.CanLoot(player.dwID)) or doodad.nKind == DOODAD_KIND.CRAFT_TARGET then
		local doodadTemplate = GetDoodadTemplate(doodad.dwTemplateID)
		if doodadTemplate.dwCraftID ~= 0 then
			local dwRecipeID = doodad.GetRecipeID()
			local recipe = GetRecipe(doodadTemplate.dwCraftID, dwRecipeID)
			if recipe then
				--生活技能等级--
				local profession = GetProfession(recipe.dwProfessionID)
				local requireLevel = recipe.dwRequireProfessionLevel
				--local playMaxLevel               = player.GetProfessionMaxLevel(recipe.dwProfessionID)
				local playerLevel                = player.GetProfessionLevel(recipe.dwProfessionID)
				--local playExp                    = player.GetProfessionProficiency(recipe.dwProfessionID)
				local nDis = playerLevel - requireLevel
				local nFont = 101
				if not player.IsProfessionLearnedByCraftID(doodadTemplate.dwCraftID) then
					nFont = 102
				end

				if doodadTemplate.dwCraftID == 1 or doodadTemplate.dwCraftID == 2 or doodadTemplate.dwCraftID == 3 then --采金 神农 庖丁
					table.insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_BEST_CRAFT, X.Table.GetProfessionName(recipe.dwProfessionID), requireLevel), nFont))
				elseif doodadTemplate.dwCraftID ~= 8 then --8 读碑文
					table.insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_CRAFT, X.Table.GetProfessionName(recipe.dwProfessionID), requireLevel), nFont))
				end

				if recipe.nCraftType == ALL_CRAFT_TYPE.READ then
					if recipe.dwProfessionIDExt ~= 0 then
						local nBookID, nSegmentID = X.RecipeToSegmentID(dwRecipeID)
						if player.IsBookMemorized(nBookID, nSegmentID) then
							table.insert(t, GetFormatText(g_tStrings.TIP_ALREADY_READ, 108))
						else
							table.insert(t, GetFormatText(g_tStrings.TIP_UNREAD, 105))
						end
					end
				end

				if recipe.dwToolItemType ~= 0 and recipe.dwToolItemIndex ~= 0 and doodadTemplate.dwCraftID ~= 8 then
					local hasItem = player.GetItemAmount(recipe.dwToolItemType, recipe.dwToolItemIndex)
					local hasCommonItem = player.GetItemAmount(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
					local toolItemInfo = GetItemInfo(recipe.dwToolItemType, recipe.dwToolItemIndex)
					local toolCommonItemInfo = GetItemInfo(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
					local szText, nFont = '', 102
					if hasItem > 0 or hasCommonItem > 0 then
						nFont = 106
					end

					if toolCommonItemInfo then
						szText = FormatString(g_tStrings.STR_MSG_NEED_TOOL, X.GetItemNameByItemInfo(toolItemInfo)
							.. g_tStrings.STR_OR .. X.GetItemNameByItemInfo(toolCommonItemInfo))
					else
						szText = FormatString(g_tStrings.STR_MSG_NEED_TOOL, X.GetItemNameByItemInfo(toolItemInfo))
					end
					table.insert(t, GetFormatText(szText, nFont))
				end

				if recipe.nCraftType == ALL_CRAFT_TYPE.COLLECTION then
					local nFont = 102
					if player.nCurrentThew >= recipe.nThew  then
						nFont = 106
					end
					table.insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_THEW, recipe.nThew), nFont))
				elseif recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE  or recipe.nCraftType == ALL_CRAFT_TYPE.READ or recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
					local nFont = 102
					if player.nCurrentStamina >= recipe.nStamina then
						nFont = 106
					end
					table.insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_STAMINA, recipe.nStamina), nFont))
				end
			end
		end
	end
	-- 任务信息
	if GetDoodadQuestTip then
		table.insert(t, GetDoodadQuestTip(doodad.dwTemplateID))
	end
	-- 自定义项
	if szExtraXml then
		table.insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_DOODAD_ID, doodad.dwID), 102))
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID), 102))
		table.insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID), 102))
	end

	if doodad.nKind == DOODAD_KIND.GUIDE and not Rect then
		local x, y = Cursor.GetPos()
		local w, h = 40, 40
		Rect = {x, y, w, h}
	end
	Rect = ConvRectEl(Rect)
	OutputTip(table.concat(t), 345, Rect)
end

function X.OutputObjectTip(Rect, dwType, dwID, szExtraXml)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwType, dwID, szExtraXml = nil, Rect, dwType, dwID
	end
	Rect = ConvRectEl(Rect)
	if dwType == TARGET.PLAYER then
		X.OutputPlayerTip(Rect, dwID, szExtraXml)
	elseif dwType == TARGET.NPC then
		X.OutputNpcTip(Rect, dwID, szExtraXml)
	elseif dwType == TARGET.DOODAD then
		X.OutputDoodadTip(Rect, dwID, szExtraXml)
	end
end

function X.OutputItemInfoTip(Rect, dwTabType, dwIndex, nBookInfo)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwTabType, dwIndex, nBookInfo = nil, Rect, dwTabType, dwIndex
	end
	local szXml = GetItemInfoTip(0, dwTabType, dwIndex, nil, nil, nBookInfo)
	if not Rect then
		local x, y = Cursor.GetPos()
		local w, h = 40, 40
		Rect = {x, y, w, h}
	end
	Rect = ConvRectEl(Rect)
	OutputTip(szXml, 345, Rect)
end

function X.GetItemTip(KItem)
	local bStatus, szXml = X.Call(GetItemTip, KItem)
	if bStatus then
		return szXml
	end
	return ''
end

function X.OutputItemTip(Rect, dwItemID)
	if not X.IsTable(Rect) and not X.IsNil(Rect) then
		Rect, dwItemID = nil, Rect
	end
	local item = GetItem(dwItemID)
	local szXml = GetItemTip(item)
	if not Rect then
		local x, y = Cursor.GetPos()
		local w, h = 40, 40
		Rect = {x, y, w, h}
	end
	Rect = ConvRectEl(Rect)
	OutputTip(szXml, 345, Rect)
end

function X.HideTip(...)
	HideTip(...)
end

-- X.OutputTableTip({
-- 	aRow = {
-- 		DEFAULT = { -- 通用行设置
-- 			nPaddingTop = 3,
-- 			nPaddingBottom = 3,
-- 			szAlignment = 'MIDDLE', -- 'TOP', 'MIDDLE', 'BOTTOM'
-- 		},
-- 		{ nPaddingTop = 0 }, -- 第一行
-- },
-- 	aColumn = {
-- 		MERGE = { -- 整行合并单元格
-- 			nPaddingLeft = 3,
-- 			nPaddingRight = 3,
-- 			nMinWidth = 100,
-- 			szAlignment = 'RIGHT' -- 'LEFT', 'CENTER', 'RIGHT'
-- 		},
-- 		{ nPaddingRight = 20, nMinWidth = 100 }, -- 第一列
-- 		{ szAlignment = 'RIGHT' },
-- 	},
-- 	aDataSource = {
-- 		{'<text>text="1:"</text>', '<text>text="4561"</text>'},
-- 		{'<text>text="23:"</text>', '<text>text="456"</text>'},
-- 		{'<text>text="123:"</text>', '<text>text="45116"</text>'},
-- 		{'<text>text="12345:"</text>', '<text>text="422256"</text>'},
-- 	},
-- 	nMinWidth = 100,
-- 	nMaxWidth = 400,
-- 	nPaddingTop = 10,
-- 	nPaddingBottom = 10,
-- 	nPaddingLeft = 10,
-- 	nPaddingRight = 10,
-- 	Rect = Rect,
-- 	nPosType = ALW.TOP_BOTTOM,
-- })
-- 其中，nMinWidth、nMaxWidth 数值相同时可合并简写为 nWidth 。
function X.OutputTableTip(tOptions)
	local aRow = tOptions.aRow or {}
	local aColumn = tOptions.aColumn or {}
	local aDataSource = tOptions.aDataSource
	local hTarget = tOptions.hTarget
	local nFramePaddingTop = tOptions.nPaddingTop or 8
	local nFramePaddingBottom = tOptions.nPaddingBottom or 8
	local nFramePaddingLeft = tOptions.nPaddingLeft or 8
	local nFramePaddingRight = tOptions.nPaddingRight or 8
	local Rect = tOptions.Rect
	local nTableWidth = tOptions.nWidth
	local nTableMinWidth = tOptions.nMinWidth
	local nTableMaxWidth = tOptions.nMaxWidth
	local nTableColumn = 1
	if nTableWidth then
		nTableMinWidth = nTableWidth
		nTableMaxWidth = nTableWidth
	end
	if hTarget then
		Rect = nil
	else
		if not Rect then
			local x, y = Cursor.GetPos()
			local w, h = 40, 40
			Rect = {x, y, w, h}
		end
		Rect = ConvRectEl(Rect)
	end
	-- 数据源不可为空
	if #aDataSource == 0 then
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'X.OutputTableTip aDataSource is empty.', X.DEBUG_LEVEL.WARNING)
		return
	end
	-- 计算列数
	for iCol, aCol in ipairs(aDataSource) do
		local nCol = #aCol
		if nCol == 0 then
			X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'X.OutputTableTip row ' .. iCol .. ' is empty.', X.DEBUG_LEVEL.WARNING)
			return
		end
		if nCol ~= 1 then
			if nTableColumn == 1 then
				nTableColumn = nCol
			end
			if nCol ~= nTableColumn then
				X.OutputDebugMessage(
					X.PACKET_INFO.NAME_SPACE,
					'X.OutputTableTip row '
						.. iCol .. ' columns count ('
						.. nCol .. ') should be the same as previous columns ('
						.. nTableColumn .. ')',
					X.DEBUG_LEVEL.LOG)
				return
			end
		end
	end
	-- 格式化列参数、计算列宽约束
	local nTableColumnMinWidthSum = 0
	for iCol = 0, nTableColumn do
		if iCol == 0 then
			iCol = 'MERGE'
		end
		local col = aColumn[iCol]
		if not col then
			col = {}
			aColumn[iCol] = col
		end
		if col.nWidth then
			col.nMinWidth = col.nWidth
			col.nMaxWidth = col.nWidth
		end
		if col.nMinWidth and col.nMaxWidth and col.nMinWidth > col.nMaxWidth then
			X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'X.OutputTableTip column ' .. iCol .. ' min width ' .. col.nMinWidth
				.. ' should be smaller than max width ' .. col.nMaxWidth .. '.', X.DEBUG_LEVEL.WARNING)
			return
		end
		if col.nMinWidth then
			if iCol == 'MERGE' then
				nTableMinWidth = math.max(nTableMinWidth or 0, col.nMinWidth)
			else
				nTableColumnMinWidthSum = nTableColumnMinWidthSum + col.nMinWidth
			end
		end
		if not col.nPaddingLeft then
			col.nPaddingLeft = 3
		end
		if not col.nPaddingRight then
			col.nPaddingRight = 3
		end
		if iCol == 'MERGE' then
			nTableMinWidth = math.max(nTableMinWidth or 0, col.nPaddingLeft)
			nTableMinWidth = math.max(nTableMinWidth or 0, col.nPaddingRight)
		else
			nTableColumnMinWidthSum = nTableColumnMinWidthSum + col.nPaddingLeft
			nTableColumnMinWidthSum = nTableColumnMinWidthSum + col.nPaddingRight
		end
	end
	if nTableMaxWidth and nTableColumnMinWidthSum > nTableMaxWidth then
		X.OutputDebugMessage(X.PACKET_INFO.NAME_SPACE, 'X.OutputTableTip summary of columns min width (including horizontal paddings) ' .. nTableColumnMinWidthSum
			.. ' should be smaller than table max width ' .. nTableMaxWidth .. '.', X.DEBUG_LEVEL.WARNING)
		return
	end
	-- 格式化行参数
	for iRow = 0, #aDataSource do
		if iRow == 0 then
			iRow = 'DEFAULT'
		end
		local row = aRow[iRow]
		if not row then
			row = {}
			aRow[iRow] = row
		end
		if iRow ~= 'DEFAULT' then
			setmetatable(row, { __index = aRow['DEFAULT'] })
		end
		if not row.nPaddingTop then
			row.nPaddingTop = 1
		end
		if not row.nPaddingBottom then
			row.nPaddingBottom = 1
		end
	end
	-- 开始创建
	local INI_PATH = X.PACKET_INFO.FRAMEWORK_ROOT .. 'ui/OutputTableTip.ini'
	local frame, hTotal, imgBg, hTable
	if hTarget then
		hTable = hTarget:AppendItemFromIni(INI_PATH, 'Handle_Table')
	else
		frame = X.UI.OpenFrame(INI_PATH, X.NSFormatString('{$NS}_OutputTableTip'))
		hTotal = frame:Lookup('', '')
		imgBg = hTotal:Lookup('Image_Bg')
		hTable = hTotal:Lookup('Handle_Table')
	end
	hTable:Clear()
	local aColumnWidth = {}
	-- 渲染列、计算填充内容后各列宽
	for iRow, aCol in ipairs(aDataSource) do
		local hRow = hTable:AppendItemFromIni(INI_PATH, 'Handle_Row')
		local bMergeColumnRow = #aCol < nTableColumn
		hRow:Clear()
		for iCol, szCol in ipairs(aCol) do
			local iColumnKey = bMergeColumnRow and 'MERGE' or iCol
			local tCol = aColumn[iColumnKey]
			local hCol = hRow:AppendItemFromIni(INI_PATH, 'Handle_Col')
			local hCell = hCol:Lookup('Handle_Cell')
			hCell:Clear()
			hCell:AppendItemFromString(szCol)
			local hCustom = hCell:GetItemCount() == 1 and hCell:Lookup(0)
			if not hCustom or hCustom:GetType() ~= 'Handle' then
				hCustom = hCell
			end
			local nCellMaxWidth = 0xffff
			if tCol.nMaxWidth then
				nCellMaxWidth = tCol.nMaxWidth - tCol.nPaddingLeft - tCol.nPaddingRight
			end
			hCustom:SetW(nCellMaxWidth)
			hCustom:FormatAllItemPos()
			local nAW = hCustom:GetAllItemSize()
			aColumnWidth[iColumnKey] = math.max(aColumnWidth[iColumnKey] or 0, nAW + tCol.nPaddingLeft + tCol.nPaddingRight)
		end
	end
	-- 整行合并单元格
	if aColumnWidth['MERGE'] then
		if nTableMaxWidth then
			aColumnWidth['MERGE'] = math.min(aColumnWidth['MERGE'], nTableMaxWidth)
		end
		if nTableMinWidth then
			nTableMinWidth = math.max(nTableMinWidth, aColumnWidth['MERGE'])
		end
	end
	-- 限制各列宽配置约束
	for iCol = 1, nTableColumn do
		local col = aColumn[iCol]
		if col.nMinWidth then
			aColumnWidth[iCol] = math.max(aColumnWidth[iCol] or 0, col.nMinWidth)
		end
		if col.nMaxWidth then
			aColumnWidth[iCol] = math.min(aColumnWidth[iCol] or math.huge, col.nMaxWidth)
		end
	end
	-- 存在整体宽度限制，自动平均分布
	if nTableMaxWidth or nTableMinWidth then
		local nExtraWidth
		if not nExtraWidth and nTableMaxWidth then
			nExtraWidth = nTableMaxWidth
			for iCol, nWidth in ipairs(aColumnWidth) do
				nExtraWidth = nExtraWidth - nWidth
			end
			if nExtraWidth >= 0 then
				nExtraWidth = nil
			end
		end
		if not nExtraWidth and nTableMinWidth then
			nExtraWidth = nTableMinWidth
			for iCol, nWidth in ipairs(aColumnWidth) do
				nExtraWidth = nExtraWidth - nWidth
			end
			if nExtraWidth <= 0 then
				nExtraWidth = nil
			end
		end
		local nLoopProtect = 0
		while nExtraWidth and math.abs(nExtraWidth) > 0.0001 do
			nLoopProtect = nLoopProtect + 1
			if nLoopProtect >= 300 then
				assert(false, 'Loop protect.')
			end
			local nExtraPerCol = nExtraWidth / nTableColumn
			for iCol, nWidth in ipairs(aColumnWidth) do
				local tCol = aColumn[iCol]
				local nOffset = nExtraPerCol
				if nExtraPerCol > 0 then
					if tCol.nMaxWidth then
						nOffset = math.min(nOffset, tCol.nMaxWidth - nWidth)
					end
				else
					if tCol.nMinWidth then
						nOffset = math.max(nOffset, tCol.nMinWidth - nWidth)
					end
				end
				aColumnWidth[iCol] = aColumnWidth[iCol] + nOffset
				nExtraWidth = nExtraWidth - nOffset
			end
		end
	end
	-- 计算实际表格宽度
	if not nTableWidth then
		nTableWidth = 0
		for _, nW in ipairs(aColumnWidth) do
			nTableWidth = nTableWidth + nW
		end
	end
	-- 应用各列宽、计算各行高
	local aRowHeight = {}
	for iRow, aCol in ipairs(aDataSource) do
		local tRow = aRow[iRow]
		local hRow = hTable:Lookup(iRow - 1)
		local bMergeColumnRow = #aCol < nTableColumn
		local nX = 0
		for iCol, szCol in ipairs(aCol) do
			local tCol = bMergeColumnRow and aColumn['MERGE'] or aColumn[iCol]
			local hCol = hRow:Lookup(iCol - 1)
			local hCell = hCol:Lookup('Handle_Cell')
			local hCustom = hCell:GetItemCount() == 1 and hCell:Lookup(0)
			if not hCustom or hCustom:GetType() ~= 'Handle' then
				hCustom = hCell
			end
			local nColumnWidth = bMergeColumnRow and nTableWidth or aColumnWidth[iCol]
			local nCellWidth, nCellHeight = nColumnWidth - tCol.nPaddingLeft - tCol.nPaddingRight, nil
			if tCol.szAlignment == 'CENTER' or tCol.szAlignment == 'RIGHT' then
				nCellWidth = math.min(nCellWidth, hCustom:GetW())
			end
			hCol:SetRelX(nX)
			hCol:SetW(nColumnWidth)
			hCell:SetW(nCellWidth)
			hCustom:SetW(nCellWidth)
			if tCol.szAlignment == 'CENTER' then
				hCell:SetRelX((nColumnWidth - nCellWidth) / 2)
				hCustom:SetHAlign(1)
			elseif tCol.szAlignment == 'RIGHT' then
				hCell:SetRelX(nColumnWidth - tCol.nPaddingRight - nCellWidth)
				hCustom:SetHAlign(2)
			else
				hCell:SetRelX(tCol.nPaddingLeft)
				hCustom:SetHAlign(0)
			end
			hCustom:FormatAllItemPos()
			nCellHeight = select(2, hCustom:GetAllItemSize())
			hCustom:SetH(nCellHeight)
			aRowHeight[iRow] = math.max(aRowHeight[iRow] or 0, nCellHeight + tRow.nPaddingTop + tRow.nPaddingBottom)
			nX = nX + nColumnWidth
		end
	end
	-- 应用各行高、计算表格总高度
	local nTableHeight = 0
	for iRow, aCol in ipairs(aDataSource) do
		local tRow = aRow[iRow]
		local nRowHeight = aRowHeight[iRow]
		local hRow = hTable:Lookup(iRow - 1)
		for iCol, szCol in ipairs(aCol) do
			local hCol = hRow:Lookup(iCol - 1)
			local hCell = hCol:Lookup('Handle_Cell')
			local hCustom = hCell:GetItemCount() == 1 and hCell:Lookup(0)
			if not hCustom or hCustom:GetType() ~= 'Handle' then
				hCustom = hCell
			end
			local nCellHeight = nRowHeight
			if tRow.szAlignment == 'MIDDLE' or tRow.szAlignment == 'BOTTOM' then
				nCellHeight = math.min(nCellHeight, hCustom:GetH())
			end
			hCell:SetH(nCellHeight)
			hCell:SetRelY(tRow.nPaddingTop)
			hCustom:SetH(nCellHeight)
			if tRow.szAlignment == 'MIDDLE' then
				hCell:SetRelY((nRowHeight - nCellHeight) / 2)
				hCustom:SetVAlign(1)
			elseif tRow.szAlignment == 'BOTTOM' then
				hCell:SetRelY(nRowHeight - tRow.nPaddingBottom - nCellHeight)
				hCustom:SetVAlign(2)
			else
				hCell:SetRelY(tRow.nPaddingTop)
				hCustom:SetVAlign(0)
			end
			hCol:SetH(nRowHeight)
			hCol:FormatAllItemPos()
		end
		hRow:SetRelY(nTableHeight)
		hRow:FormatAllItemPos()
		nTableHeight = nTableHeight + nRowHeight
	end
	hTable:FormatAllItemPos()
	hTable:SetSize(
		nTableWidth + nFramePaddingLeft + nFramePaddingRight,
		nTableHeight + nFramePaddingTop + nFramePaddingBottom)
	-- 更新外部元素大小
	if imgBg then
		imgBg:SetSize(
			nTableWidth + nFramePaddingLeft + nFramePaddingRight,
			nTableHeight + nFramePaddingTop + nFramePaddingBottom)
	end
	if hTotal then
		hTable:SetRelPos(nFramePaddingLeft, nFramePaddingTop)
		hTotal:SetSize(
			nTableWidth + nFramePaddingLeft + nFramePaddingRight,
			nTableHeight + nFramePaddingTop + nFramePaddingBottom)
		hTotal:FormatAllItemPos()
	end
	if frame then
		if not Station.IsVisible() then
			frame:ShowWhenUIHide()
		end
		X.RegisterEsc(
			X.NSFormatString('{$NS}_OutputTableTip'),
			function() return frame:IsValid() and frame:IsVisible() end,
			function() X.UI.CloseFrame(frame) end)
		frame:SetSize(
			nTableWidth + nFramePaddingLeft + nFramePaddingRight,
			nTableHeight + nFramePaddingTop + nFramePaddingBottom)
		AdjustFramePos(frame, Rect, tOptions.nPosType)
	end
end

function X.HideTableTip(bAnimate)
	local frame = Station.SearchFrame(X.NSFormatString('{$NS}_OutputTableTip'))
	if not frame then
		return
	end
	if bAnimate then
		X.UI(frame):FadeOut(2000, function()
			X.UI.CloseFrame(frame)
		end)
	else
		X.UI.CloseFrame(frame)
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
