-----------------------------------------------
-- @Desc  : ÀÊ…Ì±„º„
-- @Author: ‹¯“¡ @tinymins
-- @Date  : 2014-11-25 12:31:03
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2016-12-13 15:23:48
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. 'MY_Toolbox/lang/')
local ROLE_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 135 },
}
local GLOBAL_MEMO = {
	bEnable = false,
	nWidth = 200,
	nHeight = 200,
	szContent = '',
	anchor = { s = 'TOPRIGHT', r = 'TOPRIGHT', x = -310, y = 335 },
}
local D = {}
MY_Memo = {}
RegisterCustomData('MY_Anmerkungen.szNotePanelContent')

function D.Reload(bGlobal)
	local CFG_O = bGlobal and GLOBAL_MEMO or ROLE_MEMO
	local CFG = setmetatable({}, {
		__index = CFG_O,
		__newindex = function(t, k, v)
			CFG_O[k] = v
			MY.DelayCall('MY_Memo_SaveConfig', D.SaveConfig)
		end,
	})
	local NAME = bGlobal and 'MY_MemoGlobal' or 'MY_MemoRole'
	local TITLE = bGlobal and _L['MY Memo (Global)'] or _L['MY Memo (Role)']
	MY.UI('Normal/' .. NAME):remove()
	if CFG.bEnable then
		if not bGlobal and CFG.szContent == ''
		and MY_Anmerkungen and MY_Anmerkungen.szNotePanelContent then
			CFG.szContent = MY_Anmerkungen.szNotePanelContent
			D.SaveConfig()
			MY_Anmerkungen.szNotePanelContent = nil
		end
		XGUI.CreateFrame(NAME, {
			simple = true, alpha = 140,
			maximize = true, minimize = true, dragresize = true,
			minwidth = 180, minheight = 100,
			onmaximize = function(wnd)
				local ui = MY.UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			onrestore = function(wnd)
				local ui = MY.UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			ondragresize = function(wnd)
				local ui = MY.UI(wnd:GetRoot())
				CFG.nWidth  = ui:width()
				CFG.anchor  = ui:anchor()
				CFG.nHeight = ui:height()
				local ui = MY.UI(wnd)
				ui:children('#WndEditBox_Memo'):size(ui:size())
			end,
			w = CFG.nWidth, h = CFG.nHeight, text = TITLE,
			dragable = true, dragarea = {0, 0, CFG.nWidth, 30},
			anchor = CFG.anchor,
			events = {{ 'UI_SCALED', function() XGUI(this):anchor(CFG.anchor) end }},
			uievents = {{ 'OnFrameDragEnd', function() CFG.anchor = XGUI('Normal/' .. NAME):anchor() end }},
		}):append('WndEditBox', {
			name = 'WndEditBox_Memo',
			x = 0, y = 0, w = CFG.nWidth, h = CFG.nHeight - 30,
			text = CFG.szContent, multiline = true,
			onchange = function(text) CFG.szContent = text end,
		})
	end
end

function D.LoadConfig()
	local CFG = MY.LoadLUAData({'config/memo.jx3dat', MY_DATA_PATH.GLOBAL})
	if CFG then
		for k, v in pairs(CFG) do
			GLOBAL_MEMO[k] = v
		end
	end

	local CFG = MY.LoadLUAData({'config/memo.jx3dat', MY_DATA_PATH.ROLE})
	if CFG then
		for k, v in pairs(CFG) do
			ROLE_MEMO[k] = v
		end
		ROLE_MEMO.bEnableGlobal = nil
		GLOBAL_MEMO.bEnable = CFG.bEnableGlobal
	end
end

function D.SaveConfig()
	local CFG = {}
	for k, v in pairs(ROLE_MEMO) do
		CFG[k] = v
	end
	CFG.bEnableGlobal = GLOBAL_MEMO.bEnable
	MY.SaveLUAData({'config/memo.jx3dat', MY_DATA_PATH.ROLE}, CFG)

	local CFG = {}
	for k, v in pairs(GLOBAL_MEMO) do
		CFG[k] = v
	end
	CFG.bEnable = nil
	MY.SaveLUAData({'config/memo.jx3dat', MY_DATA_PATH.GLOBAL}, CFG)
end

function MY_Memo.IsEnable(bGlobal)
	if bGlobal then
		return GLOBAL_MEMO.bEnable
	end
	return ROLE_MEMO.bEnable
end

function MY_Memo.Toggle(bGlobal, bEnable)
	(bGlobal and GLOBAL_MEMO or ROLE_MEMO).bEnable = bEnable
	D.SaveConfig()
	D.Reload(bGlobal)
end

do
local function onInit()
	D.LoadConfig()
	D.Reload(true)
	D.Reload(false)
end
MY.RegisterInit('MY_ANMERKUNGEN_PLAYERNOTE', onInit)
end
