--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 聊天窗口名称染色插件
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Farbnamen/MY_Farbnamen'
local PLUGIN_NAME = 'MY_Farbnamen'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Farbnamen'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_Farbnamen.BanHDD', { ['*'] = true, intl = false })

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 设置和数据
--------------------------------------------------------------------------------
X.CreateDataRoot(X.PATH_TYPE.GLOBAL)

local O = X.CreateUserSettingsModule('MY_Farbnamen', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		szDescription = X.MakeCaption({
			_L['Enable MY_Farbnamen'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSaveDB = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		szDescription = X.MakeCaption({
			_L['Save talker information to database'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = X.IS_CLASSIC,
	},
	bInsertIcon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		szDescription = X.MakeCaption({
			_L['Insert force icon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nInsertIconSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		szDescription = X.MakeCaption({
			_L['Icon size'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 20,
	},
})
local D = {
	bSaveDB = false,
	tForceString = X.Clone(g_tStrings.tForceTitle),
	tRoleType    = {
		[ROLE_TYPE.STANDARD_MALE  ] = _L['Man'],
		[ROLE_TYPE.STANDARD_FEMALE] = _L['Woman'],
		[ROLE_TYPE.LITTLE_BOY     ] = _L['Boy'],
		[ROLE_TYPE.LITTLE_GIRL    ] = _L['Girl'],
	},
	tCampString  = X.Clone(g_tStrings.STR_GUILD_CAMP_NAME),
	aPlayerQueu = {},
}
local NAME_ID_HEADER_XML = {}
local GUID_HEADER_XML = {}
local DB_ERR_COUNT, DB_MAX_ERR_COUNT = 0, 5
local DB, DBP_W, DBP_RI, DBP_RN, DBP_RGI, DBT_W, DBT_RI

local function InitDB()
	if not D.bSaveDB then
		return false
	end
	if DB then
		return true
	end
	if DB_ERR_COUNT > DB_MAX_ERR_COUNT then
		return false
	end
	CPath.MakeDir(X.FormatPath({'cache/farbnamen/', X.PATH_TYPE.GLOBAL}))
	DB = X.SQLiteConnect(_L['MY_Farbnamen'], {'cache/farbnamen/farbnamen.v7.db', X.PATH_TYPE.GLOBAL})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		X.OutputSystemMessage(_L['MY_Farbnamen'], szMsg, X.CONSTANT.MSG_THEME.ERROR)
		return false
	end
	X.SQLiteExecute(DB, [[
		CREATE TABLE IF NOT EXISTS Info (
			key NVARCHAR(128) NOT NULL,
			value NVARCHAR(4096) NOT NULL,
			PRIMARY KEY (key)
		)
	]])
	X.SQLiteExecute(DB, [[INSERT INTO Info (key, value) VALUES ('version', '7')]])
	X.SQLiteExecute(DB, [[
		CREATE TABLE IF NOT EXISTS PlayerInfo (
			server NVARCHAR(10) NOT NULL,
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			guid NVARCHAR(20) NOT NULL,
			force INTEGER NOT NULL,
			role INTEGER NOT NULL,
			level INTEGER NOT NULL,
			title NVARCHAR(20) NOT NULL,
			camp INTEGER NOT NULL,
			tong INTEGER NOT NULL,
			time INTEGER NOT NULL,
			times INTEGER NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY (server, id)
		)
	]])
	X.SQLiteExecute(DB, 'CREATE UNIQUE INDEX IF NOT EXISTS player_info_server_name_u_idx ON PlayerInfo(server, name)')
	X.SQLiteExecute(DB, 'CREATE INDEX IF NOT EXISTS player_info_guid_idx ON PlayerInfo(guid)')
	local szSelectPlayerInfo = [[
		SELECT
			server as szServerName,
			id as dwID,
			name as szName,
			guid as szGlobalID,
			force as dwForceID,
			role as nRoleType,
			level as nLevel,
			title as szTitle,
			camp as nCamp,
			tong as dwTongID,
			time as dwTime,
			times as nTimes,
			extra as szExtra
		FROM PlayerInfo
	]]
	DBP_W  = X.SQLitePrepare(DB, 'REPLACE INTO PlayerInfo (server, id, name, guid, force, role, level, title, camp, tong, time, times, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
	DBP_RI = X.SQLitePrepare(DB, szSelectPlayerInfo .. ' WHERE server = ? AND id = ?')
	DBP_RN = X.SQLitePrepare(DB, szSelectPlayerInfo .. ' WHERE server = ? AND name = ?')
	DBP_RGI = X.SQLitePrepare(DB, szSelectPlayerInfo .. ' WHERE guid = ? ORDER BY time DESC')
	X.SQLiteExecute(DB, [[
		CREATE TABLE IF NOT EXISTS TongInfo (
			server NVARCHAR(10) NOT NULL,
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			time INTEGER NOT NULL,
			times INTEGER NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY(server, id)
		)
	]])
	local szSelectTongInfo = [[
		SELECT
			id as dwID,
			name as szName,
			time as dwTime,
			times as nTimes,
			extra as szExtra
		FROM TongInfo
	]]
	DBT_W  = X.SQLitePrepare(DB, 'REPLACE INTO TongInfo (server, id, name, time, times, extra) VALUES (?, ?, ?, ?, ?, ?)')
	DBT_RI = X.SQLitePrepare(DB, szSelectTongInfo .. ' WHERE server = ? AND id = ?')

	-- 旧版文件缓存转换
	local SZ_IC_PATH = X.FormatPath({'cache/PLAYER_INFO/{$server_origin}/', X.PATH_TYPE.DATA})
	if IsLocalFileExist(SZ_IC_PATH) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local szServer = X.GetServerOriginName()
		X.SQLiteBeginTransaction(DB)
		for i = 0, 999 do
			local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/DAT2/' .. i .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
			if data then
				for id, p in pairs(data) do
					X.SQLitePrepareExecuteANSI(DBP_W, szServer, p[1], p[2], '', p[3], p[4], p[5], p[6], p[7], p[8], 0, 0, '')
				end
			end
		end
		X.SQLiteEndTransaction(DB)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		X.SQLiteBeginTransaction(DB)
		for i = 0, 128 do
			for j = 0, 128 do
				local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/TONG/' .. i .. '-' .. j .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
				if data then
					for id, name in pairs(data) do
						X.SQLitePrepareExecuteANSI(DBT_W, szServer, id, name, 0, 0, '')
					end
				end
			end
		end
		X.SQLiteEndTransaction(DB)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen cleaning file cache start: ' .. SZ_IC_PATH, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		CPath.DelDir(SZ_IC_PATH)
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen cleaning file cache finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	return true
end

function D.Import(aFilePath, bTimes)
	if X.IsString(aFilePath) then
		aFilePath = {aFilePath}
	end
	local nImportChar, nSkipChar, nImportTong, nSkipTong = 0, 0, 0, 0
	for _, szFilePath in ipairs(aFilePath) do
		local db = SQLite3_Open(szFilePath)
		if db then
			local nVersion = X.Get(X.SQLiteGetAll(db, [[SELECT value FROM Info WHERE key = 'version']]), {1, 'value'}, nil)
			if nVersion then
				nVersion = tonumber(nVersion)
			else
				local szSQL = X.Get(X.SQLiteGetAll(db, [[SELECT sql FROM sqlite_master WHERE type='table' AND name='InfoCache']]), {1, 'sql'}, ''):gsub('[%s]+', ' ')
				if szSQL == 'CREATE TABLE InfoCache (id INTEGER PRIMARY KEY, name VARCHAR(20) NOT NULL, force INTEGER, role INTEGER, level INTEGER, title VARCHAR(20), camp INTEGER, tong INTEGER)' then
					nVersion = 2
				elseif szSQL == 'CREATE TABLE InfoCache ( id INTEGER NOT NULL, name VARCHAR(20) NOT NULL, force INTEGER NOT NULL, role INTEGER NOT NULL, level INTEGER NOT NULL, title VARCHAR(20) NOT NULL, camp INTEGER NOT NULL, tong INTEGER NOT NULL, extra TEXT NOT NULL, PRIMARY KEY (id) )' then
					nVersion = 3
				elseif szSQL == 'CREATE TABLE InfoCache ( id INTEGER NOT NULL, name NVARCHAR(20) NOT NULL, force INTEGER NOT NULL, role INTEGER NOT NULL, level INTEGER NOT NULL, title NVARCHAR(20) NOT NULL, camp INTEGER NOT NULL, tong INTEGER NOT NULL, extra TEXT NOT NULL, PRIMARY KEY (id) )' then
					nVersion = 4
				elseif szSQL == 'CREATE TABLE InfoCache ( id INTEGER NOT NULL, name NVARCHAR(20) NOT NULL, guid NVARCHAR(20) NOT NULL, force INTEGER NOT NULL, role INTEGER NOT NULL, level INTEGER NOT NULL, title NVARCHAR(20) NOT NULL, camp INTEGER NOT NULL, tong INTEGER NOT NULL, extra TEXT NOT NULL, PRIMARY KEY (id) )' then
					nVersion = 5
				end
			end
			if not nVersion then
				nVersion = 0
			end
			if nVersion > 0 and nVersion <= 6 then
				local szServer = X.Get(X.SQLiteGetAll(db, [[SELECT value FROM Info WHERE key = 'server']]), {1, 'value'}, nil)
				if szServer then
					szServer = UTF8ToAnsi(szServer)
				end
				if nVersion and nVersion < 6 then
					szServer = X.GetServerOriginName()
				end
				if szServer == X.GetServerOriginName() then
					local bUTF8 = nVersion > 3
					local ProcessString = bUTF8
						and function(s) return s end
						or function(s) return AnsiToUTF8(s) or '' end
					X.SQLiteBeginTransaction(DB)
					local nCount, nPageSize = X.Get(X.SQLiteGetAll(db, 'SELECT COUNT(*) AS count FROM InfoCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aInfoCache = X.SQLiteGetAll(db, 'SELECT * FROM InfoCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aInfoCache then
							for _, rec in ipairs(aInfoCache) do
								if rec.id and rec.name then
									local data = X.SQLitePrepareGetOne(DBP_RI, rec.id)
									local nTime = data and (data.dwTime or 0) or -1
									local nRecTime = rec.time or 0
									if nRecTime > nTime then
										X.SQLitePrepareExecute(
											DBP_W,
											AnsiToUTF8(szServer),
											rec.id,
											ProcessString(rec.name),
											X.IIf(
												X.IsGlobalID(rec.guid),
												ProcessString(rec.guid),
												data and data.szGlobalID or ''
											),
											rec.force or -1,
											rec.role or -1,
											rec.level or -1,
											X.IIf(
												not X.IsEmpty(rec.title),
												ProcessString(rec.title),
												data and data.szTitle or ''
											),
											rec.camp or -1,
											X.IIf(
												X.IsPositiveNumber(rec.tong),
												rec.tong,
												data and data.dwTongID or -1
											),
											nRecTime,
											data and data.nTimes or 0,
											rec.extra or ''
										)
										nImportChar = nImportChar + 1
									else
										nSkipChar = nSkipChar + 1
									end
								end
							end
						end
					end
					local nCount, nPageSize = X.Get(X.SQLiteGetAll(db, 'SELECT COUNT(*) AS count FROM TongCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aTongCache = X.SQLiteGetAll(db, 'SELECT * FROM TongCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aTongCache then
							for _, rec in ipairs(aTongCache) do
								if rec.id and rec.name then
									local data = X.SQLitePrepareGetOne(DBT_RI, rec.id)
									local nTime = data and (data.dwTime or 0) or -1
									local nRecTime = rec.time or 0
									if nRecTime > nTime then
										X.SQLitePrepareExecute(
											DBT_W,
											AnsiToUTF8(szServer),
											rec.id,
											ProcessString(rec.name),
											nRecTime,
											data and data.nTimes or 0,
											rec.extra or ''
										)
										nImportTong = nImportTong + 1
									else
										nSkipTong = nSkipTong + 1
									end
								end
							end
						end
					end
					X.SQLiteEndTransaction(DB)
				end
			elseif nVersion == 7 then
				X.SQLiteBeginTransaction(DB)
				local nCount, nPageSize = X.Get(X.SQLiteGetAll(db, 'SELECT COUNT(*) AS count FROM PlayerInfo WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
				for i = 0, nCount / nPageSize do
					local aPlayerInfo = X.SQLiteGetAll(db, 'SELECT * FROM PlayerInfo WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
					if aPlayerInfo then
						for _, rec in ipairs(aPlayerInfo) do
							if rec.server and rec.id and rec.name then
								local data = X.SQLitePrepareGetOne(DBP_RI, rec.id)
								local nTime = data and (data.dwTime or 0) or -1
								local nRecTime = rec.time or 0
								if nRecTime > nTime then
									X.SQLitePrepareExecute(
										DBP_W,
										rec.server,
										rec.id,
										rec.name,
										X.IIf(
											X.IsGlobalID(rec.guid),
											rec.guid,
											data and data.szGlobalID or ''
										),
										rec.force or -1,
										rec.role or -1,
										rec.level or -1,
										X.IIf(
											not X.IsEmpty(rec.title),
											rec.title,
											data and data.szTitle or ''
										),
										rec.camp or -1,
										X.IIf(
											X.IsPositiveNumber(rec.tong),
											rec.tong,
											data and data.dwTongID or -1
										),
										nRecTime,
										data and data.nTimes or (bTimes and rec.time or 0),
										rec.extra or ''
									)
									nImportChar = nImportChar + 1
								else
									nSkipChar = nSkipChar + 1
								end
							end
						end
					end
				end
				local nCount, nPageSize = X.Get(X.SQLiteGetAll(db, 'SELECT COUNT(*) AS count FROM TongInfo WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
				for i = 0, nCount / nPageSize do
					local aTongInfo = X.SQLiteGetAll(db, 'SELECT * FROM TongInfo WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
					if aTongInfo then
						for _, rec in ipairs(aTongInfo) do
							if rec.id and rec.name then
								local data = X.SQLitePrepareGetOne(DBT_RI, rec.id)
								local nTime = data and (data.dwTime or 0) or -1
								local nRecTime = rec.time or 0
								if nRecTime > nTime then
									X.SQLitePrepareExecute(
										DBT_W,
										rec.server,
										rec.id,
										rec.name,
										nRecTime,
										data and data.nTimes or (bTimes and rec.time or 0),
										rec.extra or ''
									)
									nImportTong = nImportTong + 1
								else
									nSkipTong = nSkipTong + 1
								end
							end
						end
					end
				end
				X.SQLiteEndTransaction(DB)
			end
			db:Release()
		end
	end
	return nImportChar, nSkipChar, nImportTong, nSkipTong
end

function D.Migration()
	local aFilePath = {}
	for _, szFilePath in ipairs({
		X.FormatPath({'cache/player_info.db', X.PATH_TYPE.SERVER}),
		X.FormatPath({'cache/player_info.v2.db', X.PATH_TYPE.SERVER}),
		X.FormatPath({'cache/farbnamen.v3.db', X.PATH_TYPE.SERVER}),
		X.FormatPath({'cache/farbnamen.v4.db', X.PATH_TYPE.SERVER}),
		X.FormatPath({'cache/farbnamen.v5.db', X.PATH_TYPE.SERVER}),
		X.FormatPath({'cache/farbnamen.v6.db', X.PATH_TYPE.SERVER}),
	}) do
		if IsLocalFileExist(szFilePath) then
			table.insert(aFilePath, szFilePath)
		end
	end
	if X.IsEmpty(aFilePath) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			D.Import(aFilePath, true)
			for _, szFilePath in ipairs(aFilePath) do
				CPath.Move(szFilePath, szFilePath .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			X.Alert(_L['Migrate succeed!'])
		end)
end

function D.UpdateSaveDB()
	local bBan = X.IsRestricted('MY_Farbnamen.BanHDD') and X.GetDiskType() == 'HDD'
	D.bSaveDB = not bBan and D.bReady and O.bSaveDB
end

---------------------------------------------------------------
-- 聊天复制和时间显示相关
---------------------------------------------------------------
function D.RenderXml(szMsg, tOption)
	-- <text>text='[就是个阵眼]' font=10 r=255 g=255 b=255  name='namelink_4662931' eventid=515</text><text>text='说：' font=10 r=255 g=255 b=255 </text><text>text='[茗伊]' font=10 r=255 g=255 b=255  name='namelink_4662931' eventid=771</text><text>text='\n' font=10 r=255 g=255 b=255 </text>
	local aXMLNode = X.XMLDecode(szMsg)
	if aXMLNode then
		local i, node, name = 1, nil, nil
		while i <= #aXMLNode do
			node = aXMLNode[i]
			name = X.XMLIsNode(node) and X.XMLGetNodeData(node, 'name')
			if name and name:sub(1, 9) == 'namelink_' then
				if tOption.bColor or tOption.bInsertIcon then
					local szName = string.gsub(X.XMLGetNodeData(node, 'text'), '[%[%]]', '')
					local tInfo = D.Get(szName)
					if tInfo then
						if tOption.bColor then
							X.XMLSetNodeData(node, 'r', tInfo.rgb[1])
							X.XMLSetNodeData(node, 'g', tInfo.rgb[2])
							X.XMLSetNodeData(node, 'b', tInfo.rgb[3])
						end
						if tOption.bInsertIcon then
							local szIcon, nFrame = GetForceImage(tInfo.dwForceID)
							if szIcon and nFrame then
								local nodeImage = X.XMLCreateNode('image')
								X.XMLSetNodeData(nodeImage, 'w', tOption.nInsertIconSize)
								X.XMLSetNodeData(nodeImage, 'h', tOption.nInsertIconSize)
								X.XMLSetNodeData(nodeImage, 'path', szIcon)
								X.XMLSetNodeData(nodeImage, 'frame', nFrame)
								table.insert(aXMLNode, i, nodeImage)
								i = i + 1
							end
						end
					end
				end
				if tOption.bTip then
					X.XMLSetNodeData(node, 'eventid', 82803)
					X.XMLSetNodeData(node, 'script', (X.XMLGetNodeData(node, 'script') or '')
						.. '\nthis.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end'
						.. '\nthis.OnItemMouseLeave=function() HideTip() end')
				end
			end
			i = i + 1
		end
		szMsg = X.XMLEncode(aXMLNode)
	end
	-- szMsg = string.gsub( szMsg, '<text>([^<]-)text='([^<]-)'([^<]-name='namelink_%d-'[^<]-)</text>', function (szExtra1, szName, szExtra2)
	--     szName = string.gsub(szName, '[%[%]]', '')
	--     local tInfo = D.Get(szName)
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
	return szMsg
end

function D.RenderNameLink(hNameLink, tOption)
	local ui, nNumOffset = X.UI(hNameLink), 0
	if tOption.bColor or tOption.bInsertIcon then
		local szName = string.gsub(hNameLink:GetText(), '[%[%]]', '')
		local tInfo = D.Get(szName)
		if tInfo then
			if tOption.bColor then
				ui:Color(tInfo.rgb)
			end
			if tOption.bInsertIcon then
				local szIcon, nFrame = GetForceImage(tInfo.dwForceID)
				if szIcon and nFrame then
					hNameLink:GetParent():InsertItemFromString(
						hNameLink:GetIndex(),
						false,
						'<image>w=' .. tOption.nInsertIconSize .. ' h=' .. tOption.nInsertIconSize
							.. ' path="' .. szIcon .. '" frame=' .. nFrame .. '</image>')
					nNumOffset = nNumOffset + 1
				end
			end
		end
	end
	if tOption.bTip then
		ui:Hover(function(bIn)
			if bIn then
				D.ShowTip()
			else
				HideTip()
			end
		end)
	end
	return hNameLink, nNumOffset
end

function D.RenderHandle(h, tOption, bIgnoreRange)
	local nIndex = not bIgnoreRange and tOption.nStartIndex or 0
	local nEndIndex = not bIgnoreRange and tOption.nEndIndex or (h:GetItemCount() - 1)
	while nIndex <= nEndIndex do
		local _, nNumOffset = D.RenderEl(h:Lookup(nIndex), tOption, true)
		nIndex = nIndex + 1 + nNumOffset
		nEndIndex = nEndIndex + nNumOffset
	end
	return h, 0
end

function D.RenderEl(el, tOption, bIgnoreRange)
	if el:GetType() == 'Text' then
		local name = el:GetName()
		if name == 'namelink' or name:sub(1, 9) == 'namelink_' then
			return D.RenderNameLink(el, tOption)
		end
	end
	if el:GetType() == 'Handle' then
		return D.RenderHandle(el, tOption, bIgnoreRange)
	end
	return el, 0
end

function D.MergeOption(dst, src)
	if X.IsTable(src) then
		for k, _ in pairs(dst) do
			if not X.IsNil(src[k]) then
				dst[k] = src[k]
			end
		end
	end
	return dst
end

-- 开放的名称染色接口
-- (userdata) Render(userdata namelink)    处理namelink染色 namelink是一个姓名Text元素
-- (string) Render(string szMsg)           格式化szMsg 处理里面的名字
function D.Render(szMsg, tOption)
	tOption = D.MergeOption(
		{
			bColor = true,
			bTip = true,
			bInsertIcon = O.bInsertIcon or false,
			nInsertIconSize = O.nInsertIconSize or 23,
		},
		tOption)
	if X.IsString(szMsg) then
		szMsg = D.RenderXml(szMsg, tOption)
	elseif X.IsElement(szMsg) then
		szMsg = D.RenderEl(szMsg, tOption)
	end
	return szMsg
end

function D.RegisterNameIDHeader(szName, dwID, szHeaderXml)
	if not NAME_ID_HEADER_XML[szName] then
		NAME_ID_HEADER_XML[szName] = {}
	end
	if NAME_ID_HEADER_XML[szName][dwID] then
		return X.OutputDebugMessage('ERROR', 'MY_Farbnamen Conflicted Name-ID: ' .. szName .. '(' .. dwID .. ')', X.DEBUG_LEVEL.ERROR)
	end
	if dwID == '*' then
		szName = X.ExtractPlayerBaseName(szName)
	end
	NAME_ID_HEADER_XML[szName][dwID] = szHeaderXml
end

function D.RegisterGlobalIDHeader(szGlobalID, szHeaderXml)
	if GUID_HEADER_XML[szGlobalID] then
		return X.OutputDebugMessage('ERROR', 'MY_Farbnamen Conflicted GUID: ' .. szGlobalID, X.DEBUG_LEVEL.ERROR)
	end
	GUID_HEADER_XML[szGlobalID] = szHeaderXml
end

function D.GetTip(szName)
	local tInfo = D.Get(szName)
	if tInfo then
		local tTip = {}
		-- author info
		if tInfo.dwID and tInfo.szName then
			local szHeaderXml = GUID_HEADER_XML[tInfo.szGlobalID]
				or (NAME_ID_HEADER_XML[tInfo.szName] and NAME_ID_HEADER_XML[tInfo.szName][tInfo.dwID])
			if szHeaderXml then
				table.insert(tTip, szHeaderXml)
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			elseif tInfo.dwID ~= X.GetClientPlayerID() then
				local szName = X.ExtractPlayerBaseName(tInfo.szName)
				local szHeaderXml = NAME_ID_HEADER_XML[szName] and NAME_ID_HEADER_XML[szName]['*']
				if szHeaderXml then
					table.insert(tTip, szHeaderXml)
					table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				end
			end
		end
		local szName = tInfo.szName
		if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
			szName = MY_ChatMosaics.MosaicsString(szName)
		end
		-- 拼音
		if IsCtrlKeyDown() then
			local szPinyin = X.Han2TonePinyin(X.ExtractPlayerBaseName(szName), true)[1]
			if not X.IsEmpty(szPinyin) then
				table.insert(tTip, GetFormatText(szPinyin .. '\n', 136))
			end
		end
		-- 名称 等级
		table.insert(tTip, GetFormatText(('%s(%d)'):format(szName, tInfo.nLevel), 136))
		-- 是否同队伍
		if X.GetClientPlayerID() ~= tInfo.dwID and X.IsTeammate(tInfo.dwID) then
			table.insert(tTip, GetFormatText(_L['[Teammate]'], nil, 0, 255, 0))
		end
		table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
		-- 称号
		if tInfo.szTitle and #tInfo.szTitle > 0 then
			table.insert(tTip, GetFormatText('<' .. tInfo.szTitle .. '>', 136))
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
		end
		-- 帮会
		if tInfo.szTongName and #tInfo.szTongName > 0 then
			local szTongName = tInfo.szTongName
			if MY_ChatMosaics and MY_ChatMosaics.MosaicsString then
				szTongName = MY_ChatMosaics.MosaicsString(szTongName)
			end
			table.insert(tTip, GetFormatText('[' .. szTongName .. ']', 136))
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
		end
		-- 门派 体型 阵营
		table.insert(tTip, GetFormatText(
			(D.tForceString[tInfo.dwForceID] or tInfo.dwForceID or _L['Unknown force']) .. _L.SPLIT_DOT ..
			(D.tRoleType[tInfo.nRoleType] or tInfo.nRoleType or  _L['Unknown gender'])    .. _L.SPLIT_DOT ..
			(D.tCampString[tInfo.nCamp] or tInfo.nCamp or  _L['Unknown camp']), 136
		))
		table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
		-- 偶遇统计
		if IsCtrlKeyDown() then
			if X.IsEmpty(tInfo.nMetCount) or X.IsEmpty(tInfo.dwUpdateTime) then
				table.insert(tTip, GetFormatText(_L('Met stat: never met'), 136))
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			else
				table.insert(tTip, GetFormatText(_L('Met count: %s', tInfo.nMetCount), 136))
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				table.insert(tTip, GetFormatText(_L('Last met time: %s', X.FormatTime(tInfo.dwUpdateTime, '%yyyy/%MM/%dd %hh:%mm:%ss')), 136))
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				if not X.IsEmpty(tInfo.dwMetMapID) then
					table.insert(tTip,  GetFormatText(_L('Last met map: %s', X.GetMapName(tInfo.dwMetMapID) or tInfo.dwMetMapID or ''), 136))
					table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				end
			end
		end
		-- 随身便笺
		if MY_PlayerRemark and MY_PlayerRemark.Get then
			local tPlayer = MY_PlayerRemark.Get(tInfo.szGlobalID) or MY_PlayerRemark.Get(tInfo.dwID)
			if tPlayer and tPlayer.szRemark ~= '' then
				table.insert(tTip, GetFormatText(tPlayer.szRemark, 0))
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			end
		end
		-- 调试信息
		if IsCtrlKeyDown() then
			if tInfo.dwRemoteID then
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				table.insert(tTip, GetFormatText(_L('Player RemoteID: %d', tInfo.dwRemoteID), 102))
			end
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(tTip, GetFormatText(_L('Player ID: %d', tInfo.dwID or 0), 102))
			if X.IsDebugging() then
				table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
				table.insert(tTip, GetFormatText(_L('Player GUID: %s', tInfo.szGlobalID or 0), 102))
			end
		end
		-- 组装Tip
		return table.concat(tTip)
	end
end

function D.ShowTip(hNameLink)
	if type(hNameLink) ~= 'table' then
		hNameLink = this
	end
	if not hNameLink then
		return
	end
	local szName = string.gsub(hNameLink:GetText(), '[%[%]]', '')
	local x, y = hNameLink:GetAbsPos()
	local w, h = hNameLink:GetSize()

	local szTip = D.GetTip(szName)
	if szTip then
		OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
	end
end

---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
local PLAYER_INFO   = {} -- 读取数据缓存
local PLAYER_INFO_W = {} -- 修改数据缓存（UTF8）
local TONG_INFO     = {} -- 帮会数据缓存
local TONG_INFO_W   = {} -- 帮会修改数据缓存（UTF8）

function D.Flush()
	if not D.bSaveDB or not InitDB() then
		return
	end
	if DBP_W then
		X.SQLiteBeginTransaction(DB)
		for i, p in pairs(PLAYER_INFO_W) do
			X.SQLitePrepareExecute(
				DBP_W,
				p.szServerName,
				p.dwID,
				p.szName,
				p.szGlobalID,
				p.dwForceID,
				p.nRoleType,
				p.nLevel,
				p.szTitle,
				p.nCamp,
				p.dwTongID,
				p.dwTime,
				p.nTimes,
				X.EncodeLUAData({
					m = p.dwMetMapID,
				})
			)
		end
		X.SQLiteEndTransaction(DB)
		PLAYER_INFO_W = {}
	end
	if DBT_W then
		X.SQLiteBeginTransaction(DB)
		for _, p in pairs(TONG_INFO_W) do
			X.SQLitePrepareExecute(
				DBT_W,
				p.szServerName,
				p.dwID,
				p.szName,
				p.dwTime,
				p.nTimes,
				''
			)
		end
		X.SQLiteEndTransaction(DB)
		TONG_INFO_W = {}
	end
end
X.RegisterFlush('MY_Farbnamen_Save', D.Flush)

do
local function OnExit()
	if not DB then
		return
	end
	DB:Release()
end
X.RegisterExit('MY_Farbnamen_Save', OnExit)
end

---从数据库与缓存中获取指定角色的信息表
---@param xKey string | number @角色名、角色ID或角色唯一ID，其中通过ID只能获取当前服务器角色信息或跨服玩家角色信息，通过角色名或角色唯一ID可以获取其他服务器角色信息
---@return table | nil @获取成功返回信息，否则返回空
function D.GetPlayerInfo(xKey)
	local tPlayer
	if X.IsNumber(xKey) then
		tPlayer = PLAYER_INFO[xKey]
		if not tPlayer and InitDB() then
			local szServer = X.GetServerOriginName()
			tPlayer = X.SQLitePrepareGetOneANSI(
				DBP_RI,
				szServer,
				xKey
			)
		end
	elseif X.IsGlobalID(xKey) then
		tPlayer = PLAYER_INFO[xKey]
		if not tPlayer and InitDB() then
			tPlayer = X.SQLitePrepareGetOneANSI(
				DBP_RGI,
				xKey
			)
		end
	elseif X.IsString(xKey) then
		local szName, szServer = X.DisassemblePlayerGlobalName(xKey, true)
		xKey = X.AssemblePlayerGlobalName(szName, szServer)
		tPlayer = PLAYER_INFO[xKey]
		if not tPlayer and InitDB() then
			tPlayer = X.SQLitePrepareGetOneANSI(
				DBP_RN,
				szServer,
				szName
			)
		end
	end
	-- 更新内存缓存
	if tPlayer then
		if X.IsEmpty(tPlayer.szExtra) then
			tPlayer.dwMetMapID = tPlayer.dwMetMapID or 0
		else
			local tExtra = X.DecodeLUAData(tPlayer.szExtra) or {}
			tPlayer.dwMetMapID = tExtra.m or 0
			tPlayer.szExtra = nil
		end
		if tPlayer.dwID and tPlayer.dwID ~= 0 and tPlayer.szServerName == X.GetServerOriginName() then
			PLAYER_INFO[tPlayer.dwID] = tPlayer
		end
		if tPlayer.szName and tPlayer.szServerName then
			PLAYER_INFO[X.AssemblePlayerGlobalName(tPlayer.szName, tPlayer.szServerName)] = tPlayer
		end
		-- 缘起兼容
		if X.IS_CLASSIC then
			tPlayer.szGlobalID = '0'
		end
		if X.IsGlobalID(tPlayer.szGlobalID) then
			PLAYER_INFO[tPlayer.szGlobalID] = tPlayer
		end
	end
	return tPlayer
end

---从数据库与缓存中获取指定帮会的信息表
---@param szServerName string @所在服务器
---@param dwTongID number @帮会ID
---@return table | nil @获取成功返回信息，否则返回空
function D.GetTongInfo(szServerName, dwTongID)
	if not szServerName or not dwTongID or dwTongID == 0 then
		return
	end
	local tTong = TONG_INFO[szServerName .. g_tStrings.STR_CONNECT .. dwTongID]
	-- 从数据库读取
	if not tTong and InitDB() then
		tTong = X.SQLitePrepareGetOneANSI(
			DBT_RI,
			szServerName,
			dwTongID
		)
	end
	-- 更新内存缓存
	if tTong then
		TONG_INFO[szServerName .. g_tStrings.STR_CONNECT .. dwTongID] = tTong
	end
	return tTong
end

---记录一个角色信息，提供自动适配跨服、部分信息等情况的逻辑
---@param szServerName string @要记录的角色所在服务器
---@param dwID number @要记录的角色ID
---@param szName string @要记录的角色名称
---@param szGlobalID string @要记录的角色唯一ID
---@param dwForceID number @要记录的角色门派
---@param nRoleType number @要记录的角色体型
---@param nLevel number @要记录的角色等级
---@param szTitle string @要记录的角色称号
---@param nCamp number @要记录的角色阵营
---@param dwTongID number @要记录的角色帮会ID
---@param bTimes boolean @是否增加偶遇次数
function D.RecordPlayerInfo(szServerName, dwID, szName, szGlobalID, dwForceID, nRoleType, nLevel, szTitle, nCamp, dwTongID, bTimes)
	-- 自动跨服处理
	do
		local szNameExt, szServerNameExt = X.DisassemblePlayerGlobalName(szName, false)
		if szServerNameExt then
			szServerName = szServerNameExt
			szName = szNameExt
		elseif not szServerName and dwID ~= 0 and not IsRemotePlayer(dwID) then
			szServerName = X.GetServerOriginName()
		end
	end
	-- 更新角色信息缓存
	local tPlayer
	if X.IsGlobalID(szGlobalID) then
		tPlayer = D.GetPlayerInfo(szGlobalID)
	end
	if not tPlayer then
		tPlayer = szServerName == X.GetServerOriginName() and not IsRemotePlayer(dwID) and D.GetPlayerInfo(dwID)
			or (szServerName and D.GetPlayerInfo(X.AssemblePlayerGlobalName(szName, szServerName)))
			or {}
	end
	tPlayer.szServerName = szServerName
	tPlayer.dwID = X.IIf(IsRemotePlayer(dwID), tPlayer.dwID, dwID)
	tPlayer.dwRemoteID = X.IIf(IsRemotePlayer(dwID), dwID, nil)
	tPlayer.szName = szName
	tPlayer.szGlobalID = X.IsGlobalID(szGlobalID) and szGlobalID or tPlayer.szGlobalID or ''
	tPlayer.dwForceID = dwForceID or tPlayer.dwForceID or -1
	tPlayer.nRoleType = nRoleType or tPlayer.nRoleType or -1
	tPlayer.nLevel = nLevel or tPlayer.nLevel or -1
	tPlayer.szTitle = szTitle or tPlayer.szTitle or ''
	tPlayer.nCamp = nCamp or tPlayer.nCamp or -1
	tPlayer.dwTongID = dwTongID or tPlayer.dwTongID or -1
	tPlayer.dwTime = bTimes and GetCurrentTime() or tPlayer.dwTime or 0
	tPlayer.nTimes = (tPlayer.nTimes or 0) + (bTimes and 1 or 0)
	tPlayer.dwMetMapID = bTimes and X.GetMapID() or tPlayer.dwMetMapID or 0
	if X.IsGlobalID(tPlayer.szGlobalID) then
		PLAYER_INFO[tPlayer.szGlobalID] = tPlayer
	end
	if tPlayer.dwRemoteID then
		PLAYER_INFO[tPlayer.dwRemoteID] = tPlayer
	end
	if not tPlayer.szServerName then
		return
	end
	if tPlayer.dwID and tPlayer.szServerName == X.GetServerOriginName() then
		PLAYER_INFO[tPlayer.dwID] = tPlayer
	end
	PLAYER_INFO[X.AssemblePlayerGlobalName(tPlayer.szName, tPlayer.szServerName)] = tPlayer
	if tPlayer.dwID then
		PLAYER_INFO_W[X.AssemblePlayerGlobalName(tPlayer.szName, tPlayer.szServerName)] = X.ConvertToUTF8(tPlayer)
	end
	-- 更新帮会信息
	if tPlayer.dwID and tPlayer.szServerName == X.GetServerOriginName() then
		if dwTongID and dwTongID ~= 0 then
			local szTongName = X.GetTongName(dwTongID, 254)
			if szTongName and szTongName ~= '' then
				D.RecordTongInfo(tPlayer.szServerName, dwTongID, szTongName, bTimes)
			end
		end
	end
end

---记录一个帮会信息
---@param szServerName string @要记录的帮会所在服务器
---@param dwTongID number @要记录的帮会ID
---@param szTongName string @要记录的帮会名称
---@param bTimes boolean @是否增加偶遇次数
function D.RecordTongInfo(szServerName, dwTongID, szTongName, bTimes)
	local tTong = D.GetTongInfo(szServerName, dwTongID) or {}
	tTong.szServerName = szServerName
	tTong.dwID = dwTongID
	tTong.szName = szTongName
	tTong.szExtra = tTong.extra or ''
	tTong.dwTime = GetCurrentTime()
	tTong.nTimes = (tTong.nTimes or 0) + (bTimes and 1 or 0)
	TONG_INFO[szServerName .. g_tStrings.STR_CONNECT .. tTong.dwID] = tTong
	TONG_INFO_W[tTong.dwID] = X.ConvertToUTF8(tTong)
end

-- 保存指定dwID的玩家
function D.AddAusID(dwID, bTimes)
	local player = X.GetPlayer(dwID)
	if not player or not player.szName or player.szName == '' then
		return false
	end
	D.RecordPlayerInfo(
		nil,
		player.dwID,
		player.szName,
		X.GetPlayerGlobalID(player.dwID),
		player.dwForceID,
		player.nRoleType,
		player.nLevel,
		X.IIf(player.nX == 0, nil, player.szTitle),
		player.nCamp,
		X.IIf(IsRemotePlayer(dwID), nil, player.dwTongID),
		bTimes
	)
	return true
end

--------------------------------------------------------------------------------
-- 公共接口
--------------------------------------------------------------------------------

---通过角色、ID或角色唯一ID获取信息，提供混合角色与帮会数据后的结果给外部使用
---@param xKey string | number @角色名、角色ID或角色唯一ID，其中通过ID只能获取当前服务器角色信息或跨服玩家角色信息，通过角色名或角色唯一ID可以获取其他服务器角色信息
---@return table | nil @获取成功返回信息，否则返回空
function D.Get(xKey)
	local tPlayer = D.GetPlayerInfo(xKey)
	if tPlayer then
		local tTong = D.GetTongInfo(tPlayer.szServerName, tPlayer.dwTongID)
		return {
			szServerName = tPlayer.szServerName,
			dwID         = tPlayer.dwID,
			szName       = tPlayer.szName,
			szGlobalID   = tPlayer.szGlobalID,
			dwRemoteID   = tPlayer.dwRemoteID,
			dwForceID    = tPlayer.dwForceID,
			nRoleType    = tPlayer.nRoleType,
			nLevel       = tPlayer.nLevel,
			szTitle      = tPlayer.szTitle,
			nCamp        = tPlayer.nCamp,
			nMetCount    = tPlayer.nTimes,
			dwMetMapID   = tPlayer.dwMetMapID,
			dwUpdateTime = tPlayer.dwTime,
			dwTongID     = tPlayer.dwTongID,
			szTongName   = tTong and tTong.szName or '',
			rgb          = X.IsNumber(tPlayer.dwForceID) and { X.GetForceColor(tPlayer.dwForceID, 'foreground') } or { 255, 255, 255 },
		}
	end
end

---通过角色ID获取信息
---@param dwID number @角色ID
---@return table | nil @获取到的角色信息，失败返回空
function D.GetAusID(dwID)
	D.AddAusID(dwID, false)
	return D.Get(dwID)
end

--------------------------------------------------------------------------------
-- 统计界面
--------------------------------------------------------------------------------
function D.ShowAnalysis(nTimeLimit, szSubTitle)
	local function BuildWhere(...)
		local szWhere = ''
		for _, v in ipairs({...}) do
			if X.IsString(v) then
				v = {v}
			end
			for _, vv in ipairs(v) do
				if szWhere == '' then
					szWhere = ' WHERE ' .. vv .. ' '
				else
					szWhere = szWhere .. ' AND ' .. vv .. ' '
				end
			end
		end
		return szWhere
	end
	local szServer = X.GetServerOriginName()
	local szTitle = _L['MY_Farbnamen__Analysis'] .. g_tStrings.STR_CONNECT .. szServer
	if szSubTitle then
		szTitle = szTitle .. g_tStrings.STR_CONNECT .. szSubTitle
	end
	local aWhere = {}
	if nTimeLimit then
		table.insert(aWhere, 'time > ' .. (GetCurrentTime() - nTimeLimit))
	end
	local ui = X.UI.CreateFrame('MY_Farbnamen__Analysis', {
		theme = X.UI.FRAME_THEME.SIMPLE,
		w = 640, h = 540,
		text = szTitle,
		close = true,
	})
	local nPaddingX = 20
	local nX, nY = nPaddingX, 30
	local nDeltaY = 30

	local uiTabs = ui:Append('WndTabs', {
		x = 0, y = 0,
		w = 640, h = 35,
	})
	local uiWndTotal = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = true,
	})
	local uiWndCamp = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = false,
	})
	local uiWndForce = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = false,
	})
	local uiWndServer = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = false,
	})
	local uiWndTong = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = false,
	})
	local uiWndMetCount = ui:Append('WndWindow', {
		x = 0, y = 50,
		w = 640, h = 480,
		visible = false,
	})

	local nAllPlayerCount = X.Get(X.SQLiteGetAllANSI(DB, [[SELECT COUNT(*) AS count FROM PlayerInfo]] .. BuildWhere(aWhere)), {1, 'count'}, 0)
	local nAllTongCount = X.Get(X.SQLiteGetAllANSI(DB, [[SELECT COUNT(*) AS count FROM TongInfo]] .. BuildWhere(aWhere)), {1, 'count'}, 0)
	local nPlayerCount = X.Get(X.SQLiteGetAllANSI(DB, [[SELECT COUNT(*) AS count FROM PlayerInfo]] .. BuildWhere(aWhere, [[server = ?]]), szServer), {1, 'count'}, 0)
	local nTongCount = X.Get(X.SQLiteGetAllANSI(DB, [[SELECT COUNT(*) AS count FROM TongInfo]] .. BuildWhere(aWhere, [[server = ?]]), szServer), {1, 'count'}, 0)

	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['Total'],
		onCheck = function(bChecked)
			uiWndTotal:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			local nY = 0
			uiWndTotal:Append('Text', {
				x = nX, y = nY,
				text = _L('All server total player count: %d', nAllPlayerCount),
			})
			nY = nY + nDeltaY
			uiWndTotal:Append('Text', {
				x = nX, y = nY,
				text = _L('All server total tong count: %d', nAllTongCount),
			})
			nY = nY + nDeltaY
			uiWndTotal:Append('Text', {
				x = nX, y = nY,
				text = _L('Current server total player count: %d', nPlayerCount),
			})
			nY = nY + nDeltaY
			uiWndTotal:Append('Text', {
				x = nX, y = nY,
				text = _L('Current server total tong count: %d', nTongCount),
			})
		end,
	}):Check(true)
	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['By Camp'],
		onCheck = function(bChecked)
			uiWndCamp:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			uiWndCamp:Append('WndTable', {
				x = 20, y = 0,
				w = 600, h = 400,
				columns = {
					{
						key = 'camp',
						title = ' ' .. _L['Camp'],
						width = 200,
						alignHorizontal = 'left',
						sorter = true,
						render = function(value, record, index)
							if record.summary then
								return GetFormatText(' ' .. _L['Summary'], 162, 255, 255, 255)
							end
							return GetFormatText(' ' .. (g_tStrings.STR_CAMP_TITLE[value] or _L('Unknown(%d)', value)), 162, X.GetCampColor(value or -1))
						end,
					},
					{
						key = 'count',
						title = ' ' .. _L['Player Count'],
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ' .. _L('%d players', value), 162, 255, 255, 255)
						end,
					},
				},
				dataSource = X.SQLiteGetAllANSI(DB, [[SELECT camp, COUNT(*) AS count FROM PlayerInfo]] .. BuildWhere(aWhere, [[server = ?]]) .. [[ GROUP BY camp]], szServer) or {},
				summary = { summary = true, count = nPlayerCount },
				sort = 'camp',
				sortOrder = 'asc',
			})
		end,
	})
	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['By Force'],
		onCheck = function(bChecked)
			uiWndForce:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			uiWndForce:Append('WndTable', {
				x = 20, y = 0,
				w = 600, h = 400,
				columns = {
					{
						key = 'force',
						title = ' ' .. _L['Force'],
						width = 200,
						alignHorizontal = 'left',
						sorter = true,
						render = function(value, record, index)
							if record.summary then
								return GetFormatText(' ' .. _L['Summary'], 162, 255, 255, 255)
							end
							return GetFormatText(' ' .. (g_tStrings.tForceTitle[value] or _L('Unknown(%d)', value)), 162, X.GetForceColor(value or -1, 'foreground'))
						end,
					},
					{
						key = 'count',
						title = ' ' .. _L['Player Count'],
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ' .. _L('%d players', value), 162, 255, 255, 255)
						end,
					},
				},
				dataSource = X.SQLiteGetAllANSI(DB, [[SELECT force, COUNT(*) AS count FROM PlayerInfo]] .. BuildWhere(aWhere, [[server = ?]]) .. [[ GROUP BY force]], szServer) or {},
				summary = { summary = true, count = nPlayerCount },
				sort = 'force',
				sortOrder = 'asc',
			})
		end,
	})
	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['By Server'],
		onCheck = function(bChecked)
			uiWndServer:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			uiWndServer:Append('WndTable', {
				x = 20, y = 0,
				w = 600, h = 400,
				columns = {
					{
						key = 'server',
						title = ' ' .. _L['Server'],
						width = 200,
						alignHorizontal = 'left',
						sorter = true,
						render = function(value, record, index)
							if record.summary then
								return GetFormatText(' ' .. _L['Summary'], 162, 255, 255, 255)
							end
							return GetFormatText(' ' .. value, 162, 255, 255, 255)
						end,
					},
					{
						key = 'count',
						title = ' ' .. _L['Player Count'],
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ' .. _L('%d players', value), 162, 255, 255, 255)
						end,
					},
				},
				dataSource = X.SQLiteGetAllANSI(DB, [[SELECT server, COUNT(*) AS count FROM PlayerInfo]] .. BuildWhere(aWhere) .. [[ GROUP BY server]]) or {},
				summary = { summary = true, count = nAllPlayerCount },
				sort = 'count',
				sortOrder = 'desc',
			})
		end,
	})
	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['By Tong'],
		onCheck = function(bChecked)
			uiWndTong:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			uiWndTong:Append('WndTable', {
				x = 20, y = 0,
				w = 600, h = 400,
				columns = {
					{
						key = 'name',
						title = ' ' .. _L['Tong'],
						width = 300,
						alignHorizontal = 'left',
						sorter = true,
						render = function(value, record, index)
							if record.summary then
								return GetFormatText(' ' .. _L['Summary'], 162, 255, 255, 255)
							end
							return GetFormatText(' ' .. value, 162, 255, 255, 255)
						end,
					},
					{
						key = 'count',
						title = ' ' .. _L['Player Count'],
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ' .. _L('%d players', value), 162, 255, 255, 255)
						end,
					},
				},
				dataSource = X.SQLiteGetAllANSI(DB, [[
					SELECT t.name, p.count
					FROM TongInfo t
					JOIN (
						SELECT tong, COUNT(id) AS count
						FROM PlayerInfo
						]] .. BuildWhere(aWhere, [[server = ?]]) .. [[
						GROUP BY tong
					) p ON t.id = p.tong
					ORDER BY p.count DESC
					LIMIT 500;
				]], szServer) or {},
				summary = { summary = true, count = nPlayerCount },
				sort = 'count',
				sortOrder = 'desc',
			})
		end,
	})
	uiTabs:Append('WndTab', {
		w = 100, h = 35,
		text = _L['By Met Count'],
		onCheck = function(bChecked)
			uiWndMetCount:Visible(bChecked)
			if this.bInit then
				return
			end
			this.bInit = true
			uiWndMetCount:Append('WndTable', {
				x = 20, y = 0,
				w = 600, h = 400,
				columns = {
					{
						key = 'name',
						title = ' ' .. _L['Name'],
						width = 300,
						alignHorizontal = 'left',
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ')
								.. X.RenderChatLink(D.Render(GetFormatText(value or '', 162, 255, 255, 255, nil, nil, 'namelink_0')))
						end,
					},
					{
						key = 'times',
						title = ' ' .. _L['Met Count'],
						sorter = true,
						render = function(value, record, index)
							return GetFormatText(' ' .. _L('%d times', value), 162, 255, 255, 255)
						end,
					},
				},
				dataSource = X.SQLiteGetAllANSI(DB, [[SELECT name, times FROM PlayerInfo]] .. BuildWhere(aWhere, [[server = ?]]) .. [[ ORDER BY times DESC LIMIT 500]], szServer) or {},
				sort = 'times',
				sortOrder = 'desc',
			})
		end,
	})

	nY = 460
	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Counts based on local cache, only players you met will be analyzed.'],
	})

	ui:Anchor('CENTER')
