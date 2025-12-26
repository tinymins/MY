--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 金团记录
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_GKP/MY_GKPChat'
local PLUGIN_NAME = 'MY_GKP'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_GKP'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local D = {}

function D.OnEvent(szEvent)
	if szEvent == 'DISTRIBUTE_ITEM' then
		D.CloseFrame(GetItem(arg1))
	elseif szEvent == 'DOODAD_LEAVE_SCENE' then
		if arg0 == this.box.data.dwDoodadID then
			X.UI.CloseFrame(this)
		end
	end
end

-- OnMsgArrive
function D.OnMsgArrive(szMsg)
	local frame = D.GetFrame()
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

function D.GetFrame()
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
	local box    = me:Lookup('Wnd_Bg', 'Box')
	local data   = box.data
	local aPartyMember = MY_GKPLoot.GetaPartyMember(data.dwDoodadID)
	local member = aPartyMember(szName)
	if member then
		MY_GKPLoot.GetMessageBox(member.dwID, data.data)
	else
		return X.Alert(_L['No Pick up Object, may due to Network off - line'])
	end
end

function D.OpenFrame(item, menu, data)
	local frame = D.GetFrame()
	if not frame then
		local ui = X.UI.CreateFrame('MY_GKP_Chat', { w = 500, h = 355, theme = X.UI.FRAME_THEME.SIMPLE, text = _L['MY_GKP_Chat'] })
		frame = ui:Raw()
		X.UI.AppendFromIni(frame, X.PACKET_INFO.ROOT .. 'MY_GKP/ui/MY_GKP_Chat.ini', 'Wnd_Total', true)
		ui:Append('WndButton', {
			x = 380, y = 5,
			text = _L['Stop Bidding'],
			buttonStyle = 'FLAT',
			onClick = function()
				X.SendChat(PLAYER_TALK_CHANNEL.RAID, _L['--- Stop Bidding ---'])
				X.DelayCall(1000, function() UnRegisterMsgMonitor(D.OnMsgArrive) end)
			end,
		})
		frame.box = frame:Lookup('Wnd_Bg', 'Box')
		frame:RegisterEvent('DISTRIBUTE_ITEM')
		frame:RegisterEvent('DOODAD_LEAVE_SCENE')
		X.UI.AdaptComponentAppearance(frame:Lookup('WndScroll_Chat/Scroll_All'))
	end
	local box = frame:Lookup('Wnd_Bg', 'Box')
	local txt = frame:Lookup('Wnd_Bg', 'Text')
	txt:SetText(X.GetItemNameByItem(item))
	txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
	local h = frame:Lookup('WndScroll_Chat'):Lookup('', '')
	h:Clear()
	UpdataItemInfoBoxObject(box, item.nVersion, item.dwTabType, item.dwIndex, (item.nGenre == ITEM_GENRE.BOOK and item.nBookID) or (item.bCanStack and item.nStackNum) or nil)
	RegisterMsgMonitor(D.OnMsgArrive, { 'MSG_TEAM' })
	box.OnItemLButtonClick = function()
		if IsCtrlKeyDown() or IsAltKeyDown() then
			return
		end
		PopupMenu(menu)
	end
	box.data = data
end

function D.CloseFrame(bCheck)
	local frame = D.GetFrame()
	if frame then
		if type(bCheck) == 'userdata' then
			local box = frame:Lookup('Wnd_Bg', 'Box')
			local nUiId, nVersion, dwTabType, dwIndex = select(2, box:GetObject())
			if bCheck.nUiId ~= nUiId or bCheck.nVersion ~= nVersion or bCheck.dwTabType ~= dwTabType or bCheck.dwIndex ~= dwIndex then
				return
			end
		end
		UnRegisterMsgMonitor(D.OnMsgArrive)
		X.UI.CloseFrame(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_GKP_Chat',
	exports = {
		{
			preset = 'UIEvent',
			fields = {
				'OpenFrame',
			},
			root = D,
		},
	},
}
MY_GKP_Chat = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
