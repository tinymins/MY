--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 云世界标记 - 本地数据
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_YunWorldMark_LocalData'
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

--------------------------------------------------------------------------------
-- 本地数据管理
--------------------------------------------------------------------------------

function D.Load()
	return X.LoadLUAData({'userdata/yun_world_mark/local_data.jx3dat', X.PATH_TYPE.GLOBAL}) or {}
end

function D.Save(aLocalData)
	X.SaveLUAData({'userdata/yun_world_mark/local_data.jx3dat', X.PATH_TYPE.GLOBAL}, aLocalData)
	FireUIEvent('MY_YUN_WORLD_MARK__LOCAL_DATA__LIST_UPDATE')
end

function D.GenerateKey()
	return 'local_' .. tostring(GetTime()) .. '_' .. tostring(math.random(100000, 999999))
end

function D.Add(info, dwMapID)
	if not info then
		return
	end
	local aLocalData = D.Load()
	-- 如果有key，移除已存在的相同 key
	if info.key then
		for i, p in X.ipairs_r(aLocalData) do
			if p.key == info.key then
				table.remove(aLocalData, i)
			end
		end
	else
		info.key = D.GenerateKey()
	end
	-- 保存地图信息
	local rec = X.Clone(info)
	rec.dwMapID = dwMapID or 0
	rec.dwUpdateTime = GetCurrentTime()
	table.insert(aLocalData, rec)
	D.Save(aLocalData)
	X.Alert(_L['Added to local data.'])
end

function D.Update(info)
	if not info or not info.key then
		return
	end
	local aLocalData = D.Load()
	for i, p in ipairs(aLocalData) do
		if p.key == info.key then
			info.dwUpdateTime = GetCurrentTime()
			aLocalData[i] = X.Clone(info)
			break
		end
	end
	D.Save(aLocalData)
	X.OutputAnnounceMessage(_L['Local data updated.'])
end

function D.Remove(info)
	if not info or not info.key then
		return
	end
	X.Confirm(_L['Confirm?'], function()
		local aLocalData = D.Load()
		for i, p in X.ipairs_r(aLocalData) do
			if p.key == info.key then
				table.remove(aLocalData, i)
			end
		end
		D.Save(aLocalData)
	end)
end

function D.IsInLocalData(info)
	if not info or not info.key then
		return false
	end
	for _, p in ipairs(D.Load()) do
		if p.key == info.key then
			return true
		end
	end
	return false
end

-- 格式化世界标记 JSON，与 ShowSceneWorldMark 保持一致
function D.FormatWorldMarkJSON(aData)
	if not X.IsTable(aData) or #aData == 0 then
		return ''
	end
	local aText = { '[' }
	for i, pt in ipairs(aData) do
		local nX = tostring(tonumber(pt.x) or 0)
		local nY = tostring(tonumber(pt.y) or 0)
		local nZ = tostring(tonumber(pt.z) or 0)
		local nMark = tostring(tonumber(pt.mark) or i)
		local szLine = string.format('\t{ "x": %s, "y": %s, "z": %s, "mark": %s }', nX, nY, nZ, nMark)
		if i < #aData then
			szLine = szLine .. ','
		end
		table.insert(aText, szLine)
	end
	table.insert(aText, ']')
	return table.concat(aText, '\n')
end

--------------------------------------------------------------------------------
-- 数据编辑界面
--------------------------------------------------------------------------------

