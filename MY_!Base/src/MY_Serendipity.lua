--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 奇遇分享模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
--------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random, abs = math.huge, math.pi, math.random, math.abs
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local GetClientPlayer, GetPlayer, GetNpc, IsPlayer = GetClientPlayer, GetPlayer, GetNpc, IsPlayer
local UI, Get, RandomChild = MY.UI, MY.Get, MY.RandomChild
local IsNil, IsBoolean, IsNumber, IsFunction = MY.IsNil, MY.IsBoolean, MY.IsNumber, MY.IsFunction
local IsEmpty, IsString, IsTable, IsUserdata = MY.IsEmpty, MY.IsString, MY.IsTable, MY.IsUserdata
---------------------------------------------------------------------------------------------------
local _L, D = MY.LoadLangPack(), {}
local SERENDIPITY_STATUS = {
	START = 0,
	FINISH = 1,
	START_AND_FINISH = 2,
}

local SERENDIPITY_LIST = {}
do
local Xtra = {
	bEnable     = MY.FormatDataStructure(MY.LoadLUAData({'config/show_notify.jx3dat'           , MY_DATA_PATH.GLOBAL}), false),
	bSound      = MY.FormatDataStructure(MY.LoadLUAData({'config/serendipity_sound.jx3dat'     , MY_DATA_PATH.GLOBAL}), true ),
	bPreview    = MY.FormatDataStructure(MY.LoadLUAData({'config/serendipity_preview.jx3dat'   , MY_DATA_PATH.GLOBAL}), true ),
	bAutoShare  = MY.FormatDataStructure(MY.LoadLUAData({'config/serendipity_autoshare.jx3dat' , MY_DATA_PATH.GLOBAL}), false),
	bSilentMode = MY.FormatDataStructure(MY.LoadLUAData({'config/serendipity_silentmode.jx3dat', MY_DATA_PATH.GLOBAL}), true ),
}
MY_Serendipity = setmetatable({}, {
	__index = function(t, k)
		return Xtra[k]
	end,
	__newindex = function(t, k, v)
		if Xtra[k] == v then
			return
		end
		if k == 'bEnable' then
			if v then
				for i, p in ipairs_r(SERENDIPITY_LIST) do
					MY.CreateNotify({
						szKey = p.szKey,
						szMsg = p.szXml,
						fnAction = p.fnAction,
						bPlaySound = false,
						bPopupPreview = false,
					})
				end
			else
				for i, p in ipairs_r(SERENDIPITY_LIST) do
					MY.DismissNotify(p.szKey)
				end
			end
			MY.SaveLUAData({'config/show_notify.jx3dat', MY_DATA_PATH.GLOBAL}, v)
		elseif k == 'bSound' then
			MY.SaveLUAData({'config/serendipity_sound.jx3dat', MY_DATA_PATH.GLOBAL}, v)
		elseif k == 'bPreview' then
			MY.SaveLUAData({'config/serendipity_preview.jx3dat', MY_DATA_PATH.GLOBAL}, v)
		elseif k == 'bAutoShare' then
			MY.SaveLUAData({'config/serendipity_autoshare.jx3dat', MY_DATA_PATH.GLOBAL}, v)
		elseif k == 'bSilentMode' then
			MY.SaveLUAData({'config/serendipity_silentmode.jx3dat', MY_DATA_PATH.GLOBAL}, v)
		end
		Xtra[k] = v
	end,
})
end

do
local function OnMyNotifyDismiss()
	for i, p in ipairs_r(SERENDIPITY_LIST) do
		if p.szKey == arg0 then
			remove(SERENDIPITY_LIST, i)
		end
	end
end
MY.RegisterEvent('MY_NOTIFY_DISMISS', OnMyNotifyDismiss)
end

function D.GetSerendipityShareName(fnAction, bNoConfirm)
	local szReporter = MY.LoadLUAData({'config/realname.jx3dat', MY_DATA_PATH.ROLE}) or GetClientPlayer().szName:gsub('@.-$', '')
	if bNoConfirm then
		if fnAction then
			fnAction(szReporter)
		end
	else
		local function fnConfirm(szText)
			if szText ~= szReporter then
				MY.SaveLUAData({'config/realname.jx3dat', MY_DATA_PATH.ROLE}, szText)
			end
			if fnAction then
				fnAction(szText)
			end
		end
		GetUserInput(_L['Please input your realname, left blank for anonymous report:'], fnConfirm, nil, nil, nil, szReporter, 6)
	end
