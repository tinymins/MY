--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录 拾取界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKPLoot'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
X.RegisterRestriction('MY_GKPLoot.FastLoot', { ['*'] = true })
X.RegisterRestriction('MY_GKPLoot.ForceLootOutsideDungeon', { ['*'] = true })
X.RegisterRestriction('MY_GKPLoot.ForceLootInsideDungeon', { ['*'] = false, classic = true })
X.RegisterRestriction('MY_GKPLoot.ForceTryAutoLoot', { ['*'] = true })
X.RegisterRestriction('MY_GKPLoot.ShowUndialogable', { ['*'] = true })
--------------------------------------------------------------------------

local DEBUG_LOOT = false -- 测试拾取分配 强制进入分配模式并最终不调用分配接口
local GKP_LOOT_INIFILE = PLUGIN_ROOT .. '/ui/MY_GKPLoot.ini'
local MY_GKP_LOOT_BOSS -- 散件老板
local GKP_AUTO_LOOT_DEBOUNCE_TIME = X.ENVIRONMENT.GAME_FPS / 2 -- 自动拾取时延

local GKP_LOOT_HUANGBABA_ICON = 2589 -- 玄晶图标
local GKP_LOOT_HUANGBABA_QUALITY = X.CONSTANT.ITEM_QUALITY.NACARAT -- 玄晶品级
local GKP_LOOT_ZIBABA_ICON = 2588 -- 小铁图标
local GKP_LOOT_ZIBABA_QUALITY = X.CONSTANT.ITEM_QUALITY.PURPLE -- 小铁品级

local GKP_LOOT_RECENT = {} -- 记录上次物品或物品组分配给了谁
local GKP_ITEM_QUALITIES = {
	{ nQuality = X.CONSTANT.ITEM_QUALITY.GRAY   , szTitle = g_tStrings.STR_GRAY                },
	{ nQuality = X.CONSTANT.ITEM_QUALITY.WHITE  , szTitle = g_tStrings.STR_WHITE               },
	{ nQuality = X.CONSTANT.ITEM_QUALITY.GREEN  , szTitle = g_tStrings.STR_ROLLQUALITY_GREEN   },
	{ nQuality = X.CONSTANT.ITEM_QUALITY.BLUE   , szTitle = g_tStrings.STR_ROLLQUALITY_BLUE    },
	{ nQuality = X.CONSTANT.ITEM_QUALITY.PURPLE , szTitle = g_tStrings.STR_ROLLQUALITY_PURPLE  },
	{ nQuality = X.CONSTANT.ITEM_QUALITY.NACARAT, szTitle = g_tStrings.STR_ROLLQUALITY_NACARAT },
}

local O = X.CreateUserSettingsModule('MY_GKPLoot', _L['General'], {
	bOn = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Enable MY_GKPLoot'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bInTeamDungeon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Team dungeon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bInRaidDungeon = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Raid dungeon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bInBattlefield = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Battlefield'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bInOtherMap = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Other map'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	anchor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['UI Anchor'],
		}),
		xSchema = X.Schema.FrameAnchor,
		xDefaultValue = { x = 0, y = 0, s = 'CENTER', r = 'CENTER' },
	},
	bVertical = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['switch styles'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSetColor = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Set Force Color'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	nConfirmQuality = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Confirm when distribute'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 3,
	},
	bShow2ndKungfuLoot = { -- 显示第二心法装备推荐提示图标
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Show 2nd kungfu fit icon'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bSortLoot = { -- 按照价值高低排序掉落物品
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Sort loot list by weight'],
		}),
		szVersion = '20241113',
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tConfirm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Confirm when distribute'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {
			Huangbaba  = true,
			Book       = true,
			Pendant    = true,
			Outlook    = true,
			Pet        = true,
			Horse      = true,
			HorseEquip = true,
		},
	},
	tFilterQuality = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Loot item filter'],
			_L['Quality filter'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Boolean),
		xDefaultValue = {
			[X.CONSTANT.ITEM_QUALITY.GRAY] = true,
		},
	},
	bNameFilter = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Loot item filter'],
			_L['Name filter'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tNameFilter = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Loot item filter'],
			_L['Name filter list'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
	bFilterBookRead = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Loot item filter'],
			_L['Filter book read'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bFilterBookHave = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Loot item filter'],
			_L['Filter book have'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoPickupFilterBookRead = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Filter book read'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoPickupFilterBookHave = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Filter book have'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoPickupTaskItem = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup quest item'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoPickupBook = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup book'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bAutoPickupQuality = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup by item quality'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	tAutoPickupQuality = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup by item quality data'],
		}),
		xSchema = X.Schema.Map(X.Schema.Number, X.Schema.Boolean),
		xDefaultValue = (function()
			local t = {}
			for _, p in ipairs(GKP_ITEM_QUALITIES) do
				t[p.nQuality] = true
			end
			return t
		end)(),
	},
	tAutoPickupNames = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup names'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
	tAutoPickupFilters = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_GKPLoot'],
		szDescription = X.MakeCaption({
			_L['Auto pickup'],
			_L['Auto pickup filters'],
		}),
		xSchema = X.Schema.Map(X.Schema.String, X.Schema.Boolean),
		xDefaultValue = {},
	},
})
local D = {
	aDoodadID = {},
	tDoodadInfo = {},
	tDoodadClosed = {},
}
local ITEM_CONFIG = setmetatable({}, {
	__index = function(_, k)
		if k == 'tNameFilter'
			or k == 'bFilterBookRead'
			or k == 'bFilterBookHave'
			or k == 'tFilterQuality'
			or k == 'bNameFilter'
			or k == 'bAutoPickupFilterBookRead'
			or k == 'bAutoPickupFilterBookHave'
			or k == 'bAutoPickupTaskItem'
			or k == 'bAutoPickupBook'
			or k == 'bAutoPickupQuality'
			or k == 'tAutoPickupQuality'
			or k == 'tAutoPickupNames'
			or k == 'tAutoPickupFilters'
		then
			return O[k]
		end
		if k == 'bHideFiltered'
		then
			return D[k]
		end
	end,
	__newindex = function(_, k, v)
		if k == 'tNameFilter'
			or k == 'bFilterBookRead'
			or k == 'bFilterBookHave'
			or k == 'tFilterQuality'
			or k == 'bNameFilter'
			or k == 'bAutoPickupFilterBookRead'
			or k == 'bAutoPickupFilterBookHave'
			or k == 'bAutoPickupTaskItem'
			or k == 'bAutoPickupBook'
			or k == 'bAutoPickupQuality'
			or k == 'tAutoPickupQuality'
			or k == 'tAutoPickupNames'
			or k == 'tAutoPickupFilters'
		then
			O[k] = v
		elseif k == 'bHideFiltered'
		then
			D[k] = v
		end
	end,
})

function D.UpdateShielded()
	GKP_AUTO_LOOT_DEBOUNCE_TIME = X.IsRestricted('MY_GKPLoot.FastLoot')
		and X.ENVIRONMENT.GAME_FPS / 2
		or 0
end

function D.InsertSceneLoot()
	local GetInfo = X.GetGameAPI('GoldTeamBase_GetAllBiddingInfos')
	local aInfo = GetInfo and GetInfo()
	if not aInfo then
		return
	end
	local aDoodadInfo, tDoodadID = {}, {}
	for _, v in ipairs(aInfo) do
		if not tDoodadID[v.dwDoodadID] then
			table.insert(aDoodadInfo, {
				dwDoodadID = v.dwDoodadID,
				dwNpcTemplateID = v.dwNpcTemplateID,
			})
			tDoodadID[v.dwDoodadID] = true
		end
	end
	for _, v in ipairs(aDoodadInfo) do
		if not D.tDoodadInfo[v.dwDoodadID] then
			D.tDoodadInfo[v.dwDoodadID] = {
				dwID   = v.dwDoodadID,
				szName = X.GetNpcTemplateName(v.dwNpcTemplateID) or '',
			}
		end
		D.InsertLootList(v.dwDoodadID)
	end
end

function D.IsEnabled()
	if not D.bReady then
		return false
	end
	if not O.bOn then
		return false
	end
	if O.bInTeamDungeon and O.bInRaidDungeon and O.bInBattlefield and O.bInOtherMap then
		return true
	end
	if X.IsInDungeonMap(false) then
		return O.bInTeamDungeon
	end
	if X.IsInDungeonMap(true) then
		return O.bInRaidDungeon
	end
	if X.IsInBattlefieldMap() or X.IsInPubgMap() or X.IsInZombieMap() then
		return O.bInBattlefield
	end
	return O.bInOtherMap
end

function D.OutputEnable()
	X.OutputSystemAnnounceMessage(
		D.IsEnabled()
			and _L['MY_GKPLoot enabled in current map']
			or _L['MY_GKPLoot disabled in current map']
	)
end

function D.CanDialog(tar, dwDoodadID)
	local doodad = X.GetDoodad(dwDoodadID)
	return doodad and doodad.CanDialog(tar)
end

function D.IsItemDisplay(itemData, config)
	-- 按品质过滤
	if X.IsTable(config.tFilterQuality) and config.tFilterQuality[itemData.nQuality] then
		return false
	end
	-- 名称过滤
	if config.bNameFilter then
		if config.tNameFilter[itemData.szName] then
			return false
		end
		for k, v in pairs(config.tNameFilter) do
			if v and k:sub(1, 1) == '^' and itemData.szName:find(k) then
				return false
			end
		end
	end
	-- 过滤已读、已有书籍
	if (config.bFilterBookRead or config.bFilterBookHave) and itemData.nGenre == ITEM_GENRE.BOOK then
		local me = X.GetClientPlayer()
		if config.bFilterBookRead then
			local nBookID, nSegmentID = X.RecipeToSegmentID(itemData.nBookID)
			if me and me.IsBookMemorized(nBookID, nSegmentID) then
				return false
			end
		end
		if config.bFilterBookHave then
			local nAmount = X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.PACKAGE, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
				+ X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.BANK, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
			if nAmount > 0 then
				return false
			end
		end
	end
	return true
end

