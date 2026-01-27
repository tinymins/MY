--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 云世界标记 - 数据订阅
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_YunWorldMark_Subscribe'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_YunWorldMark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^29.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.ROOT .. PLUGIN_NAME .. '/ui/MY_YunWorldMark_Subscribe.ini'
local D = {}

local USE_DISABLE_MS = 1000
local USE_COLOR_ACTIVE = { 255, 255, 0 }
local USE_COLOR_DISABLED = { 128, 128, 128 }

function D.ShowSceneWorldMark()
	local tTemplateToIndex = {}
	for _, info in ipairs((X.CONSTANT and X.CONSTANT.WORLD_MARK) or {}) do
		if info and info.dwNpcTemplateID and info.nIndex then
			tTemplateToIndex[info.dwNpcTemplateID] = info.nIndex
		end
	end

	local data = {}
	for i = 1, 10 do
		data[i] = { x = 0, y = 0, z = 0, mark = i }
	end

	for _, npc in ipairs(X.GetNearNpc()) do
		local nIndex = npc and tTemplateToIndex[npc.dwTemplateID]
		if nIndex and nIndex >= 1 and nIndex <= 10 then
			local nX = tonumber(npc.nX) or 0
			local nY = tonumber(npc.nY) or 0
			local nZ = tonumber(npc.nZ) or 0
			if not (nX == 0 and nY == 0 and nZ == 0) then
				data[nIndex] = { x = nX, y = nY, z = nZ, mark = nIndex }
			end
		end
	end

	-- 手动拼接可读的 JSON（同时保证能被 X.DecodeJSON 解析）
	-- 约束：第一层列表项使用 \t + 换行；对象内部不再使用 \t。
	local aText = { '[', }
	for i = 1, 10 do
		local pt = data[i] or {}
		local nX = tostring(tonumber(pt.x) or 0)
		local nY = tostring(tonumber(pt.y) or 0)
		local nZ = tostring(tonumber(pt.z) or 0)
		local nMark = tostring(tonumber(pt.mark) or i)
		local szLine = string.format('\t{ "x": %s, "y": %s, "z": %s, "mark": %s }', nX, nY, nZ, nMark)
		if i < 10 then
			szLine = szLine .. ','
		end
		table.insert(aText, szLine)
	end
	table.insert(aText, ']')
	local szText = table.concat(aText, '\n')
	X.UI.OpenTextEditor(szText, {
		w = 450,
		h = 300,
		title = _L['World mark'],
	})
end

