--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 游戏字体
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan, atan = math.pow, math.sqrt, math.sin, math.cos, math.tan, math.atan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local LIB = MY
local UI, DEBUG_LEVEL, PATH_TYPE = LIB.UI, LIB.DEBUG_LEVEL, LIB.PATH_TYPE
local var2str, str2var, ipairs_r = LIB.var2str, LIB.str2var, LIB.ipairs_r
local spairs, spairs_r, sipairs, sipairs_r = LIB.spairs, LIB.spairs_r, LIB.sipairs, LIB.sipairs_r
local GetTraceback, Call, XpCall = LIB.GetTraceback, LIB.Call, LIB.XpCall
local Get, Set, RandomChild = LIB.Get, LIB.Set, LIB.RandomChild
local GetPatch, ApplyPatch, clone, FullClone = LIB.GetPatch, LIB.ApplyPatch, LIB.clone, LIB.FullClone
local IsArray, IsDictionary, IsEquals = LIB.IsArray, LIB.IsDictionary, LIB.IsEquals
local IsNil, IsBoolean, IsNumber, IsFunction = LIB.IsNil, LIB.IsBoolean, LIB.IsNumber, LIB.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = LIB.IsEmpty, LIB.IsString, LIB.IsTable, LIB.IsUserdata
local MENU_DIVIDER, EMPTY_TABLE, XML_LINE_BREAKER = LIB.MENU_DIVIDER, LIB.EMPTY_TABLE, LIB.XML_LINE_BREAKER
-------------------------------------------------------------------------------------------------------------
local _L = LIB.LoadLangPack(LIB.GetAddonInfo().szRoot .. 'MY_Font/lang/')
if not LIB.AssertVersion('MY_Font', _L['MY_Font'], 0x2012800) then
	return
end

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
	local szOrgFile = LIB.GetLUADataPath({'config/MY_FONT/$lang.jx3dat', PATH_TYPE.DATA})
	local szFilePath = LIB.GetLUADataPath(CONFIG_PATH)
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	CONFIG = LIB.LoadLUAData(szFilePath) or {}
end

-- 初始化设置
for dwID, tConfig in pairs(CONFIG) do
	local szName, szFile, nSize, tStyle = unpack(tConfig)
	if IsFileExist(szFile) then
		local szName1, szFile1, nSize1, tStyle1 = Font.GetFont(dwID)
		Font.SetFont(dwID, szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1)
	end
end
Station.SetUIScale(Station.GetUIScale(), true)

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
		Station.SetUIScale(Station.GetUIScale(), true)
		if dwID == Font.GetChatFontID() then
			Wnd.OpenWindow('ChatSettingPanel')
			OutputWarningMessage('MSG_REWARD_GREEN', _L['please click apply or sure button to save change!'], 10)
		end
		CONFIG[dwID] = {szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1}
	end
	LIB.SaveLUAData(CONFIG_PATH, CONFIG)
end

-- 配置界面
local PS = {}
function PS.OnPanelActive(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30
	local w, h = ui:size()
	local aFontList = LIB.GetFontList()
	local aFontName, aFontPath = {}, {}

	for _, p in ipairs(aFontList) do
		insert(aFontName, p.szName)
		insert(aFontPath, p.szFile)
	end

	for _, p in ipairs(FONT_TYPE) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
		if tStyle then
			-- local ui = ui:append('WndWindow', { w = w, h = 60 }, true)
			local acFile, acName, btnSure
			local function UpdateBtnEnable()
				local szNewFile = acFile:text()
				local bFileExist = IsFileExist(szNewFile)
				acFile:color(bFileExist and {255, 255, 255} or {255, 0, 0})
				btnSure:enable(bFileExist and szNewFile ~= szFile)
			end
			x = 10
			ui:append('Text', { text = _L[' * '] .. p.szName, x = x, y = y })
			y = y + 40

			acFile = ui:append('WndAutocomplete', {
				x = x, y = y, w = w - 180 - 30,
				text = szFile,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szFile) == szText then
							if acName:text() ~= p.szName then
								acName:text(p.szName)
							end
							return
						end
					end
					acName:text(g_tStrings.STR_CUSTOM_TEAM)
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):autocomplete('close')
					else
						UI(this):autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontPath}},
			}, true)

			ui:append('WndButton', {
				x = w - 180 - x - 10, y = y, w = 25,
				text = '...',
				onclick = function()
					local file = GetOpenFileName(_L['Please select your font file.'], 'Font File(*.ttf;*.otf;*.fon)\0*.ttf;*.otf;*.fon\0All Files(*.*)\0*.*\0\0')
					if not IsEmpty(file) then
						acFile:text(LIB.GetRelativePath(file, ''):gsub('/', '\\'))
					end
				end,
			})

			acName = ui:append('WndAutocomplete', {
				w = 100, h = 25, x = w - 180 + x, y = y,
				text = szName,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(aFontList) do
						if StringLowerW(p.szName) == szText
						and acFile:text() ~= p.szFile then
							acFile:text(p.szFile)
							return
						end
					end
				end,
				onclick = function()
					if IsPopupMenuOpened() then
						UI(this):autocomplete('close')
					else
						UI(this):autocomplete('search', '')
					end
				end,
				autocomplete = {{'option', 'source', aFontName}},
			}, true)

			btnSure = ui:append('WndButton', {
				w = 60, h = 25, x = w - 60, y = y,
				text = _L['apply'], enable = false,
				onclick = function()
					MY_Font.SetFont(p.tIDs, acName:text(), acFile:text())
					szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
					UpdateBtnEnable()
				end
			}, true)
			y = y + 60
		end
	end
end
LIB.RegisterPanel('MY_Font', _L['MY_Font'], _L['System'], 'ui/Image/UICommon/CommonPanel7.UITex|36', PS)

MY_Font = OBJ
