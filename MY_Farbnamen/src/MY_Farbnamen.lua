--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 聊天窗口名称染色插件
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Farbnamen/MY_Farbnamen'
local PLUGIN_NAME = 'MY_Farbnamen'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Farbnamen'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^24.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 设置和数据
--------------------------------------------------------------------------------
X.CreateDataRoot(X.PATH_TYPE.GLOBAL)

local O = X.CreateUserSettingsModule('MY_Farbnamen', _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bInsertIcon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	nInsertIconSize = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Farbnamen'],
		xSchema = X.Schema.Number,
		xDefaultValue = 20,
	},
})
local D = {
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

local function IsGlobalID(szGlobalID)
	return szGlobalID and szGlobalID ~= '' and szGlobalID ~= '0'
end

local function IsPositiveNumber(nNumber)
	return nNumber and nNumber > 0
end

local function IsNonEmptyString(szString)
	return szString and szString ~= ''
end

local function InitDB()
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
	DB:Execute([[
		CREATE TABLE IF NOT EXISTS Info (
			key NVARCHAR(128) NOT NULL,
			value NVARCHAR(4096) NOT NULL,
			PRIMARY KEY (key)
		)
	]])
	DB:Execute([[INSERT INTO Info (key, value) VALUES ('version', '7')]])
	DB:Execute([[
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
	DB:Execute('CREATE UNIQUE INDEX IF NOT EXISTS player_info_server_name_u_idx ON PlayerInfo(server, name)')
	DB:Execute('CREATE INDEX IF NOT EXISTS player_info_guid_idx ON PlayerInfo(guid)')
	DBP_W  = DB:Prepare('REPLACE INTO PlayerInfo (server, id, name, guid, force, role, level, title, camp, tong, time, times, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
	DBP_RI = DB:Prepare('SELECT id, name, guid, force, role, level, title, camp, tong, time, times, extra FROM PlayerInfo WHERE server = ? AND id = ?')
	DBP_RN = DB:Prepare('SELECT id, name, guid, force, role, level, title, camp, tong, time, times, extra FROM PlayerInfo WHERE server = ? AND name = ?')
	DBP_RGI = DB:Prepare('SELECT id, name, guid, force, role, level, title, camp, tong, time, times, extra FROM PlayerInfo WHERE guid = ? ORDER BY time DESC')
	DB:Execute([[
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
	DBT_W  = DB:Prepare('REPLACE INTO TongInfo (server, id, name, time, times, extra) VALUES (?, ?, ?, ?, ?, ?)')
	DBT_RI = DB:Prepare('SELECT id, name, time, times, extra FROM TongInfo WHERE server = ? AND id = ?')

	-- 旧版文件缓存转换
	local SZ_IC_PATH = X.FormatPath({'cache/PLAYER_INFO/{$server_origin}/', X.PATH_TYPE.DATA})
	if IsLocalFileExist(SZ_IC_PATH) then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		local szServer = X.GetServerOriginName()
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 999 do
			local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/DAT2/' .. i .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
			if data then
				for id, p in pairs(data) do
					DBP_W:ClearBindings()
					DBP_W:BindAll(szServer, p[1], AnsiToUTF8(p[2]), '', p[3], p[4], p[5], AnsiToUTF8(p[6]), p[7], p[8], 0, 0, '')
					DBP_W:Execute()
				end
			end
		end
		DBP_W:Reset()
		DB:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 128 do
			for j = 0, 128 do
				local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/TONG/' .. i .. '-' .. j .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
				if data then
					for id, name in pairs(data) do
						DBT_W:ClearBindings()
						DBT_W:BindAll(szServer, id, AnsiToUTF8(name), 0, 0, '')
						DBT_W:Execute()
					end
				end
			end
		end
		DBT_W:Reset()
		DB:Execute('END TRANSACTION')
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
InitDB()

function D.Import(aFilePath, bTimes)
	if X.IsString(aFilePath) then
		aFilePath = {aFilePath}
	end
	local nImportChar, nSkipChar, nImportTong, nSkipTong = 0, 0, 0, 0
	for _, szFilePath in ipairs(aFilePath) do
		local db = SQLite3_Open(szFilePath)
		if db then
			local nVersion = X.Get(db:Execute([[SELECT value FROM Info WHERE key = 'version']]), {1, 'value'}, nil)
			if nVersion then
				nVersion = tonumber(nVersion)
			else
				local szSQL = X.Get(db:Execute([[SELECT sql FROM sqlite_master WHERE type='table' AND name='InfoCache']]), {1, 'sql'}, ''):gsub('[%s]+', ' ')
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
				local szServer = X.Get(db:Execute([[SELECT value FROM Info WHERE key = 'server']]), {1, 'value'}, nil)
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
					DB:Execute('BEGIN TRANSACTION')
					local nCount, nPageSize = X.Get(db:Execute('SELECT COUNT(*) AS count FROM InfoCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aInfoCache = db:Execute('SELECT * FROM InfoCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aInfoCache then
							for _, rec in ipairs(aInfoCache) do
								if rec.id and rec.name then
									DBP_RI:ClearBindings()
									DBP_RI:BindAll(rec.id)
									local data = DBP_RI:GetNext()
									DBP_RI:Reset()
									local nTime = data and (data.time or 0) or -1
									local nRecTime = rec.time or 0
									if nRecTime > nTime then
										DBP_W:ClearBindings()
										DBP_W:BindAll(
											AnsiToUTF8(szServer),
											rec.id,
											ProcessString(rec.name),
											X.IIf(
												IsGlobalID(rec.guid),
												ProcessString(rec.guid),
												data and data.guid or ''
											),
											rec.force or -1,
											rec.role or -1,
											rec.level or -1,
											X.IIf(
												IsNonEmptyString(rec.title),
												ProcessString(rec.title),
												data and data.title or ''
											),
											rec.camp or -1,
											X.IIf(
												IsPositiveNumber(rec.tong),
												rec.tong,
												data and data.tong or -1
											),
											nRecTime,
											data and data.times or 0,
											rec.extra or ''
										)
										DBP_W:Execute()
										nImportChar = nImportChar + 1
									else
										nSkipChar = nSkipChar + 1
									end
								end
							end
							DBP_W:Reset()
						end
					end
					local nCount, nPageSize = X.Get(db:Execute('SELECT COUNT(*) AS count FROM TongCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aTongCache = db:Execute('SELECT * FROM TongCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aTongCache then
							for _, rec in ipairs(aTongCache) do
								if rec.id and rec.name then
									DBT_RI:ClearBindings()
									DBT_RI:BindAll(rec.id)
									local data = DBT_RI:GetNext()
									DBT_RI:Reset()
									local nTime = data and (data.time or 0) or -1
									local nRecTime = rec.time or 0
									if nRecTime > nTime then
										DBT_W:ClearBindings()
										DBT_W:BindAll(
											AnsiToUTF8(szServer),
											rec.id,
											ProcessString(rec.name),
											nRecTime,
											data and data.times or 0,
											rec.extra or ''
										)
										DBT_W:Execute()
										nImportTong = nImportTong + 1
									else
										nSkipTong = nSkipTong + 1
									end
								end
							end
							DBT_W:Reset()
						end
					end
					DB:Execute('END TRANSACTION')
				end
			elseif nVersion == 7 then
				DB:Execute('BEGIN TRANSACTION')
				local nCount, nPageSize = X.Get(db:Execute('SELECT COUNT(*) AS count FROM PlayerInfo WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
				for i = 0, nCount / nPageSize do
					local aPlayerInfo = db:Execute('SELECT * FROM PlayerInfo WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
					if aPlayerInfo then
						for _, rec in ipairs(aPlayerInfo) do
							if rec.server and rec.id and rec.name then
								DBP_RI:ClearBindings()
								DBP_RI:BindAll(rec.id)
								local data = DBP_RI:GetNext()
								DBP_RI:Reset()
								local nTime = data and (data.time or 0) or -1
								local nRecTime = rec.time or 0
								if nRecTime > nTime then
									DBP_W:ClearBindings()
									DBP_W:BindAll(
										rec.server,
										rec.id,
										rec.name,
										X.IIf(
											IsGlobalID(rec.guid),
											rec.guid,
											data and data.guid or ''
										),
										rec.force or -1,
										rec.role or -1,
										rec.level or -1,
										X.IIf(
											IsNonEmptyString(rec.title),
											rec.title,
											data and data.title or ''
										),
										rec.camp or -1,
										X.IIf(
											IsPositiveNumber(rec.tong),
											rec.tong,
											data and data.tong or -1
										),
										nRecTime,
										data and data.times or (bTimes and rec.time or 0),
										rec.extra or ''
									)
									DBP_W:Execute()
									nImportChar = nImportChar + 1
								else
									nSkipChar = nSkipChar + 1
								end
							end
						end
						DBP_W:Reset()
					end
				end
				local nCount, nPageSize = X.Get(db:Execute('SELECT COUNT(*) AS count FROM TongInfo WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
				for i = 0, nCount / nPageSize do
					local aTongInfo = db:Execute('SELECT * FROM TongInfo WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
					if aTongInfo then
						for _, rec in ipairs(aTongInfo) do
							if rec.id and rec.name then
								DBT_RI:ClearBindings()
								DBT_RI:BindAll(rec.id)
								local data = DBT_RI:GetNext()
								DBT_RI:Reset()
								local nTime = data and (data.time or 0) or -1
								local nRecTime = rec.time or 0
								if nRecTime > nTime then
									DBT_W:ClearBindings()
									DBT_W:BindAll(
										rec.server,
										rec.id,
										rec.name,
										nRecTime,
										data and data.times or (bTimes and rec.time or 0),
										rec.extra or ''
									)
									DBT_W:Execute()
									nImportTong = nImportTong + 1
								else
									nSkipTong = nSkipTong + 1
								end
							end
						end
						DBT_W:Reset()
					end
				end
				DB:Execute('END TRANSACTION')
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
		-- 名称 等级
		table.insert(tTip, GetFormatText(('%s(%d)'):format(tInfo.szName, tInfo.nLevel), 136))
		-- 是否同队伍
		if X.GetClientPlayerID() ~= tInfo.dwID and X.IsParty(tInfo.dwID) then
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
			table.insert(tTip, GetFormatText('[' .. tInfo.szTongName .. ']', 136))
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
		end
		-- 门派 体型 阵营
		table.insert(tTip, GetFormatText(
			(D.tForceString[tInfo.dwForceID] or tInfo.dwForceID or _L['Unknown force']) .. _L.SPLIT_DOT ..
			(D.tRoleType[tInfo.nRoleType] or tInfo.nRoleType or  _L['Unknown gender'])    .. _L.SPLIT_DOT ..
			(D.tCampString[tInfo.nCamp] or tInfo.nCamp or  _L['Unknown camp']), 136
		))
		table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
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
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(tTip, GetFormatText(_L('Player ID: %d', tInfo.dwID), 102))
			table.insert(tTip, X.CONSTANT.XML_LINE_BREAKER)
			table.insert(tTip, GetFormatText(_L('Player GUID: %s', tInfo.szGlobalID), 102))
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
	if not InitDB() then
		return
	end
	if DBP_W then
		DB:Execute('BEGIN TRANSACTION')
		for i, p in pairs(PLAYER_INFO_W) do
			DBP_W:ClearBindings()
			DBP_W:BindAll(p.server, p.id, p.name, p.guid, p.force, p.role, p.level, p.title, p.camp, p.tong, p.time, p.times, '')
			DBP_W:Execute()
		end
		DBP_W:Reset()
		DB:Execute('END TRANSACTION')
		PLAYER_INFO_W = {}
	end
	if DBT_W then
		DB:Execute('BEGIN TRANSACTION')
		for _, p in pairs(TONG_INFO_W) do
			DBT_W:ClearBindings()
			DBT_W:BindAll(p.server, p.id, p.name, p.time, p.times, '')
			DBT_W:Execute()
		end
		DBT_W:Reset()
		DB:Execute('END TRANSACTION')
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
			DBP_RI:ClearBindings()
			DBP_RI:BindAll(AnsiToUTF8(szServer), xKey)
			tPlayer = X.ConvertToAnsi((DBP_RI:GetNext()))
			DBP_RI:Reset()
		end
	elseif X.IsString(xKey) and string.find(xKey, '^[0-9]+$') then
		tPlayer = PLAYER_INFO[xKey]
		if not tPlayer and InitDB() then
			DBP_RGI:ClearBindings()
			DBP_RGI:BindAll(AnsiToUTF8(xKey))
			tPlayer = X.ConvertToAnsi((DBP_RGI:GetNext()))
			DBP_RGI:Reset()
		end
	elseif X.IsString(xKey) then
		local szName, szServer = X.DisassemblePlayerGlobalName(xKey, true)
		xKey = X.AssemblePlayerGlobalName(szName, szServer)
		tPlayer = PLAYER_INFO[xKey]
		if not tPlayer and InitDB() then
			DBP_RN:ClearBindings()
			DBP_RN:BindAll(AnsiToUTF8(szServer), AnsiToUTF8(szName))
			tPlayer = X.ConvertToAnsi((DBP_RN:GetNext()))
			DBP_RN:Reset()
		end
	end
	-- 更新内存缓存
	if tPlayer then
		if tPlayer.id and tPlayer.id ~= 0 and tPlayer.server == X.GetServerOriginName() then
			PLAYER_INFO[tPlayer.id] = tPlayer
		end
		if tPlayer.name and tPlayer.server then
			PLAYER_INFO[X.AssemblePlayerGlobalName(tPlayer.name, tPlayer.server)] = tPlayer
		end
		if IsGlobalID(tPlayer.guid) then
			PLAYER_INFO[tPlayer.guid] = tPlayer
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
		DBT_RI:ClearBindings()
		DBT_RI:BindAll(X.ConvertToUTF8(szServerName), dwTongID)
		tTong = X.ConvertToAnsi((DBT_RI:GetNext()))
		DBT_RI:Reset()
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
	if IsGlobalID(szGlobalID) then
		tPlayer = D.GetPlayerInfo(szGlobalID)
	end
	if not tPlayer then
		tPlayer = szServerName == X.GetServerOriginName() and not IsRemotePlayer(dwID) and D.GetPlayerInfo(dwID)
			or (szServerName and D.GetPlayerInfo(X.AssemblePlayerGlobalName(szName, szServerName)))
			or {}
	end
	tPlayer.server = szServerName
	tPlayer.id = X.IIf(IsRemotePlayer(dwID), tPlayer.id, dwID)
	tPlayer.remoteID = X.IIf(IsRemotePlayer(dwID), dwID, nil)
	tPlayer.name = szName
	tPlayer.guid = IsGlobalID(szGlobalID) and szGlobalID or tPlayer.guid or ''
	tPlayer.force = dwForceID or tPlayer.force or -1
	tPlayer.role = nRoleType or tPlayer.role or -1
	tPlayer.level = nLevel or tPlayer.level or -1
	tPlayer.title = szTitle or tPlayer.title or ''
	tPlayer.camp = nCamp or tPlayer.camp or -1
	tPlayer.tong = dwTongID or tPlayer.tong or -1
	tPlayer.extra = tPlayer.extra or ''
	tPlayer.time = bTimes and GetCurrentTime() or tPlayer.time or 0
	tPlayer.times = (tPlayer.times or 0) + (bTimes and 1 or 0)
	if IsGlobalID(tPlayer.guid) then
		PLAYER_INFO[tPlayer.guid] = tPlayer
	end
	if tPlayer.remoteID then
		PLAYER_INFO[tPlayer.remoteID] = tPlayer
	end
	if not tPlayer.server then
		return
	end
	if tPlayer.id and tPlayer.server == X.GetServerOriginName() then
		PLAYER_INFO[tPlayer.id] = tPlayer
	end
	PLAYER_INFO[X.AssemblePlayerGlobalName(tPlayer.name, tPlayer.server)] = tPlayer
	PLAYER_INFO_W[X.AssemblePlayerGlobalName(tPlayer.name, tPlayer.server)] = X.ConvertToUTF8(tPlayer)
	-- 更新帮会信息
	if tPlayer.id and tPlayer.server == X.GetServerOriginName() then
		if tPlayer.tong and tPlayer.tong ~= 0 then
			local szTongName = GetTongClient().ApplyGetTongName(tPlayer.tong, 254)
			if szTongName and szTongName ~= '' then
				D.RecordTongInfo(tPlayer.server, tPlayer.tong, szTongName, bTimes)
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
	tTong.server = szServerName
	tTong.id = dwTongID
	tTong.name = szTongName
	tTong.extra = tTong.extra or ''
	tTong.time = GetCurrentTime()
	tTong.times = (tTong.times or 0) + (bTimes and 1 or 0)
	TONG_INFO[szServerName .. g_tStrings.STR_CONNECT .. tTong.id] = tTong
	TONG_INFO_W[tTong.id] = X.ConvertToUTF8(tTong)
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
		player.nX ~= 0 and player.szTitle or nil,
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
		local tTong = D.GetTongInfo(tPlayer.server, tPlayer.tong)
		return {
			szServerName = tPlayer.server,
			dwID         = tPlayer.id,
			szName       = tPlayer.name,
			szGlobalID   = tPlayer.guid,
			dwForceID    = tPlayer.force,
			nRoleType    = tPlayer.role,
			nLevel       = tPlayer.level,
			szTitle      = tPlayer.title,
			nCamp        = tPlayer.camp,
			dwTongID     = tPlayer.tong,
			szTongName   = tTong and tTong.name or '',
			rgb          = X.IsNumber(tPlayer.force) and { X.GetForceColor(tPlayer.force, 'foreground') } or { 255, 255, 255 },
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
	local szTitle = _L['MY_Farbnamen__Analysis'] .. g_tStrings.STR_CONNECT .. X.GetServerOriginName()
	if szSubTitle then
		szTitle = szTitle .. g_tStrings.STR_CONNECT .. szSubTitle
	end
	local szWhere, szJoinWhere = '', ''
	if nTimeLimit then
		szWhere = ' WHERE time > ' .. (GetCurrentTime() - nTimeLimit) .. ' '
		szJoinWhere = ' WHERE PlayerInfo.time > ' .. (GetCurrentTime() - nTimeLimit) .. ' '
	end
	local ui = X.UI.CreateFrame('MY_Farbnamen__Analysis', {
		simple = true, close = true,
		text = szTitle,
	})
	local nPaddingX = 20
	local nX, nY = nPaddingX, 30
	local nDeltaY = 30
	ui:Append('Text', {
		x = nX, y = nY,
		text = _L('Total player count: %d', X.Get(DB:Execute([[SELECT COUNT(*) AS count FROM PlayerInfo]] .. szWhere), {1, 'count'}, 0)),
	})
	nY = nY + nDeltaY
	ui:Append('Text', {
		x = nX, y = nY,
		text = _L('Total tong count: %d', X.Get(DB:Execute([[SELECT COUNT(*) AS count FROM TongInfo]] .. szWhere), {1, 'count'}, 0)),
	})
	nY = nY + nDeltaY
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Camp analysis:'],
	})
	nY = nY + nDeltaY

	for _, v in ipairs(DB:Execute([[SELECT camp, COUNT(*) AS count FROM PlayerInfo]] .. szWhere .. [[ GROUP BY camp]]) or {}) do
		ui:Append('Text', {
			x = nX, y = nY,
			text = g_tStrings.STR_CAMP_TITLE[v.camp] or _L('Unknown(%d)', v.camp),
		})
		ui:Append('Text', {
			x = nX + 65, y = nY,
			text = _L('%6d players', v.count),
		})
		nY = nY + nDeltaY
	end
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Force analysis:'],
	})
	nY = nY + nDeltaY

	local aForce = DB:Execute([[SELECT force, COUNT(*) AS count FROM PlayerInfo]] .. szWhere .. [[ GROUP BY force]]) or {}
	for i = 1, #aForce, 2 do
		nX = nPaddingX
		for j = 0, 1 do
			local v = aForce[i + j]
			if v then
				ui:Append('Text', {
					x = nX, y = nY,
					text = g_tStrings.tForceTitle[v.force] or _L('Unknown(%d)', v.force),
				})
				ui:Append('Text', {
					x = nX + 65, y = nY,
					text = _L('%6d players', v.count),
				})
				nX = nX + 250
			end
		end
		nY = nY + nDeltaY
	end
	nX = nPaddingX
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Top 10 tong member count analysis:'],
	})
	nY = nY + nDeltaY

	for _, v in ipairs(DB:Execute([[
		SELECT TongInfo.name, COUNT(PlayerInfo.id) AS count
		FROM PlayerInfo
		JOIN TongInfo ON PlayerInfo.tong = TongInfo.id
		]] .. szJoinWhere .. [[
		GROUP BY PlayerInfo.tong
		ORDER BY count DESC
		LIMIT 10;
	]]) or {}) do
		ui:Append('Text', {
			x = nX, y = nY,
			text = UTF8ToAnsi(v.name),
		})
		ui:Append('Text', {
			x = nX + 250, y = nY,
			text = _L('%6d players', v.count),
		})
		nY = nY + nDeltaY
	end
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['---------------------------------------------'],
	})
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Counts based on local cache, only players you met will be analyzed.'],
	})
	nY = nY + nDeltaY

	ui:Size(640, nY + 50)
	ui:Anchor('CENTER')
end

--------------------------------------------------------------------------------
-- 菜单
--------------------------------------------------------------------------------
function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	D.Migration()

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
			return O.bEnable
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
				DB:Execute('DELETE FROM PlayerInfo')
				X.OutputSystemMessage(_L['MY_Farbnamen'], _L['Cache data deleted.'])
			end)
		end,
		autoEnable = function()
			return O.bEnable
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
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		x = nX, y = nY, w = 'auto',
		buttonStyle = 'FLAT',
		text = _L['Export data'],
		onClick = function()
			X.OpenFolder(X.GetAbsolutePath({'cache/farbnamen/farbnamen.v7.db', X.PATH_TYPE.GLOBAL}))
			X.Alert(_L['Copy .db file to share.'])
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
	if not dwSenderID or not szSenderName or not dwForceID then
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

X.RegisterUserSettingsInit('MY_Farbnamen', function() D.bReady = true end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