end

--------------------------------------------------------------------------------
-- 菜单
--------------------------------------------------------------------------------
function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	D.Migration()

	local bBan = X.IsRestricted('MY_Farbnamen.BanHDD') and X.GetDiskType() == 'HDD'

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Enable MY_Farbnamen'],
		checked = O.bEnable,
		onCheck = function()
			O.bEnable = not O.bEnable
		end,
	}):Width() + 5

	nX = nPaddingX + 25
	nY = nY + nLH
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Insert force icon'],
		checked = O.bInsertIcon,
		onCheck = function()
			O.bInsertIcon = not O.bInsertIcon
		end,
		autoEnable = function()
			return O.bEnable
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndSlider', {
		x = nX, y = nY, w = 100, h = 25,
		value = O.nInsertIconSize,
		range = {1, 300},
		sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
		textFormatter = function(v) return _L('Icon size: %dpx', v) end,
		onChange = function(val)
			O.nInsertIconSize = val
		end,
		autoEnable = function() return O.bInsertIcon end,
	}):AutoWidth():Width() + 5

	nX = nPaddingX + 25
	nY = nY + nLH

	nX = nPaddingX + 25
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Save to database'],
		checked = not bBan and O.bSaveDB,
		onCheck = function()
			O.bSaveDB = not O.bSaveDB
		end,
		enable = not bBan,
		tip = bBan and {
			render = _L['This feature has been disabled on HDD disk machine for performance issues.'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		} or nil,
	}):Width() + 5

	nX = nPaddingX + 25
	nY = nY + nLH

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 'auto',
		buttonStyle = 'FLAT',
		text = _L['Show analysis'],
		onLClick = function()
			D.Flush()
			D.ShowAnalysis()
			X.UI.ClosePopupMenu()
		end,
		menuRClick = function()
			local menu = {}
			for _, nHour in ipairs({ 12, 24, 48, 72 }) do
				table.insert(menu, {
					szOption = _L('Show analysis of %d hours', nHour),
					fnAction = function()
						D.Flush()
						D.ShowAnalysis(nHour * 3600, _L('last %d hours', nHour))
						X.UI.ClosePopupMenu()
					end,
				})
			end
			table.insert(menu, {
				szOption = _L['Show analysis of last week'],
				fnAction = function()
					D.Flush()
					D.ShowAnalysis(7 * 24 * 3600, _L['last week'])
					X.UI.ClosePopupMenu()
				end,
			})
			for _, nDay in ipairs({ 30, 60, 90, 180, 365, 730 }) do
				table.insert(menu, {
					szOption = _L('Show analysis of last %d days', nDay),
					fnAction = function()
						D.Flush()
						D.ShowAnalysis(nDay * 24 * 3600, _L('last %d days', nDay))
						X.UI.ClosePopupMenu()
					end,
				})
			end
			return menu
		end,
		autoEnable = function()
			return O.bEnable and O.bSaveDB
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 'auto',
		buttonStyle = 'FLAT',
		text = _L['Reset data'],
		onClick = function()
			X.Confirm(_L['Are you sure to reset farbnamen data? All character\'s data cache will be removed.'], function()
				if not InitDB() then
					return
				end
				X.SQLiteExecute(DB, 'DELETE FROM PlayerInfo')
				X.OutputSystemMessage(_L['MY_Farbnamen'], _L['Cache data deleted.'])
			end)
		end,
		autoEnable = function()
			return O.bEnable and O.bSaveDB
		end,
	}):Width() + 5


	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 'auto',
		buttonStyle = 'FLAT',
		text = _L['Import data'],
		onClick = function()
			local szRoot = X.FormatPath({'cache/', X.PATH_TYPE.GLOBAL})
			local file = GetOpenFileName(_L['Please select your farbnamen database file.'], 'Database File(*.db)\0*.db\0\0', szRoot)
			if not X.IsEmpty(file) then
				X.Confirm(_L['DO NOT KILL PROCESS BY FORCE, OR YOUR DATABASE MAY GOT A DAMAE, PRESS OK TO CONTINUE.'], function()
					local nImportChar, nSkipChar, nImportTong, nSkipTong = D.Import(file, false)
					X.Alert(_L('%d chars imported, %d chars skipped, %d tongs imported, %d tongs skipped!', nImportChar, nSkipChar, nImportTong, nSkipTong))
				end)
			end
		end,
		autoEnable = function()
			return O.bEnable and O.bSaveDB
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 'auto',
		buttonStyle = 'FLAT',
		text = _L['Export data'],
		onClick = function()
			X.OpenFolder(X.GetAbsolutePath({'cache/farbnamen/farbnamen.v7.db', X.PATH_TYPE.GLOBAL}))
			X.Alert(_L['Copy .db file to share.'])
		end,
		autoEnable = function()
			return O.bEnable and O.bSaveDB
		end,
	}):Width() + 5

	nY = nY + nLH

	return nX, nY