function D.IsItemAutoPickup(itemData, config, doodadData, bCanDialog)
	if not bCanDialog then
		return false
	end
	-- 超过可拾取上限则不捡
	local itemInfo = GetItemInfo(itemData.dwTabType, itemData.dwIndex)
	if itemInfo and itemInfo.nMaxExistAmount > 0 then
		local nAmount = X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.PACKAGE, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
			+ X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.BANK, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
		if nAmount + itemData.nStackNum > itemInfo.nMaxExistAmount then
			return false
		end
	end

	-- 不拾取已读、已有书籍
	if (config.bAutoPickupFilterBookRead or config.bAutoPickupFilterBookHave) and itemData.nGenre == ITEM_GENRE.BOOK then
		local me = X.GetClientPlayer()
		if config.bAutoPickupFilterBookRead then
			local nBookID, nSegmentID = X.RecipeToSegmentID(itemData.nBookID)
			if me and me.IsBookMemorized(nBookID, nSegmentID) then
				return false
			end
		end
		if config.bAutoPickupFilterBookHave then
			local nAmount = X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.PACKAGE, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
				+ X.GetInventoryItemAmount(X.CONSTANT.INVENTORY_TYPE.BANK, itemData.dwTabType, itemData.dwIndex, itemData.nBookID)
			if nAmount > 0 then
				return false
			end
		end
	end
	-- 自动拾取书籍
	if config.bAutoPickupBook and itemData.nGenre == ITEM_GENRE.BOOK then
		return true
	end
	-- 自动拾取过滤
	if config.tAutoPickupFilters and config.tAutoPickupFilters[itemData.szName] then
		return false
	end
	-- 自动拾取名单
	if config.tAutoPickupNames and config.tAutoPickupNames[itemData.szName] then
		return true
	end
	-- 自动拾取任务物品
	if config.bAutoPickupTaskItem and itemData.nGenre == ITEM_GENRE.TASK_ITEM then
		return true
	end
	-- 自动拾取品级
	if config.bAutoPickupQuality and config.tAutoPickupQuality[itemData.nQuality] then
		return true
	end
	return false
end

function D.CloseLootWindow()
	local me = X.GetClientPlayer()
	if me and X.GetCharacterOTActionState(me) == X.CONSTANT.CHARACTER_OTACTION_TYPE.ACTION_PICKING then
		me.OnCloseLootWindow()
	end
end

function D.OnFrameCreate()
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('PARTY_LOOT_MODE_CHANGED')
	this:RegisterEvent('PARTY_DISBAND')
	this:RegisterEvent('PARTY_DELETE_MEMBER')
	this:RegisterEvent('DOODAD_LEAVE_SCENE')
	this:RegisterEvent('MY_GKP_LOOT_RELOAD')
	this:RegisterEvent('MY_GKP_LOOT_BOSS')
	local a = O.anchor
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	this:Lookup('Scroll_DoodadList/WndContainer_DoodadList'):Clear()
	X.UI.AdaptComponentAppearance(this:Lookup('Scroll_DoodadList/ScrolBar_DoodadList'))
	D.AdjustFrame(this)
end

function D.OnFrameBreathe()
	local nLFC = GetLogicFrameCount()
	local me = X.GetClientPlayer()
	local container = this:Lookup('Scroll_DoodadList/WndContainer_DoodadList')
	local wnd = container:LookupContent(0)
	local bRemoveUndialogable = X.IsInPubgMap() and X.IsRestricted('MY_GKPLoot.ShowUndialogable')
	while wnd do
		local doodadData = wnd.doodadData
		-- 拾取判定
		local bCanDialog = D.CanDialog(me, doodadData.dwID)
		local hList, hItem = wnd:Lookup('', 'Handle_ItemList')
		for i = 0, hList:GetItemCount() - 1 do
			hItem = hList:Lookup(i)
			if (not hItem.nAutoLootLFC or nLFC - hItem.nAutoLootLFC >= GKP_AUTO_LOOT_DEBOUNCE_TIME)
			and hItem:GetName() == 'Handle_Item'
			and not hItem.itemData.bDist and not hItem.itemData.bNeedRoll and not hItem.itemData.bBidding
			and (
				D.IsItemAutoPickup(
					hItem.itemData,
					ITEM_CONFIG,
					doodadData,
					bCanDialog or ((not X.IsRestricted('MY_GKPLoot.ForceTryAutoLoot') and not hItem.itemData.bAutoLooted))
				)
			)
			then
				X.ExecuteWithThis(hItem, D.OnItemLButtonClick)
				hItem.itemData.bAutoLooted = true
				hItem.nAutoLootLFC = nLFC
			end
		end
		wnd:Lookup('', 'Image_DoodadTitleBg'):SetFrame(bCanDialog and 0 or 3)
		-- 目标距离
		local nDistance = -1
		if me and doodadData.nX and doodadData.nY then
			nDistance = math.floor(math.sqrt(math.pow(me.nX - doodadData.nX, 2) + math.pow(me.nY - doodadData.nY, 2)) * 10 / 64) / 10
		end
		if nDistance == -1 then
			wnd:Lookup('', 'Handle_Compass'):Hide()
		else
			wnd:Lookup('', 'Handle_Compass'):Show()
			wnd:Lookup('', 'Handle_Compass/Compass_Distance'):SetText(nDistance < 4 and '' or nDistance .. '"')
			-- 自身面向
			if me then
				wnd:Lookup('', 'Handle_Compass/Image_Player'):Show()
				wnd:Lookup('', 'Handle_Compass/Image_Player'):SetRotate( - me.nFaceDirection / 128 * math.pi)
			end
			-- 物品位置
			local nRotate, nRadius = 0, 10.125
			if me and nDistance > 0 then
				-- 特判角度
				if me.nX == doodadData.nX then
					if me.nY > doodadData.nY then
						nRotate = math.pi / 2
					else
						nRotate = - math.pi / 2
					end
				else
					nRotate = math.atan((me.nY - doodadData.nY) / (me.nX - doodadData.nX))
				end
				if nRotate < 0 then
					nRotate = nRotate + math.pi
				end
				if doodadData.nY < me.nY then
					nRotate = math.pi + nRotate
				end
			end
			local nX = nRadius + nRadius * math.cos(nRotate) + 2
			local nY = nRadius - 3 - nRadius * math.sin(nRotate)
			wnd:Lookup('', 'Handle_Compass/Image_PointGreen'):SetRelPos(nX, nY)
			wnd:Lookup('', 'Handle_Compass'):FormatAllItemPos()
		end
		-- 移除不可交互的掉落
		if bRemoveUndialogable and not bCanDialog then
			D.RemoveLootList(wnd.doodadData.dwID)
		end
		wnd = wnd:GetNext()
	end
end

function D.OnEvent(szEvent)
	if szEvent == 'DOODAD_LEAVE_SCENE' then
		if X.IsInDungeonMap() then
			return
		end
		D.RemoveLootList(arg0)
	elseif szEvent == 'PARTY_LOOT_MODE_CHANGED' then
		if arg1 ~= PARTY_LOOT_MODE.DISTRIBUTE then
			-- X.UI.CloseFrame(this)
		end
	elseif szEvent == 'PARTY_DISBAND' or szEvent == 'PARTY_DELETE_MEMBER' then
		if szEvent == 'PARTY_DELETE_MEMBER' and arg1 ~= X.GetClientPlayerID() then
			return
		end
		D.CloseFrame()
	elseif szEvent == 'UI_SCALED' then
		local a = this.anchor or O.anchor
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	elseif szEvent == 'MY_GKP_LOOT_RELOAD' or szEvent == 'MY_GKP_LOOT_BOSS' then
		D.ReloadFrame()
	end
end

function D.OnFrameDragEnd()
	this:CorrectPos()
	this.anchor = GetFrameAnchor(this, 'LEFTTOP')
	O.anchor = this.anchor
end

function D.OnFrameDragSetPosEnd()
	this:CorrectPos()
end

function D.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Mini' then
		D.AdjustWnd(this:GetParent())
		D.AdjustFrame(this:GetRoot())
	end
end

function D.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Mini' then
		D.AdjustWnd(this:GetParent())
		D.AdjustFrame(this:GetRoot())
	end
end

function D.OnMouseEnter()
	local name = this:GetName()
	if name == 'Btn_Boss' then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local szXml = ''
		local dwDoodadID = this:GetParent().doodadData.dwID
		local aPartyMember = D.GetaPartyMember(dwDoodadID)
		local p = MY_GKP_LOOT_BOSS and aPartyMember(MY_GKP_LOOT_BOSS)
		if p then
			local r, g, b = X.GetForceColor(p.dwForceID)
			szXml = szXml .. GetFormatText(_L['LClick to distrubute all equipment to '], 136)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			szXml = szXml .. GetFormatText(_L['.'] .. '\n' .. _L['Ctrl + LClick to distrubute all lootable items to '], 136)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			szXml = szXml .. GetFormatText(_L['.'] .. '\n' .. _L['RClick to reselect Equipment Boss.'], 136)
		elseif MY_GKP_LOOT_BOSS then
			szXml = szXml .. GetFormatText(_L['LClick to distrubute all equipment to Equipment Boss.'] .. '\n', 136)
			szXml = szXml .. GetFormatText(_L['Ctrl + LClick to distrubute all lootable items to Equipment Boss.'] .. '\n', 136)
			szXml = szXml .. GetFormatText(_L['RClick to reselect Equipment Boss.'], 136)
		else
			szXml = szXml .. GetFormatText(_L['Click to select Equipment Boss.'], 136)
		end
		OutputTip(szXml, 450, {x, y, w, h}, ALW.TOP_BOTTOM)
	end
end

function D.OnMouseLeave()
	local name = this:GetName()
	if name == 'Btn_Boss' then
		HideTip()
	end
end

function D.OnLButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Close' then
		if IsCtrlKeyDown() then
			D.CloseFrame()
			D.aDoodadID = {}
			D.tDoodadInfo = {}
		else
			D.RemoveLootList(this:GetParent().doodadData.dwID, true)
		end
	elseif szName == 'Btn_Style' then
		local wnd = this:GetParent()
		local dwDoodadID = wnd.doodadData.dwID
		local menu = {
			{
				szOption = _L['Link All Item'],
				fnAction = function()
					local aItemData = D.GetDoodadLootInfo(dwDoodadID)
					local t = {}
					for k, v in ipairs(aItemData) do
						table.insert(t, MY_GKP.GetFormatLink(v.item))
					end
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, t)
				end,
			},
			X.CONSTANT.MENU_DIVIDER,
			{
				szOption = _L['switch styles'],
				fnAction = function()
					O.bVertical = not O.bVertical
					FireUIEvent('MY_GKP_LOOT_RELOAD')
				end,
			},
			X.CONSTANT.MENU_DIVIDER,
			D.GetFilterMenu(),
			D.GetAutoPickupMenu(),
			X.CONSTANT.MENU_DIVIDER,
			{
				szOption = _L['Config'],
				fnAction = function()
					X.Panel.Show()
					X.Panel.SwitchTab('MY_GKPDoodad')
				end,
			},
			{
				szOption = _L['About'],
				fnAction = function()
					X.Alert(_L['GKP_TIPS'])
				end,
			},
		}
		if IsCtrlKeyDown() then
			table.insert(menu, 1, { szOption = dwDoodadID, bDisable = true })
		end
		X.UI.PopupMenu(menu)
	elseif szName == 'Btn_Boss' then
		if not D.AuthCheck(this:GetParent().doodadData.dwID) then
			return X.OutputAnnounceMessage(_L['You are not the distrubutor.'])
		end
		D.GetBossAction(this:GetParent().doodadData.dwID, type(MY_GKP_LOOT_BOSS) == 'nil')
	end
