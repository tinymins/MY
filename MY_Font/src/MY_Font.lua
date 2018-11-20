--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 游戏字体
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Font/lang/')
if not MY.AssertVersion('MY_Font', _L['MY_Font'], 0x2011800) then
	return
end
local C = {
	tFontList = Font.GetFontPathList() or {},
	aFontPath = {},
	aFontName = {},
	tFontType = {
		{ tIDs = {0, 1, 2, 3, 4, 6    }, szName = _L['content'] },
		{ tIDs = {Font.GetChatFontID()}, szName = _L['chat'   ] },
		{ tIDs = {7                   }, szName = _L['fight'  ] },
	},
}
local OBJ = {}
-- 加载字体配置
local CONFIG_PATH = {'config/fontconfig.jx3dat', MY_DATA_PATH.GLOBAL}
do
	local szOrgFile = MY.GetLUADataPath('config/MY_FONT/$lang.jx3dat')
	local szFilePath = MY.GetLUADataPath(CONFIG_PATH)
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	C.tFontConfig = MY.LoadLUAData(szFilePath) or {}
end
-- 加载字体列表
local FONT_PATH = MY.GetAddonInfo().szRoot .. 'MY_Font/font/$lang.jx3dat'
for _, v in ipairs(MY.LoadLUAData(FONT_PATH) or {}) do
	table.insert(C.tFontList, v)
end
for _, p in ipairs(C.tFontList) do
	table.insert(C.aFontPath, p.szFile)
	table.insert(C.aFontName, p.szName)
end

-- 初始化设置
for dwID, tConfig in pairs(C.tFontConfig) do
	local szName, szFile, nSize, tStyle  = unpack(tConfig)
	local szName1, szFile1, nSize1, tStyle1 = Font.GetFont(dwID)
	Font.SetFont(dwID, szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1)
end
Station.SetUIScale(Station.GetUIScale(), true)

-- 设置字体函数
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
		C.tFontConfig[dwID] = {szName or szName1, szFile or szFile1, nSize or nSize1, tStyle or tStyle1}
	end
	MY.SaveLUAData(CONFIG_PATH, C.tFontConfig)
end

MY.RegisterPanel(
'MY_Font', _L['MY_Font'], _L['System'],
'ui/Image/UICommon/CommonPanel7.UITex|36', {
OnPanelActive = function(wnd)
	local ui = UI(wnd)
	local x, y = 10, 30
	local w, h = ui:size()

	for _, p in ipairs(C.tFontType) do
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
					for _, p in ipairs(C.tFontList) do
						if StringLowerW(p.szFile) == szText
						and acName:text() ~= p.szName then
							acName:text(p.szName)
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
				autocomplete = {{'option', 'source', C.aFontPath}},
			}, true)

			ui:append('WndButton', {
				x = w - 180 - x - 10, y = y, w = 25,
				text = '...',
				onclick = function()
					local file = GetOpenFileName(_L['Please select your font file.'], 'Font File(*.ttf;*.fon)\0*.ttf;*.fon\0All Files(*.*)\0*.*\0\0')
					if not empty(file) then
						local szRoot = GetRootPath()
						if file:sub(1, #szRoot) == szRoot then
							file = file:sub(#szRoot + 1)
						end
						acFile:text(file)
					end
				end,
			})

			acName = ui:append('WndAutocomplete', {
				w = 100, h = 25, x = w - 180 + x, y = y,
				text = szName,
				onchange = function(szText)
					UpdateBtnEnable()
					szText = StringLowerW(szText)
					for _, p in ipairs(C.tFontList) do
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
				autocomplete = {{'option', 'source', C.aFontName}},
			}, true)

			btnSure = ui:append('WndButton', {
				w = 60, h = 25, x = w - 60, y = y,
				text = _L['apply' ], enable = false,
				onclick = function()
					MY_Font.SetFont(p.tIDs, acName:text(), acFile:text())
					szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
					UpdateBtnEnable()
				end
			}, true)
			y = y + 60
		end
	end
end})

MY_Font = OBJ
