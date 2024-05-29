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
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^21.0.3') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------
---------------------------------------------------------------
-- 设置和数据
---------------------------------------------------------------
X.CreateDataRoot(X.PATH_TYPE.SERVER)

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
local DB, DBI_W, DBI_RI, DBI_RN, DBT_W, DBT_RI

local function InitDB()
	if DB then
		return true
	end
	if DB_ERR_COUNT > DB_MAX_ERR_COUNT then
		return false
	end
	DB = X.SQLiteConnect(_L['MY_Farbnamen'], {'cache/farbnamen.v5.db', X.PATH_TYPE.SERVER})
	if not DB then
		local szMsg = _L['Cannot connect to database!!!']
		if DB_ERR_COUNT > 0 then
			szMsg = szMsg .. _L(' Retry time: %d', DB_ERR_COUNT)
		end
		DB_ERR_COUNT = DB_ERR_COUNT + 1
		X.Sysmsg(_L['MY_Farbnamen'], szMsg, X.CONSTANT.MSG_THEME.ERROR)
		return false
	end
	DB:Execute([[
		CREATE TABLE IF NOT EXISTS InfoCache (
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			guid NVARCHAR(20) NOT NULL,
			force INTEGER NOT NULL,
			role INTEGER NOT NULL,
			level INTEGER NOT NULL,
			title NVARCHAR(20) NOT NULL,
			camp INTEGER NOT NULL,
			tong INTEGER NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY (id)
		)
	]])
	DB:Execute('CREATE UNIQUE INDEX IF NOT EXISTS info_cache_name_uidx ON InfoCache(name)')
	DB:Execute('CREATE INDEX IF NOT EXISTS info_cache_guid_uidx ON InfoCache(guid)')
	DBI_W  = DB:Prepare('REPLACE INTO InfoCache (id, name, guid, force, role, level, title, camp, tong, extra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
	DBI_RI = DB:Prepare('SELECT id, name, guid, force, role, level, title, camp, tong FROM InfoCache WHERE id = ?')
	DBI_RN = DB:Prepare('SELECT id, name, guid, force, role, level, title, camp, tong FROM InfoCache WHERE name = ?')
	DB:Execute([[
		CREATE TABLE IF NOT EXISTS TongCache (
			id INTEGER NOT NULL,
			name NVARCHAR(20) NOT NULL,
			extra TEXT NOT NULL,
			PRIMARY KEY(id)
		)
	]])
	DBT_W  = DB:Prepare('REPLACE INTO TongCache (id, name, extra) VALUES (?, ?, ?)')
	DBT_RI = DB:Prepare('SELECT id, name FROM TongCache WHERE id = ?')

	-- 旧版文件缓存转换
	local SZ_IC_PATH = X.FormatPath({'cache/PLAYER_INFO/{$server_origin}/', X.PATH_TYPE.DATA})
	if IsLocalFileExist(SZ_IC_PATH) then
		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 999 do
			local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/DAT2/' .. i .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
			if data then
				for id, p in pairs(data) do
					DBI_W:ClearBindings()
					DBI_W:BindAll(p[1], p[2], '', p[3], p[4], p[5], p[6], p[7], p[8], '')
					DBI_W:Execute()
				end
			end
		end
		DBI_W:Reset()
		DB:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen info cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite start!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		DB:Execute('BEGIN TRANSACTION')
		for i = 0, 128 do
			for j = 0, 128 do
				local data = X.LoadLUAData({'cache/PLAYER_INFO/{$server_origin}/TONG/' .. i .. '-' .. j .. '.{$lang}.jx3dat', X.PATH_TYPE.DATA})
				if data then
					for id, name in pairs(data) do
						DBT_W:ClearBindings()
						DBT_W:BindAll(id, AnsiToUTF8(name), '')
						DBT_W:Execute()
					end
				end
			end
		end
		DBT_W:Reset()
		DB:Execute('END TRANSACTION')
		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen tong cache trans from file to sqlite finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen cleaning file cache start: ' .. SZ_IC_PATH, X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
		CPath.DelDir(SZ_IC_PATH)
		--[[#DEBUG BEGIN]]
		X.Debug('MY_Farbnamen', 'Farbnamen cleaning file cache finished!', X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]
	end
	return true
end
InitDB()

function D.Migration()
	local szRoot = X.FormatPath({'cache/', X.PATH_TYPE.SERVER})
	-- 修复V4版本导入乱码问题
	for _, szFileName in ipairs(CPath.GetFileList(szRoot)) do
		local szTime = select(3, ('farbnamen.v4.db.bak20210715210715'):find('^farbnamen%.v4%.db%.bak(%d+)$'))
		local nTime = szTime and tonumber(szTime)
		if nTime and nTime < 1717034400 then
			CPath.Move(szRoot .. szFileName, szRoot .. 'farbnamen.v4.db')
		end
	end
	local DB_V1_PATH = X.FormatPath({'cache/player_info.db', X.PATH_TYPE.SERVER})
	local DB_V2_PATH = X.FormatPath({'cache/player_info.v2.db', X.PATH_TYPE.SERVER})
	local DB_V3_PATH = X.FormatPath({'cache/farbnamen.v3.db', X.PATH_TYPE.SERVER})
	local DB_V4_PATH = X.FormatPath({'cache/farbnamen.v4.db', X.PATH_TYPE.SERVER})
	if not IsLocalFileExist(DB_V1_PATH) and not IsLocalFileExist(DB_V2_PATH) and not IsLocalFileExist(DB_V3_PATH) and not IsLocalFileExist(DB_V4_PATH) then
		return
	end
	X.Confirm(
		_L['Ancient database detected, do you want to migrate data from it?'],
		function()
			-- 转移V1旧版数据
			if IsLocalFileExist(DB_V1_PATH) then
				local DB_V1 = SQLite3_Open(DB_V1_PATH)
				if DB_V1 then
					-- 角色缓存
					local nCount, nPageSize = X.Get(DB_V1:Execute('SELECT COUNT(*) AS count FROM InfoCache'), {1, 'count'}, 0), 10000
					DB:Execute('BEGIN TRANSACTION')
					for i = 0, nCount / nPageSize do
						for _, p in ipairs(DB_V1:Execute('SELECT id, name, force, role, level, title, camp, tong FROM InfoCache LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
							DBI_W:ClearBindings()
							DBI_W:BindAll(
								p.id,
								AnsiToUTF8(p.name),
								'',
								p.force or -1,
								p.role or -1,
								p.level or -1,
								AnsiToUTF8(p.title),
								p.camp or -1,
								p.tong or -1,
								''
							)
							DBI_W:Execute()
						end
					end
					DBI_W:Reset()
					DB:Execute('END TRANSACTION')
					-- 帮会缓存
					local nCount, nPageSize = X.Get(DB_V1:Execute('SELECT COUNT(*) AS count FROM TongCache'), {1, 'count'}, 0), 10000
					DB:Execute('BEGIN TRANSACTION')
					for i = 0, nCount / nPageSize do
						for _, p in ipairs(DB_V1:Execute('SELECT id, name FROM TongCache LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))) do
							DBT_W:ClearBindings()
							DBT_W:BindAll(
								p.id,
								AnsiToUTF8(p.name),
								''
							)
							DBT_W:Execute()
						end
					end
					DBT_W:Reset()
					DB:Execute('END TRANSACTION')
					DB_V1:Release()
				end
				CPath.Move(DB_V1_PATH, DB_V1_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V2旧版数据
			if IsLocalFileExist(DB_V2_PATH) then
				local DB_V2 = SQLite3_Open(DB_V2_PATH)
				if DB_V2 then
					DB:Execute('BEGIN TRANSACTION')
					local nCount, nPageSize = X.Get(DB_V2:Execute('SELECT COUNT(*) AS count FROM InfoCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aInfoCache = DB_V2:Execute('SELECT * FROM InfoCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aInfoCache then
							for _, rec in ipairs(aInfoCache) do
								if rec.id and rec.name then
									DBI_W:ClearBindings()
									DBI_W:BindAll(
										rec.id,
										AnsiToUTF8(rec.name),
										'',
										rec.force or -1,
										rec.role or -1,
										rec.level or -1,
										AnsiToUTF8(rec.title or ''),
										rec.camp or -1,
										rec.tong or -1,
										''
									)
									DBI_W:Execute()
								end
							end
							DBI_W:Reset()
						end
					end
					local nCount, nPageSize = X.Get(DB_V2:Execute('SELECT COUNT(*) AS count FROM TongCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aTongCache = DB_V2:Execute('SELECT * FROM TongCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aTongCache then
							for _, rec in ipairs(aTongCache) do
								if rec.id and rec.name then
									DBT_W:ClearBindings()
									DBT_W:BindAll(
										rec.id,
										AnsiToUTF8(rec.name or ''),
										''
									)
									DBT_W:Execute()
								end
							end
							DBT_W:Reset()
						end
					end
					DB:Execute('END TRANSACTION')
					DB_V2:Release()
				end
				CPath.Move(DB_V2_PATH, DB_V2_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V3旧版数据
			if IsLocalFileExist(DB_V3_PATH) then
				local DB_V3 = SQLite3_Open(DB_V3_PATH)
				if DB_V3 then
					DB:Execute('BEGIN TRANSACTION')
					local nCount, nPageSize = X.Get(DB_V3:Execute('SELECT COUNT(*) AS count FROM InfoCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aInfoCache = DB_V3:Execute('SELECT * FROM InfoCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aInfoCache then
							for _, rec in ipairs(aInfoCache) do
								if rec.id and rec.name then
									DBI_W:ClearBindings()
									DBI_W:BindAll(
										rec.id,
										AnsiToUTF8(rec.name),
										'',
										rec.force or -1,
										rec.role or -1,
										rec.level or -1,
										AnsiToUTF8(rec.title or ''),
										rec.camp or -1,
										rec.tong or -1,
										''
									)
									DBI_W:Execute()
								end
							end
							DBI_W:Reset()
						end
					end
					local nCount, nPageSize = X.Get(DB_V3:Execute('SELECT COUNT(*) AS count FROM TongCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aTongCache = DB_V3:Execute('SELECT * FROM TongCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aTongCache then
							for _, rec in ipairs(aTongCache) do
								if rec.id and rec.name then
									DBT_W:ClearBindings()
									DBT_W:BindAll(
										rec.id,
										AnsiToUTF8(rec.name),
										''
									)
									DBT_W:Execute()
								end
							end
							DBT_W:Reset()
						end
					end
					DB:Execute('END TRANSACTION')
					DB_V3:Release()
				end
				CPath.Move(DB_V3_PATH, DB_V3_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
			end
			-- 转移V4旧版数据
			if IsLocalFileExist(DB_V4_PATH) then
				local DB_V4 = SQLite3_Open(DB_V4_PATH)
				if DB_V4 then
					DB:Execute('BEGIN TRANSACTION')
					local nCount, nPageSize = X.Get(DB_V4:Execute('SELECT COUNT(*) AS count FROM InfoCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aInfoCache = DB_V4:Execute('SELECT * FROM InfoCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aInfoCache then
							for _, rec in ipairs(aInfoCache) do
								if rec.id and rec.name then
									DBI_W:ClearBindings()
									DBI_W:BindAll(
										rec.id,
										rec.name,
										'',
										rec.force or -1,
										rec.role or -1,
										rec.level or -1,
										rec.title or '',
										rec.camp or -1,
										rec.tong or -1,
										rec.extra or ''
									)
									DBI_W:Execute()
								end
							end
							DBI_W:Reset()
						end
					end
					local nCount, nPageSize = X.Get(DB_V4:Execute('SELECT COUNT(*) AS count FROM TongCache WHERE id IS NOT NULL'), {1, 'count'}, 0), 10000
					for i = 0, nCount / nPageSize do
						local aTongCache = DB_V4:Execute('SELECT * FROM TongCache WHERE id IS NOT NULL LIMIT ' .. nPageSize .. ' OFFSET ' .. (i * nPageSize))
						if aTongCache then
							for _, rec in ipairs(aTongCache) do
								if rec.id and rec.name then
									DBT_W:ClearBindings()
									DBT_W:BindAll(
										rec.id,
										rec.name,
										rec.extra or ''
									)
									DBT_W:Execute()
								end
							end
							DBT_W:Reset()
						end
					end
					DB:Execute('END TRANSACTION')
					DB_V4:Release()
				end
				CPath.Move(DB_V4_PATH, DB_V4_PATH .. '.bak' .. X.FormatTime(GetCurrentTime(), '%yyyy%MM%dd%hh%mm%ss'))
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
					local tInfo = D.GetAusName(szName)
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
	--     local tInfo = D.GetAusName(szName)
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

function D.RenderNamelink(namelink, tOption)
	local ui, nNumOffset = X.UI(namelink), 0
	if tOption.bColor or tOption.bInsertIcon then
		local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
		local tInfo = D.GetAusName(szName)
		if tInfo then
			if tOption.bColor then
				ui:Color(tInfo.rgb)
			end
			if tOption.bInsertIcon then
				local szIcon, nFrame = GetForceImage(tInfo.dwForceID)
				if szIcon and nFrame then
					namelink:GetParent():InsertItemFromString(
						namelink:GetIndex(),
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
	return namelink, nNumOffset
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
			return D.RenderNamelink(el, tOption)
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

-- 插入聊天内容的 HOOK （过滤、加入时间 ）
X.HookChatPanel('BEFORE', 'MY_FARBNAMEN', function(h, szMsg, ...)
	if D.bReady and O.bEnable then
		szMsg = D.Render(szMsg, true)
	end
	return szMsg
end)

function D.RegisterNameIDHeader(szName, dwID, szHeaderXml)
	if not NAME_ID_HEADER_XML[szName] then
		NAME_ID_HEADER_XML[szName] = {}
	end
	if NAME_ID_HEADER_XML[szName][dwID] then
		return X.Debug('ERROR', 'MY_Farbnamen Conflicted Name-ID: ' .. szName .. '(' .. dwID .. ')', X.DEBUG_LEVEL.ERROR)
	end
	if dwID == '*' then
		szName = X.FormatBasePlayerName(szName)
	end
	NAME_ID_HEADER_XML[szName][dwID] = szHeaderXml
end

function D.RegisterGlobalIDHeader(szGlobalID, szHeaderXml)
	if GUID_HEADER_XML[szGlobalID] then
		return X.Debug('ERROR', 'MY_Farbnamen Conflicted GUID: ' .. szGlobalID, X.DEBUG_LEVEL.ERROR)
	end
	GUID_HEADER_XML[szGlobalID] = szHeaderXml
end

function D.GetTip(szName)
	local tInfo = D.GetAusName(szName)
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
				local szName = X.FormatBasePlayerName(tInfo.szName)
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
		if MY_Anmerkungen and MY_Anmerkungen.GetPlayerNote then
			local note = MY_Anmerkungen.GetPlayerNote(tInfo.dwID)
			if note and note.szContent ~= '' then
				table.insert(tTip, GetFormatText(note.szContent, 0))
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

function D.ShowTip(namelink)
	if type(namelink) ~= 'table' then
		namelink = this
	end
	if not namelink then
		return
	end
	local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
	local x, y = namelink:GetAbsPos()
	local w, h = namelink:GetSize()

	local szTip = D.GetTip(szName)
	if szTip then
		OutputTip(szTip, 450, {x, y, w, h}, X.UI.TIP_POSITION.TOP_BOTTOM)
	end
end
---------------------------------------------------------------
-- 数据存储
---------------------------------------------------------------
local l_infocache       = {} -- 读取数据缓存
local l_infocache_w     = {} -- 修改数据缓存（UTF8）
local l_remoteinfocache = {} -- 跨服数据缓存
local l_tongnames       = {} -- 帮会数据缓存
local l_tongnames_w     = {} -- 帮会修改数据缓存（UTF8）
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
			szTong = UTF8ToAnsi(data.name)
			l_tongnames[dwID] = szTong
		end
		DBT_RI:Reset()
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
			DBI_W:BindAll(p.id, p.name, p.guid, p.force, p.role, p.level, p.title, p.camp, p.tong, '')
			DBI_W:Execute()
		end
		DBI_W:Reset()
		DB:Execute('END TRANSACTION')
	end
	if DBT_W then
		DB:Execute('BEGIN TRANSACTION')
		for id, name in pairs(l_tongnames_w) do
			DBT_W:ClearBindings()
			DBT_W:BindAll(id, name, '')
			DBT_W:Execute()
		end
		DBT_W:Reset()
		DB:Execute('END TRANSACTION')
	end
end
X.RegisterFlush('MY_Farbnamen_Save', Flush)
end

do
local function OnExit()
	if not DB then
		return
	end
	DB:Release()
end
X.RegisterExit('MY_Farbnamen_Save', OnExit)
end

-- 通过szName获取信息
function D.Get(szKey)
	local info = l_remoteinfocache[szKey] or l_infocache[szKey]
	if not info then
		if type(szKey) == 'string' then
			if InitDB() then
				DBI_RN:ClearBindings()
				DBI_RN:BindAll(AnsiToUTF8(szKey))
				info = DBI_RN:GetNext()
				DBI_RN:Reset()
			end
		elseif type(szKey) == 'number' then
			if InitDB() then
				DBI_RI:ClearBindings()
				DBI_RI:BindAll(szKey)
				info = DBI_RI:GetNext()
				DBI_RI:Reset()
			end
		end
		if info then
			info.name = UTF8ToAnsi(info.name)
			info.title = UTF8ToAnsi(info.title)
			info.guid = UTF8ToAnsi(info.guid)
			l_infocache[info.id] = info
			l_infocache[info.name] = info
			if info.guid ~= '' and info.guid ~= '0' then
				l_infocache[info.guid] = info
			end
		end
	end
	if info then
		return {
			dwID       = info.id,
			szName     = info.name,
			szGlobalID = info.guid,
			dwForceID  = info.force,
			nRoleType  = info.role,
			nLevel     = info.level,
			szTitle    = info.title,
			nCamp      = info.camp,
			dwTongID   = info.tong,
			szTongName = GetTongName(info.tong) or '',
			rgb        = X.IsNumber(info.force) and { X.GetForceColor(info.force, 'foreground') } or { 255, 255, 255 },
		}
	end
end
D.GetAusName = D.Get

-- 通过dwID获取信息
function D.GetAusID(dwID)
	D.AddAusID(dwID)
	return D.Get(dwID)
end

-- 保存指定dwID的玩家
function D.AddAusID(dwID)
	local player = X.GetPlayer(dwID)
	if not player or not player.szName or player.szName == '' then
		return false
	else
		local info
		if IsRemotePlayer(player.dwID) then
			info = l_remoteinfocache[player.dwID] or {}
		else
			info = l_infocache[player.dwID] or {}
		end
		info.id    = player.dwID
		info.name  = player.szName
		info.guid  = X.GetPlayerGlobalID(player.dwID) or ''
		info.force = player.dwForceID or -1
		info.role  = player.nRoleType or -1
		info.level = player.nLevel or -1
		info.title = player.nX ~= 0 and player.szTitle or info.title or ''
		info.camp  = player.nCamp or -1
		info.tong  = player.dwTongID or -1

		if IsRemotePlayer(info.id) then
			l_remoteinfocache[info.id] = info
			l_remoteinfocache[info.name] = info
		else
			local dwTongID = player.dwTongID
			if dwTongID and dwTongID ~= 0 then
				local szTong = GetTongClient().ApplyGetTongName(dwTongID, 254)
				if szTong and szTong ~= '' then
					l_tongnames[dwTongID] = szTong
					l_tongnames_w[dwTongID] = AnsiToUTF8(szTong)
				end
			end
			l_infocache[info.id] = info
			l_infocache[info.name] = info
			if info.guid ~= '' and info.guid ~= '0' then
				l_infocache[info.guid] = info
			end
			local infow = X.Clone(info)
			infow.name = AnsiToUTF8(info.name)
			infow.title = AnsiToUTF8(info.title)
			infow.guid = AnsiToUTF8(info.guid)
			l_infocache_w[info.id] = infow
		end
		return true
	end
end

function D.ShowAnalysis()
	local ui = X.UI.CreateFrame('MY_Farbnamen__Analysis', {
		simple = true, close = true,
		text = _L['MY_Farbnamen__Analysis'],
	})
	local nPaddingX = 20
	local nX, nY = nPaddingX, 30
	local nDeltaY = 30
	ui:Append('Text', {
		x = nX, y = nY,
		text = _L('Total player count: %d', X.Get(DB:Execute([[SELECT COUNT(*) AS count FROM InfoCache]]), {1, 'count'}, 0)),
	})
	nY = nY + nDeltaY
	ui:Append('Text', {
		x = nX, y = nY,
		text = _L('Total tong count: %d', X.Get(DB:Execute([[SELECT COUNT(*) AS count FROM TongCache]]), {1, 'count'}, 0)),
	})
	nY = nY + nDeltaY
	nY = nY + nDeltaY

	ui:Append('Text', {
		x = nX, y = nY,
		text = _L['Camp analysis:'],
	})
	nY = nY + nDeltaY

	for _, v in ipairs(DB:Execute([[SELECT camp, COUNT(*) AS count FROM InfoCache GROUP BY camp]]) or {}) do
		ui:Append('Text', {
			x = nX, y = nY,
			text = g_tStrings.STR_CAMP_TITLE[v.camp] or '',
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

	local aForce = DB:Execute([[SELECT force, COUNT(*) AS count FROM InfoCache GROUP BY force]]) or {}
	for i = 1, #aForce, 2 do
		nX = nPaddingX
		for j = 0, 1 do
			local v = aForce[i + j]
			if v then
				ui:Append('Text', {
					x = nX, y = nY,
					text = g_tStrings.tForceTitle[v.force] or '',
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
		SELECT TongCache.name, COUNT(InfoCache.id) AS count
		FROM InfoCache
		JOIN TongCache ON InfoCache.tong = TongCache.id
		GROUP BY InfoCache.tong
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

--------------------------------------------------------------
-- 菜单
--------------------------------------------------------------
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

	nX = nX + ui:Append('WndTrackbar', {
		x = nX, y = nY, w = 100, h = 25,
		value = O.nInsertIconSize,
		range = {1, 300},
		trackbarStyle = X.UI.TRACKBAR_STYLE.SHOW_VALUE,
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
		onClick = function()
			D.ShowAnalysis()
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
				DB:Execute('DELETE FROM InfoCache')
				X.Sysmsg(_L['MY_Farbnamen'], _L['Cache data deleted.'])
			end)
		end,
		autoEnable = function()
			return O.bEnable
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
				GetAusName             = D.GetAusName            ,
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
local l_peeklist = {}
local function onBreathe()
	for dwID, nRetryCount in pairs(l_peeklist) do
		if D.AddAusID(dwID) or nRetryCount > 5 then
			l_peeklist[dwID] = nil
		else
			l_peeklist[dwID] = nRetryCount + 1
		end
	end
end
X.BreatheCall(250, onBreathe)

local function OnPeekPlayer()
	if arg0 == X.CONSTANT.PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		l_peeklist[arg1] = 0
	end
end
X.RegisterEvent('PEEK_OTHER_PLAYER', OnPeekPlayer)
X.RegisterEvent('MY_PLAYER_ENTER_SCENE', function() l_peeklist[arg0] = 0 end)
X.RegisterEvent('ON_GET_TONG_NAME_NOTIFY', function() l_tongnames[arg1], l_tongnames_w[arg1] = arg2, AnsiToUTF8(arg2) end)
end

X.RegisterUserSettingsInit('MY_Farbnamen', function() D.bReady = true end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
