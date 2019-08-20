--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队工具
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------------------------
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
local IsNil, IsBoolean, IsUserdata, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsUserdata, LIB.IsFunction
local IsString, IsTable, IsArray, IsDictionary = LIB.IsString, LIB.IsTable, LIB.IsArray, LIB.IsDictionary
local IsNumber, IsHugeNumber, IsEmpty, IsEquals = LIB.IsNumber, LIB.IsHugeNumber, LIB.IsEmpty, LIB.IsEquals
local Call, XpCall, GetTraceback, RandomChild = LIB.Call, LIB.XpCall, LIB.GetTraceback, LIB.RandomChild
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local EncodeLUAData, DecodeLUAData, CONSTANT = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.CONSTANT
-----------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamTools'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2013900) then
	return
end
--------------------------------------------------------------------------
local SKILL_RESULT_TYPE = SKILL_RESULT_TYPE
local MY_IsParty, MY_GetSkillName, MY_GetBuffName = LIB.IsParty, LIB.GetSkillName, LIB.GetBuffName

local RT_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/RaidTools2.ini'
local RT_EQUIP_TOTAL = {
	'MELEE_WEAPON', -- 轻剑 藏剑取 BIG_SWORD 重剑
	'RANGE_WEAPON', -- 远程武器
	'CHEST',        -- 衣服
	'HELM',         -- 帽子
	'AMULET',       -- 项链
	'LEFT_RING',    -- 戒指
	'RIGHT_RING',   -- 戒指
	'WAIST',        -- 腰带
	'PENDANT',      -- 腰坠
	'PANTS',        -- 裤子
	'BOOTS',        -- 鞋子
	'BANGLE',       -- 护腕
}

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
-- 副本评分 晚点在做吧
-- local RT_DUNGEON_TOTAL = {}
local RT_SCORE = {
	Equip   = _L['Equip Score'],
	Buff    = _L['Buff Score'],
	Food    = _L['Food Score'],
	Enchant = _L['Enchant Score'],
	Special = _L['Special Equip Score'],
}

local RT_EQUIP_SPECIAL = {
	MELEE_WEAPON = true,
	BIG_SWORD    = true,
	AMULET       = true,
	PENDANT      = true
}

local RT_FOOD_TYPE = {
	[24] = true,
	[17] = true,
	[18] = true,
	[19] = true,
	[20] = true
}
-- 需要监控的BUFF
local RT_BUFF_ID = {
	-- 常规职业BUFF
	[362]  = true,
	[673]  = true,
	[112]  = true,
	[382]  = true,
	[2837] = true,
	-- 红篮球
	[6329] = true,
	[6330] = true,
	-- 帮会菜盘
	[2564] = true,
	[2563] = true,
	-- 七秀扇子
	[3098] = true,
	-- 缝针 / 凤凰谷
	[2313] = true,
	[5970] = true,
}
local RT_GONGZHAN_ID = 3219
-- default sort
local RT_SORT_MODE    = 'DESC'
local RT_SORT_FIELD   = 'nEquipScore'
local RT_MAPID = 0
local RT_PLAYER_MAP_COPYID = {}
local RT_SELECT_PAGE  = 0
local RT_SELECT_KUNGFU
local RT_SELECT_DEATH
--
local RT_SCORE_FULL = 30000
local RT = {
	tAnchor = {},
	tDamage = {},
	tDeath  = {},
}

MY_RaidTools = {
	nStyle = 2,
}
local RaidTools = MY_RaidTools

LIB.RegisterCustomData('MY_RaidTools')

