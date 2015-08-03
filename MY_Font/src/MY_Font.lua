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
		{ dwID = 1, szName = _L['content'] },
		{ dwID = 5, szName = _L['chat'] },
		{ dwID = 7, szName = _L['fight'] },
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
end

MY.RegisterPanel(
"MY_Font", _L["MY_Font"], _L['General'],
"ui/Image/UICommon/CommonPanel7.UITex|36", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 20
	local w, h = ui:size()
	
	for _, p in ipairs(C.tFontType) do
		local szName, szFile, nSize, tStyle = Font.GetFont(p.dwID)
		if tStyle then
			local autocomplete, editname, editsize, chkshadow, chkvertical, chkborder, chkmono, chkmipmap, btn
			local function UpdateBtnEnable()
				btn:enable(IsFileExist(autocomplete:text()) and not not tonumber(editsize:text()))
			end
			x, y = 10, y + 10
			ui:append("Text", { text = p.szName, x = x, y = y })
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
			editname  = ui:append("WndEditBox" , { w = 100, h = 25, x = x, y = y, text = szName, onchange = function() end }, true)
			x = x + 100
			editsize  = ui:append("WndEditBox" , { w = 50, h = 25, x = x, y = y, text = nSize, onchange = function() UpdateBtnEnable() end }, true)
			-- line 2
			x = 50
			y = y + 30
			chkshadow = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['shadow'], checked = tStyle.shadow, oncheck = function() end }, true)
			x = x + 100
			chkborder = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['border'], checked = tStyle.border, oncheck = function() end }, true)
			x = x + 100
			chkmono   = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['mono'  ], checked = tStyle.mono  , oncheck = function() end }, true)
			x = x + 100
			chkmipmap = ui:append("WndCheckBox", { w = 100, h = 25, x = x, y = y, text = _L['mipmap'], checked = tStyle.mipmap, oncheck = function() end }, true)
			x = w - 60
			btn       = ui:append("WndButton"  , { w = 60, h = 25, x = x, y = y, text = _L['apply' ], onclick = function()
				MY_Font.SetFont(p.dwID, editname:text(), autocomplete:text(), tonumber(editsize:text()), {
					shadow = chkshadow:check(),
					border = chkborder:check(),
					mono   = chkmono:check(),
					mipmap = chkmipmap:check(),
				})
			end }, true)
			y = y + 60
		end
	end
end})

MY_Font = OBJ