function D.Search(page, nPage)
	if not page or not page:IsValid() then
		return
	end
	local ui = X.UI(page)

	-- 防止并发搜索回调覆盖新结果
	D.nSearchToken = (tonumber(D.nSearchToken) or 0) + 1
	local nToken = D.nSearchToken

	nPage = tonumber(nPage) or 1
	if nPage < 1 then
		nPage = 1
	end

	local szSearch = X.TrimString(ui:Fetch('WndEditBox_Search'):Text() or '')
	local dwMapID = D.dwMapID or 0

	local aAllList = nil
	local tFeedRecord = nil
	local nPending = 0
	local function fnToRecord(tInfo)
		if not X.IsTable(tInfo) then
			return nil
		end
		return {
			id = tInfo.id,
			key = tInfo.key,
			szName = tInfo.name,
			szAuthor = tInfo.author,
			dwUpdateTime = tInfo.update,
			szDataURL = tInfo.data_url,
			szAboutURL = tInfo.about,
			tRaw = tInfo,
		}
	end
	local function fnFinalize()
		if nToken ~= D.nSearchToken then
			return
		end
		if nPending > 0 then
			return
		end

		local aDataSource = {}
		local nFeedID = nil
		if X.IsTable(tFeedRecord) and tFeedRecord.id then
			nFeedID = tFeedRecord.id
			table.insert(aDataSource, tFeedRecord)
		end
		for _, rec in ipairs(aAllList or {}) do
			if not (nFeedID and rec and rec.id == nFeedID) then
				table.insert(aDataSource, rec)
			end
		end
		ui:Fetch('WndTable_List'):DataSource(aDataSource)
	end
	local function fnDoneOne()
		nPending = nPending - 1
		fnFinalize()
	end

	-- 1) 排行榜列表
	nPending = nPending + 1
	X.Ajax({
		url = MY_RSS.PULL_BASE_URL .. '/api/addon/common-monitor/subscribe/all',
		data = {
			l = X.ENVIRONMENT.GAME_LANG,
			L = X.ENVIRONMENT.GAME_EDITION,
			T = 3,
			map = dwMapID,
			q = szSearch,
			page = nPage,
			pageSize = 100,
		},
		success = function(szHTML)
			if nToken ~= D.nSearchToken then
				return
			end
			local res = X.DecodeJSON(szHTML)
			if not X.IsTable(res) or not X.IsTable(res.data) then
				X.OutputAnnounceMessage(_L['Fetch repo meta list failed.'])
				aAllList = {}
				fnDoneOne()
				return
			end
			local a = {}
			for _, info in ipairs(res.data) do
				table.insert(a, fnToRecord(info))
			end
			aAllList = a
			fnDoneOne()
		end,
		error = function(html, status)
			if nToken ~= D.nSearchToken then
				return
			end
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage(_L[MODULE_NAME], 'ERROR Fetch list: ' .. X.EncodeLUAData(status) .. '\n' .. (X.ConvertToANSI(html) or ''), X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			X.OutputAnnounceMessage(_L['Fetch repo meta list failed.'])
			aAllList = {}
			fnDoneOne()
		end,
	})

	-- 2) 精准匹配（不在排行榜也能查）
	if not X.IsEmpty(szSearch) then
		nPending = nPending + 1
		X.Ajax({
			url = MY_RSS.PULL_BASE_URL .. '/api/addon/common-monitor/subscribe/feed',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				T = 3,
				map = dwMapID,
				key = szSearch,
			},
			success = function(szHTML)
				if nToken ~= D.nSearchToken then
					return
				end
				local res = X.DecodeJSON(szHTML)
				-- 不存在：{"code":404,"msg":"数据不存在"}
				if X.IsTable(res) and res.id then
					tFeedRecord = fnToRecord(res)
				else
					tFeedRecord = nil
				end
				fnDoneOne()
			end,
			error = function(szHtml, szStatus)
				if nToken ~= D.nSearchToken then
					return
				end
				tFeedRecord = nil
				fnDoneOne()
			end,
		})
	end

	fnFinalize()
end