function RaidTools.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PEEK_OTHER_PLAYER')
	this:RegisterEvent('PARTY_ADD_MEMBER')
	this:RegisterEvent('PARTY_DISBAND')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('PARTY_SET_MEMBER_ONLINE_FLAG')
	this:RegisterEvent('ON_APPLY_PLAYER_SAVED_COPY_RESPOND')
	this:RegisterEvent('LOADING_END')
	-- 团长变更 重新请求标签
	this:RegisterEvent('TEAM_AUTHORITY_CHANGED')
	-- 自定义事件
	this:RegisterEvent('MY_RAIDTOOLS_SUCCESS')
	this:RegisterEvent('MY_RAIDTOOLS_DEATH')
	this:RegisterEvent('MY_RAIDTOOLS_MAPID_CHANGE')
	-- 重置心法选择
	RT_SELECT_KUNGFU = nil
	-- 注册关闭
	LIB.RegisterEsc('MY_RaidTools', RT.IsOpened, RT.ClosePanel)
	-- 标题修改
	local title = _L['Raid Tools']
	if LIB.IsInParty() then
		local team = GetClientTeam()
		local info = team.GetMemberInfo(team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER))
		title = _L('%s\'s Team', info.szName) .. ' (' .. team.GetTeamSize() .. '/' .. team.nGroupNum * 5  .. ')'
	end
	this:Lookup('', 'Text_Title'):SetText(title)
	this.hPlayer      = this:CreateItemData(RT_INIFILE, 'Handle_Item_Player')
	this.hDeathPlayer = this:CreateItemData(RT_INIFILE, 'Handle_Item_DeathPlayer')
	this.hPageSet     = this:Lookup('PageSet_Main')
	this.hList        = this.hPageSet:Lookup('Page_Info/Scroll_Player', '')
	this.hDeatList    = this.hPageSet:Lookup('Page_Death/Scroll_Player_List', '')
	this.hDeatMsg     = this.hPageSet:Lookup('Page_Death/Scroll_Death_Info', '')

	this.tScore       = {}
	-- 排序
	local hTitle  = this.hPageSet:Lookup('Page_Info', 'Handle_Player_BG')
	for k, v in ipairs({ 'dwForceID', 'tFood', 'tBuff', 'tEquip', 'nEquipScore', 'tBossKill', 'nFightState' }) do
		local txt = hTitle:Lookup('Text_Title_' .. k)
		txt.nFont = txt:GetFontScheme()
		txt.OnItemMouseEnter = function()
			this:SetFontScheme(101)
		end
		txt.OnItemMouseLeave = function()
			this:SetFontScheme(this.nFont)
		end
		txt.OnItemLButtonClick = function()
			local frame = RT.GetFrame()
			if v == RT_SORT_FIELD then
				RT_SORT_MODE = RT_SORT_MODE == 'ASC' and 'DESC' or 'ASC'
			else
				RT_SORT_MODE = 'DESC'
			end
			RT_SORT_FIELD = v
			RT.UpdateList() -- set userdata
			frame.hList:Sort()
			frame.hList:FormatAllItemPos()
		end
	end
	-- 装备分
	this.hTotalScore = this.hPageSet:Lookup('Page_Info', 'Handle_Score/Text_TotalScore')
	this.hProgress   = this.hPageSet:Lookup('Page_Info', 'Handle_Progress')
	-- 副本信息
	local hDungeon = this.hPageSet:Lookup('Page_Info', 'Handle_Dungeon')
	RT.UpdateDungeonInfo(hDungeon)
	this.hKungfuList = this.hPageSet:Lookup('Page_Info', 'Handle_Kungfu/Handle_Kungfu_List')
	this.hKungfu     = this:CreateItemData(RT_INIFILE, 'Handle_Kungfu_Item')
	this.hKungfuList:Clear()
	for k, dwKungfuID in pairs(LIB.GetKungfuList()) do
		local h = this.hKungfuList:AppendItemFromData(this.hKungfu, dwKungfuID)
		local img = h:Lookup('Image_Force')
		img:FromIconID(select(2, MY_GetSkillName(dwKungfuID)))
		h:Lookup('Text_Num'):SetText(0)
		h.nFont = h:Lookup('Text_Num'):GetFontScheme()
		h.OnItemMouseLeave = function()
			HideTip()
			if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
				this:Lookup('Text_Num'):SetFontScheme(101)
			else
				this:Lookup('Text_Num'):SetFontScheme(h.nFont)
			end
		end
		h.OnItemLButtonClick = function()
			if this:GetAlpha() ~= 255 then
				return
			end
			local frame = RT.GetFrame()
			frame.hList:Clear()
			if RT_SELECT_KUNGFU then
				if RT_SELECT_KUNGFU == tonumber(this:GetName()) then
					RT_SELECT_KUNGFU = nil
					h:Lookup('Text_Num'):SetFontScheme(101)
					return RT.UpdateList()
				else
					local h = this:GetParent():Lookup(tostring(RT_SELECT_KUNGFU))
					h:Lookup('Text_Num'):SetFontScheme(h.nFont)
				end
			end
			RT_SELECT_KUNGFU = tonumber(this:GetName())
			this:Lookup('Text_Num'):SetFontScheme(101)
			RT.UpdateList()
		end
	end
	this.hKungfuList:FormatAllItemPos()
	-- ui 临时变量
	this.tViewInvite = {} -- 请求装备队列
	this.tDataCache  = {} -- 临时数据
	-- 请求数据
	if LIB.IsDungeonMap(RT_MAPID) and not LIB.IsDungeonRoleProgressMap(RT_MAPID) then
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID_REQUEST', RT_MAPID) -- 打开界面刷新
	end
	-- 追加呼吸
	this.hPageSet:ActivePage(RT_SELECT_PAGE)
	RT.UpdateAnchor(this)
	-- lang
	this.hPageSet:Lookup('CheckBox_Info'):Lookup('', 'Text_Basic'):SetText(_L['Team Info'])
	this.hPageSet:Lookup('CheckBox_Death'):Lookup('', 'Text_Battle'):SetText(_L['Battle Info'])
	this.hPageSet:Lookup('Page_Death/Btn_Clear', 'Text_BtnClear'):SetText(_L['Clear Record'])
	this.hPageSet:Lookup('Page_Info'):Lookup('', 'Handle_Player_BG/Text_Title_3'):SetText(_L['BUFF'])
	this.hPageSet:Lookup('Page_Info'):Lookup('', 'Handle_Player_BG/Text_Title_4'):SetText(_L['Equip'])
	this.hPageSet:Lookup('Page_Info'):Lookup('', 'Handle_Player_BG/Text_Title_6'):SetText(_L['Dungeon CD'])
	this.hPageSet:Lookup('Page_Info'):Lookup('', 'Handle_Player_BG/Text_Title_7'):SetText(_L['Fight'])
	if RaidTools.nStyle == 1 then
		this.hPageSet:Lookup('Page_Info'):Lookup('', 'Handle_Progress/Text_Progress_Title'):SetText(_L['Team Members'])
	end
end

function RaidTools.OnEvent(szEvent)
	if szEvent == 'PEEK_OTHER_PLAYER' then
		if arg0 == CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
			if this.tViewInvite[arg1] then
				RT.GetEquipCache(GetPlayer(arg1)) -- 抓取所有数据
			end
		else
			this.tViewInvite[arg1] = nil
		end
	elseif szEvent == 'PARTY_SET_MEMBER_ONLINE_FLAG' then
		if arg2 == 0 then
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'PARTY_DELETE_MEMBER' then
		local me = GetClientPlayer()
		if me.dwID == arg1 then
			this.tDataCache = {}
			this.hList:Clear()
		else
			this.tDataCache[arg1] = nil
		end
	elseif szEvent == 'LOADING_END' or szEvent == 'PARTY_DISBAND' then
		this.tDataCache = {}
		this.hList:Clear()
		RT.UpdatetDeathPage()
		-- 副本信息
		local hDungeon = this.hPageSet:Lookup('Page_Info', 'Handle_Dungeon')
		RT.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'MY_RAIDTOOLS_MAPID_CHANGE' then
		if LIB.IsDungeonMap(RT_MAPID) and not LIB.IsDungeonRoleProgressMap(RT_MAPID) then
			LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID_REQUEST', RT_MAPID) -- 地图变化刷新
		end
		local hDungeon = this.hPageSet:Lookup('Page_Info', 'Handle_Dungeon')
		RT.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'ON_APPLY_PLAYER_SAVED_COPY_RESPOND' then
		local hDungeon = this.hPageSet:Lookup('Page_Info', 'Handle_Dungeon')
		RT.UpdateDungeonInfo(hDungeon)
	elseif szEvent == 'UI_SCALED' then
		RT.UpdateAnchor(this)
	elseif szEvent == 'MY_RAIDTOOLS_SUCCESS' then
		if RT_SORT_FIELD == 'nEquipScore' then
			RT.UpdateList()
			this.hList:Sort()
			this.hList:FormatAllItemPos()
		end
	elseif szEvent == 'MY_RAIDTOOLS_DEATH' then
		local nPage = this.hPageSet:GetActivePageIndex()
		if nPage == 1 then
			RT.UpdatetDeathPage()
		end
	end
	-- update title
	if szEvent == 'PARTY_ADD_MEMBER'
		or szEvent == 'PARTY_DELETE_MEMBER'
		or szEvent == 'TEAM_AUTHORITY_CHANGED'
	then
		local team = GetClientTeam()
		local dwID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
		local info = team.GetMemberInfo(dwID)
		if info then
			this:Lookup('', 'Text_Title'):SetText(_L('%s\'s Team', info.szName) .. ' (' .. team.GetTeamSize() .. '/' .. team.nGroupNum * 5  .. ')')
		end
	end
end

function RaidTools.OnActivePage()
	local nPage = this:GetActivePageIndex()
	if nPage == 0 then
		LIB.BreatheCall('MY_RaidTools', 1000, RT.UpdateList)
		LIB.BreatheCall('MY_RaidTools_Clear', 3000, RT.GetEquip)
		local hView = RT.GetPlayerView()
		if hView and hView:IsVisible() then
			hView:Hide()
		end
	else
		LIB.BreatheCall('MY_RaidTools', false)
		LIB.BreatheCall('MY_RaidTools_Clear', false)
	end
	if nPage == 1 then
		RT.UpdatetDeathPage()
	end
	RT_SELECT_PAGE = nPage
