--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 语音报警
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_TeamMon/MY_TeamMon_VoiceAlarm_Previewer'
local PLUGIN_NAME = 'MY_TeamMon'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_TeamMon_VoiceAlarm_Previewer'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local D = {}

function D.Open(szType)
	assert(szType == 'OFFICIAL' or szType == 'CUSTOM', 'Invalid type: ' .. tostring(szType))
	X.UI.CloseFrame('MY_TeamMon_VoiceAlarm_Previewer')
	local ui = X.UI.CreateFrame('MY_TeamMon_VoiceAlarm_Previewer', {
		w = 400, h = 620, anchor = 'CENTER',
		text = szType == 'OFFICIAL' and _L['Preview official voice'] or _L['Preview custom voice'],
		events = {
			{
				'MY_TEAM_MON__VOICE_ALARM__CURRENT_PACKET_UPDATE',
				function()
					X.DelayCall('MY_TeamMon_VoiceAlarm_Previewer', 10, function() D.Open(szType) end)
				end,
			},
			{
				'MY_TEAM_MON__VOICE_ALARM__DOWNLOAD_FILE_SUCCESS',
				function()
					X.DelayCall('MY_TeamMon_VoiceAlarm_Previewer', 10, function() D.Open(szType) end)
				end,
			},
		},
	})
	ui:Raw():GetRoot().szType = szType

	local aDataSource = {}
	for _, tGroup in ipairs(MY_TeamMon_VoiceAlarm.GetSlugList(szType)) do
		table.insert(aDataSource, { szType = 'group', szGroupName = tGroup.szGroupName })
		for _, tSlug in ipairs(tGroup) do
			table.insert(aDataSource, { szType = 'slug', szRemark = tSlug.szRemark, szSlug = tSlug.szSlug })
		end
	end
	ui:Append('WndTable', {
		name = 'WndTable_Preview',
		x = 20, y = 60, w = 360, h = 530,
		columns = {
			{
				key = 'title',
				title = _L['Voice title'],
				alignHorizontal = 'left',
				width = 200,
				render = function(value, record, index)
					if record.szType == 'group' then
						return GetFormatText(' + ' .. record.szGroupName, 162, 192, 192, 0)
					end
					local r, g, b = 255, 255, 255
					if not MY_TeamMon_VoiceAlarm.IsVoiceExist(szType, record.szSlug) then
						r, g, b = 128, 128, 128
					end
					return GetFormatText('   ' .. record.szRemark, 162, r, g, b, 277, 'this.szSlug = ' .. X.EncodeLUAData(record.szSlug), 'Text_Preview_Title')
				end,
			},
			{
				key = 'preview',
				title = _L['Voice preview'],
				alignHorizontal = 'center',
				width = 160,
				render = function(value, record, index)
					if record.szType == 'group' then
						return ''
					end
					if not MY_TeamMon_VoiceAlarm.IsVoiceExist(szType, record.szSlug) then
						return GetFormatText(_L['Not exist'], 162, 128, 128, 128)
					end
					return GetFormatText(_L['Click to play'], 162, nil, nil, nil, 277, 'this.szSlug = ' .. X.EncodeLUAData(record.szSlug), 'Text_Preview_Play')
				end,
			},
		},
		rowTip = {
			render = function(rec)
				if not MY_TeamMon_VoiceAlarm.IsVoiceExist(szType, rec.szSlug) then
					return GetFormatText(_L['Voice not exist in current packet'], 162, 255, 255, 0), true
				end
				return rec.szSlug
			end,
			position = X.UI.TIP_POSITION.LEFT_RIGHT,
		},
		dataSource = aDataSource,
	})
end

function D.OnItemLButtonClick()
	local name = this:GetName()
	if name == 'Text_Preview_Play' then
		MY_TeamMon_VoiceAlarm.PlayVoice(this:GetRoot().szType, this.szSlug)
	elseif name == 'Text_Preview_Title' then
		SetDataToClip(this.szSlug)
		MY.OutputAnnounceMessage(_L['Voice slug name has been copied to clipboard'])
	end
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_TeamMon_VoiceAlarm_Previewer',
	exports = {
		{
			root = D,
			fields = {
				'Open',
			},
			preset = 'UIEvent'
		},
	},
}
MY_TeamMon_VoiceAlarm_Previewer = X.CreateModule(settings)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