end
X.RegisterAddonMenu('MY_Farbenamen', D.GetMenu)

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Farbnamen',
	exports = {
		{
			fields = {
				Render                 = D.Render                ,
				RegisterHeader         = D.RegisterNameIDHeader  ,
				RegisterNameIDHeader   = D.RegisterNameIDHeader  ,
				RegisterGlobalIDHeader = D.RegisterGlobalIDHeader,
				GetTip                 = D.GetTip                ,
				ShowTip                = D.ShowTip               ,
				Get                    = D.Get                   ,
				GetAusID               = D.GetAusID              ,
				GetAusName             = D.Get                   ,
				OnPanelActivePartial   = D.OnPanelActivePartial  ,
			},
		},
	},
}
MY_Farbnamen = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

do
local PEEK_LIST = {}
local function onBreathe()
	for dwID, v in pairs(PEEK_LIST) do
		if D.AddAusID(dwID, v.bTimes) or v.nRetryCount > 5 then
			PEEK_LIST[dwID] = nil
		else
			PEEK_LIST[dwID].nRetryCount = v.nRetryCount + 1
		end
	end
end
X.BreatheCall(250, onBreathe)

local function OnPeekPlayer()
	if arg0 == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		PEEK_LIST[arg1] = { nRetryCount = 0, bTimes = false }
	end