end

function RaidTools.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Close' then
		RT.ClosePanel()
	elseif szName == 'Btn_All' then
		RT_SELECT_DEATH = nil
		RT.UpdatetDeathMsg()
	elseif szName == 'Btn_Clear' then
		LIB.Confirm(_L['Clear Record'], RaidTools.ClearDeathLog)
	elseif szName == 'Btn_Style' then
		RaidTools.nStyle = RaidTools.nStyle == 1 and 2 or 1
		RT.SetStyle()
		RT.ClosePanel()
		RT.OpenPanel()
	end
end

function RaidTools.OnItemMouseEnter()
	local szName = this:GetName()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(true)
	elseif szName == 'Handle_Score' then
		local frame = RT.GetFrame()
		local img = this:Lookup('Image_Score')
		img:SetFrame(23)
		local nScore = this:Lookup('Text_TotalScore'):GetText()
		local xml = {}
		insert(xml, GetFormatText(g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. nScore ..'\n', 65))
		for k, v in pairs(frame.tScore) do
			insert(xml, GetFormatText(RT_SCORE[k] .. g_tStrings.STR_COLON, 67))
			insert(xml, GetFormatText(v ..'\n', 44))
		end
		local x, y = img:GetAbsPos()
		local w, h = img:GetSize()
		OutputTip(table.concat(xml), 400, { x, y, w, h })
	elseif tonumber(szName:find('D(%d+)')) then
		this:Lookup('Image_Cover'):Show()
	end
end

function RaidTools.OnItemMouseLeave()
	local szName = this:GetName()
	HideTip()
	if this:GetType() == 'Box' then
		this:SetObjectMouseOver(false)
	elseif szName == 'Handle_Score' then
		this:Lookup('Image_Score'):SetFrame(22)
	elseif tonumber(szName:find('D(%d+)')) then
		if this and this:Lookup('Image_Cover') and this:Lookup('Image_Cover'):IsValid() then
			this:Lookup('Image_Cover'):Hide()
		end
	end
end

function RaidTools.OnFrameDragEnd()
	RT.tAnchor = GetFrameAnchor(this)
end

function RT.UpdateAnchor(frame)
	local a = RT.tAnchor
	if not IsEmpty(a) then
		frame:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	else
		frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	end
end

function RaidTools.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_Dungeon' then
		local menu = LIB.GetDungeonMenu(function(p) RT.SetMapID(p.dwID) end)
		menu.x, menu.y = Cursor.GetPos(true)
		PopupMenu(menu)
	elseif tonumber(szName:find('P(%d+)')) then
		local dwID = tonumber(szName:match('P(%d+)'))
		if IsCtrlKeyDown() then
			LIB.EditBox_AppendLinkPlayer(this.szName)
		else
			RT.ViewInviteToPlayer(dwID)
		end
	elseif tonumber(szName:find('D(%d+)')) then
		local dwID = tonumber(szName:match('D(%d+)'))
		if IsCtrlKeyDown() then
			LIB.EditBox_AppendLinkPlayer(this.szName)
		else
			RT_SELECT_DEATH = dwID
			RT.UpdatetDeathMsg(dwID)
		end
	end
end

function RaidTools.OnItemRButtonClick()
	local szName = this:GetName()
	local dwID = tonumber(szName:match('P(%d+)'))
	local me = GetClientPlayer()
	if dwID and dwID ~= me.dwID then
		local menu = {
			{ szOption = this.szName, bDisable = true },
			{ bDevide = true }
		}
		InsertPlayerCommonMenu(menu, dwID, this.szName)
		menu[#menu] = {
			szOption = g_tStrings.STR_LOOKUP, fnAction = function()
				RT.ViewInviteToPlayer(dwID)
			end
		}
		local t = {}
		InsertTargetMenu(t, dwID)
		for _, v in ipairs(t) do
			if v.szOption == g_tStrings.LOOKUP_INFO then
				for _, vv in ipairs(v) do
					if vv.szOption == g_tStrings.LOOKUP_NEW_TANLENT then
						table.insert(menu, vv)
						break
					end
				end
				break
			end
		end
		if MY_CharInfo and MY_CharInfo.ViewCharInfoToPlayer then
			menu[#menu + 1] = {
				szOption = g_tStrings.STR_LOOK .. g_tStrings.STR_EQUIP_ATTR, fnAction = function()
					MY_CharInfo.ViewCharInfoToPlayer(dwID)
				end
			}
		end
		PopupMenu(menu)
	end
end

function RT.UpdateDungeonInfo(hDungeon)
	local me = GetClientPlayer()
	local szText = Table_GetMapName(RT_MAPID)
	if me.GetMapID() == RT_MAPID and LIB.IsDungeonMap(RT_MAPID) then
		szText = szText .. '\n' .. 'ID:(' .. me.GetScene().nCopyIndex  ..')'
	else
		local tCD = LIB.GetMapSaveCopy()
		if tCD and tCD[RT_MAPID] then
			szText = szText .. '\n' .. 'ID:(' .. tCD[RT_MAPID][1]  ..')'
		end
	end
	hDungeon:Lookup('Text_Dungeon'):SetText(szText)
end

function RT.GetPlayerView()
	return Station.Lookup('Normal/PlayerView')
end

function RT.ViewInviteToPlayer(dwID)
	local frame = RT.GetFrame()
	local me = GetClientPlayer()
	if dwID ~= me.dwID then
		frame.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID)
	end
end
-- 分数计算
function RT.CountScore(tab, tScore)
	tScore.Food = tScore.Food + #tab.tFood * 100
	tScore.Buff = tScore.Buff + #tab.tBuff * 20
	if tab.nEquipScore then
		tScore.Equip = tScore.Equip + tab.nEquipScore
	end
	if tab.tTemporaryEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tTemporaryEnchant * 300
	end
	if tab.tPermanentEnchant then
		tScore.Enchant = tScore.Enchant + #tab.tPermanentEnchant * 100
	end
	if tab.tEquip then
		for k, v in ipairs(tab.tEquip) do
			tScore.Special = tScore.Special + v.nLevel * 0.15 *  v.nQuality
		end
	end
end
-- 排序计算
function RT.CalculateSort(tInfo)
	local nCount = -2
	if RT_SORT_FIELD == 'tBossKill' then
		if LIB.IsDungeonRoleProgressMap(RT_MAPID) then
			nCount = 0
			for _, p in ipairs(tInfo[RT_SORT_FIELD]) do
				if p then
					nCount = nCount + 100
				else
					nCount = nCount + 1
				end
			end
		else
			nCount = tInfo.nCopyID or HUGE
		end
	elseif tInfo[RT_SORT_FIELD] then
		if type(tInfo[RT_SORT_FIELD]) == 'table' then
			nCount = #tInfo[RT_SORT_FIELD]
		else
			nCount = tInfo[RT_SORT_FIELD]
		end
	end
	if nCount == 0 and not tInfo.bIsOnLine then
		nCount = -2
	end
	return nCount