function D.OpenEditPanel(rec)
	local FRAME_NAME = 'MY_YunWorldMark_LocalData_Edit'
	X.UI.CloseFrame(FRAME_NAME)

	local bEdit = rec and rec.key
	local me = X.GetClientPlayer()
	local dwDefaultMapID = (rec and rec.dwMapID) or (me and me.GetMapID()) or 0

	local tMapName, aMapSource, tMapMenu = {}, {}, {}
	for _, group in ipairs(X.GetTypeGroupMap()) do
		local tSub = { szOption = group.szGroup }
		for _, info in ipairs(group.aMapInfo) do
			table.insert(tSub, {
				szOption = info.szName,
				fnAction = function()
					D.nEditMapID = info.dwID
					D.uiEditMap:Text(info.szName)
					X.UI.ClosePopupMenu()
				end,
			})
			tMapName[info.dwID] = info.szName
			table.insert(aMapSource, { text = info.szName, dwID = info.dwID })
		end
		table.insert(tMapMenu, tSub)
	end

	D.nEditMapID = dwDefaultMapID

	local ui = X.UI.CreateFrame(FRAME_NAME, {
		w = 684,
		h = 468,
		close = true,
		text = bEdit and _L['Edit local data'] or _L['Add local data'],
		anchor = { s = 'CENTER', r = 'CENTER', x = 0, y = -100 },
	})

	local nX, nY = 30, 60
	local nLabelW = 80
	local nInputW = 534
	local nLineH = 35

	-- 数据地图
	ui:Append('Text', { x = nX, y = nY, w = nLabelW, h = 25, text = _L['Map'] .. ':' })
	D.uiEditMap = ui:Append('WndAutocomplete', {
		name = 'WndAutocomplete_Map',
		x = nX + nLabelW,
		y = nY,
		w = nInputW,
		h = 25,
		text = tMapName[dwDefaultMapID] or '',
		placeholder = _L['Current map'],
		autocomplete = {
			{
				'option', 'source', aMapSource,
			},
			{
				'option', 'afterComplete', function(raw)
					if raw and raw.dwID then
						D.nEditMapID = raw.dwID
					end
				end,
			},
		},
		menu = function() return tMapMenu end,
	})
	nY = nY + nLineH

	-- 数据标题
	ui:Append('Text', { x = nX, y = nY, w = nLabelW, h = 25, text = _L['Title'] .. ':' })
	local uiTitle = ui:Append('WndEditBox', {
		name = 'WndEditBox_Title',
		x = nX + nLabelW,
		y = nY,
		w = nInputW,
		h = 25,
		text = (rec and rec.szName) or '',
		placeholder = _L['Data title'],
	})
	nY = nY + nLineH

	-- 数据作者
	ui:Append('Text', { x = nX, y = nY, w = nLabelW, h = 25, text = _L['Author'] .. ':' })
	local uiAuthor = ui:Append('WndEditBox', {
		name = 'WndEditBox_Author',
		x = nX + nLabelW,
		y = nY,
		w = nInputW,
		h = 25,
		text = (rec and rec.szAuthor) or (me and me.szName) or '',
		placeholder = _L['Data author'],
	})
	nY = nY + nLineH

	-- 数据内容
	ui:Append('Text', { x = nX, y = nY, w = nLabelW, h = 25, text = _L['Content'] .. ':' })
	local uiContent = ui:Append('WndEditBox', {
		name = 'WndEditBox_Content',
		x = nX + nLabelW,
		y = nY,
		w = nInputW,
		h = 250,
		multiline = true,
		text = (rec and rec.aData and D.FormatWorldMarkJSON(rec.aData)) or '',
		placeholder = _L['World mark json data'],
	})
	nY = nY + 260

	-- 确认按钮
	ui:Append('WndButton', {
		name = 'Btn_Confirm',
		x = 292,
		y = nY,
		w = 100,
		h = 30,
		text = _L['Confirm'],
		onClick = function()
			local szTitle = uiTitle:Text()
			local szAuthor = uiAuthor:Text()
			local szContent = uiContent:Text()

			if X.IsEmpty(szTitle) then
				X.OutputAnnounceMessage(_L['Please input title.'])
				return
			end

			local aData = nil
			if not X.IsEmpty(szContent) then
				aData = X.DecodeJSON(szContent)
				if not X.IsTable(aData) then
					X.OutputAnnounceMessage(_L('Decode %s failed!', _L['World mark']))
					return
				end
			end

			local info = {
				key = (rec and rec.key) or nil,
				szName = szTitle,
				szAuthor = szAuthor,
				aData = aData,
				dwMapID = D.nEditMapID,
			}

			if bEdit then
				D.Update(info)
			else
				D.Add(info, D.nEditMapID)
			end

			X.UI.CloseFrame(FRAME_NAME)
		end,
	})
end

--------------------------------------------------------------------------------
-- 界面逻辑
--------------------------------------------------------------------------------