end

function D.OnRButtonClick()
	local szName = this:GetName()
	if szName == 'Btn_Boss' then
		D.GetBossAction(this:GetParent().doodadData.dwID, true)
	end
end

function D.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == 'Handle_Item' then
		this = this:Lookup('Box_Item')
		this.OnItemLButtonDown()
	end
end

function D.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == 'Handle_Item' then
		this = this:Lookup('Box_Item')
		this.OnItemLButtonUp()
	end
end

function D.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' or szName == 'Handle_FilterItem' or szName == 'Box_FilterItem' then
		local hItem = (szName == 'Handle_Item' or szName == 'Handle_FilterItem') and this or this:GetParent()
		local box   = hItem:Lookup('Box_Item') or hItem:Lookup('Box_FilterItem')
		if IsAltKeyDown() and not IsCtrlKeyDown() and not IsShiftKeyDown() then
			X.OutputTip(this, X.EncodeLUAData(hItem.itemData, '  ') .. '\n' .. X.EncodeLUAData({
				nUiId = hItem.itemData.item.nUiId,
				dwID = hItem.itemData.item.dwID,
				nGenre = hItem.itemData.item.nGenre,
				nSub = hItem.itemData.item.nSub,
				nDetail = hItem.itemData.item.nDetail,
				nLevel = hItem.itemData.item.nLevel,
				nPrice = hItem.itemData.item.nPrice,
				dwScriptID = hItem.itemData.item.dwScriptID,
				nMaxDurability = hItem.itemData.item.nMaxDurability,
				nMaxExistAmount = hItem.itemData.item.nMaxExistAmount,
				nMaxExistTime = hItem.itemData.item.nMaxExistTime,
				bCanTrade = hItem.itemData.item.bCanTrade,
				bCanDestory = hItem.itemData.item.bCanDestory,
				szName = hItem.itemData.item.szName,
			}, '  '))
		elseif szName == 'Handle_Item' then
			X.ExecuteWithThis(box, box.OnItemMouseEnter)
		end
		-- local item = hItem.itemData.item
		-- if itme and item.nGenre == ITEM_GENRE.EQUIPMENT then
		-- 	if itme.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON then
		-- 		this:SetOverText(3, g_tStrings.WeapenDetail[item.nDetail])
		-- 	else
		-- 		this:SetOverText(3, g_tStrings.tEquipTypeNameTable[item.nSub])
		-- 	end
		-- end
	elseif szName == 'Image_GroupDistrib' then
		local hItem = this:GetParent()
		local hList = hItem:GetParent()
		for i = 0, hList:GetItemCount() - 1 do
			local h = hList:Lookup(i)
			if h:GetName() == 'Handle_Item' then
				h:Lookup('Shadow_Highlight'):SetVisible(h.itemData.szType == hItem.itemData.szType)
			end
		end
		X.OutputTip(hItem, GetFormatText(_L['Onekey distrib this group'], 136), true)
	end
end

function D.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' then
		if szName == 'Handle_Item' then
			local box = this:Lookup('Box_Item')
			if box and box.OnItemMouseLeave then
				X.ExecuteWithThis(box, box.OnItemMouseLeave)
			end
		end
		-- if this and this:IsValid() and this.SetOverText then
		-- 	this:SetOverText(3, '')
		-- end
	elseif szName == 'Image_GroupDistrib' then
		local hItem = this:GetParent()
		local hList = hItem:GetParent()
		for i = 0, hList:GetItemCount() - 1 do
			hList:Lookup(i):Lookup('Shadow_Highlight'):Hide()
		end
		HideTip()
	end
end