end
function RT.Sorter(a, b)
	local nCountA = RT.CalculateSort(a)
	local nCountB = RT.CalculateSort(b)

	if RT_SORT_MODE == 'ASC' then -- 升序
		return nCountA < nCountB
	else
		return nCountA > nCountB
	end
end
-- 更新UI 没什么特殊情况 不要clear
function RT.UpdateList()
	local me = GetClientPlayer()
	if not me then return end
	local aTeam, frame, tKungfu = RT.GetTeam(), RT.GetFrame(), {}
	local tScore = {
		Equip   = 0,
		Buff    = 0,
		Food    = 0,
		Enchant = 0,
		Special = 0,
	}
	table.sort(aTeam, RT.Sorter)

	for k, v in ipairs(aTeam) do
		-- 心法统计
		tKungfu[v.dwMountKungfuID] = tKungfu[v.dwMountKungfuID] or {}
		insert(tKungfu[v.dwMountKungfuID], v)
		RT.CountScore(v, tScore)
		if not RT_SELECT_KUNGFU or (RT_SELECT_KUNGFU and v.dwMountKungfuID == RT_SELECT_KUNGFU) then
			local szName = 'P' .. v.dwID
			local h = frame.hList:Lookup(szName)
			if not h then
				h = frame.hList:AppendItemFromData(frame.hPlayer)
			end
			h:SetUserData(k)
			h:SetName(szName)
			h.dwID   = v.dwID
			h.szName = v.szName
			-- 心法名字
			if v.dwMountKungfuID and v.dwMountKungfuID ~= 0 then
				local nIcon = select(2, MY_GetSkillName(v.dwMountKungfuID, 1))
				h:Lookup('Image_Icon'):FromIconID(nIcon)
			else
				h:Lookup('Image_Icon'):FromUITex(GetForceImage(v.dwForceID))
			end
			h:Lookup('Text_Name'):SetText(v.szName)
			h:Lookup('Text_Name'):SetFontColor(LIB.GetForceColor(v.dwForceID))
			-- 药品和BUFF
			if not h['hHandle_Food'] then
				h['hHandle_Food'] = {
					self = h:Lookup('Handle_Food'),
					Pool = UI.HandlePool(h:Lookup('Handle_Food'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			if not h['hHandle_Equip'] then
				h['hHandle_Equip'] = {
					self = h:Lookup('Handle_Equip'),
					Pool = UI.HandlePool(h:Lookup('Handle_Equip'), '<box>w=29 h=29 eventid=784</box>')
				}
			end
			local hBuff = h:Lookup('Box_Buff')
			local hBox = h:Lookup('Box_Grandpa')
			if not v.bIsOnLine then
				h.hHandle_Equip.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				h:Lookup('Text_Toofar1'):SetText(g_tStrings.STR_GUILD_OFFLINE)
			end
			if not v.KPlayer then
				h.hHandle_Food.Pool:Clear()
				h:Lookup('Text_Toofar1'):Show()
				if v.bIsOnLine then
					h:Lookup('Text_Toofar1'):SetText(_L['Too Far'])
				end
				hBuff:Hide()
				hBox:Hide()
			else
				hBuff:Show()
				hBox:Show()
				h:Lookup('Text_Toofar1'):Hide()
				-- 小药UI处理
				local handle_food = h.hHandle_Food.self
				for kk, vv in ipairs(v.tFood) do
					local szName = vv.dwID .. '_' .. vv.nLevel
					local nIcon = select(2, MY_GetBuffName(vv.dwID, vv.nLevel))
					local box = handle_food:Lookup(szName)
					if not box then
						box = h.hHandle_Food.Pool:New()
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, vv.dwID, vv.nLevel, vv.nEndFrame)
					box:SetObjectIcon(nIcon)
					box.OnItemRefreshTip = function()
						local dwID, nLevel, nEndFrame = select(2, this:GetObject())
						local nTime = (nEndFrame - GetLogicFrameCount()) / 16
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						LIB.OutputBuffTip({ x, y, w, h }, dwID, nLevel, nTime)
					end
					local nTime = (vv.nEndFrame - GetLogicFrameCount()) / 16
					if nTime < 480 then
						box:SetAlpha(80)
					else
						box:SetAlpha(255)
					end
					box:Show()
				end
				for i = 0, handle_food:GetItemCount() - 1, 1 do
					local item = handle_food:Lookup(i)
					if item and not item.bFree then
						local dwID, nLevel, nEndFrame = select(2, item:GetObject())
						if dwID and nLevel then
							if not LIB.GetBuff(v.KPlayer, dwID, nLevel) then
								h.hHandle_Food.Pool:Remove(item)
							end
						end
					end
				end
				handle_food:FormatAllItemPos()
				-- BUFF UI处理
				if v.tBuff and #v.tBuff > 0 then
					hBuff:EnableObject(true)
					hBuff:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
					hBuff:SetOverTextFontScheme(1, 197)
					hBuff:SetOverText(1, #v.tBuff)
					hBuff.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local xml = {}
						for k, v in ipairs(v.tBuff) do
							local nIcon = select(2, MY_GetBuffName(v.dwID, v.nLevel))
							local nTime = (v.nEndFrame - GetLogicFrameCount()) / 16
							local nAlpha = nTime < 600 and 80 or 255
							insert(xml, '<image> path="fromiconid" frame=' .. nIcon ..' alpha=' .. nAlpha ..  ' w=30 h=30 </image>')
						end
						OutputTip(table.concat(xml), 250, { x, y, w, h })
					end
				else
					hBuff:SetOverText(1, '')
					hBuff:EnableObject(false)
				end
				if v.bGrandpa then
					hBox:EnableObject(true)
					hBox.OnItemMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local kBuff = LIB.GetBuff(v.KPlayer, RT_GONGZHAN_ID)
						if kBuff then
							LIB.OutputBuffTip({ x, y, w, h }, kBuff.dwID, kBuff.nLevel)
						end
					end
				end
				hBox:EnableObject(v.bGrandpa)
			end
			-- 药品：大附魔
			if v.tTemporaryEnchant and #v.tTemporaryEnchant > 0 then
				local vv = v.tTemporaryEnchant[1]
				local box = h:Lookup('Box_Enchant')
				box:Show()
				if vv.CommonEnchant then
					box:SetObjectIcon(6216)
				else
					box:SetObjectIcon(7577)
				end
				box.OnItemRefreshTip = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local desc = ''
					if vv.CommonEnchant then
						desc = LIB.Table_GetCommonEnchantDesc(vv.dwTemporaryEnchantID)
					else
						-- ... 官方搞的太麻烦了
						local tEnchant = GetItemEnchantAttrib(vv.dwTemporaryEnchantID)
						if tEnchant then
							for kkk, vvv in pairs(tEnchant) do
								if vvv.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then -- ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER
									local skillEvent = g_tTable.SkillEvent:Search(vvv.nValue1)
									if skillEvent then
										desc = desc .. FormatString(skillEvent.szDesc, vvv.nValue1, vvv.nValue2)
									else
										desc = desc .. '<text>text="unknown skill event id:'.. vvv.nValue1..'"</text>'
									end
								elseif vvv.nID == ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE then -- ATTRIBUTE_TYPE.SET_EQUIPMENT_RECIPE
									local tRecipeSkillAtrri = g_tTable.EquipmentRecipe:Search(vvv.nValue1, vvv.nValue2)
									if tRecipeSkillAtrri then
										desc = desc .. tRecipeSkillAtrri.szDesc
									end
								else
									if Table_GetMagicAttributeInfo then
										desc = desc .. FormatString(Table_GetMagicAttributeInfo(vvv.nID, true), vvv.nValue1, vvv.nValue2, 0, 0)
									else
										desc = GetFormatText('Enchant Attrib value ' .. vvv.nValue1 .. ' ', 113)
									end
								end

							end
						end
					end
					if desc and #desc > 0 then
						OutputTip(desc:gsub('font=%d+', 'font=113') .. GetFormatText(FormatString(g_tStrings.STR_ITEM_TEMP_ECHANT_LEFT_TIME ..'\n', GetTimeText(vv.nTemporaryEnchantLeftSeconds)), 102), 400, { x, y, w, h })
					end
				end
				if vv.nTemporaryEnchantLeftSeconds < 480 then
					box:SetAlpha(80)
				else
					box:SetAlpha(255)
				end
			else
				h:Lookup('Box_Enchant'):Hide()
			end
			-- 装备
			if v.tEquip and #v.tEquip > 0 then
				local handle_equip = h.hHandle_Equip.self
				for kk, vv in ipairs(v.tEquip) do

					local szName = tostring(vv.nUiId)
					local box = handle_equip:Lookup(szName)
					if not box then
						box = h.hHandle_Equip.Pool:New()
						LIB.UpdateItemBoxExtend(box, vv.nQuality)
					end
					box:SetName(szName)
					box:SetObject(UI_OBJECT_OTER_PLAYER_ITEM, vv.nUiId, vv.dwBox, vv.dwX, v.dwID)
					box:SetObjectIcon(vv.nIcon)
					local item = GetItem(vv.dwID)
					if item then
						UpdataItemBoxObject(box, vv.dwBox, vv.dwX, item, nil, nil, v.dwID)
					end
					box.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						if not GetItem(vv.dwID) then
							RT.GetTotalEquipScore(v.dwID)
							OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, vv.dwTabType, vv.dwIndex, {x, y, w, h})
						else
							OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, vv.dwID, nil, nil, { x, y, w, h })
						end
					end
					box:Show()
				end
				for i = 0, handle_equip:GetItemCount() - 1, 1 do
					local item = handle_equip:Lookup(i)
					if item and not item.bFree then
						local nUiId, bDelete = item:GetName(), true
						for kk ,vv in ipairs(v.tEquip) do
							if tostring(vv.nUiId) == nUiId then
								bDelete = false
								break
							end
						end
						if bDelete then
							h.hHandle_Equip.Pool:Remove(item)
						end
					end
				end
				handle_equip:FormatAllItemPos()
			end
			-- 装备分
			local hScore = h:Lookup('Text_Score')
			if v.nEquipScore then
				hScore:SetText(v.nEquipScore)
			else
				if v.bIsOnLine then
					hScore:SetText(_L['Loading'])
				else
					hScore:SetText(g_tStrings.STR_GUILD_OFFLINE)
				end
			end
			-- 副本CD
			if not h.hHandle_BossKills then
				h.hHandle_BossKills = {
					self = h:Lookup('Handle_BossKills'),
					Pool = UI.HandlePool(h:Lookup('Handle_BossKills'), '<handle>postype=8 eventid=784 w=16 h=14 <image>name="Image_BossKilled" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=20</image><image>name="Image_BossAlive" w=14 h=14 path="ui/Image/UITga/FBcdPanel01.UITex" frame=21</image></handle>')
				}
			end
			local hCopyID = h:Lookup('Text_CopyID')
			local hBossKills = h:Lookup('Handle_BossKills')
			if LIB.IsDungeonRoleProgressMap(RT_MAPID) then
				for nIndex, bKill in ipairs(v.tBossKill) do
					local szName = tostring(nIndex)
					local hBossKill = hBossKills:Lookup(szName)
					if not hBossKill then
						hBossKill = h.hHandle_BossKills.Pool:New()
						hBossKill:SetName(szName)
					end
					hBossKill:Lookup('Image_BossAlive'):SetVisible(not bKill)
					hBossKill:Lookup('Image_BossKilled'):SetVisible(bKill)
					hBossKill.OnItemRefreshTip = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local texts = {}
						for i, boss in ipairs(Table_GetCDProcessBoss(RT_MAPID)) do
							insert(texts, boss.szName .. '\t' .. _L[v.tBossKill[i] and 'x' or 'r'])
						end
						OutputTip(GetFormatText(concat(texts, '\n')), 400, { x, y, w, h })
					end
					hBossKill:Show()
				end
				for i = 0, hBossKills:GetItemCount() - 1, 1 do
					local item = hBossKills:Lookup(i)
					if item and not item.bFree then
						if tonumber(item:GetName()) > #v.tBossKill then
							h.hHandle_BossKills.Pool:Remove(item)
						end
					end
				end
				hBossKills:FormatAllItemPos()
				hCopyID:Hide()
				hBossKills:Show()
			else
				hCopyID:SetText(v.nCopyID == -1 and _L['None'] or v.nCopyID or _L['Unknown'])
				hCopyID:Show()
				hBossKills:Hide()
			end
			-- 战斗状态
			if v.nFightState == 1 then
				h:Lookup('Image_Fight'):Show()
			else
				h:Lookup('Image_Fight'):Hide()
			end
		end
	end
	frame.hList:FormatAllItemPos()
	for i = 0, frame.hList:GetItemCount() - 1, 1 do
		local item = frame.hList:Lookup(i)
		if item and item:IsValid() then
			if not MY_IsParty(item.dwID) and item.dwID ~= me.dwID then
				frame.hList:RemoveItem(item)
				frame.hList:FormatAllItemPos()
			end
		end
	end
	-- 分数
	frame.tScore = tScore
	local nScore = 0
	for k, v in pairs(tScore) do
		nScore = nScore + v
	end
	frame.hTotalScore:SetText(math.floor(nScore))
	local nNum      = #RT.GetTeamMemberList(true)
	local nAvgScore = nScore / nNum
	frame.hProgress:Lookup('Image_Progress'):SetPercentage(nAvgScore / RT_SCORE_FULL)
	frame.hProgress:Lookup('Text_Progress'):SetText(_L('Team strength(%d/%d)', math.floor(nAvgScore), RT_SCORE_FULL))
	-- 心法统计
	for k, dwKungfuID in pairs(LIB.GetKungfuList()) do
		local h = frame.hKungfuList:Lookup(k - 1)
		local img = h:Lookup('Image_Force')
		local nCount = 0
		if tKungfu[dwKungfuID] then
			nCount = #tKungfu[dwKungfuID]
		end
		local szName, nIcon = MY_GetSkillName(dwKungfuID)
		img:FromIconID(nIcon)
		h:Lookup('Text_Num'):SetText(nCount)
		if not tKungfu[dwKungfuID] then
			h:SetAlpha(60)
			h.OnItemMouseEnter = nil
		else
			h:SetAlpha(255)
			h.OnItemMouseEnter = function()
				this:Lookup('Text_Num'):SetFontScheme(101)
				local xml = {}
				insert(xml, GetFormatText(szName .. g_tStrings.STR_COLON .. nCount .. g_tStrings.STR_PERSON ..'\n', 157))
				table.sort(tKungfu[dwKungfuID], function(a, b)
					local nCountA = a.nEquipScore or -1
					local nCountB = b.nEquipScore or -1
					return nCountA > nCountB
				end)
				for k, v in ipairs(tKungfu[dwKungfuID]) do
					if v.nEquipScore then
						insert(xml, GetFormatText(v.szName .. g_tStrings.STR_COLON ..  v.nEquipScore  ..'\n', 106))
					else
						insert(xml, GetFormatText(v.szName ..'\n', 106))
					end
				end
				local x, y = img:GetAbsPos()
				local w, h = img:GetSize()
				OutputTip(table.concat(xml), 400, { x, y, w, h })
			end
		end
	end
end

local function CreateItemTable(item, dwBox, dwX)
	return {
		nIcon     = LIB.GetItemIconByUIID(item.nUiId),
		dwID      = item.dwID,
		nLevel    = item.nLevel,
		szName    = LIB.GetItemNameByUIID(item.nUiId),
		nUiId     = item.nUiId,
		nVersion  = item.nVersion,
		dwTabType = item.dwTabType,
		dwIndex   = item.dwIndex,
		nQuality  = item.nQuality,
		dwBox     = dwBox,
		dwX       = dwX
	}
end

function RT.GetEquipCache(KPlayer)
	if not KPlayer then return end
	local me = GetClientPlayer()
	local frame = RT.GetFrame()
	local aInfo = {
		tEquip            = {},
		tPermanentEnchant = {},
		tTemporaryEnchant = {}
	}
	-- 装备 Output(GetClientPlayer().GetItem(0,0).GetMagicAttrib())
	for _, equip in ipairs(RT_EQUIP_TOTAL) do
		-- if #aInfo.tEquip >= 3 then break end
		-- 藏剑只看重剑
		if KPlayer.dwForceID == 8 and CONSTANT.EQUIPMENT_INVENTORY[equip] == CONSTANT.EQUIPMENT_INVENTORY.MELEE_WEAPON then
			equip = 'BIG_SWORD'
		end
		local dwBox, dwX = INVENTORY_INDEX.EQUIP, CONSTANT.EQUIPMENT_INVENTORY[equip]
		local item = KPlayer.GetItem(dwBox, dwX)
		if item then
			if RT_EQUIP_SPECIAL[equip] then
				if equip == 'PENDANT' then
					local desc = Table_GetItemDesc(item.nUiId)
					if desc and (desc:find(_L['use'] .. g_tStrings.STR_COLON) or desc:find(_L['Use:']) or desc:find('15' .. g_tStrings.STR_TIME_SECOND)) then
						insert(aInfo.tEquip, CreateItemTable(item, dwBox, dwX))
					end
				-- elseif item.nQuality == 5 then -- 橙色装备
				-- 	insert(aInfo.tEquip, CreateItemTable(item))
				else
					-- 黄字装备
					local aMagicAttrib = item.GetMagicAttrib()
					for _, tAttrib in ipairs(aMagicAttrib) do
						if tAttrib.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
							insert(aInfo.tEquip, CreateItemTable(item, dwBox, dwX))
							break
						end
					end
				end
			end
			-- 永久的附魔 用于评分
			if item.dwPermanentEnchantID and item.dwPermanentEnchantID ~= 0 then
				insert(aInfo.tPermanentEnchant, {
					dwPermanentEnchantID = item.dwPermanentEnchantID,
				})
			end
			-- 大附魔 / 临时附魔 用于评分
			if item.dwTemporaryEnchantID and item.dwTemporaryEnchantID ~= 0 then
				local dat = {
					dwTemporaryEnchantID         = item.dwTemporaryEnchantID,
					nTemporaryEnchantLeftSeconds = item.GetTemporaryEnchantLeftSeconds()
				}
				if LIB.Table_GetCommonEnchantDesc(item.dwTemporaryEnchantID) then
					dat.CommonEnchant = true
				end
				insert(aInfo.tTemporaryEnchant, dat)
			end
		end
	end
	-- 这些都是一次性的缓存数据
	frame.tDataCache[KPlayer.dwID] = {
		tEquip            = aInfo.tEquip,
		tPermanentEnchant = aInfo.tPermanentEnchant,
		tTemporaryEnchant = aInfo.tTemporaryEnchant,
		nEquipScore       = KPlayer.GetTotalEquipScore()
	}
	frame.tViewInvite[KPlayer.dwID] = nil
	if IsEmpty(frame.tViewInvite) then
		if KPlayer.dwID ~= me.dwID then
			FireUIEvent('MY_RAIDTOOLS_SUCCESS') -- 装备请求完毕
		end
	else
		ViewInviteToPlayer(next(frame.tViewInvite), true)
	end
end

function RT.GetTotalEquipScore(dwID)
	local frame = RT.GetFrame()
	if not frame.tViewInvite[dwID] then
		frame.tViewInvite[dwID] = true
		ViewInviteToPlayer(dwID, true)
	end
end

-- 获取团队大部分情况 非缓存
function RT.GetTeam()
	local me    = GetClientPlayer()
	local team  = GetClientTeam()
	local aList = {}
	local frame = RT.GetFrame()
	local bIsInParty = LIB.IsInParty()
	local bIsDungeonRoleProgressMap = LIB.IsDungeonRoleProgressMap(RT_MAPID)
	local aProgressMapBoss = bIsDungeonRoleProgressMap and Table_GetCDProcessBoss(RT_MAPID)
	local aRequestMapCopyID = {}
	local aTeamMemberList = RT.GetTeamMemberList()
	for _, dwID in ipairs(aTeamMemberList) do
		local KPlayer = GetPlayer(dwID)
		local info = bIsInParty and team.GetMemberInfo(dwID) or {}
		local aInfo = {
			KPlayer           = KPlayer,
			szName            = KPlayer and KPlayer.szName or info.szName or _L['Loading...'],
			dwID              = dwID,  -- ID
			dwForceID         = KPlayer and KPlayer.dwForceID or info.dwForceID, -- 门派ID
			dwMountKungfuID   = info and info.dwMountKungfuID or UI_GetPlayerMountKungfuID(), -- 内功
			-- tPermanentEnchant = {}, -- 附魔
			-- tTemporaryEnchant = {}, -- 临时附魔
			-- tEquip            = {}, -- 特效装备
			tBuff             = {}, -- 增益BUFF
			tFood             = {}, -- 小吃和附魔
			-- nEquipScore       = -1,  -- 装备分
			nCopyID           = RT_PLAYER_MAP_COPYID[dwID] and RT_PLAYER_MAP_COPYID[dwID][RT_MAPID] and RT_PLAYER_MAP_COPYID[dwID][RT_MAPID].nID, -- 副本ID
			tBossKill         = {}, -- 副本进度
			nFightState       = KPlayer and KPlayer.bFightState and 1 or 0, -- 战斗状态
			bIsOnLine         = true,
			bGrandpa          = false, -- 大爷
		}
		if info and info.bIsOnLine ~= nil then
			aInfo.bIsOnLine = info.bIsOnLine
		end
		if KPlayer then
			-- 小吃和buff
			for _, tBuff in ipairs(LIB.GetBuffList(KPlayer)) do
				local nType = GetBuffInfo(tBuff.dwID, tBuff.nLevel, {}).nDetachType or 0
				if RT_FOOD_TYPE[nType] then
					insert(aInfo.tFood, tBuff)
				end
				if RT_BUFF_ID[tBuff.dwID] then
					insert(aInfo.tBuff, tBuff)
				end
				if tBuff.dwID == RT_GONGZHAN_ID then -- grandpa
					aInfo.bGrandpa = true
				end
			end
			if me.dwID == KPlayer.dwID then
				RT.GetEquipCache(me)
			end
		end
		-- 副本CDID
		if aInfo.bIsOnLine and not bIsDungeonRoleProgressMap and LIB.IsDungeonMap(RT_MAPID) then
			if not RT_PLAYER_MAP_COPYID[dwID] then
				RT_PLAYER_MAP_COPYID[dwID] = {}
			end
			if not RT_PLAYER_MAP_COPYID[dwID][RT_MAPID] then
				RT_PLAYER_MAP_COPYID[dwID][RT_MAPID] = {}
			end
			local tCopyID = RT_PLAYER_MAP_COPYID[dwID][RT_MAPID]
			if (not tCopyID.nRequestTime or GetCurrentTime() - tCopyID.nRequestTime > 10)
			and (not tCopyID.nReceiveTime or GetCurrentTime() - tCopyID.nReceiveTime > 60) then
				insert(aRequestMapCopyID, dwID)
				tCopyID.nRequestTime = GetCurrentTime()
			end
		end
		-- 副本进度
		if aInfo.bIsOnLine and bIsDungeonRoleProgressMap then
			for i, boss in ipairs(aProgressMapBoss) do
				ApplyDungeonRoleProgress(RT_MAPID, dwID) -- 成功回调 UPDATE_DUNGEON_ROLE_PROGRESS(dwMapID, dwPlayerID)
				aInfo.tBossKill[i] = GetDungeonRoleProgress(RT_MAPID, dwID, boss.dwProgressID)
			end
		end
		setmetatable(aInfo, { __index = frame.tDataCache[dwID] })
		insert(aList, aInfo)
	end
	if #aRequestMapCopyID > 0 then
		if #aRequestMapCopyID == #aTeamMemberList then
			aRequestMapCopyID = nil
		end
		LIB.SendBgMsg(PLAYER_TALK_CHANNEL.RAID, 'MY_MAP_COPY_ID_REQUEST', RT_MAPID, aRequestMapCopyID) -- 周期刷新
	end
	return aList
end

function RT.GetEquip()
	local hView = RT.GetPlayerView()
	if hView and hView:IsVisible() then -- 查看装备的时候停止请求
		return
	end
	local me = GetClientPlayer()
	if not me then return end
	local frame = RT.GetFrame()
	local team  = GetClientTeam()
	for k, v in ipairs(RT.GetTeamMemberList()) do
		if v ~= me.dwID then
			local info = team.GetMemberInfo(v)
			if info.bIsOnLine then
				RT.GetTotalEquipScore(v)
			end
		end
	end
end

-- 获取团队成员列表
function RT.GetTeamMemberList(bIsOnLine)
	local me   = GetClientPlayer()
	local team = GetClientTeam()
	if me.IsInParty() then
		if bIsOnLine then
			local tTeam = {}
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = team.GetMemberInfo(v)
				if info and info.bIsOnLine then
					insert(tTeam, v)
				end
			end
			return tTeam
		else
			return team.GetTeamMemberList()
		end
	else
		return { me.dwID }
	end
end

-- 重伤记录
function RT.UpdatetDeathPage()
	local frame = RT.GetFrame()
	local team  = GetClientTeam()
	local me    = GetClientPlayer()
	frame.hDeatList:Clear()
	local tList = {}
	for k, v in pairs(RaidTools.GetDeathLog()) do
		insert(tList, {
			dwID   = k,
			nCount = #v
		})
	end
	table.sort(tList, function(a, b)
		return a.nCount > b.nCount
	end)
	for k, v in ipairs(tList) do
		local dwID = v.dwID == 'self' and me.dwID or v.dwID
		local info = team.GetMemberInfo(dwID)
		if info or dwID == me.dwID then
			local h = frame.hDeatList:AppendItemFromData(frame.hDeathPlayer, 'D' .. dwID)
			local icon = select(2, MY_GetSkillName(info and info.dwMountKungfuID or UI_GetPlayerMountKungfuID()))
			local szName = info and info.szName or me.szName
			h.szName = szName
			h:Lookup('Image_DeathIcon'):FromIconID(icon)
			h:Lookup('Text_DeathName'):SetText(szName)
			h:Lookup('Text_DeathName'):SetFontColor(LIB.GetForceColor(info and info.dwForceID or me.dwForceID))
			h:Lookup('Text_DeathCount'):SetText(v.nCount)
		end
	end
	frame.hDeatList:FormatAllItemPos()
	RT.UpdatetDeathMsg(RT_SELECT_DEATH)
end

function RaidTools.OnShowDeathInfo()
	local dwID, i = this:GetName():match('(%d+)_(%d+)')
	if dwID then
		dwID, i = tonumber(dwID), tonumber(i)
	else
		dwID = 'self'
		i = tonumber(this:GetName():match('self_(%d+)'))
	end
	local tDeath = RaidTools.GetDeathLog()
	if tDeath[dwID] and tDeath[dwID][i] then
		local tab = tDeath[dwID][i]
		local xml = {}
		insert(xml, GetFormatText(_L['last 5 skill damage'] .. '\n\n' , 59))
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
			insert(xml, GetFormatText('\t' .. string.format('%02d:%02d:%02d', t.hour, t.minute, t.second), 41))
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
		OutputTip(table.concat(xml), 400, { x, y, w, h })
	end
end

function RaidTools.OnAppendEdit()
	local handle = this:GetParent()
	local edit = Station.Lookup('Lowest2/EditBox/Edit_Input')
	edit:ClearText()
	for i = this:GetIndex() + 1, handle:GetItemCount() do
		local h = handle:Lookup(i)
		local szText = h:GetText()
		if szText == '\n' then
			break
		end
		if h:GetName() == 'namelink' then
			edit:InsertObj(szText, { type = 'name', text = szText, name = string.sub(szText, 2, -2) })
		else
			edit:InsertObj(szText, { type = 'text', text = szText })
		end
	end
	Station.SetFocusWindow(edit)
end

function RT.UpdatetDeathMsg(dwID)
	local frame = RT.GetFrame()
	local me    = GetClientPlayer()
	local team  = GetClientTeam()
	local data  = {}
	local key = dwID == me.dwID and 'self' or dwID
	local tDeath = RaidTools.GetDeathLog()
	if not dwID then
		for k, v in pairs(tDeath) do
			for kk, vv in ipairs(v) do
				if k == 'self' then
					vv.dwID = me.dwID
				else
					vv.dwID = k
				end
				vv.nIndex = kk
				insert(data, vv)
			end
		end
	else
		for k, v in ipairs(tDeath[key] or {}) do
			if key == 'self' then
				v.dwID = me.dwID
			else
				v.dwID = key
			end
			v.nIndex = k
			insert(data, v)
		end
	end
	table.sort(data, function(a, b) return a.nCurrentTime > b.nCurrentTime end)
	frame.hDeatMsg:Clear()
	for k, v in ipairs(data) do
		if MY_IsParty(v.dwID) or v.dwID == me.dwID then
			local info  = team.GetMemberInfo(v.dwID)
			local key = v.dwID == me.dwID and 'self' or v.dwID
			local t = TimeToDate(v.nCurrentTime)
			local xml = {}
			insert(xml, GetFormatText(_L[' * '] .. string.format('[%02d:%02d:%02d]', t.hour, t.minute, t.second), 10, 255, 255, 255, 16, 'this.OnItemLButtonClick = MY_RaidTools.OnAppendEdit'))
			local r, g, b = LIB.GetForceColor(info and info.dwForceID or me.dwForceID)
			insert(xml, GetFormatText('[' .. (info and info.szName or me.szName) ..']', 10, r, g, b, 16, 'this.OnItemLButtonClick = function() OnItemLinkDown(this) end', 'namelink'))
			insert(xml, GetFormatText(g_tStrings.TRADE_BE, 10, 255, 255, 255))
			if szKiller == '' and v.data[1].szKiller ~= '' then
				insert(xml, GetFormatText('[' .. _L['OUTER GUEST'] .. g_tStrings.STR_OR .. v.data[1].szKiller ..']', 10, 13, 150, 70, 256, 'this.OnItemMouseEnter = MY_RaidTools.OnShowDeathInfo', key .. '_' .. v.nIndex))
			else
				insert(xml, GetFormatText('[' .. (v.szKiller ~= '' and v.szKiller or  _L['OUTER GUEST']) ..']', 10, 255, 128, 0, 256, 'this.OnItemMouseEnter = MY_RaidTools.OnShowDeathInfo', key .. '_' .. v.nIndex))
			end
			insert(xml, GetFormatText(g_tStrings.STR_KILL .. g_tStrings.STR_FULL_STOP, 10, 255, 255, 255))
			insert(xml, GetFormatText('\n'))
			frame.hDeatMsg:AppendItemFromString(table.concat(xml))
		end
	end
	frame.hDeatMsg:FormatAllItemPos()
end

-- UI操作 惯例
function RT.SetStyle()
	RT_INIFILE = PACKET_INFO.ROOT .. 'MY_TeamTools/ui/MY_RaidTools' .. RaidTools.nStyle .. '.ini'
end

function RT.SetMapID(dwMapID)
	if RT_MAPID == dwMapID then
		return
	end
	RT_MAPID = dwMapID
	FireUIEvent('MY_RAIDTOOLS_MAPID_CHANGE')
end

function RT.GetFrame()
	return Station.Lookup('Normal/MY_RaidTools')
end

RT.IsOpened = RT.GetFrame

function RT.OpenPanel()
	if not RT.IsOpened() then
		Wnd.OpenWindow(RT_INIFILE, 'MY_RaidTools')
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
end

function RT.ClosePanel()
	if RT.IsOpened() then
		local frame = RT.GetFrame()
		Wnd.CloseWindow(RT.GetFrame())
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		LIB.BreatheCall('MY_RaidTools', false)
		LIB.BreatheCall('MY_RaidTools_Clear', false)
		LIB.RegisterEsc('RaidTools')
	end
end

function RT.TogglePanel()
	if RT.IsOpened() then
		RT.ClosePanel()
	else
		RT.OpenPanel()
	end
end

LIB.RegisterInit('MY_TeamTools', RT.SetStyle)

local function onLoadingEnd()
	RT.SetMapID(GetClientPlayer().GetMapID())
end
LIB.RegisterEvent('LOADING_END', onLoadingEnd)

local function onBgMsgMapCopyID(_, nChannel, dwID, szName, bIsSelf, dwMapID, aCopyID)
	if not RT_PLAYER_MAP_COPYID[dwID] then
		RT_PLAYER_MAP_COPYID[dwID] = {}
	end
	if not RT_PLAYER_MAP_COPYID[dwID][dwMapID] then
		RT_PLAYER_MAP_COPYID[dwID][dwMapID] = {}
	end
	RT_PLAYER_MAP_COPYID[dwID][dwMapID].nID = IsTable(aCopyID) and aCopyID[1] or -1
	RT_PLAYER_MAP_COPYID[dwID][dwMapID].nReceiveTime = GetCurrentTime()
end
LIB.RegisterBgMsg('MY_MAP_COPY_ID', onBgMsgMapCopyID)

LIB.RegisterAddonMenu({ szOption = _L['Raid Tools Panel'], fnAction = RT.TogglePanel })
LIB.RegisterHotKey('MY_RaidTools', _L['Open/Close Raid Tools Panel'], RT.TogglePanel)

local ui = {
	TogglePanel = RT.TogglePanel
}
setmetatable(RaidTools, { __index = ui, __metatable = true })
