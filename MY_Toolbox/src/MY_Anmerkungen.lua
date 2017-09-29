-----------------------------------------------
-- @Desc  : 随身便笺 玩家标签
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2014-11-25 12:31:03
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 15:23:48
-----------------------------------------------
-- #######################################################################################################
--   * * *         *                 *                     *                   *           *
--   *   *   * * * * * * *       * * * * * * *             * * * * * * * *     * * * *     * * * *
--   *   *       *               *           *           *         *         *   *       *   *
--   *   * *   * * * * *         * * * * * * *           *   * * * * * * *         *     *     *
--   * *     *   *     *         *           *         * *   *     *     *           *     *
--   * *         * * * *         * * * * * * *   *   *   *   * * * * * * *           * * * * * *
--   *   * * *   *     *         *           * *         *   *     *     *     * * * *
--   *   *   *   * * * *     * * * * * * * * *           *   * * * * * * *           *   * * * * *
--   *   *   *   *     *               * *   *           *     *   *         * * * * * *     *
--   * *     *   *   * *           * *       *           *       *                     *   *
--   *       *               * * *           *           *     *   *                   * *       *
--   *     *   * * * * * *               * * *           *   *       * * *     * * * *     * * * *
-- #######################################################################################################
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Toolbox/lang/")
local _C = {}
MY_Anmerkungen = {}
MY_Anmerkungen.bNotePanelEnable = false
MY_Anmerkungen.anchorNotePanel = { s = "TOPRIGHT", r = "TOPRIGHT", x = -310, y = 135 }
MY_Anmerkungen.nNotePanelWidth = 200
MY_Anmerkungen.nNotePanelHeight = 200
MY_Anmerkungen.szNotePanelContent = ""
MY_Anmerkungen.tPrivatePlayerNotes = {} -- 私有玩家描述
MY_Anmerkungen.tPublicPlayerNotes = {} -- 公共玩家描述
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }
RegisterCustomData("MY_Anmerkungen.bNotePanelEnable")
RegisterCustomData("MY_Anmerkungen.anchorNotePanel")
RegisterCustomData("MY_Anmerkungen.nNotePanelWidth")
RegisterCustomData("MY_Anmerkungen.nNotePanelHeight")
RegisterCustomData("MY_Anmerkungen.szNotePanelContent")
-- 重载便笺
MY_Anmerkungen.ReloadNotePanel = function()
	MY.UI("Normal/MY_Anmerkungen_NotePanel"):remove()
	if MY_Anmerkungen.bNotePanelEnable then
		-- frame
		local ui = MY.UI.CreateFrame("MY_Anmerkungen_NotePanel", {
			simple = true, alpha = 140,
			maximize = true, minimize = true, dragresize = true,
			minwidth = 180, minheight = 100,
			onmaximize = function(wnd)
				local ui = MY.UI(wnd)
				ui:children("#WndEditBox_Anmerkungen"):size(ui:size())
			end,
			onrestore = function(wnd)
				local ui = MY.UI(wnd)
				ui:children("#WndEditBox_Anmerkungen"):size(ui:size())
			end,
			ondragresize = function(wnd)
				local ui = MY.UI(wnd:GetRoot())
				MY_Anmerkungen.nNotePanelWidth  = ui:width()
				MY_Anmerkungen.anchorNotePanel  = ui:anchor()
				MY_Anmerkungen.nNotePanelHeight = ui:height()
				local ui = MY.UI(wnd)
				ui:children("#WndEditBox_Anmerkungen"):size(ui:size())
			end,
		})
		ui:size(MY_Anmerkungen.nNotePanelWidth, MY_Anmerkungen.nNotePanelHeight)
		  :drag(true):drag(0,0,MY_Anmerkungen.nNotePanelWidth, 30)
		  :text(_L['my anmerkungen'])
		  :anchor(MY_Anmerkungen.anchorNotePanel)
		-- input box
		ui:append("WndEditBox", "WndEditBox_Anmerkungen"):children("#WndEditBox_Anmerkungen")
		  :pos(0, 0):size(MY_Anmerkungen.nNotePanelWidth, MY_Anmerkungen.nNotePanelHeight - 30)
		  :multiLine(true):text(MY_Anmerkungen.szNotePanelContent)
		  :change(function(raw, txt) MY_Anmerkungen.szNotePanelContent = txt end)

		ui:uievent("OnFrameDragEnd", function()
			MY_Anmerkungen.anchorNotePanel = MY.UI("Normal/MY_Anmerkungen_NotePanel"):anchor()
		end):event("UI_SCALED", function()
			MY.UI(this):anchor(MY_Anmerkungen.anchorNotePanel)
		end)
	end
