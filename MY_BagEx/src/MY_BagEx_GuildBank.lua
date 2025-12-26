--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 背包堆叠
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_BagEx/MY_BagEx_GuildBank'
local PLUGIN_NAME = 'MY_BagEx'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_BagEx_GuildBank'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local O = X.CreateUserSettingsModule(MODULE_NAME, _L['General'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['GuildBank'],
			_L['Guild package sort and stack'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
	bConfirm = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_BagEx'],
		szDescription = X.MakeCaption({
			_L['GuildBank'],
			_L['Sort need confirm'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = true,
	},
})
local D = {}

-- 检测冲突
function D.CheckConflict(bRestore)
end

function D.OnEnableChange()
	D.CheckConflict()
	MY_BagEx_GuildBankSort.CheckInjection()
	MY_BagEx_GuildBankStack.CheckInjection()
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY, nLH)
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Guild package sort and stack'],
		checked = O.bEnable,
		onCheck = function(bChecked)
			O.bEnable = bChecked
			D.OnEnableChange()
		end,
	}):AutoWidth():Width() + 5
	nX = nX + ui:Append('WndCheckBox', {
		x = nX, y = nY, w = 200,
		text = _L['Need confirm'],
		checked = O.bConfirm,
		onCheck = function(bChecked)
			O.bConfirm = bChecked
		end,
		autoEnable = function() return O.bEnable end,
	}):AutoWidth():Width() + 5
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_BagEx_GuildBank',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
		{
			fields = {
				'bEnable',
				'bConfirm',
			},
			root = O,
		},
	},
}
MY_BagEx_GuildBank = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_BagEx_GuildBank', function() D.CheckConflict() end)
X.RegisterFrameCreate('BigBagPanel', 'MY_BagEx_GuildBank', function() D.CheckConflict() end)
X.RegisterReload('MY_BagEx_GuildBank', function() D.CheckConflict(true) end)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
