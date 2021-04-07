--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 技能显示 - 战斗可视化
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
local wsub, wlen, wfind, wgsub = wstring.sub, wstring.len, StringFindW, StringReplaceW
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
local EncodeLUAData, DecodeLUAData = LIB.EncodeLUAData, LIB.DecodeLUAData
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^3.0.1') then
	return
end
--------------------------------------------------------------------------
local INI_PATH = PACKET_INFO.ROOT .. 'MY_ToolBox/ui/MY_VisualSkill.ini'
local DEFAULT_ANCHOR = { x = 0, y = -220, s = 'BOTTOMCENTER', r = 'BOTTOMCENTER' }
local D = {}
local O = {
	bEnable = false,
	bPenetrable = true,
	nVisualSkillBoxCount = 5,
	anchor = Clone(DEFAULT_ANCHOR),
}
RegisterCustomData('MY_VisualSkill.bEnable')
RegisterCustomData('MY_VisualSkill.bPenetrable')
RegisterCustomData('MY_VisualSkill.nVisualSkillBoxCount')
RegisterCustomData('MY_VisualSkill.anchor')

local BOX_WIDTH = 48
local BOX_ANIMATION_TIME = 300
local BOX_SLIDEOUT_DISTANCE = 200

-- local FORMATION_SKILL = {
-- 	[230  ] = true, -- (230)  万花伤害阵法施放  七绝逍遥阵
-- 	[347  ] = true, -- (347)  纯阳气宗阵法施放  九宫八卦阵
-- 	[526  ] = true, -- (526)  七秀治疗阵法施放  花月凌风阵
-- 	[662  ] = true, -- (662)  天策防御阵法释放  九襄地玄阵
-- 	[740  ] = true, -- (740)  少林防御阵法施放  金刚伏魔阵
-- 	[745  ] = true, -- (745)  少林攻击阵法施放  天鼓雷音阵
-- 	[754  ] = true, -- (754)  天策攻击阵法释放  卫公折冲阵
-- 	[778  ] = true, -- (778)  纯阳剑宗阵法施放  北斗七星阵
-- 	[781  ] = true, -- (781)  七秀伤害阵法施放  九音惊弦阵
-- 	[1020 ] = true, -- (1020) 万花治疗阵法施放  落星惊鸿阵
-- 	[1866 ] = true, -- (1866) 藏剑阵法释放      依山观澜阵
-- 	[2481 ] = true, -- (2481) 五毒治疗阵法施放  妙手织天阵
-- 	[2487 ] = true, -- (2487) 五毒攻击阵法施放  万蛊噬心阵
-- 	[3216 ] = true, -- (3216) 唐门外功阵法施放  流星赶月阵
-- 	[3217 ] = true, -- (3217) 唐门内功阵法施放  千机百变阵
-- 	[4674 ] = true, -- (4674) 明教攻击阵法施放  炎威破魔阵
-- 	[4687 ] = true, -- (4687) 明教防御阵法施放  无量光明阵
-- 	[5311 ] = true, -- (5311) 丐帮攻击阵法释放  降龙伏虎阵
-- 	[13228] = true, -- (13228)  临川列山阵释放  临川列山阵
-- 	[13275] = true, -- (13275)  锋凌横绝阵施放  锋凌横绝阵
-- }
local COMMON_SKILL = {
	[10   ] = true, -- (10)    横扫千军           横扫千军
	[11   ] = true, -- (11)    普通攻击-棍攻击     六合棍
	[12   ] = true, -- (12)    普通攻击-枪攻击     梅花枪法
	[13   ] = true, -- (13)    普通攻击-剑攻击     三柴剑法
	[14   ] = true, -- (14)    普通攻击-拳套攻击   长拳
	[15   ] = true, -- (15)    普通攻击-双兵攻击   连环双刀
	[16   ] = true, -- (16)    普通攻击-笔攻击     判官笔法
	[1795 ] = true, -- (1795)  普通攻击-重剑攻击   四季剑法
	[2183 ] = true, -- (2183)  普通攻击-虫笛攻击   大荒笛法
	[3121 ] = true, -- (3121)  普通攻击-弓攻击     罡风镖法
	[4326 ] = true, -- (4326)  普通攻击-双刀攻击   大漠刀法
	[13039] = true, -- (13039) 普通攻击_盾刀攻击   卷雪刀
	[14063] = true, -- (14063) 普通攻击_琴攻击     五音六律
	[16010] = true, -- (16010) 普通攻击_傲霜刀攻击  霜风刀法
	[19712] = true, -- (19712) 普通攻击_蓬莱伞攻击  飘遥伞击
	[17   ] = true, -- (17)    江湖-防身武艺-打坐  打坐
	[18   ] = true, -- (18)    踏云               踏云
}

function D.UpdateAnchor(frame)
	local anchor = O.anchor
	frame:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
	frame:CorrectPos()