end
X.RegisterEvent('PEEK_OTHER_PLAYER', OnPeekPlayer)
X.RegisterEvent('MY_PLAYER_ENTER_SCENE', function() PEEK_LIST[arg0] = { nRetryCount = 0, bTimes = arg0 ~= X.GetClientPlayerID() } end)
X.RegisterEvent('ON_GET_TONG_NAME_NOTIFY', function() D.RecordTongInfo(X.GetServerOriginName(), arg1, arg2, true) end)
end

X.RegisterEvent('PLAYER_CHAT', function ()
	local dwSenderID    = arg1
	local szSenderName  = arg2
	local szGlobalID    = arg10
	-- local dwAvatar      = arg11
	local dwForceID     = arg12
	local nLevel        = arg13
	local nCamp         = arg14
	local nRoleType     = arg15
	if not dwSenderID or not szSenderName or not dwForceID or not X.IsGlobalID(szGlobalID) then
		return
	end
	if szGlobalID == X.GetClientPlayerGlobalID() then -- 密聊频道自己发言回显数据对不上
		return
	end
	D.RecordPlayerInfo(nil, dwSenderID, szSenderName, szGlobalID, dwForceID, nRoleType, nLevel, nil, nCamp, nil, false)
end)

-- 插入聊天内容的 HOOK （过滤、加入时间 ）
X.HookChatPanel('BEFORE', 'MY_FARBNAMEN', function(h, szMsg, ...)
	if D.bReady and O.bEnable then
		szMsg = D.Render(szMsg, true)
	end
	return szMsg
end)
-- X.HookChatPanel('AFTER', 'MY_FARBNAMEN', function(h, nIndex)
-- 	if D.bReady and O.bEnable then
-- 		for i = h:GetItemCount() - 1, nIndex, -1 do
-- 			D.Render(h:Lookup(i), true)
-- 		end
-- 	end
-- end)

X.RegisterChatPlayerAddonMenu('MY_Farbnamen', function(szName)
	if not (IsCtrlKeyDown() and X.IsDebugging()) then
		return
	end
	return {
		{
			szOption = _L['Copy debug information'],
			fnAction = function()
				local tInfo = D.Get(szName)
				X.UI.OpenTextEditor(X.EncodeLUAData(tInfo, '\t'))
			end,
		},
	}
end)

X.RegisterUserSettingsInit('MY_Farbnamen', function()
	D.bReady = true
	D.UpdateSaveDB()
end)
X.RegisterUserSettingsRelease('MY_Farbnamen', function()
	D.bReady = false
end)
X.RegisterUserSettingsUpdate('MY_Farbnamen.bSaveDB', function()
	D.UpdateSaveDB()
end)

X.RegisterEvent('MY_RESTRICTION', 'MY_Farbnamen.BanHDD', function()
	if arg0 and arg0 ~= 'MY_Farbnamen.BanHDD' then
		return
	end
	D.UpdateSaveDB()
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
