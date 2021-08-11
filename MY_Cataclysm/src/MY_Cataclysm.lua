--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 团队面板模块
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
local wlen, wfind, wgsub, wlower = wstring.len, StringFindW, StringReplaceW, StringLowerW
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
local EncodeLUAData, DecodeLUAData, Schema = LIB.EncodeLUAData, LIB.DecodeLUAData, LIB.Schema
local GetTraceback, RandomChild, GetGameAPI = LIB.GetTraceback, LIB.RandomChild, LIB.GetGameAPI
local Get, Set, Clone, GetPatch, ApplyPatch = LIB.Get, LIB.Set, LIB.Clone, LIB.GetPatch, LIB.ApplyPatch
local IIf, CallWithThis, SafeCallWithThis = LIB.IIf, LIB.CallWithThis, LIB.SafeCallWithThis
local Call, XpCall, SafeCall, NSFormatString = LIB.Call, LIB.XpCall, LIB.SafeCall, LIB.NSFormatString
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Cataclysm'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Cataclysm'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^8.0.0') then
	return
end
--------------------------------------------------------------------------

local O = LIB.CreateUserSettingsModule('MY_Cataclysm', _L['Raid'], {
	bEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	eCss = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.String,
		xDefaultValue = '',
	},
	eFrameStyle = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.String,
		xDefaultValue = 'CATACLYSM',
	},
	bDrag = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowInRaid = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bEditMode = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowAllGrid = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tAnchor = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.FrameAnchor,
		xDefaultValue = { s = 'LEFTCENTER', r = 'LEFTCENTER', x = 100, y = -200 },
	},
	nAutoLinkMode = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 5,
	},
	nBGColorMode = { -- 0 不着色 1 根据距离 2 根据门派
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	nColoredName = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	nNameVAlignment = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 0,
	},
	nNameHAlignment = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 0,
	},
	nHPShownMode2 = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 2,
	},
	nHPShownNumMode = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 3,
	},
	nHPVAlignment = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 2,
	},
	nHPHAlignment = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 2,
	},
	bShowHPDecimal = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffAboveMana = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	nShowMP = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bHPHitAlert = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	nShowIcon = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 2,
	},
	bShowDistance = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowBossTarget = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBossFocus = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bEnableDistance = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowTargetTargetAni = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nNameFont = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 40,
	},
	nLifeFont = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 15,
	},
	nManaFont = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 190,
	},
	fNameFontScale = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1.05,
	},
	fLifeFontScale = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1.05,
	},
	fManaFontScale = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	nMaxShowBuff = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 4,
	},
	bLifeGradient = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bManaGradient = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	nAlpha = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 220,
	},
	fBuffScale = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1,
	},
	bAutoBuffSize = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bAltView = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bAltViewInFight = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bHideTipInFight = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowTipAtRightBottom = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bTempTargetEnable = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	nTempTargetDelay = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 0,
	},
	fScaleX = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1.1,
	},
	fScaleY = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 1.0,
	},
	bFasterHP = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bStaring = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	bShowBuffTime = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBuffNum = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowBuffReminder = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffAltPublish = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffPushToOfficial = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bBuffDataTeamMon = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowAttention = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowCaution = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowScreenHead = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowGroupNumber = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = true,
	},
	bShowEffect = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false, -- 五毒醉舞提示 万花距离提示 晚点做
	},
	bShowSputtering = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Boolean,
		xDefaultValue = false,
	},
	tSputteringFontColor = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 79, 255, 108 },
	},
	nSputteringFontAlpha = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 192,
	},
	tSputteringShadowColor = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 79, 255, 108 },
	},
	nSputteringShadowAlpha = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 192,
	},
	nSputteringDistance = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Number,
		xDefaultValue = 15,
	},
	aBuffList = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Map(Schema.Number, Schema.Any),
		xDefaultValue = {},
	},
	tDistanceLevel = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Map(Schema.Number, Schema.Number),
		xDefaultValue = { 20, 22, 200 },
	},
	tManaColor = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = { 0, 96, 255 },
	},
	tDistanceCol = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Map(Schema.Number, Schema.Tuple(Schema.Number, Schema.Number, Schema.Number)),
		xDefaultValue = {
			{ 0,   180, 52  }, -- 绿
			{ 0,   180, 52  }, -- 绿
			-- 免得被说乱
			-- { 230, 170, 40  }, -- 黄
			{ 230, 80,  80  }, -- 红
			{ 230, 80,  80  }, -- 红
		},
	},
	tOtherCol = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Map(Schema.Number, Schema.Tuple(Schema.Number, Schema.Number, Schema.Number)),
		xDefaultValue = {
			{ 255, 255, 255 },
			{ 110, 110, 110 },
			{ 192, 192, 192 },
		},
	},
	tDistanceAlpha = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Map(Schema.Number, Schema.Number),
		xDefaultValue = {
			255,
			255,
			110,
		},
	},
	tOtherAlpha = {
		ePathType = PATH_TYPE.ROLE,
		szLabel = _L['MY_Cataclysm'],
		xSchema = Schema.Tuple(Schema.Number, Schema.Number, Schema.Number),
		xDefaultValue = {
			0,
			255, -- 不在线
			110, -- 出同步范围
		},
	},
})
local D = {
	CFG = O,
	bFold = false,
	BG_COLOR_MODE = {
		SAME_COLOR = 0,
		BY_DISTANCE = 1,
		BY_FORCE = 2,
		OFFICIAL = 3,
	},
}