function D.OnInitPage()
	local page = this
	local ui = X.UI(page)

	local me = X.GetClientPlayer()
	if me then
		D.dwMapID = me.GetMapID() or 0
	else
		D.dwMapID = 0
	end

	local tMapName, aMapSource, tMapMenu = {}, {}, {}
	for _, group in ipairs(X.GetTypeGroupMap()) do
		local tSub = { szOption = group.szGroup }
		for _, info in ipairs(group.aMapInfo) do
			table.insert(tSub, {
				szOption = info.szName,
				fnAction = function()
					D.dwMapID = info.dwID
					ui:Fetch('WndAutocomplete_Map'):Text(info.szName)
					X.UI.ClosePopupMenu()
				end,
			})
			tMapName[info.dwID] = info.szName
			table.insert(aMapSource, { text = info.szName, dwID = info.dwID })
		end
		table.insert(tMapMenu, tSub)
	end
	local szCurrentMapName = tMapName[D.dwMapID] or ''

	local dwTargetType, dwTargetID = 0, 0
	if me then
		dwTargetType, dwTargetID = X.GetCharacterTarget(me)
	end

	local nX, nY = 20, 10
	local COMPONENT_H = 25

	nX = nX + ui:Append('WndAutocomplete', {
		name = 'WndAutocomplete_Map',
		x = nX,
		y = nY,
		w = 250,
		h = COMPONENT_H,
		text = szCurrentMapName,
		placeholder = _L['Current map'],
		autocomplete = {
			{
				'option', 'source', aMapSource,
			},
			{
				'option', 'afterComplete', function(raw)
					if raw and raw.dwID then
						D.dwMapID = raw.dwID
					end
				end,
			},
		},
		menu = function() return tMapMenu end,
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.Search(page)
				return 1
			end
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndEditBox', {
		name = 'WndEditBox_Search',
		x = nX,
		y = nY,
		w = 500,
		h = COMPONENT_H,
		text = dwTargetType == TARGET.NPC and X.GetNpcName(dwTargetID) or '',
		placeholder = _L['Search'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.Search(page)
				return 1
			end
		end,
	}):Width() + 5

	nX = nX + ui:Append('WndButton', {
		name = 'Btn_Search',
		x = nX,
		y = nY,
		w = 100,
		h = COMPONENT_H,
		text = _L['Search'],
		onClick = function()
			D.Search(page)
		end,
	}):Width() + 5

	ui:Append('WndTable', {
		name = 'WndTable_List',
		x = 20,
		y = 50,
		w = 960,
		h = 560,
		onRowHover = function(bIn, rec, nIndex, rect)
			if not bIn then
				HideTip()
				return
			end
			local a = {
				_L['Key'] .. ': ' .. tostring(rec and rec.key or ''),
				_L['ID'] .. ': ' .. tostring(rec and rec.id or ''),
				_L['Name'] .. ': ' .. tostring(rec and rec.szName or ''),
				_L['Author'] .. ': ' .. tostring(rec and rec.szAuthor or ''),
				_L['Update time'] .. ': ' .. tostring(rec and rec.dwUpdateTime or ''),
				_L['About'] .. ': ' .. tostring(rec and rec.szAboutURL or ''),
			}
			local tipRect = nil
			if X.IsTable(rect) then
				tipRect = { rect.x or rect[1], rect.y or rect[2], rect.w or rect[3], rect.h or rect[4] }
			end
			X.OutputTip(tipRect, table.concat(a, '\n'), 106, X.UI.TIP_POSITION.RIGHT_LEFT, 450)
		end,
		onRowRClick = function(rec, nIndex)
			if not rec then
				return
			end
			local t = {
				{
					szOption = MY_YunWorldMark_Favorite.IsFavorited(rec) and _L['Remove from favorites'] or _L['Add to favorites'],
					fnAction = function()
						if MY_YunWorldMark_Favorite.IsFavorited(rec) then
							MY_YunWorldMark_Favorite.Remove(rec)
						else
							MY_YunWorldMark_Favorite.Add(rec, D.dwMapID)
						end
					end,
				},
				{
					szOption = _L['Add to local data'],
					fnAction = function()
						if not rec.szDataURL then
							return
						end
						X.FetchLUAData(rec.szDataURL, { passphrase = false, crc = false, compress = false })
							:Then(function(aData)
								if not X.IsTable(aData) then
									X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
									return
								end
								-- 清洗数据，只保留 x, y, z, mark
								local aCleanData = {}
								for i, pt in ipairs(aData) do
									aCleanData[i] = {
										x = tonumber(pt.x) or 0,
										y = tonumber(pt.y) or 0,
										z = tonumber(pt.z) or 0,
										mark = tonumber(pt.mark) or i,
									}
								end
								MY_YunWorldMark_LocalData.Add({
									szName = rec.szName,
									szAuthor = rec.szAuthor,
									aData = aCleanData,
								}, D.dwMapID)
							end)
							:Catch(function(error)
								X.OutputAnnounceMessage((error and error.message) or _L['Failed.'])
							end)
					end,
				},
			}
			PopupMenu(t)
		end,
		columns = {
			{
				key = 'szName',
				title = _L['Name'],
				alignHorizontal = 'left',
				minWidth = 200,
				overflow = 'hidden',
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'szAuthor',
				title = _L['Author'],
				alignHorizontal = 'center',
				width = 150,
				overflow = 'hidden',
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'dwUpdateTime',
				title = _L['Update time'],
				alignHorizontal = 'center',
				width = 150,
				render = function(value)
					return GetFormatText(' ' .. X.ReplaceSensitiveWord(tostring(value or '')), 162, 255, 255, 255)
				end,
			},
			{
				key = 'use',
				title = _L['Action'],
				alignHorizontal = 'center',
				width = 80,
				render = function(_, record)
					return GetFormatText(_L['Use'], 162, 255, 255, 0, 255, 'this.szURL = ' .. X.EncodeLUAData(record and record.szDataURL or ''), 'Text_Use')
				end,
			},
		},
		dataSource = {},
	})

	D.Search(page, 1)
	D.OnResizePage()
end

function D.OnActivePage()
end

function D.OnResizePage()
	local page = this
	local ui = X.UI(page)
	local nW, nH = ui:Size()
	-- 布局常量
	local nPadding = 20
	local nGap = 5
	local nMapW = 250
	local nBtnW = 100
	-- 搜索框动态宽度
	local nSearchW = nW - nPadding - nMapW - nGap - nGap - nBtnW - nPadding
	if nSearchW < 100 then
		nSearchW = 100
	end
	ui:Fetch('WndEditBox_Search'):Size(nSearchW, 25)
	-- 按钮位置
	ui:Fetch('Btn_Search'):Pos(nPadding + nMapW + nGap + nSearchW + nGap, 10)
	-- 列表动态宽高
	ui:Fetch('WndTable_List'):Size(nW - 40, nH - 70)
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Text_Use' then
		if not X.IsClientPlayerTeamMarker() then
			X.OutputAnnounceMessage(_L['Only team marker can do this.'])
			return
		end
		local szURL = this.szURL
		if X.IsEmpty(szURL) then
			return
		end
		MY_YunWorldMark.ApplyYunWorldMark(szURL)

		-- 防止重复点击：置灰并禁用 2 秒
		local nNow = GetTime and GetTime() or 0
		if this.__MY_UseDisabledUntil and this.__MY_UseDisabledUntil > nNow then
			return
		end
		this.__MY_UseDisabledUntil = nNow + USE_DISABLE_MS
		local el = this
		if type(el.SetFontColor) == 'function' then
			el:SetFontColor(unpack(USE_COLOR_DISABLED))
		end
		local function RestoreUseButton()
			if not el or (type(el.IsValid) == 'function' and not el:IsValid()) then
				return
			end
			local nNow2 = GetTime and GetTime() or 0
			local nRemaining = (tonumber(el.__MY_UseDisabledUntil) or 0) - nNow2
			if nRemaining > 0 then
				X.DelayCall(nRemaining, RestoreUseButton)
				return
			end
			if type(el.SetFontColor) == 'function' then
				el:SetFontColor(unpack(USE_COLOR_ACTIVE))
			end
		end
		X.DelayCall(USE_DISABLE_MS, RestoreUseButton)
	end
end

--------------------------------------------------------------------------------
-- 目标头像菜单：副本内 NPC 右键快捷搜索
--------------------------------------------------------------------------------
do
local function GetNpcTargetMenu()
	if not X.IsInDungeonMap() then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local dwType = X.GetCharacterTarget(me)
	if dwType ~= TARGET.NPC then
		return
	end
	return {
		szOption = _L['Search MY cloud world mark'],
		fnAction = function()
			MY_YunWorldMark.OpenPanel()
		end,
	}
end
X.RegisterTargetAddonMenu('MY_YunWorldMark', GetNpcTargetMenu)
end

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_Subscribe',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnActivePage',
				'OnResizePage',
				'OnDeactivePage',
				'OnItemLButtonClick',
			},
			root = D,
		},
	},
}
MY_YunWorldMark.RegisterModule('Subscribe', _L['Data subscribe'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_Subscribe',
	exports = {
		{
			root = D,
			fields = {
				'Search',
				'ShowSceneWorldMark',
			},
			preset = 'UIEvent',
		},
	},
}
MY_YunWorldMark_Subscribe = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
