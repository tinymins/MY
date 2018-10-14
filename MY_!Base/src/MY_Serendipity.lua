-----------------------------------------------
-- @Desc  : 茗伊插件
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2018-4-19 23:59:25
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2018-4-20 0:28:38
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
-----------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
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
		-- 战斗中移动中免打扰防止卡住
		MY.BreatheCall(function()
			if not Cursor.IsVisible()
			or not me or me.bFightState
			or (
				me.nMoveState ~= MOVE_STATE.ON_STAND
				and me.nMoveState ~= MOVE_STATE.ON_FLOAT
				and me.nMoveState ~= MOVE_STATE.ON_SIT
				and me.nMoveState ~= MOVE_STATE.ON_FREEZE
				and me.nMoveState ~= MOVE_STATE.ON_ENTRAP
				and me.nMoveState ~= MOVE_STATE.ON_DEATH
				and me.nMoveState ~= MOVE_STATE.ON_AUTO_FLY
				and me.nMoveState ~= MOVE_STATE.ON_START_AUTO_FLY
			) then
				return
			end
			MY.Ajax({
				driver = 'webcef',
				url = 'http://data.jx3.derzh.com/serendipity/?l='
				.. MY.GetLang() .. '&m=' .. nMethod
				.. '&data=' .. MY.SimpleEncrypt(MY.JsonEncode({
					n = szName, N = szNameCRC, R = szReporter,
					S = MY.GetRealServer(1), s = MY.GetRealServer(2),
					a = szSerendipity, f = nStatus, t = dwTime,
					w = w, h = h, c = szMode == 'silent' and 0 or Station.GetUIScale(),
				})),
			})
			return 0
		end)
		if szMode ~= 'silent' then
			local w, h = 270, 180
			local ui = XGUI.CreateFrame('MY_Serendipity#' .. szKey, {
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
	if MY.IsInDevMode() then
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

MY.RegisterMsgMonitor('QIYU', function(szMsg, nFont, bRich, r, g, b, szChannel)
	local me = GetClientPlayer()
	if not me then
		return
	end
	-- if not me or me.bFightState
	-- or (
	-- 	me.nMoveState ~= MOVE_STATE.ON_STAND    and
	-- 	me.nMoveState ~= MOVE_STATE.ON_FLOAT    and
	-- 	me.nMoveState ~= MOVE_STATE.ON_SIT      and
	-- 	me.nMoveState ~= MOVE_STATE.ON_FREEZE   and
	-- 	me.nMoveState ~= MOVE_STATE.ON_ENTRAP   and
	-- 	me.nMoveState ~= MOVE_STATE.ON_DEATH    and
	-- 	me.nMoveState ~= MOVE_STATE.ON_AUTO_FLY and
	-- 	me.nMoveState ~= MOVE_STATE.ON_START_AUTO_FLY
	-- ) then
	-- 	return
	-- end
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
	-- “醉戈止战”侠士福缘非浅，触发奇遇【阴阳两界】，此千古奇缘将开启怎样的奇妙际遇，令人神往！
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	szMsg:gsub(_L.ADVENTURE_PATT, function(szName, szSerendipity)
		D.OnSerendipity(szName, szSerendipity, 1, 0, GetCurrentTime())
	end)
	-- 恭喜侠士江阙阙在25人英雄会战唐门中获得稀有掉落[夜话·白鹭]！
	szMsg:gsub(_L.ADVENTURE_PATT2, function(szName, szSerendipity)
		if not IsDebugClient() and not MY.IsParty(szName) and not MY.IsFriend(szName) then
			return
		end
		D.OnSerendipity(szName, szSerendipity, 1, 0, GetCurrentTime())
	end)
end, {'MSG_SYS'})

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
	end
	local serendipity = l_serendipities[dwTabType] and l_serendipities[dwTabType][dwIndex]
	if serendipity then
		local iteminfo = GetItemInfo(serendipity[1], serendipity[2])
		if iteminfo then
			return iteminfo.szName, serendipity[3]
		end
	end
end

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