-- 解析
function D.EncodeBuffRule(v, bNoBasic)
	local a = {}
	if not bNoBasic then
		insert(a, v.szName or v.dwID)
		if v.nLevel then
			insert(a, 'lv' .. v.nLevel)
		end
	end
	if v.nStackNum then
		insert(a, 'sn' .. (v.szStackOp or '>=') .. v.nStackNum)
	end
	if v.bOnlyMe then
		insert(a, 'me')
	end
	if v.bOnlyMine or v.bOnlySelf or v.bSelf then
		insert(a, 'mine')
	end
	a = { concat(a, '|') }

	if v.col then
		local cols = { v.col }
		if v.nColAlpha and v.col:sub(1, 1) ~= '#' then
			insert(cols, v.nColAlpha)
		end
		insert(a, '[' .. concat(cols, '|') .. ']')
	end
	if not IsEmpty(v.szReminder) then
		insert(a, '(' .. v.szReminder .. ')')
	end
	if v.nPriority then
		insert(a, '#' .. v.nPriority)
	end
	if v.bAttention then
		insert(a, '!!')
	end
	if v.bCaution then
		insert(a, '!!!')
	end
	if v.bScreenHead then
		if v.colScreenHead then
			insert(a, '!!!!|[' .. v.colScreenHead .. ']')
		else
			insert(a, '!!!!')
		end
	end
	if v.bDelete then
		insert(a, '-')
	end
	return concat(a, ',')
end

function D.DecodeBuffRule(line)
	line = LIB.TrimString(line)
	if line ~= '' then
		local tab = {}
		local vals = LIB.SplitString(line, ',')
		for i, val in ipairs(vals) do
			if i == 1 then
				local vs = LIB.SplitString(val, '|')
				for j, v in ipairs(vs) do
					v = LIB.TrimString(v)
					if v ~= '' then
						if j == 1 then
							tab.dwID = tonumber(v)
							if not tab.dwID then
								tab.szName = v
							end
						elseif v == 'self' or v == 'mine' then
							tab.bOnlyMine = true
						elseif v:sub(1, 2) == 'lv' then
							tab.nLevel = tonumber((v:sub(3)))
						elseif v:sub(1, 2) == 'sn' then
							if tonumber(v:sub(4, 4)) then
								tab.szStackOp = v:sub(3, 3)
								tab.nStackNum = tonumber((v:sub(4)))
							else
								tab.szStackOp = v:sub(3, 4)
								tab.nStackNum = tonumber((v:sub(5)))
							end
						end
					end
				end
			elseif val == '!!' then
				tab.bAttention = true
			elseif val == '!!!' then
				tab.bCaution = true
			elseif val == '!!!!' or val:sub(1, 5) == '!!!!|' then
				tab.bScreenHead = true
				local vs = LIB.SplitString(val, '|')
				for _, v in ipairs(vs) do
					if v:sub(1, 1) == '[' and v:sub(-1, -1) == ']' then
						tab.colScreenHead = v:sub(2, -2)
					end
				end
			elseif val == '-' then
				tab.bDelete = true
			elseif val:sub(1, 1) == '#' then
				tab.nPriority = tonumber((val:sub(2)))
			elseif val:sub(1, 1) == '[' and val:sub(-1, -1) == ']' then
				val = val:sub(2, -2)
				if val:sub(1, 1) == '#' then
					tab.col = val
				else
					local vs = LIB.SplitString(val, '|')
					tab.col = vs[1]
					tab.nColAlpha = vs[2] and tonumber(vs[2])
				end
			elseif val:sub(1, 1) == '(' and val:sub(-1, -1) == ')' then
				tab.szReminder = val:sub(2, -2)
			end
		end
		if tab.dwID or tab.szName then
			return tab
		end
	end
