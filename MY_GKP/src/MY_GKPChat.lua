--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 金团记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-- lib apis caching
local X = MY
local UI, ENVIRONMENT, CONSTANT, wstring, lodash = X.UI, X.ENVIRONMENT, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

local Chat = {}
MY_GKP_Chat = {}
function MY_GKP_Chat.OnFrameCreate()
	this:RegisterEvent('DISTRIBUTE_ITEM')
	this:RegisterEvent('DOODAD_LEAVE_SCENE')
	this.box = this:Lookup('', 'Box')
end

function MY_GKP_Chat.OnEvent(szEvent)
	if szEvent == 'DISTRIBUTE_ITEM' then
		Chat.CloseFrame(GetItem(arg1))
	elseif szEvent == 'DOODAD_LEAVE_SCENE' then
		if arg0 == this.box.data.dwDoodadID then
			Wnd.CloseWindow(this)
		end
	end
end

-- OnMsgArrive
function Chat.OnMsgArrive(szMsg)
	local frame = Chat.GetFrame()
	if frame then
		local hScroll = frame:Lookup('WndScroll_Chat')
		local h = hScroll:Lookup('', '')
		szMsg = string.gsub(szMsg, _L['[Team]'], '')
		local AppendText = function()
			local t = TimeToDate(GetCurrentTime())
			return GetFormatText(string.format(' %02d:%02d:%02d ', t.hour, t.minute, t.second), 10, 255, 255, 255)
		end
		szMsg = AppendText() .. szMsg
		if MY and X.SendChat and X.RenderChatLink then
			szMsg =  X.RenderChatLink(szMsg)
		end
		if MY_ChatEmotion and MY_ChatEmotion.Render then
			szMsg = MY_ChatEmotion.Render(szMsg)
		end
		if MY_Farbnamen and MY_Farbnamen.Render then
			szMsg = MY_Farbnamen.Render(szMsg)
		end
		local xml = '<image>path=' .. EncodeComponentsString('UI/Image/Button/ShopButton.uitex') .. ' frame=1 eventid=786 w=20 h=20 script="this.OnItemLButtonClick=MY_GKP.DistributionItem\nthis.OnItemMouseEnter=function() this:SetFrame(2) end\nthis.OnItemMouseLeave=function() this:SetFrame(1) end"</<image>>'
		h:AppendItemFromString(xml)
		h:AppendItemFromString(szMsg)
		h:FormatAllItemPos()
		hScroll:Lookup('Scroll_All'):ScrollEnd()
	end
end

function Chat.GetFrame()
	return Station.Lookup('Normal/MY_GKP_Chat')
end

-- 点击锤子图标预览 严格判断
function MY_GKP.DistributionItem()
	local h, i = this:GetParent(), this:GetIndex()
	if not h or not i then
		error('GKP_ERROR -> UI_ERROR')
	end
	local szName = string.match(h:Lookup(i + 3):GetText(), '%[(.*)%]')
	local me     = Station.Lookup('Normal/MY_GKP_Chat')
	local box    = me:Lookup('', 'Box')
	local data   = box.data
	local aPartyMember = MY_GKPLoot.GetaPartyMember(data.dwDoodadID)
	local member = aPartyMember(szName)
	if member then
		MY_GKPLoot.GetMessageBox(member.dwID, data.data)
	else
		return X.Alert(_L['No Pick up Object, may due to Network off - line'])
	end
end

function Chat.OpenFrame(item, menu, data)
	local frame = Chat.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(X.PACKET_INFO.ROOT .. 'MY_GKP/ui/MY_GKP_Chat.ini', 'MY_GKP_Chat')
		local ui = UI(frame):Anchor('CENTER')
		ui:Append('WndButton', {
			x = 380, y = 38,
			text = _L['Stop Bidding'],
			buttonStyle = 'FLAT',
			onClick = function()
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['--- Stop Bidding ---'])
				X.DelayCall(1000, function() UnRegisterMsgMonitor(Chat.OnMsgArrive) end)
			end,
		})
		ui:Children('#Btn_Close'):Click(Chat.CloseFrame)
	end
	local box = frame:Lookup('', 'Box')
	local txt = frame:Lookup('', 'Text')
	txt:SetText(X.GetItemNameByItem(item))
	txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
	local h = frame:Lookup('WndScroll_Chat'):Lookup('', '')
	h:Clear()
	UpdataItemInfoBoxObject(box, item.nVersion, item.dwTabType, item.dwIndex, (item.nGenre == ITEM_GENRE.BOOK and item.nBookID) or (item.bCanStack and item.nStackNum) or nil)
	RegisterMsgMonitor(Chat.OnMsgArrive, { 'MSG_TEAM' })
	box.OnItemLButtonClick = function()
		if IsCtrlKeyDown() or IsAltKeyDown() then
			return
		end
		PopupMenu(menu)
	end
	box.data = data
end

function Chat.CloseFrame(bCheck)
	local frame = Chat.GetFrame()
	if frame then
		if type(bCheck) == 'userdata' then
			local box = frame:Lookup('', 'Box')
			local nUiId, nVersion, dwTabType, dwIndex = select(2, box:GetObject())
			if bCheck.nUiId ~= nUiId or bCheck.nVersion ~= nVersion or bCheck.dwTabType ~= dwTabType or bCheck.dwIndex ~= dwIndex then
				return
			end
		end
		UnRegisterMsgMonitor(Chat.OnMsgArrive)
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

local ui = {
	OpenFrame = Chat.OpenFrame
}
setmetatable(MY_GKP_Chat, { __index = ui, __newindex = function() end, __metatable = true })