end
MY_Serendipity.GetSerendipityShareName = D.GetSerendipityShareName

function D.SerendipityShareConfirm(szName, szSerendipity, nMethod, nStatus, dwTime, szMode)
	local szKey = szName .. '_' .. szSerendipity .. '_' .. dwTime
	local szNameU = AnsiToUTF8(szName)
	local szNameCRC = ('%x%x%x'):format(szNameU:byte(), GetStringCRC(szNameU), szNameU:byte(-1))
	local function fnAction(szReporter)
		if szReporter == '' and nMethod ~= 1 then
			szName = ''
		end
		local function DoUpload()
			local configs, i, dc = {{'auto', 'post'}, {'auto', 'get'}, {'webcef', 'get'}, {'webbrowser', 'get'}}, 1
			local function TryUploadWithNextDriver()
				local config = configs[i]
				if not config then
					return
				end
				MY.Ajax({
					driver = config[1],
					type = config[2],
					url = 'http://data.jx3.derzh.com/serendipity/?l='
					.. MY.GetLang() .. '&m=' .. nMethod
					.. '&data=' .. MY.EncryptString(MY.JsonEncode({
						n = szName, N = szNameCRC, R = szReporter,
						S = MY.GetRealServer(1), s = MY.GetRealServer(2),
						a = szSerendipity, f = nStatus, t = dwTime,
					})),
					success = function() MY.DelayCall(dc, false) end,
					error = function() TryUploadWithNextDriver() end,
				})
				i = i + 1
				dc = MY.DelayCall(3000, TryUploadWithNextDriver)
			end
			TryUploadWithNextDriver()
		end
		if szMode == 'manual' or nMethod ~= 1 then
			DoUpload()
		else
			MY.DelayCall(math.random(0, 10000), DoUpload)
		end
		-- if szMode == 'manual' then
		-- 	DoUpload()
		-- else
		-- 	-- 战斗中移动中免打扰防止卡住
		-- 	MY.BreatheCall(function()
		-- 		if Cursor.IsVisible()
		-- 		and me and not me.bFightState
		-- 		and (
		-- 			me.nMoveState == MOVE_STATE.ON_STAND
		-- 			or me.nMoveState == MOVE_STATE.ON_FLOAT
		-- 			or me.nMoveState == MOVE_STATE.ON_SIT
		-- 			or me.nMoveState == MOVE_STATE.ON_FREEZE
		-- 			or me.nMoveState == MOVE_STATE.ON_ENTRAP
		-- 			or me.nMoveState == MOVE_STATE.ON_DEATH
		-- 			or me.nMoveState == MOVE_STATE.ON_AUTO_FLY
		-- 			or me.nMoveState == MOVE_STATE.ON_START_AUTO_FLY
		-- 		) then
		-- 			DoUpload()
		-- 			return 0
		-- 		end
		-- 	end)
		-- end
		if szMode ~= 'silent' then
			local w, h = 270, 180
			local ui = UI.CreateFrame('MY_Serendipity#' .. szKey, {
				w = w, h = h, close = true, text = '', anchor = {},
			})
			if szMode == 'auto' then
				ui:alpha(200)
				ui:anchor({ x = 0, y = -60, s = 'BOTTOMRIGHT', r = 'BOTTOMRIGHT' })
			end
			ui:append('Handle', { x = 10, y = (h - 90) / 2, w = w - 20, h = h, valign = 1, halign = 1, handlestyle = 3 }, true)
				:append('Text', {
					text = (szName == '' and _L['Anonymous'] or szName)
						.. '\n' .. szSerendipity .. ' - ' .. MY.FormatTime('hh:mm:ss', dwTime)
						.. '\n' .. (szReporter == '' and '' or (szReporter .. _L[','])) .. _L['JX3 is pround of you!']
						.. '\n' .. _L['Thanks for your kindness!'],
					fontscale = 1.2,
				})
				:formatChildrenPos()
			MY.DelayCall(10000, function() ui:remove() end)
			MY.DismissNotify(szKey)
		end
	end
	D.GetSerendipityShareName(fnAction, szMode ~= 'manual')
