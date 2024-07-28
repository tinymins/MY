--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 记录点名到密聊频道
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Chat/MY_WhisperMention'
local PLUGIN_NAME = 'MY_Chat'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Chat'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^25.0.0') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_WhisperMention', _L['Chat'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Chat'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
})
local D = {}

function D.Apply()
	if O.bEnable then
		X.RegisterMsgMonitor({
			'MSG_NORMAL',
			'MSG_PARTY',
			'MSG_MAP',
			'MSG_BATTLE_FILED',
			'MSG_GUILD',
			'MSG_GUILD_ALLIANCE',
			'MSG_SCHOOL',
			'MSG_WORLD',
			'MSG_TEAM',
			'MSG_CAMP',
			'MSG_GROUP',
			'MSG_SEEK_MENTOR',
			'MSG_FRIEND',
			'MSG_IDENTITY',
			'MSG_SYS',
			'MSG_NPC_NEARBY',
			'MSG_NPC_YELL',
			'MSG_NPC_PARTY',
			'MSG_NPC_WHISPER',
		}, 'MY_RedirectMentionToWhisper', function(szChannel, szMsg, nFont, bRich, r, g, b, dwTalkerID, szName)
			local me = X.GetClientPlayer()
			if not me or me.dwID == dwTalkerID then
				return
			end
			local bEcho = false
			local aXMLNode = X.XMLDecode(szMsg)
			if not X.IsTable(aXMLNode) then
				return
			end
			for _, node in ipairs(aXMLNode) do
				local nodeType = X.XMLGetNodeType(node)
				local nodeName = X.XMLGetNodeData(node, 'name') or ''
				local nodeText = X.XMLGetNodeData(node, 'text')
				if nodeType == 'text' and nodeName:sub(1, 8) == 'namelink' and nodeText:sub(2, -2) == me.szName then
					bEcho = true
					break
				end
			end
			if bEcho then
				OutputMessage('MSG_WHISPER', szMsg, bRich, nFont, {r, g, b}, dwTalkerID, szName)
			end
		end)
		X.HookChatPanel('FILTER', 'MY_RedirectMentionToWhisper', function(h, szMsg, szChannel, dwTime)
			local tInfo = MY_Chat.ParseMessageInfo(szMsg)
			if tInfo then
				dwTime    = tInfo.dwTime
				szChannel = tInfo.szChannel
			end
			if h.__MY_LastMsg == szMsg and h.__MY_LastMsgChannel ~= szChannel and szChannel == 'MSG_WHISPER' then
				return false
			end
			h.__MY_LastMsg = szMsg
			h.__MY_LastMsgChannel = szChannel
			return true
		end)
	else
		X.HookChatPanel('FILTER', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_NORMAL', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_PARTY', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_MAP', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_BATTLE_FILED', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_GUILD', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_GUILD_ALLIANCE', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_SCHOOL', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_WORLD', 'MY_RedirectMentionToWhisper',false)
		X.RegisterMsgMonitor('MSG_TEAM', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_CAMP', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_GROUP', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_SEEK_MENTOR', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_FRIEND', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_IDENTITY', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_SYS', 'MY_RedirectMentionToWhisper',false)
		X.RegisterMsgMonitor('MSG_NPC_NEARBY', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_NPC_YELL', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_NPC_PARTY', 'MY_RedirectMentionToWhisper', false)
		X.RegisterMsgMonitor('MSG_NPC_WHISPER', 'MY_RedirectMentionToWhisper',false)
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, lineHeight)
	nX = nPaddingX
	ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 'auto',
		text = _L['Redirect mention to whisper'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
			D.Apply()
		end,
	})
	nY = nY + lineHeight
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_WhisperMention',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_WhisperMention = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_WhisperMention', D.Apply)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
