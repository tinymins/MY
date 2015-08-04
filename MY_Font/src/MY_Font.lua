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
	tFontType = {
		{ dwID = 0, szName = _L['title'] },
		{ dwID = 1, szName = _L['normal\ncontent'] },
		{ dwID = 3, szName = _L['small\ncontent'] },
		{ dwID = 2, szName = _L['large\ncontent'] },
		{ dwID = 4, szName = _L['huge\ncontent'] },
		{ dwID = 6, szName = _L['vertical\ncontent'] },
		{ dwID = 5, szName = _L['chat'] },
		{ dwID = 7, szName = _L['fight'] },
		-- { dwID = 8, szName = _L['8'] },
		-- { dwID = Font.GetChatFontID(), szName = _L['chat'] },
	},
}
local LUA_DATA_PATH = MY.GetAddonInfo().szRoot .. "MY_Font/font/$lang.jx3dat"
for _, v in ipairs(MY.LoadLUAData(LUA_DATA_PATH) or {}) do
	table.insert(C.tFontList, v)
end
for _, p in ipairs(C.tFontList) do
	table.insert(C.aFontPath, p.szFile)
end
local OBJ = {}

function OBJ.SetFont(dwID, szName, szPath, nSize, tStyle)
	-- dwID  : 要改变字体的类型（标题/文本/姓名 等）
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
	Font.SetFont(dwID, szName, szPath, nSize, tStyle)
	Station.SetUIScale(Station.GetUIScale(), true)
	if dwID == Font.GetChatFontID() then
		Wnd.OpenWindow("ChatSettingPanel")
		OutputWarningMessage("MSG_REWARD_GREEN", _L['please click apply or sure button to save change!'], 10)
	end
end

MY.RegisterPanel(
"MY_Font", _L["MY_Font"], _L['General'],
"ui/Image/UICommon/CommonPanel7.UITex|36", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 5
	local w, h = ui:size()
	
	for _, p in ipairs(C.tFontType) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.dwID)
		if tStyle then
			-- local ui = ui:append("WndWindow", { w = w, h = 60 }, true)
			local autocomplete, editname, editsize, chkshadow, chkvertical, chkborder, chkmono, chkmipmap, btn
			local function UpdateBtnEnable()
				local nSize1 = tonumber(editsize:text())
				btn:enable(IsFileExist(autocomplete:text()) and not not nSize1 and nSize1 > 0 and (
					autocomplete:text() ~= szFile or
					editname:text() ~= szName or
					nSize1 ~= nSize or
					not chkshadow:check()   ~= not tStyle.shadow   or
					not chkvertical:check() ~= not tStyle.vertical or
					not chkborder:check()   ~= not tStyle.border   or
					not chkmono:check()     ~= not tStyle.mono     or
					not chkmipmap:check()   ~= not tStyle.mipmap
				))
			end
			x, y = 10, y + 10
			ui:append("Text", { text = p.szName, x = x, y = y, multiline = true })
			x = x + 40
			-- line 1
			y = y - 10
			autocomplete = ui:append("WndAutoComplete", {
				x = x, y = y, w = w - 200,
				text = szFile,
				onchange = function(szText)
					UpdateBtnEnable()
					for _, p in ipairs(C.tFontList) do
						if p.szFile == szText then
							editname:text(p.szName)
							return
						end
					end
					editname:text(g_tStrings.STR_CUSTOM_TEAM)
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
			x = w - 200 + x
			editname  = ui:append("WndEditBox" , { w = 100, h = 25, x = x, y = y, text = szName, onchange = function() UpdateBtnEnable() end }, true)
			x = x + 100
			editsize  = ui:append("WndEditBox" , { w = 50, h = 25, x = x, y = y, text = nSize, onchange = function() UpdateBtnEnable() end }, true)
			-- line 2
			x = 50
			y = y + 25
			chkshadow   = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['shadow'], checked = tStyle.shadow, oncheck = function() UpdateBtnEnable() end }, true)
			x = x + 90
			chkvertical = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['vertical'], checked = tStyle.vertical, oncheck = function() UpdateBtnEnable() end }, true)
			x = x + 90
			chkborder   = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['border'], checked = tStyle.border, oncheck = function() UpdateBtnEnable() end }, true)
			x = x + 90
			chkmono     = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['mono'  ], checked = tStyle.mono  , oncheck = function() UpdateBtnEnable() end }, true)
			x = x + 90
			chkmipmap   = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['mipmap'], checked = tStyle.mipmap, oncheck = function() UpdateBtnEnable() end }, true)
			x = w - 60
			btn         = ui:append("WndButton"  , { w = 60, h = 25, x = x, y = y, text = _L['apply' ], enable = false, onclick = function()
				MY_Font.SetFont(p.dwID, editname:text(), autocomplete:text(), tonumber(editsize:text()), {
					shadow   = chkshadow:check(),
					vertical = chkvertical:check(),
					border   = chkborder:check(),
					mono     = chkmono:check(),
					mipmap   = chkmipmap:check(),
				})
				szName, szFile, nSize, tStyle = Font.GetFont(p.dwID)
			end }, true)
			y = y + 30
		end
	end
end})

MY_Font = OBJ
