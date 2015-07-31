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
	tFontType = {
		{ dwID = Font.GetChatFontID(), szName = _L['chat'] }
	},
}
local OBJ = {}

function OBJ.SetFont(dwID, szName, szPath, nSize, tTable)
	-- dwID  : 要改变字体的类型（标题/文本/姓名 等）
	-- szName: 字体名称
	-- szPath: 字体路径
	-- nSize : 字体大小
	-- tTable: {
	--     ["vertical"] = (bool),
	--     ["border"  ] = (bool),
	--     ["shadow"  ] = (bool),
	--     ["mono"    ] = (bool),
	--     ["mipmap"  ] = (bool),
	-- }
	-- Ex: SetFont(Font.GetChatFontID(), "黑体", "\\UI\\Font\\方正黑体_GBK.ttf", 16, {["shadow"] = true})
	Font.SetFont(dwID, szName, szPath, nSize, tTable)
	Station.SetUIScale(Station.GetUIScale(), true)
end

MY.RegisterPanel(
"MY_Font", _L["MY_Font"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 30
	
end})

MY_Font = OBJ