-- 分配菜单
function D.OnItemLButtonClick()
	local szName = this:GetName()
	if IsCtrlKeyDown() or IsAltKeyDown() then
		return
	end
	if szName == 'Handle_Item' or szName == 'Box_Item' or szName == 'Handle_FilterItem' or szName == 'Box_FilterItem' then
		local hItem      = (szName == 'Handle_Item' or szName == 'Handle_FilterItem') and this or this:GetParent()
		local box        = hItem:Lookup('Box_Item') or hItem:Lookup('Box_FilterItem')
		local data       = hItem.itemData
		local me, team   = X.GetClientPlayer(), GetClientTeam()
		local dwDoodadID = data.dwDoodadID
		local doodad     = X.GetDoodad(dwDoodadID)
		if doodad and not data.bDist and not data.bNeedRoll and not data.bBidding then
			if doodad.CanLoot(me.dwID) then
				X.OpenDoodad(me, doodad)
			elseif not doodad.CanDialog(me) then
				X.OutputAnnounceMessage(g_tStrings.TIP_TOO_FAR)
			end
		end
		if data.bDist then
			if not doodad and not (X.IS_REMAKE and X.IsInDungeonMap()) then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('MY_GKPLoot:OnItemLButtonClick', 'Doodad does not exist!', X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				if not X.IsInDungeonMap() then
					D.RemoveLootList(dwDoodadID)
				end
				return
			end
			if not D.AuthCheck(dwDoodadID) then
				return
			end
			return X.UI.PopupMenu(D.GetDistributeMenu(data, data.item.nUiId))
		elseif data.bBidding then
			if team.nLootMode ~= PARTY_LOOT_MODE.BIDDING then
				return OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.GOLD_CHANGE_BID_LOOT)
			end
			X.OutputSystemMessage(_L['GKP does not support bidding, please re open loot list.'])
		elseif data.bNeedRoll then
			X.OutputAnnounceMessage(g_tStrings.ERROR_LOOT_ROLL)
		else -- 左键摸走
			LootItem(dwDoodadID, data.dwID)
		end
		X.DelayCall('MY_GKPLoot__LootDoodad', 150, D.CloseLootWindow)
	elseif szName == 'Image_GroupDistrib' then
		local hItem     = this:GetParent()
		local hList     = hItem:GetParent()
		local aItemData = {}
		for i = 0, hList:GetItemCount() - 1 do
			local h = hList:Lookup(i)
			if h:GetName() == 'Handle_Item' and h.itemData.szType == hItem.itemData.szType then
				table.insert(aItemData, h.itemData)
			end
		end
		for _, data in ipairs(aItemData) do
			local dwDoodadID = data.dwDoodadID
			local doodad     = X.GetDoodad(dwDoodadID)
			if not doodad then
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('MY_GKPLoot:OnItemLButtonClick', 'Doodad does not exist!', X.DEBUG_LEVEL.WARNING)
				--[[#DEBUG END]]
				if not X.IsInDungeonMap() then
					D.RemoveLootList(dwDoodadID)
				end
				return
			end
			if not D.AuthCheck(dwDoodadID) then
				return X.OutputAnnounceMessage(_L['You are not the distrubutor.'])
			end
		end
		return X.UI.PopupMenu(D.GetDistributeMenu(aItemData, hItem.itemData.szType))
	end
end

-- 右键拍卖
function D.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == 'Handle_Item' or szName == 'Box_Item' or szName == 'Handle_FilterItem' or szName == 'Box_FilterItem' then
		local hItem = (szName == 'Handle_Item' or szName == 'Handle_FilterItem') and this or this:GetParent()
		local box   = hItem:Lookup('Box_Item') or hItem:Lookup('Box_FilterItem')
		local data = hItem.itemData
		if not data.bDist and not data.bBidding then
			return
		end
		local dwDoodadID = data.dwDoodadID
		if not D.AuthCheck(dwDoodadID, true) then
			return
		end
		X.UI.PopupMenu(D.GetItemBiddingMenu(dwDoodadID, data))
	end
end

function D.GetFilterMenu()
	local t = {
		szOption = _L['Loot item filter'],
		-- 隐藏过滤物品
		{
			szOption = _L['Hide filter items'],
			bCheck = true,
			bChecked = ITEM_CONFIG.bHideFiltered,
			fnAction = function()
				ITEM_CONFIG.bHideFiltered = not ITEM_CONFIG.bHideFiltered
				D.ReloadFrame()
			end,
			fnMouseEnter = function()
				local nX, nY = this:GetAbsX(), this:GetAbsY()
				local nW, nH = this:GetW(), this:GetH()
				local szText = GetFormatText(_L['Hide all filter items instead of collapse display them, will be reset after loading.'], nil, 255, 255, 0)
				OutputTip(szText, 600, {nX, nY, nW, nH}, ALW.RIGHT_LEFT)
			end,
			fnMouseLeave = function()
				HideTip()
			end,
		},
		X.CONSTANT.MENU_DIVIDER,
	}

	-- 品级过滤
	local t1 = {
		szOption = _L['Quality filter'],
	}
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t1, {
			szOption = p.szTitle,
			rgb = { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true,
			bChecked = ITEM_CONFIG.tFilterQuality[p.nQuality],
			fnAction = function()
				ITEM_CONFIG.tFilterQuality[p.nQuality] = not ITEM_CONFIG.tFilterQuality[p.nQuality]
				ITEM_CONFIG.tFilterQuality = ITEM_CONFIG.tFilterQuality
				D.ReloadFrame()
			end,
		})
	end
	table.insert(t, t1)

	-- 名称过滤
	local t1 = {
		szOption = _L['Name filter'],
		{
			szOption = _L['Enable'],
			bCheck = true, bChecked = ITEM_CONFIG.bNameFilter,
			fnAction = function()
				ITEM_CONFIG.bNameFilter = not ITEM_CONFIG.bNameFilter
				D.ReloadFrame()
			end,
		},
		X.CONSTANT.MENU_DIVIDER,
	}
	for szName, bEnable in pairs(O.tNameFilter) do
		table.insert(t1, {
			szOption = szName,
			bCheck = true,
			bChecked = bEnable,
			fnAction = function()
				O.tNameFilter[szName] = not O.tNameFilter[szName]
				O.tNameFilter = O.tNameFilter
				D.ReloadFrame()
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				O.tNameFilter[szName] = nil
				O.tNameFilter = O.tNameFilter
				X.UI.ClosePopupMenu()
				D.ReloadFrame()
			end,
			fnDisable = function() return not ITEM_CONFIG.bNameFilter end,
		})
	end
	if not X.IsEmpty(O.tNameFilter) then
		table.insert(t1, X.CONSTANT.MENU_DIVIDER)
	end
	table.insert(t1, {
		szOption = _L['Add'],
		fnAction = function()
			GetUserInput(_L['Please input filter name'], function(szText)
				O.tNameFilter[szText] = true
				O.tNameFilter = O.tNameFilter
				D.ReloadFrame()
			end, nil, nil, nil, '', nil)
		end,
		fnDisable = function() return not ITEM_CONFIG.bNameFilter end,
	})
	table.insert(t, t1)

	-- 过滤已读书籍
	table.insert(t, {
		szOption = _L['Filter book read'],
		bCheck = true,
		bChecked = O.bFilterBookRead,
		fnAction = function()
			O.bFilterBookRead = not O.bFilterBookRead
			D.ReloadFrame()
		end,
	})

	-- 过滤已有书籍
	table.insert(t, {
		szOption = _L['Filter book have'],
		bCheck = true,
		bChecked = O.bFilterBookHave,
		fnAction = function()
			O.bFilterBookHave = not O.bFilterBookHave
			D.ReloadFrame()
		end,
	})

	return t
end

function D.GetAutoPickupMenu()
	local t = { szOption = _L['Auto pickup'] }
	table.insert(t, { szOption = _L['Filters have higher priority'], bDisable = true })
	-- 拾取过滤
	-- 过滤已读书籍
	table.insert(t, {
		szOption = _L['Filter book read'],
		bCheck = true,
		bChecked = O.bAutoPickupFilterBookRead,
		fnAction = function()
			O.bAutoPickupFilterBookRead = not O.bAutoPickupFilterBookRead
		end,
	})
	-- 过滤已有书籍
	table.insert(t, {
		szOption = _L['Filter book have'],
		bCheck = true,
		bChecked = O.bAutoPickupFilterBookHave,
		fnAction = function()
			O.bAutoPickupFilterBookHave = not O.bAutoPickupFilterBookHave
		end,
	})
	-- 自动拾取物品过滤
	local t1 = { szOption = _L['Auto pickup filters'] }
	for s, b in pairs(O.tAutoPickupFilters or {}) do
		table.insert(t1, {
			szOption = s,
			bCheck = true, bChecked = b,
			fnAction = function()
				O.tAutoPickupFilters[s] = not O.tAutoPickupFilters[s]
				O.tAutoPickupFilters = O.tAutoPickupFilters
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				O.tAutoPickupFilters[s] = nil
				O.tAutoPickupFilters = O.tAutoPickupFilters
				X.UI.ClosePopupMenu()
			end,
		})
	end
	if #t1 > 0 then
		table.insert(t1, X.CONSTANT.MENU_DIVIDER)
	end
	table.insert(t1, {
		szOption = _L['Add new'],
		fnAction = function()
			GetUserInput(_L['Please input new auto pickup filter:'], function(text)
				O.tAutoPickupFilters[text] = true
				O.tAutoPickupFilters = O.tAutoPickupFilters
			end)
		end,
	})
	table.insert(t, t1)
	-- 自动拾取
	table.insert(t, X.CONSTANT.MENU_DIVIDER)
	-- 自动拾取任务物品
	table.insert(t, {
		szOption = _L['Auto pickup quest item'],
		bCheck = true, bChecked = O.bAutoPickupTaskItem,
		fnAction = function()
			O.bAutoPickupTaskItem = not O.bAutoPickupTaskItem
		end,
	})
	-- 自动拾取书籍
	table.insert(t, {
		szOption = _L['Auto pickup book'],
		bCheck = true, bChecked = O.bAutoPickupBook,
		fnAction = function()
			O.bAutoPickupBook = not O.bAutoPickupBook
		end,
	})
	-- 自动拾取品级
	local t1 = {
		szOption = _L['Auto pickup by item quality'],
		{
			szOption = _L['Enable'],
			bCheck = true,
			bChecked = O.bAutoPickupQuality,
			fnAction = function()
				O.bAutoPickupQuality = not O.bAutoPickupQuality
			end,
		},
		X.CONSTANT.MENU_DIVIDER,
	}
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t1, {
			szOption = p.szTitle,
			rgb = { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true,
			bChecked = O.tAutoPickupQuality[p.nQuality],
			fnAction = function()
				O.tAutoPickupQuality[p.nQuality] = not O.tAutoPickupQuality[p.nQuality]
				O.tAutoPickupQuality = O.tAutoPickupQuality
			end,
			fnDisable = function() return not O.bAutoPickupQuality end,
		})
	end
	table.insert(t, t1)
	-- 自动拾取物品名称
	local t1 = { szOption = _L['Auto pickup names'] }
	for s, b in pairs(O.tAutoPickupNames or {}) do
		table.insert(t1, {
			szOption = s,
			bCheck = true, bChecked = b,
			fnAction = function()
				O.tAutoPickupNames[s] = not O.tAutoPickupNames[s]
				O.tAutoPickupNames = O.tAutoPickupNames
			end,
			szIcon = 'ui/Image/UICommon/CommonPanel2.UITex',
			nFrame = 49,
			nMouseOverFrame = 51,
			nIconWidth = 17,
			nIconHeight = 17,
			szLayer = 'ICON_RIGHTMOST',
			fnClickIcon = function()
				O.tAutoPickupNames[s] = nil
				O.tAutoPickupNames = O.tAutoPickupNames
				X.UI.ClosePopupMenu()
			end,
		})
	end
	if #t1 > 0 then
		table.insert(t1, X.CONSTANT.MENU_DIVIDER)
	end
	table.insert(t1, {
		szOption = _L['Add new'],
		fnAction = function()
			GetUserInput(_L['Please input new auto pickup name:'], function(text)
				O.tAutoPickupNames[text] = true
				O.tAutoPickupNames = O.tAutoPickupNames
			end)
		end,
	})
	table.insert(t, t1)
	return t
end

function D.GetBossAction(dwDoodadID, bMenu)
	if not D.AuthCheck(dwDoodadID) then
		return
	end
	local aItemData = D.GetDoodadLootInfo(dwDoodadID)
	local fnAction = function()
		local aEquipmentItemData = {}
		for k, v in ipairs(aItemData) do
			if (
				(v.item.nGenre == ITEM_GENRE.EQUIPMENT and (
					v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.CHEST
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.HELM
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.AMULET
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.RING
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.PENDANT
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.PANTS
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.BOOTS
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.BANGLE
					or v.item.nSub == X.CONSTANT.EQUIPMENT_SUB.ARROW
				))
				or IsCtrlKeyDown()
			) and v.bDist then -- 按住Ctrl的情况下 无视分类 否则只给装备
				table.insert(aEquipmentItemData, v)
			end
		end
		if #aEquipmentItemData == 0 then
			return X.Alert(_L['No Equiptment left for Equiptment Boss'])
		end
		local aPartyMember = D.GetaPartyMember(dwDoodadID)
		local p = aPartyMember(MY_GKP_LOOT_BOSS)
		if p and p.bOnlineFlag then  -- 这个人存在团队的情况下
			local szXml = GetFormatText(_L['Are you sure you want the following item\n'], 162, 255, 255, 255)
			local r, g, b = X.GetForceColor(p.dwForceID)
			for k, v in ipairs(aEquipmentItemData) do
				local r, g, b = GetItemFontColorByQuality(v.item.nQuality)
				szXml = szXml .. GetFormatText('['.. X.GetItemNameByItem(v.item) ..']\n', 166, r, g, b)
			end
			szXml = szXml .. GetFormatText(_L['All distrubute to'], 162, 255, 255, 255)
			szXml = szXml .. GetFormatText('['.. p.szName ..']', 162, r, g, b)
			local msg = {
				szMessage = szXml,
				szName = 'GKP_Distribute',
				szAlignment = 'CENTER',
				bRichText = true,
				{
					szOption = g_tStrings.STR_HOTKEY_SURE,
					fnAction = function()
						D.DistributeItem(MY_GKP_LOOT_BOSS, aEquipmentItemData, nil, true)
					end
				},
				{
					szOption = g_tStrings.STR_HOTKEY_CANCEL
				},
			}
			MessageBox(msg)
		else
			return X.Alert(_L['Cannot distrubute items to Equipment Boss, may due to Equipment Boss is too far away or got dropline when looting.'])
		end
	end
	if bMenu then
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			MY_GKP_LOOT_BOSS = v.dwID
			fnAction()
		end, false, true)
		table.insert(menu, 1, X.CONSTANT.MENU_DIVIDER)
		table.insert(menu, 1, { szOption = _L['select equip boss'], bDisable = true })
		X.UI.PopupMenu(menu)
	else
		fnAction()
	end
end

function D.AuthCheck(dwDoodadID, bIgnoreLootMode)
	-- 需要自己是分配者
	if not X.IsClientPlayerTeamDistributor() and not X.IsDebugging('MY_GKP') then
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	local team = GetClientTeam()
	-- 需要分配者模式
	local nLootMode = team.nLootMode
	if not bIgnoreLootMode and nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not X.IsDebugging('MY_GKP') then
		OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
		return false
	end
	-- 需要掉落所属是在自己队伍
	if not X.IsInDungeonMap() then
		local doodad = X.GetDoodad(dwDoodadID)
		if not doodad then
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('MY_GKPLoot:AuthCheck', 'Doodad does not exist!', X.DEBUG_LEVEL.WARNING)
			--[[#DEBUG END]]
			return
		end
		local dwBelongTeamID = doodad.GetBelongTeamID()
		if dwBelongTeamID ~= team.dwTeamID then
			OutputMessage('MSG_ANNOUNCE_RED', g_tStrings.ERROR_LOOT_DISTRIBUTE)
			return false
		end
	end
	return true
end

-- 拾取对象
function D.GetaPartyMember(aDoodadID)
	if not X.IsTable(aDoodadID) then
		aDoodadID = {aDoodadID}
	end
	local team = GetClientTeam()
	local tDoodadID = {}
	local tPartyMember = {}
	local aPartyMember = {}
	for _, dwDoodadID in ipairs(aDoodadID) do
		if not tDoodadID[dwDoodadID] then
			local aLooterList = X.GetDoodadLooterList(dwDoodadID)
			if aLooterList then
				for _, p in ipairs(aLooterList) do
					if not tPartyMember[p.dwID] then
						table.insert(aPartyMember, p)
						tPartyMember[p.dwID] = true
					end
				end
			else
				X.OutputSystemMessage(_L['Pick up time limit exceeded, please try again.'])
			end
			tDoodadID[dwDoodadID] = true
		end
	end
	for k, v in ipairs(aPartyMember) do
		local player = team.GetMemberInfo(v.dwID)
		aPartyMember[k].dwForceID = player.dwForceID
		aPartyMember[k].dwMapID   = player.dwMapID
	end
	setmetatable(aPartyMember, { __call = function(me, dwID)
		for k, v in ipairs(me) do
			if v.dwID == dwID or v.szName == dwID then
				return v
			end
		end
	end })
	return aPartyMember
end

-- 严格判断
function D.DistributeItem(dwID, info, szAutoDistType, bSkipRecordPanel)
	if X.IsArray(info) then
		for _, p in ipairs(info) do
			D.DistributeItem(dwID, p, szAutoDistType, bSkipRecordPanel)
		end
		return
	end
	if not D.AuthCheck(info.dwDoodadID) then
		return
	end
	local me = X.GetClientPlayer()
	local item = GetItem(info.dwID)
	if not item then
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_GKPLoot', 'Item does not exist, check!!', X.DEBUG_LEVEL.WARNING)
		--[[#DEBUG END]]
		local aItemData = D.GetDoodadLootInfo(info.dwDoodadID)
		for k, v in ipairs(aItemData) do
			if v.nQuality == info.nQuality and X.GetItemNameByItem(v.item) == info.szName then
				info.dwID = v.item.dwID
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('MY_GKPLoot', 'Item matching, ' .. X.GetItemNameByItem(v.item), X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
				break
			end
		end
	end
	local item         = GetItem(info.dwID)
	local team         = GetClientTeam()
	local player       = team.GetMemberInfo(dwID)
	local aPartyMember = D.GetaPartyMember(info.dwDoodadID)
	if item then
		if not player or (player and not player.bIsOnLine) then -- 不在线
			return X.Alert(_L['No Pick up Object, may due to Network off - line'])
		end
		if not aPartyMember(dwID) then -- 给不了
			return X.Alert(_L['No Pick up Object, may due to Network off - line'])
		end
		if player.dwMapID ~= me.GetMapID() then -- 不在同一地图
			return X.Alert(_L['No Pick up Object, Please confirm that in the Dungeon.'])
		end
		local tab = {
			szPlayer   = player.szName,
			dwID       = item.dwID,
			nUiId      = item.nUiId,
			szNpcName  = info.szDoodadName,
			dwDoodadID = info.dwDoodadID,
			dwTabType  = item.dwTabType,
			dwIndex    = item.dwIndex,
			nVersion   = item.nVersion,
			nTime      = GetCurrentTime(),
			nQuality   = item.nQuality,
			dwForceID  = player.dwForceID,
			szName     = X.GetItemNameByItem(item),
			nGenre     = item.nGenre,
		}
		if item.bCanStack and item.nStackNum > 1 then
			tab.nStackNum = item.nStackNum
		end
		if item.nGenre == ITEM_GENRE.BOOK then
			tab.nBookID = item.nBookID
		end
		MY_GKP_MI.NewAuction(tab, IsShiftKeyDown() or bSkipRecordPanel)
		if szAutoDistType then
			GKP_LOOT_RECENT[szAutoDistType] = dwID
		end
		if DEBUG_LOOT then
			return X.OutputSystemMessage('LOOT: ' .. info.dwID .. '->' .. dwID) -- !!! Debug
		end
		X.DistributeDoodadItem(info.dwDoodadID, info.dwID, dwID)
	else
		X.OutputSystemMessage(_L['Userdata is overdue, distribut failed, please try again.'])
	end
end

function D.GetMessageBox(dwID, aItemData, szAutoDistType, bSkipRecordPanel)
	if not X.IsArray(aItemData) then
		aItemData = {aItemData}
	end
	local team = GetClientTeam()
	local info = team.GetMemberInfo(dwID)
	local fr, fg, fb = X.GetForceColor(info.dwForceID)
	local aItemName = {}
	for _, data in ipairs(aItemData) do
		local ir, ig, ib = GetItemFontColorByQuality(data.nQuality)
		table.insert(aItemName, GetFormatText('['.. data.szName .. ']', 166, ir, ig, ib))
	end
	local msg = {
		szMessage = FormatLinkString(
			g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
			'font=162',
			table.concat(aItemName, GetFormatText(g_tStrings.STR_PAUSE)),
			GetFormatText('['.. info.szName .. ']', 162, fr, fg, fb)
		),
		szName = 'GKP_Distribute',
		bRichText = true,
		{
			szOption = g_tStrings.STR_HOTKEY_SURE,
			fnAction = function()
				D.DistributeItem(dwID, aItemData, szAutoDistType, bSkipRecordPanel)
			end
		},
		{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
	}
	MessageBox(msg)
end

do
local function IsItemRequireConfirm(data)
	if data.nQuality >= O.nConfirmQuality
	or (O.tConfirm.Huangbaba -- 玄晶
		and data.item.nQuality == GKP_LOOT_HUANGBABA_QUALITY
		and X.GetItemIconByUIID(data.item.nUiId) == GKP_LOOT_HUANGBABA_ICON
	)
	or (O.tConfirm.Book and data.item.nGenre == ITEM_GENRE.BOOK) -- 书籍
	or (O.tConfirm.Pendant and data.item.nGenre == ITEM_GENRE.EQUIPMENT and ( -- 挂件
		data.item.nSub == EQUIPMENT_REPRESENT.WAIST_EXTEND
		or data.item.nSub == EQUIPMENT_REPRESENT.BACK_EXTEND
		or data.item.nSub == EQUIPMENT_REPRESENT.FACE_EXTEND
	))
	or (O.tConfirm.Outlook and data.item.nGenre == ITEM_GENRE.EQUIPMENT and ( -- 肩饰披风
		data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_CLOAK_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.L_SHOULDER_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.R_SHOULDER_EXTEND
	))
	or (O.tConfirm.Pet and ( -- 跟宠
		data.item.nGenre == ITEM_GENRE.CUB
		or (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.PET)
	))
	or (O.tConfirm.Horse and ( -- 坐骑
		data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE
	))
	or (O.tConfirm.HorseEquip and ( -- 马具
		data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE_EQUIP
	))
	then
		return true
	end
	return false
end
local function GetMemberMenu(member, aItemData, szAutoDistType, aDoodadID)
	local frame = D.GetFrame()
	local szIcon, nFrame = GetForceImage(member.dwForceID)
	local szOption = member.szName
	return {
		szOption = szOption,
		bDisable = not member.bOnlineFlag,
		rgb = { X.GetForceColor(member.dwForceID) },
		szIcon = szIcon, nFrame = nFrame,
		fnAutoClose = function()
			for _, v in ipairs(aDoodadID) do
				if D.GetDoodadWnd(frame, v) then
					return false
				end
			end
			return true
		end,
		szLayer = 'ICON_RIGHTMOST',
		fnAction = function()
			local bConfirm = false
			for _, data in ipairs(aItemData) do
				if IsItemRequireConfirm(data) then
					bConfirm = true
					break
				end
			end
			if bConfirm then
				D.GetMessageBox(member.dwID, aItemData, szAutoDistType, IsShiftKeyDown())
			else
				D.DistributeItem(member.dwID, aItemData, szAutoDistType, IsShiftKeyDown())
			end
		end,
		fnMouseEnter = function()
			X.OutputTip(_L['Hold shift click to skip gkp record panel'], 136)
		end,
		fnMouseLeave = function()
			HideTip()
		end,
	}
end
function D.GetDistributeMenu(aItemData, szAutoDistType)
	if not X.IsArray(aItemData) then
		aItemData = {aItemData}
	end
	local aDoodadID = {}
	for _, p in ipairs(aItemData) do
		if p.bDist then
			table.insert(aDoodadID, p.dwDoodadID)
		end
	end
	local me, team     = X.GetClientPlayer(), GetClientTeam()
	local dwMapID      = me.GetMapID()
	local aPartyMember = D.GetaPartyMember(aDoodadID)
	table.sort(aPartyMember, function(a, b)
		return a.dwForceID < b.dwForceID
	end)
	local aItemName = {}
	for _, p in ipairs(aItemData) do
		table.insert(aItemName, p.szName)
	end
	local menu = {
		{ szOption = table.concat(aItemName, g_tStrings.STR_PAUSE), bDisable = true },
		X.CONSTANT.MENU_DIVIDER
	}
	local dwAutoDistID
	if szAutoDistType then
		dwAutoDistID = GKP_LOOT_RECENT[szAutoDistType]
		if dwAutoDistID then
			local member = aPartyMember(dwAutoDistID)
			if member then
				table.insert(menu, GetMemberMenu(member, aItemData, szAutoDistType, aDoodadID))
				table.insert(menu, X.CONSTANT.MENU_DIVIDER)
			end
		end
	end
	for _, member in ipairs(aPartyMember) do
		table.insert(menu, GetMemberMenu(member, aItemData, szAutoDistType, aDoodadID))
	end
	return menu
end
end

function D.GetItemBiddingMenu(dwDoodadID, data)
	local menu = {}
	table.insert(menu, { szOption = data.szName , bDisable = true })
	table.insert(menu, X.CONSTANT.MENU_DIVIDER)
	table.insert(menu, {
		szOption = 'Roll',
		fnAction = function()
			if MY_RollMonitor then
				if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
					MY_RollMonitor.OpenPanel()
					MY_RollMonitor.Clear({echo=false})
				end
			end
			X.SendChat(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L['Roll the dice if you wang']) })
			return 0
		end
	})
	table.insert(menu, X.CONSTANT.MENU_DIVIDER)
	for k, v in ipairs(MY_GKP.aScheme) do
		if v[3] then
			table.insert(menu, {
				szOption = v[1] .. ',' .. v[2],
				fnAction = function()
					local bNewBidding = MY_GKP.bNewBidding == not IsShiftKeyDown()
					if bNewBidding then
						MY_Bidding.Open({
							nPriceMin = v[1],
							nPriceStep = v[2],
							nNumber = data.item.bCanStack and data.item.nStackNum or 1,
							dwTabType = data.item.dwTabType,
							dwTabIndex = data.item.dwIndex,
							nBookID = data.item.nGenre == ITEM_GENRE.BOOK and data.item.nBookID or nil,
						})
						return 0
					end
					MY_GKP_Chat.OpenFrame(data.item, D.GetDistributeMenu(data, data.nUiId), {
						dwDoodadID = dwDoodadID,
						data = data,
					})
					X.SendChat(PLAYER_TALK_CHANNEL.RAID, {
						MY_GKP.GetFormatLink(data.item),
						MY_GKP.GetFormatLink(_L(' %d Gold Start Bidding, off a price if you want.', v[1])),
					})
					return 0
				end,
				fnMouseEnter = function()
					local szMsg = GetFormatText(
						MY_GKP.bNewBidding
							and _L['Hold SHIFT click to raise ancient bidding panel.']
							or _L['Hold SHIFT click to raise new bidding panel.']
						, nil, 255, 255, 0)
					OutputTip(szMsg, 600, {this:GetAbsX(), this:GetAbsY(), this:GetW(), this:GetH()}, ALW.RIGHT_LEFT)
				end,
				fnMouseLeave = function()
					HideTip()
				end,
			})
		end
	end
	return menu
end

function D.GetListWidth()
	return O.bVertical and 270 or (52 * 8)
end

function D.AdjustFrame(frame)
	local scroll = frame:Lookup('Scroll_DoodadList')
	local scrollbar = scroll:Lookup('ScrolBar_DoodadList')
	local container = scroll:Lookup('WndContainer_DoodadList')
	local nW, nH = frame:GetW(), 0
	local wnd = container:LookupContent(0)
	while wnd do
		nW = wnd:GetW()
		nH = nH + wnd:GetH()
		wnd = wnd:GetNext()
	end
	nH = math.min(nH, select(2, Station.GetClientSize()) * 4 / 5)
	scroll:SetSize(nW, nH)
	scrollbar:SetH(nH)
	scrollbar:SetRelX(nW - 8)
	container:SetSize(nW, nH)
	container:FormatAllContentPos()
	frame:SetSize(nW, nH)
end

function D.AdjustWnd(wnd)
	local nInnerW = D.GetListWidth()
	local nOuterW = O.bVertical and nInnerW or (nInnerW + 10)
	local hDoodad = wnd:Lookup('', '')
	local hList = hDoodad:Lookup('Handle_ItemList')
	local bMini = wnd:Lookup('CheckBox_Mini'):IsCheckBoxChecked()
	hList:SetW(nInnerW)
	hList:SetRelX((nOuterW - nInnerW) / 2)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetVisible(not bMini)
	hDoodad:SetSize(nOuterW, (bMini and 0 or hList:GetH()) + 30)
	hDoodad:Lookup('Handle_Compass'):SetRelX(nOuterW - 107)
	hDoodad:Lookup('Image_DoodadTitleBg'):SetW(nOuterW)
	hDoodad:Lookup('Image_DoodadBg'):SetSize(nOuterW, hDoodad:GetH() - 20)
	hDoodad:FormatAllItemPos()
	wnd:SetSize(nOuterW, hDoodad:GetH())
	wnd:Lookup('Btn_Boss'):SetRelX(nOuterW - 80)
	wnd:Lookup('CheckBox_Mini'):SetRelX(nOuterW - 50)
	wnd:Lookup('Btn_Close'):SetRelX(nOuterW - 28)
end

function D.GetDoodadWnd(frame, dwDoodadID, bCreate)
	if not frame then
		return
	end
	local container = frame:Lookup('Scroll_DoodadList/WndContainer_DoodadList')
	local wnd = container:LookupContent(0)
	while wnd and wnd.doodadData.dwID ~= dwDoodadID do
		wnd = wnd:GetNext()
	end
	if not wnd and bCreate then
		local tDoodadInfo = D.GetDoodadData(dwDoodadID)
		if tDoodadInfo then
			wnd = container:AppendContentFromIni(GKP_LOOT_INIFILE, 'Wnd_Doodad')
			wnd.doodadData = tDoodadInfo
		end
	end
	return wnd
end

local function IsItemDataSuitable(data)
	local me = X.GetClientPlayer()
	if not me then
		return 'NOT_SUITABLE'
	end
	local aKungfu = X.GetForceKungfuList(me.dwForceID)
	if data.szType == 'BOOK' then
		local nBookID, nSegmentID = X.RecipeToSegmentID(data.item.nBookID)
		if me.IsBookMemorized(nBookID, nSegmentID) then
			return 'NOT_SUITABLE'
		end
		return 'SUITABLE'
	else
		local szSuit = X.DoesEquipmentSuit(data.item, true) and 'SUITABLE' or 'NOT_SUITABLE'
		if szSuit == 'SUITABLE' then
			if data.szType == 'EQUIPMENT' or data.szType == 'WEAPON' then
				szSuit = X.IsItemFitKungfu(data.item, me.GetKungfuMountID()) and 'SUITABLE' or 'NOT_SUITABLE'
				if szSuit == 'NOT_SUITABLE' and O.bShow2ndKungfuLoot then
					for _, dwKungfuID in ipairs(aKungfu) do
						if X.IsItemFitKungfu(data.item, dwKungfuID) then
							szSuit = 'MAYBE_SUITABLE'
							break
						end
					end
				end
			elseif data.szType == 'EQUIPMENT_SIGN' then
				szSuit = X.StringFindW(data.item.szName, g_tStrings.tForceTitle[me.dwForceID]) and 'SUITABLE' or 'NOT_SUITABLE'
			end
		end
		if szSuit == 'SUITABLE' and X.IsBetterEquipment(data.item) then
			return 'BETTER'
		end
		return szSuit
	end
end

function D.InsertLootList(dwDoodadID)
	local bExist = false
	for _, v in ipairs(D.aDoodadID) do
		if v == dwDoodadID then
			bExist = true
			break
		end
	end
	if not bExist then
		table.insert(D.aDoodadID, dwDoodadID)
	end
	D.DrawLootList(dwDoodadID)
end

function D.DrawLootList(dwDoodadID, bRemove)
	--[[#DEBUG BEGIN]]
	local nTickCount = GetTickCount()
	--[[#DEBUG END]]
	local frame = D.GetFrame()
	local wnd = D.GetDoodadWnd(frame, dwDoodadID)

	if bRemove then
		if wnd then
			wnd:Destroy()
			local container = frame:Lookup('Scroll_DoodadList/WndContainer_DoodadList')
			if container:GetAllContentCount() == 0 then
				D.CloseFrame()
			else
				D.AdjustFrame(frame)
			end
		end
	else
		local config = ITEM_CONFIG
		-- 计算掉落
		local aItemData, nMoney, szName, bSpecial = D.GetDoodadLootInfo(dwDoodadID)
		if nMoney > 0 then
			LootMoney(dwDoodadID)
		end
		local nCount = #aItemData
		local aNormalItemData = aItemData
		local aFilterItemData = {}
		if not X.IsEmpty(config.tFilterQuality) or config.bFilterBookRead or config.bFilterBookHave then
			nCount = 0
			aNormalItemData = {}
			for i, v in ipairs(aItemData) do
				if D.IsItemDisplay(v, config) then
					nCount = nCount + 1
					table.insert(aNormalItemData, v)
				else
					if not ITEM_CONFIG.bHideFiltered then
						nCount = nCount + 1
					end
					table.insert(aFilterItemData, v)
				end
			end
		end
		--[[#DEBUG BEGIN]]
		X.OutputDebugMessage('MY_GKPLoot', ('Doodad %d, items %d, display %d.'):format(dwDoodadID, #aItemData, nCount), X.DEBUG_LEVEL.LOG)
		--[[#DEBUG END]]

		if not szName or nCount == 0 then
			if not szName then
				D.RemoveLootList(dwDoodadID)
				--[[#DEBUG BEGIN]]
				X.OutputDebugMessage('MY_GKPLoot:DrawLootList', 'Doodad does not exist!', X.DEBUG_LEVEL.LOG)
				--[[#DEBUG END]]
			elseif frame then
				D.DrawLootList(dwDoodadID, true)
			end
			return
		end

		-- 获取/创建UI元素
		if not frame then
			frame = D.OpenFrame()
		end
		if not wnd then
			wnd = D.GetDoodadWnd(frame, dwDoodadID, true)
		end
		if not wnd then
			D.RemoveLootList(dwDoodadID)
			--[[#DEBUG BEGIN]]
			X.OutputDebugMessage('MY_GKPLoot:DrawLootList', 'Doodad wnd does not exist!', X.DEBUG_LEVEL.LOG)
			--[[#DEBUG END]]
			return
		end

		-- 修改UI元素
		local bDist = false
		local hDoodad = wnd:Lookup('', '')
		local hList = hDoodad:Lookup('Handle_ItemList')
		hList:Clear()
		for i, itemData in ipairs(aNormalItemData) do
			local item = itemData.item
			local szName = X.GetItemNameByItem(item)
			local h = hList:AppendItemFromIni(GKP_LOOT_INIFILE, 'Handle_Item')
			local box = h:Lookup('Box_Item')
			local txt = h:Lookup('Text_Item')
			if O.bVertical then
				txt:SetText(szName)
				h:Lookup('Image_GroupDistrib'):SetVisible(itemData.bDist
					and (i == 1 or aNormalItemData[i - 1].szType ~= itemData.szType or not aNormalItemData[i - 1].bDist))
				h:Lookup('Image_Spliter'):SetVisible(i ~= #aNormalItemData)
			else
				txt:SetText((szName:gsub('^.-' .. g_tStrings.STR_CONNECT, '')))
				txt:SetRelPos(2, 2)
				txt:SetW(48)
				txt:SetHAlign(2)
				txt:SetVAlign(0)
				txt:SetFontScheme(8)
				box:SetSize(48, 48)
				box:SetRelPos(2, 2)
				h:Lookup('Image_Suitable'):SetRelPos(0, 35)
				h:Lookup('Image_MaybeSuitable'):SetRelPos(0, 35)
				h:Lookup('Image_Better'):SetRelPos(0, 32)
				h:Lookup('Image_Better'):SetH(22)
				h:SetSize(52, 52)
				h:FormatAllItemPos()
				h:Lookup('Image_GroupDistrib'):Hide()
				h:Lookup('Image_Spliter'):Hide()
				h:Lookup('Image_Hover'):SetSize(0, 0)
			end
			local szSuit = IsItemDataSuitable(itemData)
			h:Lookup('Image_Suitable'):SetVisible(szSuit == 'SUITABLE')
			h:Lookup('Image_MaybeSuitable'):SetVisible(szSuit == 'MAYBE_SUITABLE')
			h:Lookup('Image_Better'):SetVisible(szSuit == 'BETTER')
			txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
			UpdateBoxObject(box, UI_OBJECT_ITEM_ONLY_ID, item.dwID)
			-- box:SetOverText(3, '')
			-- box:SetOverTextFontScheme(3, 15)
			-- box:SetOverTextPosition(3, ITEM_POSITION.LEFT_TOP)
			if GKP_LOOT_RECENT[item.nUiId] then
				box:SetObjectStaring(true)
			end
			if O.bSetColor and item.nGenre == ITEM_GENRE.MATERIAL then
				for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
					if szName:find(szForceTitle) then
						txt:SetFontColor(X.GetForceColor(dwForceID))
						break
					end
				end
			end
			if itemData.bDist then
				bDist = true
			end
			h.itemData = itemData
			h.nAutoLootLFC = nil
		end
		if #aFilterItemData > 0 and not ITEM_CONFIG.bHideFiltered then
			local h = hList:AppendItemFromIni(GKP_LOOT_INIFILE, 'Handle_ItemFiltered')
			local hFL = h:Lookup('Handle_FilterItemList')
			hFL:Clear()
			for i, itemData in ipairs(aFilterItemData) do
				local item = itemData.item
				local hFI = hFL:AppendItemFromIni(GKP_LOOT_INIFILE, 'Handle_FilterItem')
				local box = hFI:Lookup('Box_FilterItem')
				UpdateBoxObject(box, UI_OBJECT_ITEM_ONLY_ID, item.dwID)
				if GKP_LOOT_RECENT[item.nUiId] then
					box:SetObjectStaring(true)
				end
				if itemData.bDist then
					bDist = true
				end
				hFI.itemData = itemData
			end
			local nW = D.GetListWidth()
			if O.bVertical then
				hFL:SetW(nW - 8)
				hFL:FormatAllItemPos()
				hFL:SetSizeByAllItemSize()
				h:FormatAllItemPos()
				h:SetSizeByAllItemSize()
				h:SetW(nW)
			else
				local nRemainW = nW - (#aNormalItemData * 52) % nW
				local nMaxRemainFilterItem = math.floor(nRemainW / 26) * 2
				if nMaxRemainFilterItem >= #aFilterItemData then
					hFL:SetW(nRemainW)
				else
					hFL:SetW(nW - 8)
				end
				hFL:SetRelPos(0, 0)
				hFL:FormatAllItemPos()
				hFL:SetSizeByAllItemSize()
				h:Lookup('Image_FilterSpliter'):Hide()
				h:FormatAllItemPos()
				h:SetSize(hFL:GetSize())
			end
		end
		if bSpecial then
			hDoodad:Lookup('Image_DoodadBg'):FromUITex('ui/Image/OperationActivity/RedEnvelope2.uitex', 14)
			hDoodad:Lookup('Image_DoodadTitleBg'):FromUITex('ui/Image/OperationActivity/RedEnvelope2.uitex', 14)
			hDoodad:Lookup('Text_Title'):SetAlpha(255)
			hDoodad:Lookup('SFX'):Show()
		end
		hDoodad:Lookup('Text_Title'):SetText((szName or g_tStrings.STR_NAME_UNKNOWN) .. ' (' .. nCount ..  ')')
		wnd:Lookup('Btn_Boss'):Enable(bDist)

		-- 修改UI大小
		D.AdjustWnd(wnd)
		D.AdjustFrame(frame)

		-- 立即自动拾取一次
		X.ExecuteWithThis(frame, D.OnFrameBreathe)
		--[[#DEBUG BEGIN]]
		nTickCount = GetTickCount() - nTickCount
		X.OutputDebugMessage(
			_L['PMTool'],
			_L('DrawLootList %d in %dms.', dwDoodadID, nTickCount),
			X.DEBUG_LEVEL.PM_LOG)
		--[[#DEBUG END]]
	end
end

function D.RemoveLootList(dwDoodadID, bManually)
	if bManually then
		D.tDoodadClosed[dwDoodadID] = true
	end
	for i, v in ipairs(D.aDoodadID) do
		if dwDoodadID == v then
			table.remove(D.aDoodadID, i)
			break
		end
	end
	D.DrawLootList(dwDoodadID, true)
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_GKPLoot')
end

function D.OpenFrame()
	local frame = D.GetFrame()
	if not frame then
		frame = X.UI.OpenFrame(GKP_LOOT_INIFILE, 'MY_GKPLoot')
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end

-- 手动关闭 不适用自定关闭
function D.CloseFrame()
	local frame = D.GetFrame()
	if frame then
		X.UI.CloseFrame(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

function D.ReloadFrame()
	if #D.aDoodadID == 0 then
		D.CloseFrame()
	else
		D.OpenFrame()
		for _, dwDoodadID in ipairs(D.aDoodadID) do
			D.DrawLootList(dwDoodadID)
		end
	end
end

function D.GetDoodadData(dwDoodadID)
	local doodad = X.GetDoodad(dwDoodadID)
	if doodad then
		D.tDoodadInfo[dwDoodadID] = {
			dwID   = doodad.dwID,
			szName = doodad.szName,
			nX     = doodad.nX,
			nY     = doodad.nY,
		}
	end
	return D.tDoodadInfo[dwDoodadID]
end

local ITEM_DATA_WEIGHT = {
	COIN_SHOP      = 1,	-- 外观 披风 礼盒
	OUTLOOK        = 1,	-- 外观 披风 礼盒
	PENDANT        = 2,	-- 挂件
	PET            = 3,	-- 宠物
	HORSE          = 4,	-- 坐骑 马
	HORSE_EQUIP    = 5,	-- 马具
	BOOK           = 6,	-- 书籍
	WEAPON         = 7,	-- 武器
	EQUIPMENT_SIGN = 8,	-- 装备兑换牌
	EQUIPMENT      = 9,	-- 散件装备
	MATERIAL       = 10, -- 材料
	ZIBABA         = 11, -- 小铁
	ENCHANT_ITEM   = 12, -- 附魔
	TASK_ITEM      = 13, -- 任务道具
	OTHER          = 14,
	GARBAGE        = 15, -- 垃圾
}
local function GetItemDataType(data)
	-- 外观 披风 礼盒
	if data.item.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
		return 'COIN_SHOP'
	end
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT and (
		data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.L_SHOULDER_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.R_SHOULDER_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_CLOAK_EXTEND
	) then
		return 'OUTLOOK'
	end
	-- 挂件
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT and (
		data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.WAIST_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.BACK_EXTEND
		or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.FACE_EXTEND
	) then
		return 'PENDANT'
	end
	-- 宠物
	if (data.item.nGenre == ITEM_GENRE.CUB)
	or (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.PET) then
		return 'PET'
	end
	-- 坐骑 马
	if (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE) then
		return 'HORSE'
	end
	-- 马具
	if (data.item.nGenre == ITEM_GENRE.EQUIPMENT and data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.HORSE_EQUIP) then
		return 'HORSE_EQUIP'
	end
	-- 书籍
	if (data.item.nGenre == ITEM_GENRE.BOOK) then
		return 'BOOK'
	end
	-- 武器
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT
	and (data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.MELEE_WEAPON or data.item.nSub == X.CONSTANT.EQUIPMENT_SUB.RANGE_WEAPON) then
		return 'WEAPON'
	end
	-- 装备兑换牌
	if (data.item.nGenre == ITEM_GENRE.MATERIAL and data.item.nSub == 6) then -- TODO: 枚举？
		return 'EQUIPMENT_SIGN'
	end
	-- 散件装备
	if data.item.nGenre == ITEM_GENRE.EQUIPMENT then -- TODO: 枚举？
		return 'EQUIPMENT'
	end
	-- 材料
	if data.item.nGenre == ITEM_GENRE.MATERIAL then
		-- 小铁
		if data.item.nQuality == GKP_LOOT_ZIBABA_QUALITY and X.GetItemIconByUIID(data.item.nUiId) == GKP_LOOT_ZIBABA_ICON then
			return 'ZIBABA'
		end
		-- 材料
		return 'MATERIAL'
	end
	-- 附魔
	if data.item.nGenre == ITEM_GENRE.ENCHANT_ITEM then
		return 'ENCHANT_ITEM'
	end
	-- 任务道具
	if data.item.nGenre == ITEM_GENRE.TASK_ITEM then
		return 'TASK_ITEM'
	end
	-- 垃圾
	if data.item.nQuality == 0 then
		return 'GARBAGE'
	end
	return 'OTHER'
end

function D.GetItemData(dwDoodadID, nItemIndex)
	local tDoodadInfo = D.tDoodadInfo[dwDoodadID]
	local item, bNeedRoll, bDist, bBidding = X.GetDoodadLootItem(dwDoodadID, nItemIndex)
	if item then
		-- itemData
		local data = {
			dwDoodadID   = dwDoodadID    ,
			nItemIndex   = nItemIndex    ,
			szDoodadName = tDoodadInfo and tDoodadInfo.szName or '',
			item         = item          ,
			szName       = X.GetItemNameByItem(item),
			dwID         = item.dwID     ,
			dwTabType    = item.dwTabType,
			dwIndex      = item.dwIndex  ,
			nUiId        = item.nUiId    ,
			nGenre       = item.nGenre   ,
			nSub         = item.nSub     ,
			nQuality     = item.nQuality ,
			bNeedRoll    = bNeedRoll     ,
			bDist        = bDist         ,
			bBidding     = bBidding      ,
			nStackNum    = item.bCanStack and item.nStackNum or 1,
			bSpecial     = item.nQuality == GKP_LOOT_HUANGBABA_QUALITY
				and X.GetItemIconByUIID(item.nUiId) == GKP_LOOT_HUANGBABA_ICON,
		}
		if DEBUG_LOOT then
			data.bDist = true -- !!! Debug
		end
		if item.nGenre == ITEM_GENRE.BOOK then
			data.nBookID = item.nBookID
		end
		data.szType = GetItemDataType(data)
		data.nWeight = ITEM_DATA_WEIGHT[data.szType]
		return data
	end
end

local function LootItemWeightSorter(data1, data2)
	return data1.nWeight < data2.nWeight
end

local function LootItemIndexSorter(data1, data2)
	return data1.nItemIndex > data2.nItemIndex
end

-- 检查物品
function D.GetDoodadLootInfo(dwDoodadID)
	local tDoodadInfo = D.GetDoodadData(dwDoodadID)
	local aItemData = {}
	local bSpecial = false
	local nMoney = X.GetDoodadLootMoney(dwDoodadID) or 0
	local szName = tDoodadInfo and tDoodadInfo.szName or nil
	local nLootItemCount = X.GetDoodadLootItemCount(dwDoodadID) or 0
	for i = 1, nLootItemCount do
		local data = D.GetItemData(dwDoodadID, i)
		if data then
			if data.bSpecial then
				bSpecial = true
			end
			table.insert(aItemData, data)
		end
	end
	if O.bSortLoot then
		table.sort(aItemData, LootItemWeightSorter)
	else
		table.sort(aItemData, LootItemIndexSorter)
	end
	return aItemData, nMoney, szName, bSpecial
end

function D.ShowSystemLoot()
	for _, szName in ipairs({'LootList', 'GoldTeamLootList'}) do
		local frame = Station.SearchFrame(szName)
		if frame and frame:GetAbsX() == 4096 then
			frame:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
		end
	end
end

function D.HideSystemLoot()
	for _, szName in ipairs({'LootList', 'GoldTeamLootList'}) do
		local frame = Station.SearchFrame(szName)
		if frame and frame:GetAbsX() ~= 4096 then
			frame:SetAbsPos(4096, 4096)
		end
		-- X.UI.CloseFrame(szName)
	end
end

function D.AutoSetSystemLootVisible()
	local team = GetClientTeam()
	local bCanBiddingDistribute = team and team.nLootMode == PARTY_LOOT_MODE.BIDDING
		and team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == X.GetClientPlayerID()
	if D.IsEnabled() and not bCanBiddingDistribute then
		D.HideSystemLoot()
	else
		D.ShowSystemLoot()
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nLH, nX, nY, nLFY)
	nX, nY = nPaddingX, nLFY
	ui:Append('Text', { text = _L['GKP Doodad helper'], x = nX, y = nY, font = 27 })

	nX, nY = nPaddingX + 10, nY + nLH

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Enable MY_GKPLoot'],
		checked = O.bOn,
		onCheck = function(bChecked)
			O.bOn = bChecked
		end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Team dungeon'],
		checked = O.bInTeamDungeon,
		onCheck = function(bChecked)
			O.bInTeamDungeon = bChecked
			D.OutputEnable()
		end,
		tip = {
			render = _L['Enable in checked map type'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Raid dungeon'],
		checked = O.bInRaidDungeon,
		onCheck = function(bChecked)
			O.bInRaidDungeon = bChecked
			D.OutputEnable()
		end,
		tip = {
			render = _L['Enable in checked map type'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Battlefield'],
		checked = O.bInBattlefield,
		onCheck = function(bChecked)
			O.bInBattlefield = bChecked
			D.OutputEnable()
		end,
		tip = {
			render = _L['Enable in checked map type'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Other map'],
		checked = O.bInOtherMap,
		onCheck = function(bChecked)
			O.bInOtherMap = bChecked
			D.OutputEnable()
		end,
		tip = {
			render = _L['Enable in checked map type'],
			position = X.UI.TIP_POSITION.BOTTOM_TOP,
		},
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX, nY = nPaddingX + 10, nY + nLH

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Set Force Color'],
		checked = O.bSetColor,
		onCheck = function()
			O.bSetColor = not O.bSetColor
			FireUIEvent('MY_GKP_LOOT_RELOAD')
		end,
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Show 2nd kungfu fit icon'],
		checked = O.bShow2ndKungfuLoot,
		onCheck = function()
			O.bShow2ndKungfuLoot = not O.bShow2ndKungfuLoot
			FireUIEvent('MY_GKP_LOOT_RELOAD')
		end,
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY,
		text = _L['Sort loot list by weight'],
		checked = O.bSortLoot,
		onCheck = function()
			O.bSortLoot = not O.bSortLoot
			FireUIEvent('MY_GKP_LOOT_RELOAD')
		end,
		autoEnable = function() return O.bOn end,
	}):Width() + 10

	nX, nY = nPaddingX + 10, nY + nLH

	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY,
		text = _L['Confirm when distribute'],
		menuLClick = function()
			local t = {}
			table.insert(t, { szOption = _L['Category'], bDisable = true })
			for _, szKey in ipairs({
				'Huangbaba',
				'Book',
				'Pendant',
				'Outlook',
				'Pet',
				'Horse',
				'HorseEquip',
			}) do
				table.insert(t, {
					szOption = _L[szKey],
					bCheck = true,
					bChecked = O.tConfirm[szKey],
					fnAction = function()
						O.tConfirm[szKey] = not O.tConfirm[szKey]
						O.tConfirm = O.tConfirm
					end,
				})
			end
			table.insert(t, X.CONSTANT.MENU_DIVIDER)
			table.insert(t, { szOption = _L['Quality'], bDisable = true })
			for i, s in ipairs({
				[1] = g_tStrings.STR_WHITE,
				[2] = g_tStrings.STR_ROLLQUALITY_GREEN,
				[3] = g_tStrings.STR_ROLLQUALITY_BLUE,
				[4] = g_tStrings.STR_ROLLQUALITY_PURPLE,
				[5] = g_tStrings.STR_ROLLQUALITY_NACARAT,
			}) do
				table.insert(t, {
					szOption = _L('Reach %s', s),
					rgb = i == -1 and {255, 255, 255} or { GetItemFontColorByQuality(i) },
					bCheck = true, bMCheck = true,
					bChecked = i == O.nConfirmQuality,
					fnAction = function()
						O.nConfirmQuality = i
					end,
				})
			end
			return t
		end,
		autoEnable = function() return O.bOn end,
	}):Width() + 5

	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY,
		text = _L['Loot item filter'],
		menu = D.GetFilterMenu,
		autoEnable = function() return O.bOn end,
	}):Width() + 5

	nX = nX + ui:Append('WndComboBox', {
		x = nX, y = nY,
		text = _L['Auto pickup'],
		menu = D.GetAutoPickupMenu,
		autoEnable = function() return O.bOn end,
	}):Width() + 5

	nLFY = nY + nLH

	return nX, nY, nLFY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_GKPLoot',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'IsEnabled',
				'CanDialog',
				'IsItemDisplay',
				'IsItemAutoPickup',
				'GetMessageBox',
				'GetaPartyMember',
				'GetItemData',
				'GetItemBiddingMenu',
				'OnPanelActivePartial',
			},
			root = D,
		},
		{
			fields = {
				'bOn',
				'tAutoPickupQuality',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'CanDialog',
				'IsItemDisplay',
				'IsItemAutoPickup',
			},
			root = D,
		},
		{
			fields = {
				'bOn',
			},
			root = O,
		},
	},
}
MY_GKPLoot = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterEvent('MY_RESTRICTION', 'MY_GKPLoot', function()
	if arg0 and arg0 ~= 'MY_GKPLoot.FastLoot' then
		return
	end
	D.UpdateShielded()
end)

X.RegisterEvent('LOADING_END', 'MY_GKPLoot', function()
	D.UpdateShielded()
	D.CloseFrame()
	D.aDoodadID = {}
	D.tDoodadInfo = {}
	D.tDoodadClosed = {}
	ITEM_CONFIG.bHideFiltered = false
	D.InsertSceneLoot()
end)

X.RegisterInit('MY_GKPLoot', function()
	for _, k in ipairs({'tConfirm'}) do
		if D[k] then
			X.SafeCall(X.Set, O, k, D[k])
			D[k] = nil
		end
	end
	if D.tItemConfig and X.IsTable(D.tItemConfig) then
		for k, v in pairs(D.tItemConfig) do
			X.SafeCall(X.Set, O, k, v)
		end
		D.tItemConfig = nil
	end
	D.bReady = true
end)

X.RegisterFrameCreate('LootList', 'MY_GKPLoot', function()
	HookTableFunc(arg0, 'SetPoint', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'SetRelPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'SetAbsPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'CorrectPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
end)

X.RegisterFrameCreate('GoldTeamLootList', 'MY_GKPLoot', function()
	HookTableFunc(arg0, 'SetPoint', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'SetRelPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'SetAbsPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
	HookTableFunc(arg0, 'CorrectPos', D.AutoSetSystemLootVisible, { bAfterOrigin = true })
end)

X.RegisterEvent('TEAM_AUTHORITY_CHANGED', 'MY_GKPLoot', D.AutoSetSystemLootVisible)

-- 摸箱子
X.RegisterEvent('OPEN_DOODAD', function()
	if not D.IsEnabled() then
		return
	end
	if arg1 ~= X.GetClientPlayerID() then
		return
	end
	local nM = X.GetDoodadLootMoney(arg0) or 0
	if nM > 0 then
		LootMoney(arg0)
		PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
	end
	local data = D.GetDoodadLootInfo(arg0)
	if #data == 0 then
		return D.DrawLootList(arg0, true)
	end
	--[[#DEBUG BEGIN]]
	X.OutputDebugMessage('MY_GKPLoot', 'Open Doodad: ' .. arg0, X.DEBUG_LEVEL.LOG)
	--[[#DEBUG END]]
	D.tDoodadClosed[arg0] = nil
	D.InsertLootList(arg0)
	D.HideSystemLoot()
end)

-- 刷新箱子
X.RegisterEvent('SYNC_LOOT_LIST', function()
	if not D.IsEnabled() then
		return
	end
	local frame = D.GetFrame()
	local wnd = D.GetDoodadWnd(frame, arg0)
	if not wnd then
		if X.IsInDungeonMap() then
			if X.IsRestricted('MY_GKPLoot.ForceLootInsideDungeon') then
				return
			end
		else
			if X.IsRestricted('MY_GKPLoot.ForceLootOutsideDungeon') then
				return
			end
		end
	end
	if D.tDoodadClosed[arg0] then
		return
	end
	D.InsertLootList(arg0)
end)

X.RegisterEvent('MY_GKP_LOOT_BOSS', function()
	if not arg0 then
		MY_GKP_LOOT_BOSS = nil
		GKP_LOOT_RECENT = {}
	else
		local team = GetClientTeam()
		if team then
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = GetClientTeam().GetMemberInfo(v)
				if info.szName == arg0 then
					MY_GKP_LOOT_BOSS = v
					break
				end
			end
		end
	end
end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