end

function D.OpenBuffRuleEditor(rec, onChangeNotify, onCloseNotify, bHideBase)
	local w, h = 320, 320
	local ui = UI.CreateFrame('MY_Cataclysm_BuffConfig', {
		w = w, h = h,
		text = _L['Edit buff'],
		close = true, anchor = 'CENTER',
	}):Remove(function()
		if not bHideBase and not rec.dwID and (not rec.szName or rec.szName == '') then
			onChangeNotify()
		end
		SafeCall(onCloseNotify)
	end)
	local nPaddingX, nPaddingY = 25, 60
	local x, y = nPaddingX, nPaddingY
	if not bHideBase then
		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Name or id'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 105, h = 25,
			text = rec.dwID or rec.szName,
			onchange = function(text)
				if tonumber(text) then
					rec.dwID = tonumber(text)
					rec.szName = nil
				else
					rec.dwID = nil
					rec.szName = text
				end
				onChangeNotify(rec)
			end,
		}):Width() + 15

		x = x + ui:Append('Text', {
			x = x, y = y, h = 25,
			text = _L['Level'],
		}):AutoWidth():Width() + 5
		x = x + ui:Append('WndEditBox', {
			x = x, y = y, w = 60, h = 25,
			placeholder = _L['No limit'],
			edittype = UI.EDIT_TYPE.NUMBER, text = rec.nLevel,
			onchange = function(text)
				rec.nLevel = tonumber(text)
				onChangeNotify(rec)
			end,
		}):Width() + 5
		y = y + 30
		y = y + 10
	end

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Stacknum'],
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndComboBox', {
		name = 'WndComboBox_StackOp',
		x = x, y = y, w = 90, h = 25,
		text = rec.szStackOp or (rec.nStackNum and '>=' or _L['No limit']),
		menu = function()
			local this = this
			local menu = {{
				szOption = _L['No limit'],
				fnAction = function()
					rec.szStackOp = nil
					ui:Children('#WndEditBox_StackNum'):Text('')
					onChangeNotify(rec)
					UI(this):Text(_L['No limit'])
				end,
			}}
			for _, op in ipairs({ '>=', '=', '!=', '<', '<=', '>', '>=' }) do
				insert(menu, {
					szOption = op,
					fnAction = function()
						rec.szStackOp = op
						onChangeNotify(rec)
						UI(this):Text(op)
					end,
				})
			end
			return menu
		end,
	}):Width() + 5
	x = x + ui:Append('WndEditBox', {
		name = 'WndEditBox_StackNum',
		x = x, y = y, w = 30, h = 25,
		edittype = UI.EDIT_TYPE.NUMBER,
		text = rec.nStackNum,
		onchange = function(text)
			rec.nStackNum = tonumber(text)
			if rec.nStackNum then
				if not rec.szStackOp then
					rec.szStackOp = '>='
					ui:Children('#WndComboBox_StackOp'):Text('>=')
				end
			end
			onChangeNotify(rec)
		end,
	}):Width() + 10

	ui:Append('WndCheckBox', {
		x = x, y = y - 10,
		text = _L['Only mine'],
		checked = rec.bOnlyMine,
		oncheck = function(bChecked)
			rec.bOnlyMine = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	ui:Append('WndCheckBox', {
		x = x, y = y + 10,
		text = _L['Only me'],
		checked = rec.bOnlyMe,
		oncheck = function(bChecked)
			rec.bOnlyMe = bChecked
			onChangeNotify(rec)
		end,
	}):AutoWidth()
	y = y + 30
	y = y + 10

	if not bHideBase then
		x = nPaddingX
		y = y + 10
		x = x + ui:Append('WndCheckBox', {
			x = x, y = y,
			text = _L['Hide (Can Modify Default Data)'],
			checked = rec.bDelete,
			oncheck = function(bChecked)
				rec.bDelete = bChecked
				onChangeNotify(rec)
			end,
		}):AutoWidth():Width() + 5
		y = y + 30
		y = y + 10
	end

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Reminder'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 30, h = 25,
		text = rec.szReminder,
		onchange = function(text)
			rec.szReminder = text
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Priority'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndEditBox', {
		x = x, y = y, w = 40, h = 25,
		edittype = UI.EDIT_TYPE.NUMBER,
		text = rec.nPriority,
		onchange = function(text)
			rec.nPriority = tonumber(text)
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Color'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.col and {LIB.HumanColor2RGB(rec.col)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				local a = rec.col and select(4, LIB.Hex2RGB(rec.col)) or 255
				rec.nColAlpha = a
				rec.col = LIB.RGB2Hex(r, g, b, a)
				UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onrclick = function()
			UI(this):Color(255, 255, 0)
			rec.col = nil
			onChangeNotify(rec)
		end,
		tip = _L['Left click to change color, right click to clear color'],
		tippostype = UI.TIP_POSITION.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	x = x + ui:Append('Shadow', {
		x = x, y = y + 2, w = 22, h = 22,
		color = rec.colScreenHead and {LIB.HumanColor2RGB(rec.colScreenHead)} or {255, 255, 0},
		onlclick = function()
			local this = this
			UI.OpenColorPicker(function(r, g, b)
				rec.colScreenHead = LIB.RGB2Hex(r, g, b)
				UI(this):Color(r, g, b)
				onChangeNotify(rec)
			end)
		end,
		onrclick = function()
			UI(this):Color(255, 255, 0)
			rec.colScreenHead = nil
			onChangeNotify(rec)
		end,
		tip = _L['Left click to change screen head color, right click to clear color'],
		tippostype = ALW.TOP_BOTTOM,
		autoenable = function() return not rec.bDelete end,
	}):Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('Text', {
		x = x, y = y, h = 25,
		text = _L['Border alpha'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndTrackbar', {
		x = x, y = y, text = '',
		range = {0, 255},
		trackbarstyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
		value = rec.col and select(4, LIB.HumanColor2RGB(rec.col)) or rec.nColAlpha or 255,
		onchange = function(nVal)
			if rec.col then
				local r, g, b = LIB.Hex2RGB(rec.col)
				if r and g and b then
					rec.col = LIB.RGB2Hex(r, g, b, nVal)
				end
			end
			rec.nColAlpha = nVal
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	y = y + 30

	x = nPaddingX
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Attention'],
		checked = rec.bAttention,
		oncheck = function(bChecked)
			rec.bAttention = bChecked
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Caution'],
		checked = rec.bCaution,
		oncheck = function(bChecked)
			rec.bCaution = bChecked
			onChangeNotify(rec)
		end,
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5
	x = x + ui:Append('WndCheckBox', {
		x = x, y = y,
		text = _L['Screen Head'],
		checked = rec.bScreenHead,
		oncheck = function(bChecked)
			rec.bScreenHead = bChecked
			onChangeNotify(rec)
		end,
		tip = _L['Requires MY_LifeBar loaded.'],
		autoenable = function() return not rec.bDelete end,
	}):AutoWidth():Width() + 5

	y = y + 50
	ui:Append('WndButton', {
		x = (w - 120) / 2, y = y, w = 120,
		text = _L['Delete'], color = {223, 63, 95},
		buttonstyle = 'FLAT',
		onclick = function()
			local function fnAction()
				onChangeNotify()
				ui:Remove()
			end
			if rec.dwID or (rec.szName and rec.szName ~= '') then
				LIB.Confirm(_L('Delete [%s]?', rec.szName or rec.dwID), fnAction)
			else
				fnAction()
			end
		end,
	})
	y = y + 30

	h = y + 15
	ui:Height(h)
end

--------------------------------------------------------------------------
-- Global exports
--------------------------------------------------------------------------
do
local settings = {
	name = 'MY_Cataclysm',
	exports = {
		{
			fields = {
				'CFG',
				'bFold',
				'BG_COLOR_MODE',
				'EncodeBuffRule',
				'DecodeBuffRule',
				'OpenBuffRuleEditor',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
	imports = {
		{
			fields = {
				'CFG',
				'bFold',
				'BG_COLOR_MODE',
			},
			root = D,
		},
		{
			fields = {
				'bEnable',
			},
			root = O,
		},
	},
}
MY_Cataclysm = LIB.CreateModule(settings)
end