end

function D.OnSerendipity(szName, szSerendipity, nMethod, nStatus, dwTime)
	if MY.IsInDevServer() then
		return
	end
	local szKey = szName .. '_' .. szSerendipity .. '_' .. dwTime
	if MY_Serendipity.bAutoShare then
		D.SerendipityShareConfirm(szName, szSerendipity, nMethod, nStatus, dwTime, MY_Serendipity.bSilentMode and 'silent' or 'auto')
	else
		local szXml = GetFormatText(szName == GetClientPlayer().szName
			and _L(nStatus == SERENDIPITY_STATUS.START
				and 'You got %s, would you like to share?'
				or 'You finished %s, would you like to share?', szSerendipity)
			or _L(nStatus == SERENDIPITY_STATUS.START
				and '[%s] got %s, would you like to share?'
				or '[%s] finished %s, would you like to share?', szName, szSerendipity)
		)
		local function fnAction()
			D.SerendipityShareConfirm(szName, szSerendipity, nMethod, nStatus, dwTime, 'manual')
		end
		if MY_Serendipity.bEnable then
			MY.CreateNotify({
				szKey = szKey,
				szMsg = szXml,
				fnAction = fnAction,
				bPlaySound = MY_Serendipity.bSound,
				bPopupPreview = MY_Serendipity.bPreview,
			})
		end
		insert(SERENDIPITY_LIST, { szKey = szKey, szXml = szXml, fnAction = fnAction })
	end
end

do
local function GetSerendipityName(nID)
	for i = 2, g_tTable.Adventure:GetRowCount() do
		local tLine = g_tTable.Adventure:GetRow(i)
		if tLine.dwID == nID then
			return tLine.szName
		end
	end
end

MY.RegisterEvent('ON_SERENDIPITY_TRIGGER.QIYU', function()
	local me = GetClientPlayer()
	if not me then
		return
	end
	D.OnSerendipity(me.szName, GetSerendipityName(arg0), 2, arg1, GetCurrentTime())
end)
end

do
local l_serendipities
local function GetSerendipityInfo(dwTabType, dwIndex)
	if not l_serendipities then
		l_serendipities = MY.LoadLUAData(MY.GetAddonInfo().szFrameworkRoot .. 'data/serendipities/$lang.jx3dat')
		l_serendipities.name = {}
		for dwTabType, tList in pairs(l_serendipities) do
			if dwTabType ~= 'name' then
				for dwID, p in pairs(tList) do
					if IsNumber(dwTabType) then
						local KItemInfo = GetItemInfo(dwTabType, dwID)
						if KItemInfo then
							l_serendipities.name[KItemInfo.szName] = p
						end
					end
					local KItemInfo = GetItemInfo(p[1], p[2])
					if KItemInfo then
						l_serendipities.name[KItemInfo.szName] = p
					end
				end
			end
		end
	end
	local serendipity = l_serendipities[dwTabType] and l_serendipities[dwTabType][dwIndex]
	if serendipity then
		local iteminfo = GetItemInfo(serendipity[1], serendipity[2])
		if iteminfo then
			return iteminfo.szName, serendipity[3]
		end
	end
end

