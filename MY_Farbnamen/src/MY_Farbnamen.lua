--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天窗口名称染色插件
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
local PLUGIN_NAME = 'MY_Farbnamen'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Farbnamen'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------
---------------------------------------------------------------
-- 设置和数据
---------------------------------------------------------------
LIB.CreateDataRoot(PATH_TYPE.SERVER)

MY_Farbnamen = MY_Farbnamen or {
	bEnabled = true,
}
RegisterCustomData('MY_Farbnamen.bEnabled')

local _MY_Farbnamen = {
	tForceString = Clone(g_tStrings.tForceTitle),
	tRoleType    = {
		[ROLE_TYPE.STANDARD_MALE  ] = _L['man'],
		[ROLE_TYPE.STANDARD_FEMALE] = _L['woman'],
		[ROLE_TYPE.LITTLE_BOY     ] = _L['boy'],
		[ROLE_TYPE.LITTLE_GIRL    ] = _L['girl'],
	},
	tCampString  = Clone(g_tStrings.STR_GUILD_CAMP_NAME),
	aPlayerQueu = {},
}
local DB_ERR_COUNT, DB_MAX_ERR_COUNT = 0, 5
local DB, DBI_W, DBI_RI, DBI_RN, DBT_W, DBT_RI

local function InitDB()
	if DB then
		return true
	end
	if DB_ERR_COUNT > DB_MAX_ERR_COUNT then
		return false
	end
	DB = LIB.ConnectDatabase(_L['MY_Farbnamen'], {'cache/player_info.v2.db', PATH_TYPE.SERVER})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		LIB.Sysmsg(_L['MY_Farbnamen'], szMsg, CONSTANT.MSG_THEME.ERROR)
		return false
	end
	DB:Execute('CREATE TABLE IF NOT EXISTS InfoCache (id INTEGER PRIMARY KEY, name VARCHAR(20) NOT NULL, force INTEGER, role INTEGER, level INTEGER, title VARCHAR(20), camp INTEGER, tong INTEGER)')
	DB:Execute('CREATE UNIQUE INDEX IF NOT EXISTS info_cache_name_uidx ON InfoCache(name)')
	DBI_W  = DB:Prepare('REPLACE INTO InfoCache (id, name, force, role, level, title, camp, tong) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
	DBI_RI = DB:Prepare('SELECT id, name, force, role, level, title, camp, tong FROM InfoCache WHERE id = ?')
	DBI_RN = DB:Prepare('SELECT id, name, force, role, level, title, camp, tong FROM InfoCache WHERE name = ?')
	DB:Execute('CREATE TABLE IF NOT EXISTS TongCache (id INTEGER PRIMARY KEY, name VARCHAR(20))')
	DBT_W  = DB:Prepare('REPLACE INTO TongCache (id, name) VALUES (?, ?)')
	DBT_RI = DB:Prepare('SELECT id, name FROM TongCache WHERE id = ?')

	-- 旧版文件缓存转换
	local SZ_IC_PATH = LIB.FormatPath({'cache/PLAYER_INFO/{$relserver}/', PATH_TYPE.DATA})
	if IsLocalFileExist(SZ_IC_PATH) then
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite start!', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 999 do
			local data = LIB.LoadLUAData({'cache/PLAYER_INFO/{$relserver}/DAT2/' .. i .. '.{$lang}.jx3dat', PATH_TYPE.DATA})
			if data then
				for id, p in pairs(data) do
					DBI_W:ClearBindings()
					DBI_W:BindAll(p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
					DBI_W:Execute()
				end
			end
		end
		DB:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite finished!', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite start!', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 128 do
			for j = 0, 128 do
				local data = LIB.LoadLUAData({'cache/PLAYER_INFO/{$relserver}/TONG/' .. i .. '-' .. j .. '.{$lang}.jx3dat', PATH_TYPE.DATA})
				if data then
					for id, name in pairs(data) do
						DBT_W:ClearBindings()
						DBT_W:BindAll(id, name)
						DBT_W:Execute()
					end
				end
			end
		end
		DB:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite finished!', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen cleaning file cache start: ' .. SZ_IC_PATH, DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		CPath.DelDir(SZ_IC_PATH)
		--[[#DEBUG BEGIN]]
		LIB.Debug('MY_Farbnamen', 'Farbnamen cleaning file cache finished!', DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end

	-- 转移V1旧版数据
	local DB_V1_PATH = LIB.FormatPath({'cache/player_info.db', PATH_TYPE.SERVER})
	if IsLocalFileExist(DB_V1_PATH) then
		local DB_V1 = SQLite3_Open(DB_V1_PATH)
		if DB_V1 then
			-- 角色缓存
			local nCount, nPageSize = Get(DB_V1:Execute('SELECT COUNT(*) AS count FROM InfoCache'), {1, 'count'}, 0), 10000
			DB:Execute('BEGIN TRANSACTION')
			for i = 0, nCount / nPageSize do
				for _, p in ipairs(DB_V1:Execute('SELECT id, name, force, role, level, title, camp, tong FROM InfoCache LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
					DBI_W:ClearBindings()
					DBI_W:BindAll(p.id, p.name, p.force, p.role, p.level, p.title, p.camp, p.tong)
					DBI_W:Execute()
				end
			end
			DB:Execute('END TRANSACTION')
			-- 帮会缓存
			local nCount, nPageSize = Get(DB_V1:Execute('SELECT COUNT(*) AS count FROM TongCache'), {1, 'count'}, 0), 10000
			DB:Execute('BEGIN TRANSACTION')
			for i = 0, nCount / nPageSize do
				for _, p in ipairs(DB_V1:Execute('SELECT id, name FROM TongCache LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
					DBI_W:ClearBindings()
					DBI_W:BindAll(p.id, p.name)
					DBI_W:Execute()
				end
			end
			DB:Execute('END TRANSACTION')
			DB_V1:Release()
		end
		LIB.Sysmsg(_L['MY_Farbnamen'], _L['Upgrade database finished!'])
		CPath.DelFile(DB_V1_PATH)
	end
	return true
end
InitDB()

---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
-- 插入聊天内容的 HOOK （过滤、加入时间 ）
LIB.HookChatPanel('AFTER.MY_FARBNAMEN', function(h, nIndex)
	if MY_Farbnamen.bEnabled then
		for i = nIndex, h:GetItemCount() - 1 do
			MY_Farbnamen.Render(h:Lookup(i))
		end
	end
end)
-- 开放的名称染色接口
-- (userdata) MY_Farbnamen.Render(userdata namelink)    处理namelink染色 namelink是一个姓名Text元素
-- (string) MY_Farbnamen.Render(string szMsg)           格式化szMsg 处理里面的名字
function MY_Farbnamen.Render(szMsg)
	if type(szMsg) == 'string' then
		-- <text>text='[就是个阵眼]' font=10 r=255 g=255 b=255  name='namelink_4662931' eventid=515</text><text>text='说：' font=10 r=255 g=255 b=255 </text><text>text='[茗伊]' font=10 r=255 g=255 b=255  name='namelink_4662931' eventid=771</text><text>text='\n' font=10 r=255 g=255 b=255 </text>
		local xml = LIB.Xml.Decode(szMsg)
		if xml then
			for _, ele in ipairs(xml) do
				if ele[''].name and ele[''].name:sub(1, 9) == 'namelink_' then
					local szName = string.gsub(ele[''].text, '[%[%]]', '')
					local tInfo = MY_Farbnamen.GetAusName(szName)
					if tInfo then
						ele[''].r = tInfo.rgb[1]
						ele[''].g = tInfo.rgb[2]
						ele[''].b = tInfo.rgb[3]
					end
					ele[''].eventid = 82803
					ele[''].script = (ele[''].script or '') .. '\nthis.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end'
				end
			end
			szMsg = LIB.Xml.Encode(xml)
		end
		-- szMsg = string.gsub( szMsg, '<text>([^<]-)text='([^<]-)'([^<]-name='namelink_%d-'[^<]-)</text>', function (szExtra1, szName, szExtra2)
		--     szName = string.gsub(szName, '[%[%]]', '')
		--     local tInfo = MY_Farbnamen.GetAusName(szName)
		--     if tInfo then
		--         szExtra1 = string.gsub(szExtra1, '[rgb]=%d+', '')
		--         szExtra2 = string.gsub(szExtra2, '[rgb]=%d+', '')
		--         szExtra1 = string.gsub(szExtra1, 'eventid=%d+', '')
		--         szExtra2 = string.gsub(szExtra2, 'eventid=%d+', '')
		--         return string.format(
		--             '<text>%stext='[%s]'%s eventid=883 script='this.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end' r=%d g=%d b=%d</text>',
		--             szExtra1, szName, szExtra2, tInfo.rgb[1], tInfo.rgb[2], tInfo.rgb[3]
		--         )
		--     end
		-- end)
	elseif type(szMsg) == 'table' and type(szMsg.GetName) == 'function' and szMsg:GetName():sub(1, 8) == 'namelink' then
		local namelink = szMsg
		local ui = UI(namelink):Hover(MY_Farbnamen.ShowTip, HideTip, true)
		local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
		local tInfo = MY_Farbnamen.GetAusName(szName)
		if tInfo then
			ui:Color(tInfo.rgb)
		end
	end
	return szMsg
end

function MY_Farbnamen.GetTip(szName)
	local tInfo = MY_Farbnamen.GetAusName(szName)
	if tInfo then
		local tTip = {}
		-- author info
		if tInfo.dwID and tInfo.szName and tInfo.szName == PACKET_INFO.AUTHOR_ROLES[tInfo.dwID] then
			insert(tTip, GetFormatText(PACKET_INFO.NAME, 8, 89, 224, 232))
			insert(tTip, GetFormatText(' ', 136, 89, 224, 232))
			insert(tTip, GetFormatText(_L['[author]'], 8, 89, 224, 232))
			insert(tTip, CONSTANT.XML_LINE_BREAKER)
		end
		-- 名称 等级
		insert(tTip, GetFormatText(('%s(%d)'):format(tInfo.szName, tInfo.nLevel), 136))
		-- 是否同队伍
		if UI_GetClientPlayerID() ~= tInfo.dwID and LIB.IsParty(tInfo.dwID) then
			insert(tTip, GetFormatText(_L['[teammate]'], nil, 0, 255, 0))
		end
		insert(tTip, CONSTANT.XML_LINE_BREAKER)
		-- 称号
		if tInfo.szTitle and #tInfo.szTitle > 0 then
			insert(tTip, GetFormatText('<' .. tInfo.szTitle .. '>', 136))
			insert(tTip, CONSTANT.XML_LINE_BREAKER)
		end
		-- 帮会
		if tInfo.szTongID and #tInfo.szTongID > 0 then
			insert(tTip, GetFormatText('[' .. tInfo.szTongID .. ']', 136))
			insert(tTip, CONSTANT.XML_LINE_BREAKER)
		end
		-- 门派 体型 阵营
		insert(tTip, GetFormatText(
			(_MY_Farbnamen.tForceString[tInfo.dwForceID] or tInfo.dwForceID or _L['Unknown force']) .. _L.STR_SPLIT_DOT ..
			(_MY_Farbnamen.tRoleType[tInfo.nRoleType] or tInfo.nRoleType or  _L['Unknown gender'])    .. _L.STR_SPLIT_DOT ..
			(_MY_Farbnamen.tCampString[tInfo.nCamp] or tInfo.nCamp or  _L['Unknown camp']), 136
		))
		insert(tTip, CONSTANT.XML_LINE_BREAKER)
		-- 随身便笺
		if MY_Anmerkungen and MY_Anmerkungen.GetPlayerNote then
			local note = MY_Anmerkungen.GetPlayerNote(tInfo.dwID)
			if note and note.szContent ~= '' then
				insert(tTip, GetFormatText(note.szContent, 0))
				insert(tTip, CONSTANT.XML_LINE_BREAKER)
			end
		end
		-- 调试信息
		if IsCtrlKeyDown() then
			insert(tTip, CONSTANT.XML_LINE_BREAKER)
			insert(tTip, GetFormatText(_L('Player ID: %d', tInfo.dwID), 102))
		end
		-- 组装Tip
		return concat(tTip)
	end
end

function MY_Farbnamen.ShowTip(namelink)
	if type(namelink) ~= 'table' then
		namelink = this
	end
	if not namelink then
		return
	end
	local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
	local x, y = namelink:GetAbsPos()
	local w, h = namelink:GetSize()

	local szTip = MY_Farbnamen.GetTip(szName)
	if szTip then
		OutputTip(szTip, 450, {x, y, w, h}, UI.TIP_POSITION.TOP_BOTTOM)
	end
end
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
local l_infocache       = {} -- 读取数据缓存
local l_infocache_w     = {} -- 修改数据缓存
local l_remoteinfocache = {} -- 跨服数据缓存
local l_tongnames       = {} -- 帮会数据缓存
local l_tongnames_w     = {} -- 帮会修改数据缓存
local function GetTongName(dwID)
	if not dwID then
		return
	end
	local szTong = l_tongnames[dwID]
	if not szTong and InitDB() then
		DBT_RI:ClearBindings()
		DBT_RI:BindAll(dwID)
		local data = DBT_RI:GetNext()
		if data then
			szTong = data.name
			l_tongnames[dwID] = data.name
		end
	end
	return szTong
end

do
local function Flush()
	if not InitDB() then
		return
	end
	if DBI_W then
		DB:Execute('BEGIN TRANSACTION')
		for i, p in pairs(l_infocache_w) do
			DBI_W:ClearBindings()
			DBI_W:BindAll(p.id, p.name, p.force, p.role, p.level, p.title, p.camp, p.tong)
			DBI_W:Execute()
		end
		DB:Execute('END TRANSACTION')
	end
	if DBT_W then
		DB:Execute('BEGIN TRANSACTION')
		for id, name in pairs(l_tongnames_w) do
			DBT_W:ClearBindings()
			DBT_W:BindAll(id, name)
			DBT_W:Execute()
		end
		DB:Execute('END TRANSACTION')
	end
end
LIB.RegisterFlush('MY_Farbnamen_Save', Flush)
end

do
local function OnExit()
	if not DB then
		return
	end
	DB:Release()
end
LIB.RegisterExit('MY_Farbnamen_Save', OnExit)
end

-- 通过szName获取信息
function MY_Farbnamen.Get(szKey)
	local info = l_remoteinfocache[szKey] or l_infocache[szKey]
	if not info then
		if type(szKey) == 'string' then
			if InitDB() then
				DBI_RN:ClearBindings()
				DBI_RN:BindAll(szKey)
				info = DBI_RN:GetNext()
			end
		elseif type(szKey) == 'number' then
			if InitDB() then
				DBI_RI:ClearBindings()
				DBI_RI:BindAll(szKey)
				info = DBI_RI:GetNext()
			end
		end
		if info then
			l_infocache[info.id] = info
			l_infocache[info.name] = info
		end
	end
	if info then
		return {
			dwID      = info.id,
			szName    = info.name,
			dwForceID = info.force,
			nRoleType = info.role,
			nLevel    = info.level,
			szTitle   = info.title,
			nCamp     = info.camp,
			szTongID  = GetTongName(info.tong) or '',
			rgb       = { LIB.GetForceColor(info.force, 'forecolor') },
		}
	end
end
MY_Farbnamen.GetAusName = MY_Farbnamen.Get

-- 通过dwID获取信息
function MY_Farbnamen.GetAusID(dwID)
	MY_Farbnamen.AddAusID(dwID)
	return MY_Farbnamen.Get(dwID)
end

-- 保存指定dwID的玩家
function MY_Farbnamen.AddAusID(dwID)
	local player = GetPlayer(dwID)
	if not player or not player.szName or player.szName == '' then
		return false
	else
		local info = l_infocache[player.dwID] or {}
		info.id    = player.dwID
		info.name  = player.szName
		info.force = player.dwForceID or -1
		info.role  = player.nRoleType or -1
		info.level = player.nLevel or -1
		info.title = player.nX ~= 0 and player.szTitle or info.title
		info.camp  = player.nCamp or -1
		info.tong  = player.dwTongID or -1

		if IsRemotePlayer(info.id) then
			l_infocache[info.id] = info
			l_infocache[info.name] = info
		else
			local dwTongID = player.dwTongID
			if dwTongID and dwTongID ~= 0 then
				local szTong = GetTongClient().ApplyGetTongName(dwTongID, 254)
				if szTong and szTong ~= '' then
					l_tongnames[dwTongID] = szTong
					l_tongnames_w[dwTongID] = szTong
				end
			end
			l_infocache[info.id] = info
			l_infocache[info.name] = info
			l_infocache_w[info.id] = info
		end
		return true
	end
end

--------------------------------------------------------------
-- 菜单
--------------------------------------------------------------
function MY_Farbnamen.GetMenu()
	local t = {szOption = _L['MY_Farbnamen']}
	table.insert(t, {
		szOption = _L['enable'],
		fnAction = function()
			MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
		end,
		bCheck = true,
		bChecked = MY_Farbnamen.bEnabled
	})
	table.insert(t, {
		szOption = _L['customize color'],
		fnAction = function()
			LIB.ShowPanel()
			LIB.FocusPanel()
			LIB.SwitchTab('GlobalColor')
		end,
		fnDisable = function()
			return not MY_Farbnamen.bEnabled
		end,
	})
	table.insert(t, {
		szOption = _L['reset data'],
		fnAction = function()
			if not InitDB() then
				return
			end
			DB:Execute('DELETE FROM InfoCache')
			LIB.Sysmsg(_L['MY_Farbnamen'], _L['cache data deleted.'])
		end,
		fnDisable = function()
			return not MY_Farbnamen.bEnabled
		end,
	})
	return t
end
LIB.RegisterAddonMenu('MY_Farbenamen', MY_Farbnamen.GetMenu)
--------------------------------------------------------------
-- 注册事件
--------------------------------------------------------------
do
local l_peeklist = {}
local function onBreathe()
	for dwID, nRetryCount in pairs(l_peeklist) do
		if MY_Farbnamen.AddAusID(dwID) or nRetryCount > 5 then
			l_peeklist[dwID] = nil
		else
			l_peeklist[dwID] = nRetryCount + 1
		end
	end
end
LIB.BreatheCall(250, onBreathe)

local function OnPeekPlayer()
	if arg0 == CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		l_peeklist[arg1] = 0
	end
end
LIB.RegisterEvent('PEEK_OTHER_PLAYER', OnPeekPlayer)
LIB.RegisterEvent('PLAYER_ENTER_SCENE', function() l_peeklist[arg0] = 0 end)
LIB.RegisterEvent('ON_GET_TONG_NAME_NOTIFY', function() l_tongnames[arg1], l_tongnames_w[arg1] = arg2, arg2 end)
end
