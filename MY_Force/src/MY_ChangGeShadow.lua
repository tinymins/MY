--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 长歌影子头顶次序
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_Force/MY_ChangGeShadow'
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ChangGeShadow', _L['Target'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ChangGeShadow'],
			_L['Show changge shadow index'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ChangGeShadow'],
			_L['Show distance'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowCD = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ChangGeShadow'],
			_L['Show countdown'],
		}),
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		szDescription = X.MakeCaption({
			_L['MY_ChangGeShadow'],
			_L['Scale'],
		}),
		xSchema = X.Schema.Number,
		xDefaultValue = 1.5,
	},
})
local D = {}

function D.Apply()
	if O.bEnable then
		local MAX_LIMIT_TIME = 25
		local hList, hItem, nCount, sha, r, g, b, nDis, szText, fPer
		local hShaList = X.UI.GetShadowHandle('MY_ChangGeShadow')
		local MAX_SHADOW_COUNT = 10
		local nInterval = (O.bShowDistance or O.bShowCD) and 50 or 400
		X.BreatheCall('CHANGGE_SHADOW', nInterval, function()
			local frame = Station.Lookup('Lowest1/ChangGeShadow')
			if not frame then
				if nCount and nCount > 0 then
					for i = 0, nCount - 1 do
						sha = hShaList:Lookup(i)
						if sha then
							sha:Hide()
						end
					end
					nCount = 0
				end
				return
			end
			local me = X.GetClientPlayer()
			if not me then
				return
			end
			hList = frame:Lookup('Wnd_Bar', 'Handle_Skill')
			nCount = hList:GetItemCount()
			for i = 0, nCount - 1 do
				hItem = hList:Lookup(i)
				sha = hShaList:Lookup(i)
				if not sha then
					hShaList:AppendItemFromString('<shadow></shadow>')
					sha = hShaList:Lookup(i)
				end
				local kNpc = X.GetNpc(hItem.nNpcID)
				nDis = kNpc and X.GetCharacterDistance(me, kNpc) or -1
				if hItem.szState == 'disable' then
					r, g, b = 191, 31, 31
				else
					if nDis > 25 then
						r, g, b = 255, 255, 31
					else
						r, g, b = 63, 255, 31
					end
				end
				fPer = hItem:Lookup('Image_CD'):GetPercentage()
				szText = tostring(i + 1)
				if O.bShowDistance and nDis >= 0 then
					szText = szText .. g_tStrings.STR_CONNECT .. KeepOneByteFloat(nDis) .. g_tStrings.STR_METER
				end
				if O.bShowCD then
					szText = szText .. g_tStrings.STR_CONNECT .. math.floor(fPer * MAX_LIMIT_TIME) .. '"'
				end
				sha:Show()
				sha:ClearTriangleFanPoint()
				sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
				sha:AppendCharacterID(hItem.nNpcID, true, r, g, b, 200, 0, 40, szText, 0, O.fScale)
			end
			for i = nCount, MAX_SHADOW_COUNT do
				sha = hShaList:Lookup(i)
				if sha then
					sha:Hide()
				end
			end
		end)
		hShaList:Show()
	else
		X.BreatheCall('CHANGGE_SHADOW', false)
		X.UI.GetShadowHandle('MY_ChangGeShadow'):Hide()
	end
end

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	if X.IS_REMAKE then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 'auto',
			text = _L['Show changge shadow index'],
			checked = O.bEnable,
			onCheck = function(bChecked)
				O.bEnable = bChecked
				D.Apply()
			end,
			tip = {
				render = function()
					if not X.UI(this):Enable() then
						return _L['Changge force only']
					end
				end,
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = X.GetClientPlayer()
				return me and me.dwForceID == X.CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		}):Width() + 5
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 'auto',
			text = _L['Show distance'],
			checked = O.bShowDistance,
			onCheck = function(bChecked)
				O.bShowDistance = bChecked
				D.Apply()
			end,
			tip = {
				render = function()
					if not X.UI(this):Enable() then
						return _L['Changge force only']
					end
				end,
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = X.GetClientPlayer()
				return me and me.dwForceID == X.CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		}):Width() + 5
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 'auto',
			text = _L['Show countdown'],
			checked = O.bShowCD,
			onCheck = function(bChecked)
				O.bShowCD = bChecked
				D.Apply()
			end,
			tip = {
				render = function()
					if not X.UI(this):Enable() then
						return _L['Changge force only']
					end
				end,
				position = X.UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = X.GetClientPlayer()
				return me and me.dwForceID == X.CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		}):Width() + 5
		ui:Append('WndSlider', {
			x = nX, y = nY, w = 150,
			textFormatter = function(val) return _L('Scale: %d%%.', val) end,
			range = {10, 800},
			sliderStyle = X.UI.SLIDER_STYLE.SHOW_VALUE,
			value = O.fScale * 100,
			onChange = function(val)
				O.fScale = val / 100
				D.Apply()
			end,
			autoEnable = function()
				local me = X.GetClientPlayer()
				return me and me.dwForceID == X.CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		})
	end
	return nX, nY
end

--------------------------------------------------------------------------------
-- 全局导出
--------------------------------------------------------------------------------
do
local settings = {
	name = 'MY_ChangGeShadow',
	exports = {
		{
			fields = {
				OnPanelActivePartial = D.OnPanelActivePartial,
			},
		},
	},
}
MY_ChangGeShadow = X.CreateModule(settings)
end

--------------------------------------------------------------------------------
-- 事件注册
--------------------------------------------------------------------------------

X.RegisterUserSettingsInit('MY_ChangGeShadow', D.Apply)

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
