--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : Tip相关逻辑
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
local IsNil, IsEmpty, IsEquals, IsString = LIB.IsNil, LIB.IsEmpty, LIB.IsEquals, LIB.IsString
local IsBoolean, IsNumber, IsHugeNumber = LIB.IsBoolean, LIB.IsNumber, LIB.IsHugeNumber
local IsTable, IsArray, IsDictionary = LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsFunction, IsUserdata, IsElement = LIB.IsFunction, LIB.IsUserdata, LIB.IsElement
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack()
-------------------------------------------------------------------------------------------------------------

-- 将输入转为 Rect 数组
local function ConvRectEl(Rect, ePos)
	if IsTable(Rect) and IsUserdata(Rect.___id) then
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

-- nFont 为 true 表示传入的是Xml字符串 否则表示格式化的字体
function LIB.OutputTip(Rect, szText, nFont, ePos, nMaxWidth)
	if not IsTable(Rect) then
		Rect, szText, nFont, ePos, nMaxWidth = nil, Rect, szText, nFont, ePos
	end
	if nFont ~= true then
		szText = GetFormatText(szText, nFont or 18)
	end
	Rect, ePos = ConvRectEl(Rect, ePos)
	return OutputTip(szText, nMaxWidth or 800, Rect, ePos)
end

function LIB.OutputBuffTip(Rect, dwID, nLevel, nTime, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwID, nLevel, nTime, szExtraXml = nil, Rect, dwID, nLevel, nTime
	end
	local t = {}

	insert(t, GetFormatText(Table_GetBuffName(dwID, nLevel) .. '\t', 65))
	local buffInfo = GetBuffInfo(dwID, nLevel, {})
	if buffInfo and buffInfo.nDetachType and g_tStrings.tBuffDetachType[buffInfo.nDetachType] then
		insert(t, GetFormatText(g_tStrings.tBuffDetachType[buffInfo.nDetachType] .. '\n', 106))
	else
		insert(t, CONSTANT.XML_LINE_BREAKER)
	end

	local szDesc = GetBuffDesc(dwID, nLevel, 'desc')
	if szDesc then
		insert(t, GetFormatText(szDesc .. g_tStrings.STR_FULL_STOP, 106))
	end

	if nTime then
		if nTime == 0 then
			insert(t, CONSTANT.XML_LINE_BREAKER)
			insert(t, GetFormatText(g_tStrings.STR_BUFF_H_TIME_ZERO, 102))
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
				insert(t, CONSTANT.XML_LINE_BREAKER)
				insert(t, GetFormatText(FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, H, M, S), 102))
			end
		end
	end

	if szExtraXml then
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, szExtraXml)
	end
	-- For test
	if IsCtrlKeyDown() then
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, GetFormatText(g_tStrings.DEBUG_INFO_ITEM_TIP, 102))
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, GetFormatText('ID:     ' .. dwID, 102))
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, GetFormatText('Level:  ' .. nLevel, 102))
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, GetFormatText('IconID: ' .. tostring(Table_GetBuffIconID(dwID, nLevel)), 102))
	end
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 300, Rect)
end

function LIB.OutputTeamMemberTip(Rect, dwID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local team = GetClientTeam()
	local tMemberInfo = team.GetMemberInfo(dwID)
	if not tMemberInfo then
		return
	end
	local r, g, b = LIB.GetForceColor(tMemberInfo.dwForceID, 'foreground')
	local szPath, nFrame = GetForceImage(tMemberInfo.dwForceID)
	local xml = {}
	insert(xml, GetFormatImage(szPath, nFrame, 22, 22))
	insert(xml, GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, tMemberInfo.szName), 80, r, g, b))
	if tMemberInfo.bIsOnLine then
		local p = GetPlayer(dwID)
		if p and p.dwTongID > 0 then
			if GetTongClient().ApplyGetTongName(p.dwTongID) then
				insert(xml, GetFormatText('[' .. GetTongClient().ApplyGetTongName(p.dwTongID) .. ']\n', 41))
			end
		end
		insert(xml, GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, tMemberInfo.nLevel), 82))
		insert(xml, GetFormatText(LIB.GetSkillName(tMemberInfo.dwMountKungfuID, 1) .. '\n', 82))
		local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
		if szMapName then
			insert(xml, GetFormatText(szMapName .. '\n', 82))
		end
		insert(xml, GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[tMemberInfo.nCamp] .. '\n', 82))
	else
		insert(xml, GetFormatText(g_tStrings.STR_FRIEND_NOT_ON_LINE .. '\n', 82, 128, 128, 128))
	end
	if szExtraXml then
		insert(xml, szExtraXml)
	end
	if IsCtrlKeyDown() then
		insert(xml, GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, dwID), 102))
	end
	Rect = ConvRectEl(Rect)
	OutputTip(concat(xml), 345, Rect)
end