end
-- 打开一个玩家的记录编辑器
MY_Anmerkungen.OpenPlayerNoteEditPanel = function(dwID, szName)
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}
	-- frame
	local ui = MY.UI.CreateFrame("MY_Anmerkungen_PlayerNoteEdit_"..(dwID or 0))
	local CloseFrame = function()
		ui:remove()
		return true
	end

	MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', function()
		return ui and ui:count() > 0
	end, CloseFrame)
	local function onRemove()
		MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:remove(onRemove)

	local w, h = 300, 210
	local x, y = 20 , 0

	ui:size(w + 40, h + 90):anchor( { s = "CENTER", r = "CENTER", x = 0, y = 0 } )
	-- title
	ui:text(_L['my anmerkungen - player note edit'])
	-- id
	ui:append("Text", "Label_ID"):children("#Label_ID"):pos(x, y)
	  :text(_L['ID:'])
	-- id input
	ui:append("WndEditBox", "WndEditBox_ID"):children("#WndEditBox_ID"):pos(x + 60, y)
	  :size(200, 25):multiLine(false):enable(false):color(200,200,200)
	  :text(dwID or note.dwID or "")
	  -- :change(function(raw, dwID)
	  --   if dwID == "" or string.find(dwID, "[^%d]") then
	  --       ui:children("#WndButton_Submit"):enable(false)
	  --   else
	  --       ui:children("#WndButton_Submit"):enable(true)
	  --       local rec = MY_Anmerkungen.GetPlayerNote(dwID)
	  --       if rec then
	  --           ui:children("#WndEditBox_Name"):text(rec.szName)
	  --           ui:children("#WndEditBox_Content"):text(rec.szContent)
	  --           ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
	  --           ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
	  --       end
	  --   end
	  -- end)
	-- name
	ui:append("Text", "Label_Name"):children("#Label_Name"):pos(x, y + 30)
	  :text(_L['Name:'])
	-- name input
	ui:append("WndEditBox", "WndEditBox_Name"):children("#WndEditBox_Name"):pos(x + 60, y + 30)
	  :size(200, 25):multiLine(false):text(szName or note.szName or "")
	  :change(function(raw, szName)
	  	local rec = MY_Anmerkungen.GetPlayerNote(szName)
	  	if rec then
	  		ui:children("#WndButton_Submit"):enable(true)
	  		ui:children("#WndEditBox_ID"):text(rec.dwID)
	  		ui:children("#WndEditBox_Content"):text(rec.szContent)
	  		ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
	  		ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
	  	else
	  		local tInfo
	  		if MY_Farbnamen then
	  			tInfo = MY_Farbnamen.GetAusName(szName)
	  		end
	  		if tInfo then
	  			ui:children("#WndButton_Submit"):enable(true)
	  			ui:children("#WndEditBox_ID"):text(tInfo.dwID)
	  			ui:children("#WndEditBox_Content"):text('')
	  			ui:children("#WndCheckBox_TipWhenGroup"):check(true)
	  			ui:children("#WndCheckBox_AlertWhenGroup"):check(false)
	  		else
	  			ui:children("#WndButton_Submit"):enable(false)
	  			ui:children("#WndEditBox_ID"):text('')
	  		end
	  	end
	  end)
	-- content
	ui:append("Text", "Label_Content"):children("#Label_Content"):pos(x, y + 60)
	  :text(_L['Content:'])
	-- content input
	ui:append("WndEditBox", "WndEditBox_Content"):children("#WndEditBox_Content")
	  :pos(x + 60, y + 60):size(200, 80)
	  :multiLine(true):text(note.szContent or "")
	-- alert when group
	ui:append("WndCheckBox", "WndCheckBox_AlertWhenGroup"):children("#WndCheckBox_AlertWhenGroup")
	  :pos(x + 58, y + 140):width(200)
	  :text(_L['alert when group']):check(note.bAlertWhenGroup or false)
	-- tip when group
	ui:append("WndCheckBox", "WndCheckBox_TipWhenGroup"):children("#WndCheckBox_TipWhenGroup")
	  :pos(x + 58, y + 160):width(200)
	  :text(_L['tip when group']):check(note.bTipWhenGroup or true)
	-- submit button
	ui:append("WndButton", "WndButton_Submit"):children("#WndButton_Submit")
	  :pos(x + 58, y + 190):width(80)
	  :text(_L['sure']):click(function()
	  	MY_Anmerkungen.SetPlayerNote(
	  		ui:children("#WndEditBox_ID"):text(),
	  		ui:children("#WndEditBox_Name"):text(),
	  		ui:children("#WndEditBox_Content"):text(),
	  		ui:children("#WndCheckBox_TipWhenGroup"):check(),
	  		ui:children("#WndCheckBox_AlertWhenGroup"):check()
	  	)
	  	CloseFrame(ui)
	  end)
	-- cancel button
	ui:append("WndButton", "WndButton_Cancel"):children("#WndButton_Cancel")
	  :pos(x + 143, y + 190):width(80)
	  :text(_L['cancel']):click(function() CloseFrame(ui) end)
	-- delete button
	ui:append("Text", "Text_Delete"):children("#Text_Delete")
	  :pos(x + 230, y + 188):width(80):alpha(200)
	  :text(_L['delete']):color(255,0,0):hover(function(bIn) MY.UI(this):alpha((bIn and 255) or 200) end)
	  :click(function()
	  	MY_Anmerkungen.SetPlayerNote(ui:children("#WndEditBox_ID"):text())
	  	CloseFrame(ui)
	  	-- 删除
	  end)

	-- init data
	ui:children("#WndEditBox_ID"):change()
	Station.SetFocusWindow(ui[1])
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end
-- 重载右键菜单
MY.RegisterTargetAddonMenu("MY_Anmerkungen_PlayerNotes", function()
	local dwType, dwID = MY.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = MY.GetObject(dwType, dwID)
		return {
			szOption = _L['edit player note'],
			fnAction = function()
				MY.DelayCall(1, function()
					MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end)
-- 获取一个玩家的记录
MY_Anmerkungen.GetPlayerNote = function(dwID)
	-- { dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate }
	dwID = tostring(dwID)
	local t, rec = {}, nil
	if not rec then
		rec = MY_Anmerkungen.tPrivatePlayerNotes[dwID]
		if type(rec) ~= "table" then
			rec = MY_Anmerkungen.tPrivatePlayerNotes[tostring(rec)]
		end
		t.bPrivate = true
	end
	if not rec then
		rec = MY_Anmerkungen.tPublicPlayerNotes[dwID]
		if type(rec) ~= "table" then
			rec = MY_Anmerkungen.tPublicPlayerNotes[tostring(rec)]
		end
		t.bPrivate = false
	end
	if not rec then
		t = nil
	else
		t.dwID, t.szName, t.szContent, t,bTipWhenGroup, t.bAlertWhenGroup = rec.dwID, rec.szName, rec.szContent, rec,bTipWhenGroup, rec.bAlertWhenGroup
	end
	return t
end
-- 当有玩家进队时
MY_Anmerkungen.OnPartyAddMember = function()
	MY_Anmerkungen.PartyAddMember(arg1)
end
MY_Anmerkungen.PartyAddMember = function(dwID)
	local team = GetClientTeam()
	local szName = team.GetClientTeamMemberName(dwID)
	-- local dwLeaderID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
	-- local szLeaderName = team.GetClientTeamMemberName(dwLeader)
	local t = MY_Anmerkungen.GetPlayerNote(dwID)
	if t then
		if t.bAlertWhenGroup then
			MessageBox({
				szName = "MY_Anmerkungen_PlayerNotes_"..t.dwID,
				szMessage = _L("Tip: [%s] is in your team.\nNote: %s\n", t.szName, t.szContent),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if t.bTipWhenGroup then
			MY.Sysmsg({_L("Tip: [%s] is in your team.\nNote: %s", t.szName, t.szContent)})
		end
	end
end
MY.RegisterEvent("PARTY_ADD_MEMBER", MY_Anmerkungen.OnPartyAddMember)
MY.RegisterEvent("PARTY_SYNC_MEMBER_DATA", MY_Anmerkungen.OnPartyAddMember)
-- 设置一个玩家的记录
MY_Anmerkungen.SetPlayerNote = function(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
	if not dwID then return nil end
	dwID = tostring(dwID)
	if not szName then -- 删除一个玩家的记录
		MY_Anmerkungen.LoadConfig()
		if MY_Anmerkungen.tPrivatePlayerNotes[dwID] then
			MY_Anmerkungen.tPrivatePlayerNotes[MY_Anmerkungen.tPrivatePlayerNotes[dwID].szName] = nil
			MY_Anmerkungen.tPrivatePlayerNotes[dwID] = nil
		end
		if MY_Anmerkungen.tPublicPlayerNotes[dwID] then
			MY_Anmerkungen.tPublicPlayerNotes[MY_Anmerkungen.tPublicPlayerNotes[dwID].szName] = nil
			MY_Anmerkungen.tPublicPlayerNotes[dwID] = nil
		end
		if _C.list then
			_C.list:listbox('delete', nil, dwID)
		end
		MY_Anmerkungen.SaveConfig()
		return nil
	end
	MY_Anmerkungen.SetPlayerNote(dwID)
	MY_Anmerkungen.LoadConfig()
	local t = {
		dwID = dwID,
		szName = szName,
		szContent = szContent,
		bTipWhenGroup = bTipWhenGroup,
		bAlertWhenGroup = bAlertWhenGroup,
	}
	if bPrivate then
		MY_Anmerkungen.tPrivatePlayerNotes[dwID] = t
		MY_Anmerkungen.tPrivatePlayerNotes[szName] = dwID
	else
		MY_Anmerkungen.tPublicPlayerNotes[dwID] = t
		MY_Anmerkungen.tPublicPlayerNotes[szName] = dwID
	end
	if _C.list then
		_C.list:listbox('update', _L('[%s] %s', t.szName, t.szContent), dwID, t)
	end
	MY_Anmerkungen.SaveConfig()
end
-- 读取公共数据
MY_Anmerkungen.LoadConfig = function()
	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$relserver.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	MY_Anmerkungen.tPublicPlayerNotes = MY.LoadLUAData(szFilePath) or {}
	if type(MY_Anmerkungen.tPublicPlayerNotes) == 'string' then
		MY_Anmerkungen.tPublicPlayerNotes = MY.Json.Decode(MY_Anmerkungen.tPublicPlayerNotes)
	end

	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$uid.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	MY_Anmerkungen.tPrivatePlayerNotes = MY.LoadLUAData(szFilePath) or {}
	if type(MY_Anmerkungen.tPrivatePlayerNotes) == 'string' then
		MY_Anmerkungen.tPrivatePlayerNotes = MY.Json.Decode(MY_Anmerkungen.tPrivatePlayerNotes)
	end
end
-- 保存公共数据
MY_Anmerkungen.SaveConfig = function()
	MY.SaveLUAData({"config/playernotes.jx3dat", MY_DATA_PATH.SERVER}, MY_Anmerkungen.tPublicPlayerNotes)
	MY.SaveLUAData({"config/playernotes.jx3dat", MY_DATA_PATH.ROLE}, MY_Anmerkungen.tPrivatePlayerNotes)
end
MY.RegisterInit('MY_ANMERKUNGEN', MY_Anmerkungen.LoadConfig)
MY.RegisterInit('MY_ANMERKUNGEN_PLAYERNOTE', MY_Anmerkungen.ReloadNotePanel)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0

	ui:append("WndButton2", {
		x = w - 230, y = y, w = 110,
		text = _L['Import'],
		onclick = function()
			GetUserInput(_L['please input import data:'], function(szVal)
				local config = str2var(szVal)
				if config and config.server and config.public and config.private then
					if config.server ~= MY.GetRealServer() then
						return MY.Alert(_L['Server not match!'])
					end
					local function Next(usenew)
						for k, v in pairs(config.public) do
							if not MY_Anmerkungen.tPublicPlayerNotes[k] or usenew then
								MY_Anmerkungen.tPublicPlayerNotes[k] = v
							end
						end
						for k, v in pairs(config.private) do
							if not MY_Anmerkungen.tPrivatePlayerNotes[k] or usenew then
								MY_Anmerkungen.tPrivatePlayerNotes[k] = v
							end
						end
						MY_Anmerkungen.SaveConfig()
						MY.SwitchTab("MY_Anmerkungen_Player_Note", true)
					end
					MY.Confirm(_L['Prefer old data or new data?'], function() Next(false) end,
						function() Next(true) end, _L['Old data'], _L['New data'])
				else
					MY.Alert(_L['Decode data failed!'])
				end
			end, function() end, function() end, nil, "" )
		end,
	})

	ui:append("WndButton2", {
		x = w - 110, y = y, w = 110,
		text = _L['Export'],
		onclick = function()
			XGUI.OpenTextEditor(var2str({
				server  = MY.GetRealServer(),
				public  = MY_Anmerkungen.tPublicPlayerNotes,
				private = MY_Anmerkungen.tPrivatePlayerNotes,
			}))
		end,
	})

	y = y + 30
	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1')
	  :pos(x, y)
	  :size(w, h - 30)
	  :listbox('onlclick', function(hItem, szText, szID, data, bSelected)
	  	MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
	  	return false
	  end)
	for dwID, t in pairs(MY_Anmerkungen.tPublicPlayerNotes) do
		if tonumber(dwID) then
			list:listbox('insert', _L('[%s] %s', t.szName, t.szContent), t.dwID, t)
		end
	end
	_C.list = list
end
function PS.OnPanelDeactive()
	_C.list = nil
end
MY.RegisterPanel( "MY_Anmerkungen_Player_Note", _L["player note"], _L['Target'], "ui/Image/button/ShopButton.UITex|12", {255,255,0,200}, PS)
