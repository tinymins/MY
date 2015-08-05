--------------------------------------------
-- @Desc  : 游戏字体
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-03-01 00:13:27
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Font/lang/")
local C = {
	tFontList = Font.GetFontPathList() or {},
	aFontPath = {},
	aFontName = {},
	tFontType = {
		{ tIDs = {0, 1, 2, 3, 4, 6}, szName = _L['content'] },
		{ tIDs = {Font.GetChatFontID()}, szName = _L['chat'] },
		{ tIDs = {7}, szName = _L['fight'] },
	},
}
local LUA_DATA_PATH = MY.GetAddonInfo().szRoot .. "MY_Font/font/$lang.jx3dat"
for _, v in ipairs(MY.LoadLUAData(LUA_DATA_PATH) or {}) do
	table.insert(C.tFontList, v)
end
for _, p in ipairs(C.tFontList) do
	table.insert(C.aFontPath, p.szFile)
	table.insert(C.aFontName, p.szName)
end
local OBJ = {}

function OBJ.SetFont(tIDs, szName, szPath, nSize, tStyle)
	-- tIDs  : 要改变字体的类型组（标题/文本/姓名 等）
	-- szName: 字体名称
	-- szPath: 字体路径
	-- nSize : 字体大小
	-- tStyle: {
	--     ["vertical"] = (bool),
	--     ["border"  ] = (bool),
	--     ["shadow"  ] = (bool),
	--     ["mono"    ] = (bool),
	--     ["mipmap"  ] = (bool),
	-- }
	-- Ex: SetFont(Font.GetChatFontID(), "黑体", "\\UI\\Font\\方正黑体_GBK.ttf", 16, {["shadow"] = true})
	for _, dwID in ipairs(tIDs) do
		local szName1, szFile1, nSize1, tStyle1 = Font.GetFont(dwID)
		Font.SetFont(dwID, szName or szName1, szPath or szPath1, nSize or nSize1, tStyle or tStyle1)
		Station.SetUIScale(Station.GetUIScale(), true)
		if dwID == Font.GetChatFontID() then
			Wnd.OpenWindow("ChatSettingPanel")
			OutputWarningMessage("MSG_REWARD_GREEN", _L['please click apply or sure button to save change!'], 10)
		end
	end
end

MY.RegisterPanel(
"MY_Font", _L["MY_Font"], _L['General'],
"ui/Image/UICommon/CommonPanel7.UITex|36", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 30
	local w, h = ui:size()
	
	for _, p in ipairs(C.tFontType) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.tIDs[1])
		if tStyle then
			-- local ui = ui:append("WndWindow", { w = w, h = 60 }, true)
			local acFile, acName, btnSure
			local function UpdateBtnEnable()
				local szNewFile = acFile:text()
				local bFileExist = IsFileExist(szNewFile)
				acFile:color(bFileExist and {255, 255, 255} or {255, 0, 0})
				btnSure:enable(bFileExist and szNewFile ~= szFile)
			end
			x = 10
			ui:append("Text", { text = _L[" * "] .. p.szName, x = x, y = y })
			y = y + 40
			
			acFile = ui:append("WndAutoComplete", {
				x = x, y = y, w = w - 180,
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
				onclick = function(nButton, raw)
					if IsPopupMenuOpened() then
						MY.UI(raw):autocomplete('close')
					else
						MY.UI(raw):autocomplete('search', '')
					end
			  	end,
				autocomplete = {{"option", "source", C.aFontPath}},
			}, true)
			
			acName = ui:append("WndAutoComplete", {
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
				onclick = function(nButton, raw)
					if IsPopupMenuOpened() then
						MY.UI(raw):autocomplete('close')
					else
						MY.UI(raw):autocomplete('search', '')
					end
			  	end,
				autocomplete = {{"option", "source", C.aFontName}},
			}, true)
			
			btnSure = ui:append("WndButton", {
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