function LIB.OutputPlayerTip(Rect, dwID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local player = GetPlayer(dwID)
	if not player then
		return
	end
	local me, t = GetClientPlayer(), {}
	local r, g, b = GetForceFontColor(dwID, me.dwID)

	-- 名字
	insert(t, GetFormatText(FormatString(g_tStrings.STR_NAME_PLAYER, player.szName), 80, r, g, b))
	-- 称号
	if player.szTitle ~= '' then
		insert(t, GetFormatText('<' .. player.szTitle .. '>\n', 0))
	end
	-- 帮会
	if player.dwTongID ~= 0 then
		local szName = GetTongClient().ApplyGetTongName(player.dwTongID, 1)
		if szName and szName ~= '' then
			insert(t, GetFormatText('[' .. szName .. ']\n', 0))
		end
	end
	-- 等级
	if player.nLevel - me.nLevel > 10 and not me.IsPlayerInMyParty(dwID) then
		insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	else
		insert(t, GetFormatText(FormatString(g_tStrings.STR_PLAYER_H_WHAT_LEVEL, player.nLevel), 82))
	end
	-- 声望
	if g_tStrings.tForceTitle[player.dwForceID] then
		insert(t, GetFormatText(g_tStrings.tForceTitle[player.dwForceID] .. '\n', 82))
	end
	-- 所在地图
	if IsParty(dwID, me.dwID) then
		local team = GetClientTeam()
		local tMemberInfo = team.GetMemberInfo(dwID)
		if tMemberInfo then
			local szMapName = Table_GetMapName(tMemberInfo.dwMapID)
			if szMapName then
				insert(t, GetFormatText(szMapName .. '\n', 82))
			end
		end
	end
	-- 阵营
	if player.bCampFlag then
		insert(t, GetFormatText(g_tStrings.STR_TIP_CAMP_FLAG .. '\n', 163))
	end
	insert(t, GetFormatText(g_tStrings.STR_GUILD_CAMP_NAME[player.nCamp], 82))
	-- 小本本
	if _G.MY_Anmerkungen and _G.MY_Anmerkungen.GetPlayerNote then
		local note = _G.MY_Anmerkungen.GetPlayerNote(player.dwID)
		if note and note.szContent ~= '' then
			insert(t, CONSTANT.XML_LINE_BREAKER)
			insert(t, GetFormatText(note.szContent, 0))
		end
	end
	-- 自定义项
	if szExtraXml then
		insert(t, CONSTANT.XML_LINE_BREAKER)
		insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_PLAYER_ID, player.dwID), 102))
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, player.dwModelID), 102))
		insert(t, GetFormatText(EncodeLUAData(player.GetRepresentID(), '  '), 102))
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 345, Rect)
end

function LIB.OutputNpcTemplateTip(Rect, dwNpcTemplateID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwNpcTemplateID, szExtraXml = nil, Rect, dwNpcTemplateID
	end
	local npc = GetNpcTemplate(dwNpcTemplateID)
	if not npc then
		return
	end
	local t = {}

	-- 名字
	local szName = LIB.GetTemplateName(TARGET.NPC, dwNpcTemplateID) or dwNpcTemplateID
	insert(t, GetFormatText(szName .. '\n', 80, 255, 255, 0))
	-- 等级
	if npc.nLevel - GetClientPlayer().nLevel > 10 then
		insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	else
		insert(t, GetFormatText(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel), 0))
	end
	-- 模版ID
	insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, npc.nIntensity or 1), 101))
	-- 自定义项
	if szExtraXml then
		insert(t, szExtraXml)
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 345, Rect)
end

function LIB.OutputNpcTip(Rect, dwID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwID, szExtraXml = nil, Rect, dwID
	end
	local npc = GetNpc(dwID)
	if not npc then
		return
	end

	local me = GetClientPlayer()
	local r, g, b = GetForceFontColor(dwID, me.dwID)
	local t = {}

	-- 名字
	local szName = LIB.GetObjectName(npc)
	insert(t, GetFormatText(szName .. '\n', 80, r, g, b))
	-- 称号
	if npc.szTitle ~= '' then
		insert(t, GetFormatText('<' .. npc.szTitle .. '>\n', 0))
	end
	-- 等级
	if npc.nLevel - me.nLevel > 10 then
		insert(t, GetFormatText(g_tStrings.STR_PLAYER_H_UNKNOWN_LEVEL, 82))
	elseif npc.nLevel > 0 then
		insert(t, GetFormatText(FormatString(g_tStrings.STR_NPC_H_WHAT_LEVEL, npc.nLevel), 0))
	end
	-- 势力
	if g_tReputation and g_tReputation.tReputationTable[npc.dwForceID] then
		insert(t, GetFormatText(g_tReputation.tReputationTable[npc.dwForceID].szName .. '\n', 0))
	end
	-- 任务信息
	if GetNpcQuestTip then
		insert(t, GetNpcQuestTip(npc.dwTemplateID))
	end
	-- 自定义项
	if szExtraXml then
		insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_NPC_ID, npc.dwID), 102))
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID_NPC_INTENSITY, npc.dwTemplateID, npc.nIntensity), 102))
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, npc.dwModelID), 102))
		if IsShiftKeyDown() and GetNpcQuestState then
			local tState = GetNpcQuestState(npc, true)
			for szKey, tQuestList in pairs(tState) do
				tState[szKey] = concat(tQuestList, ',')
			end
			insert(t, GetFormatText(EncodeLUAData(tState, '  '), 102))
		end
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 345, Rect)
end

