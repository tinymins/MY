--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 游戏字体
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
local PLUGIN_NAME = 'MY_Font'
local PLUGIN_ROOT = PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Font'
local _L = LIB.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not LIB.AssertVersion(MODULE_NAME, _L[MODULE_NAME], 0x2014200) then
	return
end
--------------------------------------------------------------------------

-- 本地变量
local OBJ = {}
local FONT_TYPE = {
	{ tIDs = {0, 1, 2, 3, 4, 6    }, szName = _L['content'] },
	{ tIDs = {Font.GetChatFontID()}, szName = _L['chat'   ] },
	{ tIDs = {7                   }, szName = _L['fight'  ] },
}
local CONFIG

-- 加载字体配置
local CONFIG_PATH = {'config/fontconfig.jx3dat', PATH_TYPE.GLOBAL}
do
	local szOrgFile = LIB.GetLUADataPath({'config/MY_FONT/{$lang}.jx3dat', PATH_TYPE.DATA})
	local szFilePath = LIB.GetLUADataPath(CONFIG_PATH)
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	CONFIG = LIB.LoadLUAData(szFilePath) or {}
end

-- 初始化设置
do
	local bChanged = false
	for dwID, tConfig in pairs(CONFIG) do
		local szName, szFile, nSize, tStyle = unpack(tConfig)
		if IsFileExist(szFile) then
			local szCurName, szCurFile, nCurSize, tCurStyle = Font.GetFont(dwID)
			local szNewName, szNewFile, nNewSize, tNewStyle = szName or szCurName, szFile or szCurFile, nSize or nCurSize, tStyle or tCurStyle
			if not IsEquals(szNewName, szCurName) or not IsEquals(szNewFile, szCurFile)
			or not IsEquals(nNewSize, nCurSize) or not IsEquals(tNewStyle, tCurStyle) then
				Font.SetFont(dwID, szNewName, szNewFile, nNewSize, tNewStyle)
				bChanged = true
			end
		end
	end
	if bChanged then
		Station.SetUIScale(Station.GetUIScale(), true)
	end
end

-- 设置字体
function OBJ.SetFont(tIDs, szName, szFile, nSize, tStyle)
	-- tIDs  : 要改变字体的类型组（标题/文本/姓名 等）
	-- szName: 字体名称
	-- szFile: 字体路径
	-- nSize : 字体大小
	-- tStyle: {
	--     ['vertical'] = (bool),
	--     ['border'  ] = (bool),
	--     ['shadow'  ] = (bool),
	--     ['mono'    ] = (bool),
	--     ['mipmap'  ] = (bool),
	-- }
	-- Ex: SetFont(Font.GetChatFontID(), '黑体', '\\UI\\Font\\方正黑体_GBK.ttf', 16, {['shadow'] = true})
	for _, dwID in ipairs(tIDs) do
		local szName1, szFile1, nSize1, tStyle1 = Font.GetFont(dwID)
		Font.SetFont(dwID, szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1)
		if dwID == Font.GetChatFontID() then
			Wnd.OpenWindow('ChatSettingPanel')
			OutputWarningMessage('MSG_REWARD_GREEN', _L['please click apply or sure button to save change!'], 10)
		end
		CONFIG[dwID] = {szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1}
	end
	LIB.SaveLUAData(CONFIG_PATH, CONFIG)
	Station.SetUIScale(Station.GetUIScale(), true)
end

-- 配置界面
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30
	local w, h = ui:Size()
	local aFontList = LIB.GetFontList()
	local aFontName, aFontPath = {}, {}

	for _, p in ipairs(aFontList) do
		insert(aFontName, p.szName)
		insert(aFontPath, p.szFile)
	end

	for _, p in ipairs(FONT_TYPE) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
		if tStyle then
			-- local ui = ui:Append('WndWindow', { w = w, h = 60 })
			local acFile, acName, btnSure
			local function UpdateBtnEnable()
				local szNewFile = acFile:Text()
				local bFileExist = IsFileExist(szNewFile)
				acFile:Color(bFileExist and {255, 255, 255} or {255, 0, 0})
				btnSure:Enable(bFileExist and szNewFile ~= szFile)
			end
			x = 10
			ui:Append('Text', { text = _L[' * '] .. p.szName, x = x, y = y })
			y = y + 40

			acFile = ui:Append('WndAutocomplete', {
				x = x, y = y, w = w - 180 - 30,
				text = szFile,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szFile) == szText then
							if acName:Text() ~= p.szName then
								acName:Text(p.szName)
							end
							return
						end
					end
					acName:Text(g_tStrings.STR_CUSTOM_TEAM)
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):Autocomplete('close')
					else
						UI(this):Autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontPath}},
			})

			ui:Append('WndButton', {
				x = w - 180 - x - 10, y = y, w = 25,
				text = '...',
				onclick = function()
					local file = GetOpenFileName(_L['Please select your font file.'], 'Font File(*.ttf;*.otf;*.fon)\0*.ttf;*.otf;*.fon\0All Files(*.*)\0*.*\0\0')
					if not IsEmpty(file) then
						file = LIB.GetRelativePath(file, '') or file
						acFile:Text(wgsub(file, '/', '\\'))
					end
				end,
			})

			acName = ui:Append('WndAutocomplete', {
				w = 100, h = 25, x = w - 180 + x, y = y,
				text = szName,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szName) == szText
						and acFile:Text() ~= p.szFile then
							acFile:Text(p.szFile)
							return
						end
					end
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):Autocomplete('close')
					else
						UI(this):Autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontName}},
			})

			btnSure = ui:Append('WndButton', {
				w = 60, h = 25, x = w - 60, y = y,
				text = _L['apply'], enable = false,
				onclick = function()
					MY_Font.SetFont(p.tIDs, acName:Text(), acFile:Text())
					szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
					UpdateBtnEnable()
				end
			})
			y = y + 60
		end
	end
end
LIB.RegisterPanel('MY_Font', _L['MY_Font'], _L['System'], 'ui/Image/UICommon/CommonPanel7.UITex|36', PS)

MY_Font = OBJ
