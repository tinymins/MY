--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : Tip相关逻辑
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
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
local _L = LIB.LoadLangPack(PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
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
function LIB.OutputTip(Rect, szText, nFont, ePos, nMaxWidth)
	if not IsTable(Rect) and not IsNil(Rect) then
		Rect, szText, nFont, ePos, nMaxWidth = nil, Rect, szText, nFont, ePos
	end
	if nFont ~= true then
		szText = GetFormatText(szText, nFont or 18)
	end
	Rect, ePos = ConvRectEl(Rect, ePos)
	return OutputTip(szText, nMaxWidth or 800, Rect, ePos)
end

function LIB.OutputBuffTip(Rect, dwID, nLevel, nTime, szExtraXml)
	if not IsTable(Rect) and not IsNil(Rect) then
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
			local h = floor(nTime / 3600)
			local m = floor(nTime / 60) % 60
			local s = floor(nTime % 60)
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
		local szGUID = LIB.GetPlayerGUID(dwID)
		if szGUID then
			insert(xml, GetFormatText('GUID: ' .. szGUID .. '\n', 102))
		end
	end
	Rect = ConvRectEl(Rect)
	OutputTip(concat(xml), 345, Rect)
end

function LIB.OutputPlayerTip(Rect, dwID, szExtraXml)
	if not IsTable(Rect) and not IsNil(Rect) then
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
	if CONSTANT.FORCE_TYPE_LABEL[player.dwForceID] then
		insert(t, GetFormatText(CONSTANT.FORCE_TYPE_LABEL[player.dwForceID] .. '\n', 82))
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_DOODAD_ID, doodad.dwID), 102))
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_TEMPLATE_ID, doodad.dwTemplateID), 102))
		insert(t, GetFormatText(FormatString(g_tStrings.TIP_REPRESENTID_ID, doodad.dwRepresentID), 102))
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
	if not IsTable(Rect) and not IsNil(Rect) then
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
	if not IsTable(Rect) and not IsNil(Rect) then
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

function LIB.GetItemTip(KItem)
	local bStatus, szXml = Call(GetItemTip, KItem)
	if bStatus then
		return szXml
	end
	return ''
end

function LIB.OutputItemTip(Rect, dwItemID)
	if not IsTable(Rect) and not IsNil(Rect) then
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