MY.RegisterMsgMonitor('QIYU', function(szMsg, nFont, bRich, r, g, b, szChannel)
	local me = GetClientPlayer()
	if not me then
		return
	end
	-- local hWnd = Station.GetFocusWindow()
	-- if hWnd and hWnd:GetType() == 'WndEdit' then
	-- 	return
	-- end
	-- 跨服中免打扰
	if IsRemotePlayer(me.dwID) then
		return
	end
	-- 确认是真实系统消息
	if not StringLowerW(szMsg):find('ui/image/minimap/minimap.uitex') then
		return
	end
	-- OutputMessage('MSG_SYS', "<image>path=\"UI/Image/Minimap/Minimap.UITex\" frame=184</image><text>text=\"“一只蠢盾盾”侠士正在为人传功，不经意间触发奇遇【雪山恩仇】！正是：侠心义行，偏遭奇症缠身；雪峰疗伤，却逢绝世奇缘。\" font=10 r=255 g=255 b=0 </text><text>text=\"\\\n\"</text>", true)
	-- “醉戈止战”侠士福缘非浅，触发奇遇【阴阳两界】，此千古奇缘将开启怎样的奇妙际遇，令人神往！
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	szMsg:gsub(_L.ADVENTURE_PATT, function(szName, szSerendipity)
		D.OnSerendipity(szName, szSerendipity, 1, 0, GetCurrentTime())
	end)
	-- 恭喜侠士江阙阙在25人英雄会战唐门中获得稀有掉落[夜话·白鹭]！
	szMsg:gsub(_L.ADVENTURE_PATT2, function(szName, szSerendipity)
		if not IsDebugClient() and MY.IsParty(szName) and not MY.IsFriend(szName) then
			return
		end
		if not GetSerendipityInfo('name', szSerendipity) then -- 太多了筛选下…
			return
		end
		D.OnSerendipity(szName, szSerendipity, 1, 0, GetCurrentTime())
	end)
end, {'MSG_SYS'})

MY.RegisterEvent('LOOT_ITEM', function()
	local player = GetPlayer(arg0)
	local item = GetItem(arg1)
	if not player or not item then
		return
	end
	local szSerendipity, nStatus = GetSerendipityInfo(item.dwTabType, item.dwIndex)
	if szSerendipity then
		D.OnSerendipity(player.szName, szSerendipity, 3, nStatus, GetCurrentTime())
	end
end)

MY.RegisterEvent('QUEST_FINISHED', function()
	local me = GetClientPlayer()
	if not me then
		return
	end
	local szSerendipity, nStatus = GetSerendipityInfo('quest', arg0)
	if szSerendipity then
		D.OnSerendipity(me.szName, szSerendipity, 4, nStatus, GetCurrentTime())
	end
end)
end

MY.RegisterInit(function()
	MY.RegisterTutorial({
		szKey = 'MY_Serendipity',
		szMessage = _L['Would you like to share serendipity?'],
		fnRequire = function()
			return not MY.IsInDevMode() and not MY_Serendipity.bEnable
		end,
		{
			szOption = _L['Yes'],
			bDefault = true,
			fnAction = function()
				MY_Serendipity.bEnable = true
				MY.RedrawTab(nil)
			end,
		},
		{
			szOption = _L['No'],
			fnAction = function()
				MY_Serendipity.bEnable = false
				MY.RedrawTab(nil)
			end,
		},
	})

	MY.RegisterTutorial({
		szKey = 'MY_Serendipity_Auto',
		szMessage = _L['Would you like to auto share serendipity?'],
		fnRequire = function()
			return not MY.IsInDevMode()
				and MY_Serendipity.bEnable
				and not MY_Serendipity.bAutoShare
		end,
		{
			szOption = _L['Yes'],
			bDefault = true,
			fnAction = function()
				MY_Serendipity.bAutoShare = true
				MY.RedrawTab(nil)
			end,
		},
		{
			szOption = _L['No'],
			fnAction = function()
				MY_Serendipity.bAutoShare = false
				MY.RedrawTab(nil)
			end,
		},
	})

	MY.RegisterTutorial({
		szKey = 'MY_Serendipity_Silent',
		szMessage = _L['Would you like to share serendipity silently?'],
		fnRequire = function()
			return not MY.IsInDevMode()
				and MY_Serendipity.bEnable
				and MY_Serendipity.bAutoShare
				and not MY_Serendipity.bSilentMode
		end,
		{
			szOption = _L['Yes'],
			bDefault = true,
			fnAction = function()
				MY_Serendipity.bSilentMode = true
				MY.RedrawTab(nil)
			end,
		},
		{
			szOption = _L['No'],
			fnAction = function()
				MY_Serendipity.bSilentMode = false
				MY.RedrawTab(nil)
			end,
		},
	})
end)