end

function D.UpdateAnimation(frame, fPercentage)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nCount = hList:GetItemCount()
	local nSlideLRelX = 0 - BOX_SLIDEOUT_DISTANCE
	local nSlideRRelX = hList:GetW() + BOX_SLIDEOUT_DISTANCE
	-- [0, O.nVisualSkillBoxCount] 最终显示的BOX
	-- [O.nVisualSkillBoxCount - 1, nCount - 1] 用作动画的渐隐BOX
	for i = 0, nCount - 1 do
		local hItem = hList:LogicLookup(i)
		if not hItem.nStartX then
			hItem.nStartX = hItem:GetRelX()
		end
		local nDstRelX = i < O.nVisualSkillBoxCount
			and hList:GetW() - BOX_WIDTH * (i + 1) -- 列表BOX计算排列位置
			or ((fPercentage == 1 or hItem.nStartX > hList:GetW() - BOX_WIDTH)
				and (nSlideRRelX + BOX_WIDTH * (nCount - i + 1)) -- 未参与动画或动画结束的BOX终点为右侧
				or (nSlideLRelX - BOX_WIDTH * (i - O.nVisualSkillBoxCount))) -- 参与动画的BOX终点为左侧
		local nRelX = hItem.nStartX + (nDstRelX - hItem.nStartX) * (
			hItem.nStartX > hList:GetW() - BOX_WIDTH
				and min(fPercentage / 0.4, 1) -- 动画BOX先行运动发起碰撞
				or max((fPercentage - 0.4) / 0.6, 0) -- 列表BOX延迟碰撞
		)
		if hItem.nStartX > hList:GetW() - BOX_WIDTH then -- 右侧进场BOX播放碰撞动画
			if fPercentage < 0.7 and (not hItem.nHitTime or GetTime() - hItem.nHitTime > BOX_ANIMATION_TIME) then
				hItem:Lookup('Animate_Hit'):Replay()
				hItem.nHitTime = GetTime()
			end
		end
		local nAlpha = (nRelX >= 0 and nRelX <= hList:GetW() - BOX_WIDTH)
			and 255
			or (1 - min(abs(nRelX < 0 and nRelX or (hList:GetW() - BOX_WIDTH - nRelX)) / BOX_SLIDEOUT_DISTANCE, 1)) * 255
		hItem:SetRelX(nRelX)
		hItem:SetAlpha(nAlpha)
	end
	hList:FormatAllItemPos()
end

function D.StartAnimation(frame, nStep)
	local hList = frame:Lookup('', 'Handle_Boxes')
	if nStep then
		hList.nIndexBase = (hList.nIndexBase - nStep) % hList:GetItemCount()
	end
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1 do
		local hItem = hList:Lookup(i)
		hItem.nStartX = hItem:GetRelX()
	end
	frame.nTickStart = GetTickCount()
end

-- 绘制正确数量的列表
function D.CorrectBoxCount(frame)
	local hList = frame:Lookup('', 'Handle_Boxes')
	local nBoxCount = O.nVisualSkillBoxCount * 2
	local nBoxCountOffset = nBoxCount - hList:GetItemCount()
	if nBoxCountOffset == 0 then
		return
	end
	if nBoxCountOffset > 0 then
		for i = 1, nBoxCountOffset do
			hList:AppendItemFromIni(INI_PATH, 'Handle_Box'):Lookup('Box_Skill'):Hide()
			for i = hList:GetItemCount() - 1, hList.nIndexBase + 1 do
				hList:ExchangeItemIndex(i, i - 1)
			end
		end
	elseif nBoxCountOffset < 0 then
		for i = nBoxCountOffset, -1 do
			hList:LogicRemoveItem(0)
			hList.nIndexBase = hList.nIndexBase % hList:GetItemCount()
		end
	end
	local nBoxesW = BOX_WIDTH * O.nVisualSkillBoxCount
	frame:Lookup('', 'Handle_Bg/Image_Bg_11'):SetW(nBoxesW)
	frame:Lookup('', 'Handle_Bg'):FormatAllItemPos()
	frame:Lookup('', ''):FormatAllItemPos()
	frame:SetW(nBoxesW + 169)
	hList:SetW(nBoxesW)
	hList.nCount = nBoxCount
	D.UpdateAnimation(frame, 1)
end

