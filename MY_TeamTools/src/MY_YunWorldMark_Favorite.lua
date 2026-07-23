--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 云世界标记 - 收藏列表
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamTools/MY_YunWorldMark_Favorite'
local PLUGIN_NAME = 'MY_TeamTools'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_YunWorldMark'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^29.0.10') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local INI_PATH = X.PACKET_INFO.ROOT .. PLUGIN_NAME .. '/ui/MY_YunWorldMark_Subscribe.ini'
local D = {}

local USE_DISABLE_MS = 1000
local USE_COLOR_ACTIVE = { 255, 255, 0 }
local USE_COLOR_DISABLED = { 128, 128, 128 }

--------------------------------------------------------------------------------
-- 收藏数据管理
--------------------------------------------------------------------------------

function D.Load()
	return X.LoadLUAData({'userdata/yun_world_mark/favorite.jx3dat', X.PATH_TYPE.GLOBAL}) or {}
end

function D.Save(aFavorite)
	X.SaveLUAData({'userdata/yun_world_mark/favorite.jx3dat', X.PATH_TYPE.GLOBAL}, aFavorite)
	FireUIEvent('MY_YUN_WORLD_MARK__FAVORITE__LIST_UPDATE')
end

function D.Add(info, dwMapID)
	if not info or not info.key then
		return
	end
	-- 如果没有传入地图ID，尝试获取当前地图
	if not dwMapID then
		local me = X.GetClientPlayer()
		if me then
			dwMapID = me.GetMapID() or 0
		end
	end
	local aFavorite = D.Load()
	-- 移除已存在的相同 key
	for i, p in X.ipairs_r(aFavorite) do
		if p.key == info.key then
			table.remove(aFavorite, i)
		end
	end
	-- 保存地图信息
	local rec = X.Clone(info)
	rec.dwMapID = dwMapID or 0
	table.insert(aFavorite, rec)
	D.Save(aFavorite)
	X.OutputAnnounceMessage(_L['Added to favorites.'])
end

function D.Remove(info)
	if not info or not info.key then
		return
	end
	X.Confirm(_L['Confirm?'], function()
		local aFavorite = D.Load()
		for i, p in X.ipairs_r(aFavorite) do
			if p.key == info.key then
				table.remove(aFavorite, i)
			end
		end
		D.Save(aFavorite)
	end)
end

function D.IsFavorited(info)
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

	local aFavorite = D.Load()
	local aDataSource = {}
	for _, rec in ipairs(aFavorite) do
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
		placeholder = _L['Filter favorites'],
		onSpecialKeyDown = function(_, szKey)
			if szKey == 'Enter' then
				D.Search(page)
				return 1
			end
		end,
	}):Width() + 5

	ui:Append('WndButton', {
		name = 'Btn_Search',
		x = nX,
		y = nY,
		w = 100,
		h = COMPONENT_H,
		text = _L['Search'],
		onClick = function()
			D.Search(page)
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
					szOption = _L['Remove from favorites'],
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
				title = _L('Update time'),
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

	local frame = this:GetRoot()
	frame:RegisterEvent('MY_YUN_WORLD_MARK__FAVORITE__LIST_UPDATE')

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

function D.OnEvent(event)
	if event == 'MY_YUN_WORLD_MARK__FAVORITE__LIST_UPDATE' then
		D.Search(this)
	end
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
-- 模块导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_Favorite',
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
MY_YunWorldMark.RegisterModule('Favorite', _L['Favorite list'], X.CreateModule(settings))
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_YunWorldMark_Favorite',
	exports = {
		{
			root = D,
			fields = {
				'Load',
				'Save',
				'Add',
				'Remove',
				'IsFavorited',
			},
			preset = 'UIEvent',
		},
	},
}
MY_YunWorldMark_Favorite = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
