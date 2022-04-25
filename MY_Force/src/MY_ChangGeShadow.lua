--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 长歌影子头顶次序
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
local PLUGIN_NAME = 'MY_Force'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^11.0.0') then
	return
end
--------------------------------------------------------------------------

local O = X.CreateUserSettingsModule('MY_ChangGeShadow', _L['Target'], {
	bEnable = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowDistance = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	bShowCD = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.Boolean,
		xDefaultValue = false,
	},
	fScale = {
		ePathType = X.PATH_TYPE.ROLE,
		szLabel = _L['MY_Force'],
		xSchema = X.Schema.Number,
		xDefaultValue = 1.5,
	},
})
local D = {}

function D.Apply()
	if O.bEnable then
		local MAX_LIMIT_TIME = 25
		local hList, hItem, nCount, sha, r, g, b, nDis, szText, fPer
		local hShaList = UI.GetShadowHandle('MY_ChangGeShadow')
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
			hList = frame:Lookup('Wnd_Bar', 'Handle_Skill')
			nCount = hList:GetItemCount()
			for i = 0, nCount - 1 do
				hItem = hList:Lookup(i)
				sha = hShaList:Lookup(i)
				if not sha then
					hShaList:AppendItemFromString('<shadow></shadow>')
					sha = hShaList:Lookup(i)
				end
				nDis = X.GetDistance(GetNpc(hItem.nNpcID))
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
		UI.GetShadowHandle('MY_ChangGeShadow'):Hide()
	end
end
X.RegisterUserSettingsUpdate('@@INIT@@', 'MY_ChangGeShadow', D.Apply)

function D.OnPanelActivePartial(ui, nPaddingX, nPaddingY, nW, nH, nX, nY)
	if ENVIRONMENT.GAME_BRANCH ~= 'classic' then
		nX = nX + ui:Append('WndCheckBox', {
			x = nX, y = nY, w = 'auto',
			text = _L['Show changge shadow index'],
			checked = O.bEnable,
			onCheck = function(bChecked)
				O.bEnable = bChecked
				D.Apply()
			end,
			tip = {
				render = function(self)
					if not self:Enable() then
						return _L['Changge force only']
					end
				end,
				position = UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = GetClientPlayer()
				return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
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
				render = function(self)
					if not self:Enable() then
						return _L['Changge force only']
					end
				end,
				position = UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = GetClientPlayer()
				return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
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
				render = function(self)
					if not self:Enable() then
						return _L['Changge force only']
					end
				end,
				position = UI.TIP_POSITION.TOP_BOTTOM,
			},
			autoEnable = function()
				local me = GetClientPlayer()
				return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		}):Width() + 5
		ui:Append('WndTrackbar', {
			x = nX, y = nY, w = 150,
			textFormatter = function(val) return _L('Scale: %d%%.', val) end,
			range = {10, 800},
			trackbarStyle = UI.TRACKBAR_STYLE.SHOW_VALUE,
			value = O.fScale * 100,
			onChange = function(val)
				O.fScale = val / 100
				D.Apply()
			end,
			autoEnable = function()
				local me = GetClientPlayer()
				return me and me.dwForceID == CONSTANT.FORCE_TYPE.CHANG_GE
			end,
		})
	end
	return nX, nY
end

-- Global exports
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