function D.OnSkillCast(frame, dwSkillID, dwSkillLevel)
	-- 获取技能信息
	local szSkillName, dwIconID = LIB.GetSkillName(dwSkillID, dwSkillLevel)
	if dwSkillID == 4097 then -- 骑乘
		dwIconID = 1899
	end
	-- 无名技能屏蔽
	if not szSkillName or szSkillName == '' then
		return
	end
	-- 普攻屏蔽
	if COMMON_SKILL[dwSkillID] then
		return
	end
	-- 特殊图标技能屏蔽
	if dwIconID == 1817 --[[闭阵]] or dwIconID == 533 --[[打坐]] or dwIconID == 0 --[[子技能]] or dwIconID == 13 --[[子技能]] then
		return
	end
	-- 阵法释放技能屏蔽
	if Table_IsSkillFormation(dwSkillID, dwSkillLevel) or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel) then
		return
	end
	-- 渲染界面触发动画
	local box = frame:Lookup('', 'Handle_Boxes')
		:LogicLookup(-1):Lookup('Box_Skill')
	box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
	box:SetObjectIcon(dwIconID)
	box:Show()
	D.StartAnimation(frame, 1)
end

function D.OnFrameCreate()
	local hList = this:Lookup('', 'Handle_Boxes')
	hList.LogicLookup = function(el, i)
		return el:Lookup((i + el.nIndexBase) % el.nCount)
	end
	hList.LogicRemoveItem = function(el, i)
		return el:RemoveItem((i + el.nIndexBase) % el.nCount)
	end
	hList.nIndexBase = 0
	hList.nCount = 0
	D.CorrectBoxCount(this)
	this:RegisterEvent('RENDER_FRAME_UPDATE')
	this:RegisterEvent('UI_SCALED')
	this:RegisterEvent('DO_SKILL_CAST')
	this:RegisterEvent('DO_SKILL_CHANNEL_PROGRESS')
	this:RegisterEvent('ON_ENTER_CUSTOM_UI_MODE')
	this:RegisterEvent('ON_LEAVE_CUSTOM_UI_MODE')
	this:RegisterEvent('CUSTOM_UI_MODE_SET_DEFAULT')
	D.OnEvent('UI_SCALED')
end

function D.OnEvent(event)
	if event == 'RENDER_FRAME_UPDATE' then
		if not this.nTickStart then
			return
		end
		local nTickDuring = GetTickCount() - this.nTickStart
		if nTickDuring > 600 then
			this.nTickStart = nil
		end
		D.UpdateAnimation(this, min(max(nTickDuring / BOX_ANIMATION_TIME, 0), 1))
	elseif event == 'UI_SCALED' then
		D.UpdateAnchor(this)
	elseif event == 'DO_SKILL_CAST' then
		local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'DO_SKILL_CHANNEL_PROGRESS' then
		local dwID, dwSkillID, dwSkillLevel = arg3, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			D.OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == 'ON_ENTER_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
	elseif event == 'ON_LEAVE_CUSTOM_UI_MODE' then
		UpdateCustomModeWindow(this, _L['Visual skill'], O.bPenetrable)
		MY_VisualSkill.anchor = GetFrameAnchor(this)
	elseif event == 'CUSTOM_UI_MODE_SET_DEFAULT' then
		MY_VisualSkill.anchor = Clone(DEFAULT_ANCHOR)
		D.UpdateAnchor(this)
	end
end

function D.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_VisualSkill')
end

function D.GetFrame()
	return Station.Lookup('Normal/MY_VisualSkill')
end

function D.Close()
	Wnd.CloseWindow('MY_VisualSkill')
end

function D.Reload()
	if O.bEnable then
		local frame = D.GetFrame()
		if frame then
			D.CorrectBoxCount(frame)
		else
			D.Open()
		end
	else
		D.Close()
	end
end
LIB.RegisterInit('MY_VISUALSKILL', D.Reload)

function D.OnPanelActivePartial(ui, X, Y, W, H, x, y, deltaY)
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y, w = 'auto',
		text = _L['Visual skill'],
		checked = MY_VisualSkill.bEnable,
		oncheck = function(bChecked)
			MY_VisualSkill.bEnable = bChecked
		end,
	}):Width() + 5

	ui:Append('WndTrackbar', {
		x = x, y = y,
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE, range = {1, 32},
		value = MY_VisualSkill.nVisualSkillBoxCount,
		text = _L('Display %d skills.', MY_VisualSkill.nVisualSkillBoxCount),
		textfmt = function(val) return _L('Display %d skills.', val) end,
		onchange = function(val)
			MY_VisualSkill.nVisualSkillBoxCount = val
		end,
	})
	x = X
	y = y + deltaY
	return x, y
end

---------------------------------------------------------------------
-- Global exports
---------------------------------------------------------------------
do
local settings = {
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			preset = 'UIEvent',
			root = D,
		},
		{
			fields = {
				bEnable              = true,
				bPenetrable          = true,
				nVisualSkillBoxCount = true,
				anchor               = true,
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				bEnable              = true,
				bPenetrable          = true,
				nVisualSkillBoxCount = true,
				anchor               = true,
			},
			triggers = {
				bEnable              = D.Reload,
				nVisualSkillBoxCount = D.Reload,
			},
			root = O,
		},
	},
}
MY_VisualSkill = LIB.GeneGlobalNS(settings)
end