function D.Search(page)
	if not page or not page:IsValid() then
		return
	end
	local ui = X.UI(page)
	local szSearch = X.TrimString(ui:Fetch('WndEditBox_Search'):Text() or ''):lower()
	local dwMapID = D.dwMapID or 0

	local aLocalData = D.Load()
	local aDataSource = {}
	for _, rec in ipairs(aLocalData) do
		local bMatchMap = (dwMapID == 0) or (rec.dwMapID == dwMapID)
		local bMatchSearch = X.IsEmpty(szSearch)
			or (rec.szName and rec.szName:lower():find(szSearch, 1, true))
			or (rec.szAuthor and rec.szAuthor:lower():find(szSearch, 1, true))
			or (rec.key and rec.key:lower():find(szSearch, 1, true))
		if bMatchMap and bMatchSearch then
			table.insert(aDataSource, rec)
		end
	end
	ui:Fetch('WndTable_List'):DataSource(aDataSource)
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
	table.insert(tMapMenu, {
		szOption = _L['All maps'],
		fnAction = function()
			D.dwMapID = 0
			ui:Fetch('WndAutocomplete_Map'):Text('')
			X.UI.ClosePopupMenu()
			D.Search(page)
		end,
	})
	for _, group in ipairs(X.GetTypeGroupMap()) do
		local tSub = { szOption = group.szGroup }
		for _, info in ipairs(group.aMapInfo) do
			table.insert(tSub, {
				szOption = info.szName,
				fnAction = function()
					D.dwMapID = info.dwID
					ui:Fetch('WndAutocomplete_Map'):Text(info.szName)
					X.UI.ClosePopupMenu()
					D.Search(page)
				end,
			})
			tMapName[info.dwID] = info.szName
			table.insert(aMapSource, { text = info.szName, dwID = info.dwID })
		end
		table.insert(tMapMenu, tSub)
	end
	local szCurrentMapName = tMapName[D.dwMapID] or ''

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
					else
						D.dwMapID = 0
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
		placeholder = _L['Filter local data'],
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

	ui:Append('WndButton', {
		name = 'Btn_Add',
		x = nX,
		y = nY,
		w = 35,
		h = COMPONENT_H,
		text = '+',
		onClick = function()
			D.OpenEditPanel()
		end,
	})

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
			local szUpdateTime = ''
			if rec and rec.dwUpdateTime then
				szUpdateTime = X.FormatRelativeTime(rec.dwUpdateTime)
			end
			local a = {
				_L['Key'] .. ': ' .. tostring(rec and rec.key or ''),
				_L['Name'] .. ': ' .. tostring(rec and rec.szName or ''),
				_L['Author'] .. ': ' .. tostring(rec and rec.szAuthor or ''),
				_L['Update time'] .. ': ' .. szUpdateTime,
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
					szOption = _L['Edit data'],
					fnAction = function()
						D.OpenEditPanel(rec)
					end,
				},
				{
					szOption = _L['Delete data'],
					fnAction = function()
						D.Remove(rec)
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
					local szTime = ''
					if value then
						szTime = X.FormatRelativeTime(value)
					end
					return GetFormatText(' ' .. szTime, 162, 255, 255, 255)
				end,
			},
			{
				key = 'use',
				title = _L['Action'],
				alignHorizontal = 'center',
				width = 80,
				render = function(_, record)
					return GetFormatText(_L['Use'], 162, 255, 255, 0, 255, 'this.rec = ' .. X.EncodeLUAData(record), 'Text_Use_Local')
				end,
			},
		},
		dataSource = {},
	})

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_YUN_WORLD_MARK__LOCAL_DATA__LIST_UPDATE')

	D.Search(page)
	D.OnResizePage()
end

function D.OnActivePage()
	D.Search(this)
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
	local nAddW = 35
	-- 搜索框动态宽度
	local nSearchW = nW - nPadding - nMapW - nGap - nGap - nBtnW - nGap - nAddW - nPadding
	if nSearchW < 100 then
		nSearchW = 100
	end
	ui:Fetch('WndEditBox_Search'):Size(nSearchW, 25)
	-- 按钮位置
	ui:Fetch('Btn_Search'):Pos(nPadding + nMapW + nGap + nSearchW + nGap, 10)
	ui:Fetch('Btn_Add'):Pos(nPadding + nMapW + nGap + nSearchW + nGap + nBtnW + nGap, 10)
	-- 列表动态宽高
	ui:Fetch('WndTable_List'):Size(nW - 40, nH - 70)
end

function D.OnEvent(event)
	if event == 'MY_YUN_WORLD_MARK__LOCAL_DATA__LIST_UPDATE' then
		D.Search(this)
	end
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Text_Use_Local' then
		if not X.IsClientPlayerTeamMarker() then
			X.OutputAnnounceMessage(_L['Only team marker can do this.'])
			return
		end
		local rec = this.rec
		if not rec or not rec.aData then
			X.OutputAnnounceMessage(_L['No data.'])
			return
		end
		-- 直接应用本地数据，不拉取远端
		MY_YunWorldMark.ApplyWorldMark(rec.aData)
	end
end

--------------------------------------------------------------------------------
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_LocalData',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OnInitPage',
				'OnActivePage',
				'OnResizePage',
				'OnDeactivePage',
				'OnEvent',
				'OnItemLButtonClick',
			},
			root = D,
		},
	},
}
MY_YunWorldMark.RegisterModule('LocalData', _L['Local data'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_LocalData',
	exports = {
		{
			root = D,
			fields = {
				'Load',
				'Save',
				'Add',
				'Update',
				'Remove',
				'IsInLocalData',
				'OpenEditPanel',
			},
			preset = 'UIEvent',
		},
	},
}
MY_YunWorldMark_LocalData = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