function LIB.OutputDoodadTemplateTip(Rect, dwTemplateID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwTemplateID, szExtraXml = nil, Rect, dwTemplateID
	end
	local doodad = GetDoodadTemplate(dwTemplateID)
	if not doodad then
		return
	end
	local t = {}
	-- 名字
	local szName = doodad.szName ~= '' and doodad.szName or dwTemplateID
	if doodad.nKind == DOODAD_KIND.CORPSE then
		szName = szName .. g_tStrings.STR_DOODAD_CORPSE
	end
	insert(t, GetFormatText(szName .. '\n', 65))
	insert(t, GetDoodadQuestTip(dwTemplateID))
	-- 模版ID
	insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID), 101))
	if IsCtrlKeyDown() then
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID), 102))
	end
	-- 自定义项
	if szExtraXml then
		insert(t, szExtraXml)
	end
	-- 格式化输出
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 300, Rect)
end

function LIB.OutputDoodadTip(Rect, dwDoodadID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwDoodadID, szExtraXml = nil, Rect, dwDoodadID
	end
	local doodad = GetDoodad(dwDoodadID)
	if not doodad then
		return
	end

	local player, t = GetClientPlayer(), {}
	-- 名字
	local szDoodadName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
	if doodad.nKind == DOODAD_KIND.CORPSE then
		szDoodadName = szDoodadName .. g_tStrings.STR_DOODAD_CORPSE
	end
	insert(t, GetFormatText(szDoodadName .. '\n', 37))
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
					insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_BEST_CRAFT, LIB.Table_GetProfessionName(recipe.dwProfessionID), requireLevel), nFont))
				elseif doodadTemplate.dwCraftID ~= 8 then --8 读碑文
					insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_CRAFT, LIB.Table_GetProfessionName(recipe.dwProfessionID), requireLevel), nFont))
				end

				if recipe.nCraftType == ALL_CRAFT_TYPE.READ then
					if recipe.dwProfessionIDExt ~= 0 then
						local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
						if player.IsBookMemorized(nBookID, nSegmentID) then
							insert(t, GetFormatText(g_tStrings.TIP_ALREADY_READ, 108))
						else
							insert(t, GetFormatText(g_tStrings.TIP_UNREAD, 105))
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
						szText = FormatString(g_tStrings.STR_MSG_NEED_TOOL, LIB.GetItemNameByItemInfo(toolItemInfo)
							.. g_tStrings.STR_OR .. LIB.GetItemNameByItemInfo(toolCommonItemInfo))
					else
						szText = FormatString(g_tStrings.STR_MSG_NEED_TOOL, LIB.GetItemNameByItemInfo(toolItemInfo))
					end
					insert(t, GetFormatText(szText, nFont))
				end

				if recipe.nCraftType == ALL_CRAFT_TYPE.COLLECTION then
					local nFont = 102
					if player.nCurrentThew >= recipe.nThew  then
						nFont = 106
					end
					insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_THEW, recipe.nThew), nFont))
				elseif recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE  or recipe.nCraftType == ALL_CRAFT_TYPE.READ or recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
					local nFont = 102
					if player.nCurrentStamina >= recipe.nStamina then
						nFont = 106
					end
					insert(t, GetFormatText(FormatString(g_tStrings.STR_MSG_NEED_COST_STAMINA, recipe.nStamina), nFont))
				end
			end
		end
	end
	-- 任务信息
	if GetDoodadQuestTip then
		insert(t, GetDoodadQuestTip(doodad.dwTemplateID))
	end
	-- 自定义项
	if szExtraXml then
		insert(t, szExtraXml)
	end
	-- 调试信息
	if IsCtrlKeyDown() then
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_DOODAD_ID, doodad.dwID)), 102)
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID)), 102)
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID)), 102)
	end

	if doodad.nKind == DOODAD_KIND.GUIDE and not Rect then
		local x, y = Cursor.GetPos()
		local w, h = 40, 40
		Rect = {x, y, w, h}
	end
	Rect = ConvRectEl(Rect)
	OutputTip(concat(t), 345, Rect)
end

function LIB.OutputObjectTip(Rect, dwType, dwID, szExtraXml)
	if not IsTable(Rect) then
		Rect, dwType, dwID, szExtraXml = nil, Rect, dwType, dwID
	end
	Rect = ConvRectEl(Rect)
	if dwType == TARGET.PLAYER then
		LIB.OutputPlayerTip(Rect, dwID, szExtraXml)
	elseif dwType == TARGET.NPC then
		LIB.OutputNpcTip(Rect, dwID, szExtraXml)
	elseif dwType == TARGET.DOODAD then
		LIB.OutputDoodadTip(Rect, dwID, szExtraXml)
	end
end

function LIB.OutputItemInfoTip(Rect, dwTabType, dwIndex, nBookInfo)
	if not IsTable(Rect) then
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