-- LIB.OutputTableTip({
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
-- 	Rect = Rect,
-- 	nPosType = ALW.TOP_BOTTOM,
-- })
-- 其中，nMinWidth、nMaxWidth 数值相同时可合并简写为 nWidth 。
function LIB.OutputTableTip(tOptions)
	local aRow = tOptions.aRow or {}
	local aColumn = tOptions.aColumn or {}
	local aDataSource = tOptions.aDataSource
	local hTarget = tOptions.hTarget
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
		LIB.Debug(PACKET_INFO.NAME_SPACE, 'LIB.OutputTableTip aDataSource is empty.', DEBUG_LEVEL.WARNING)
		return
	end
	-- 计算列数
	for iCol, aCol in ipairs(aDataSource) do
		local nCol = #aCol
		if nCol == 0 then
			LIB.Debug(PACKET_INFO.NAME_SPACE, 'LIB.OutputTableTip row ' .. iCol .. ' is empty.', DEBUG_LEVEL.WARNING)
			return
		end
		if nCol ~= 1 then
			if nTableColumn == 1 then
				nTableColumn = nCol
			end
			if nCol ~= nTableColumn then
				LIB.Debug(
					PACKET_INFO.NAME_SPACE,
					'LIB.OutputTableTip row '
						.. iCol .. ' columns count ('
						.. nCol .. ') should be the same as previous columns ('
						.. nTableColumn .. ')',
					DEBUG_LEVEL.LOG)
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
			LIB.Debug(PACKET_INFO.NAME_SPACE, 'LIB.OutputTableTip column ' .. iCol .. ' min width ' .. col.nMinWidth
				.. ' should be smaller than max width ' .. col.nMaxWidth .. '.', DEBUG_LEVEL.WARNING)
			return
		end
		if col.nMinWidth then
			if iCol == 'MERGE' then
				nTableMinWidth = max(nTableMinWidth or 0, col.nMinWidth)
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
			nTableMinWidth = max(nTableMinWidth or 0, col.nPaddingLeft)
			nTableMinWidth = max(nTableMinWidth or 0, col.nPaddingRight)
		else
			nTableColumnMinWidthSum = nTableColumnMinWidthSum + col.nPaddingLeft
			nTableColumnMinWidthSum = nTableColumnMinWidthSum + col.nPaddingRight
		end
	end
	if nTableMaxWidth and nTableColumnMinWidthSum > nTableMaxWidth then
		LIB.Debug(PACKET_INFO.NAME_SPACE, 'LIB.OutputTableTip summary of columns min width (including horizontal paddings) ' .. nTableColumnMinWidthSum
			.. ' should be smaller than table max width ' .. nTableMaxWidth .. '.', DEBUG_LEVEL.WARNING)
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
	local INI_PATH = PACKET_INFO.FRAMEWORK_ROOT .. 'ui/OutputTableTip.ini'
	local frame, hTotal, imgBg, hTable
	if hTarget then
		hTable = hTarget:AppendItemFromIni(INI_PATH, 'Handle_Table')
	else
		frame = Wnd.OpenWindow(INI_PATH, NSFormatString('{$NS}_OutputTableTip'))
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
			aColumnWidth[iColumnKey] = max(aColumnWidth[iColumnKey] or 0, nAW + tCol.nPaddingLeft + tCol.nPaddingRight)
		end
	end
	-- 整行合并单元格
	if aColumnWidth['MERGE'] then
		if nTableMaxWidth then
			aColumnWidth['MERGE'] = min(aColumnWidth['MERGE'], nTableMaxWidth)
		end
		if nTableMinWidth then
			nTableMinWidth = max(nTableMinWidth, aColumnWidth['MERGE'])
		end
	end
	-- 限制各列宽配置约束
	for iCol = 1, nTableColumn do
		local col = aColumn[iCol]
		if col.nMinWidth then
			aColumnWidth[iCol] = max(aColumnWidth[iCol] or 0, col.nMinWidth)
		end
		if col.nMaxWidth then
			aColumnWidth[iCol] = min(aColumnWidth[iCol] or HUGE, col.nMaxWidth)
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
		while nExtraWidth and abs(nExtraWidth) > 0.0001 do
			nLoopProtect = nLoopProtect + 1
			assert(nLoopProtect < 300)
			local nExtraPerCol = nExtraWidth / nTableColumn
			for iCol, nWidth in ipairs(aColumnWidth) do
				local tCol = aColumn[iCol]
				local nOffset = nExtraPerCol
				if nExtraPerCol > 0 then
					if tCol.nMaxWidth then
						nOffset = min(nOffset, tCol.nMaxWidth - nWidth)
					end
				else
					if tCol.nMinWidth then
						nOffset = max(nOffset, tCol.nMinWidth - nWidth)
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
				nCellWidth = min(nCellWidth, hCustom:GetW())
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
			aRowHeight[iRow] = max(aRowHeight[iRow] or 0, nCellHeight + tRow.nPaddingTop + tRow.nPaddingBottom)
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
				nCellHeight = min(nCellHeight, hCustom:GetH())
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
	hTable:SetSize(nTableWidth + 8, nTableHeight + 8)
	-- 更新外部元素大小
	if imgBg then
		imgBg:SetSize(nTableWidth + 8, nTableHeight + 8)
	end
	if hTotal then
		hTable:SetRelPos(4, 4)
		hTotal:SetSize(nTableWidth + 8, nTableHeight + 8)
		hTotal:FormatAllItemPos()
	end
	if frame then
		LIB.RegisterEsc(
			NSFormatString('{$NS}_OutputTableTip'),
			function() return frame:IsValid() and frame:IsVisible() end,
			function() Wnd.CloseWindow(frame) end)
		frame:SetSize(nTableWidth + 8, nTableHeight + 8)
		AdjustFramePos(frame, Rect, tOptions.nPosType)
	end
end

function LIB.HideTableTip()
	Wnd.CloseWindow(NSFormatString('{$NS}_OutputTableTip'))
end
