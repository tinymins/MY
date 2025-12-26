--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 公共数据分享模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/MY_ShareKnowledge')
--------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_!Base'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_!Base'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '*') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

---------------
-- 系统事件
---------------
do
local FREQUENCY_LIMIT = 10000
local NEXT_AWAKE_TIME = 0
local CURRENT_EVENT = {}

MY_RSS.RegisterAdapter('share-event', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, p in ipairs(data) do
			if X.IsString(p[1]) then
				local r = { name = p[1], argv = {}, argc = p[3] }
				if X.IsTable(p[2]) then
					for key, value in pairs(p[2]) do
						if X.IsNumber(key) and key > 0 then
							r.argv['arg' .. (key - 1)] = value
						end
					end
				end
				table.insert(t, r)
			end
		end
	end
	return t
end)

X.RegisterEvent('MY_RSS_UPDATE', function()
	for k, _ in pairs(CURRENT_EVENT) do
		X.RegisterEvent(k, 'MY_ShareKnowledge__Event', false)
	end
	CURRENT_EVENT = {}
	local rss = MY_RSS.Get('share-event')
	if not rss then
		return
	end
	for _, p in ipairs(rss) do
		X.RegisterEvent(p.name, 'MY_ShareKnowledge__Event', function()
			if not MY_Serendipity.bEnable then
				return
			end
			if GetTime() < NEXT_AWAKE_TIME then
				return
			end
			for key, value in pairs(p.argv) do
				if _G[key] ~= value then
					return
				end
			end
			local argv = {}
			for i = 0, p.argc - 1 do
				argv[i + 1] = _G['arg' .. i]
			end
			local szArgs = X.EncodeJSON(argv)
			X.EnsureAjax({
				url = MY_RSS.PUSH_BASE_URL .. '/api/share-event',
				data = {
					l = X.ENVIRONMENT.GAME_LANG,
					L = X.ENVIRONMENT.GAME_EDITION,
					region = X.GetRegionOriginName(),
					server = X.GetServerOriginName(),
					event = p.name,
					args = szArgs,
					time = GetCurrentTime(),
				},
				signature = X.SECRET['J3CX::SHARE_EVENT'],
			})
			NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
		end)
		CURRENT_EVENT[p.name] = true
	end
end)
end

---------------
-- 界面抓取
---------------
do
local FREQUENCY_LIMIT = 10000
local NEXT_AWAKE_TIME = 0
local CACHE = {}

local TRANSLATOR = {}
function TRANSLATOR.PLAIN(info)
	local t = {}
	if info.children then
		for _, v in ipairs(info.children) do
			table.insert(t, TRANSLATOR.PLAIN(v))
		end
	end
	if info.type == 'Text' then
		table.insert(t, info.text)
	end
	return table.concat(t)
end
function TRANSLATOR.BBCODE(info)
	local t = {}
	if info.children then
		for _, v in ipairs(info.children) do
			table.insert(t, TRANSLATOR.BBCODE(v))
		end
	end
	if info.type == 'Text' then
		local bStyle = false
		if info.r and info.g and info.b then
			bStyle = true
			table.insert(t, '[style color="')
			table.insert(t, X.RGB2Hex(info.r, info.g, info.b, info.a))
			table.insert(t, '"]')
		end
		table.insert(t, X.StringReplaceW(X.StringReplaceW(info.text, '[', '\\['), ']', '\\]'))
		if bStyle then
			table.insert(t, '[/style]')
		end
	elseif info.type == 'Image' then
		table.insert(t, '[img]')
		table.insert(t, info.image)
		if info.frame then
			table.insert(t, ':')
			table.insert(t, info.frame)
		end
		table.insert(t, '[/img]]')
	end
	return table.concat(t)
end

local SCHEMA = X.Schema.MixedTable({
	-- PATH
	[1] = X.Schema.MixedTable({
		[1] = X.Schema.String,
		[2] = X.Schema.OneOf(X.Schema.String, X.Schema.Nil),
	}),
	-- UI PROPS PATH / DATA TRANSLATOR NAME
	[2] = X.Schema.OneOf(unpack((function()
		local a = {X.Schema.Collection(X.Schema.Any), X.Schema.Nil}
		for k, _ in pairs(TRANSLATOR) do
			table.insert(a, k)
		end
		return a
	end)())),
})

MY_RSS.RegisterAdapter('share-ui', function(data)
	local t = {}
	if X.IsTable(data) then
		for k, v in pairs(data) do
			local err = X.Schema.CheckSchema(v, SCHEMA)
			if not err then
				local key = k
				if not X.IsString(key) then
					key = v[1][1]
					if v[1][2] then
						key = key .. '::' .. v[1][2]
					end
				end
				table.insert(t, {
					id = GetStringCRC(X.EncodeJSON({key, v[1], v[2]})),
					key = key,
					path = v[1],
					dataTranslator = v[2],
				})
			end
		end
	end
	return t
end)

local function SerializeElement(el)
	local info = { type = el:GetType(), name = el:GetName() }
	if el:GetBaseType() == 'Wnd' then
		local h = el:Lookup('', '')
		if h then
			info.handle = SerializeElement(h)
		end
		local c = el:GetFirstChild()
		if c then
			info.children = {}
		end
		while c do
			table.insert(c.children, SerializeElement(c))
			c = c:GetNext()
		end
	end
	if info.type == 'Text' then
		local r, g, b = el:GetFontColor()
		local a = el:GetAlpha()
		if r ~= 255 or g ~= 255 or b ~= 255 or a ~= 255 then
			info.r = r
			info.g = g
			info.b = b
			info.a = a
		end
		info.text = el:GetText()
	elseif info.type == 'Image' then
		local image, frame = el:GetImagePath()
		info.image = image
		info.frame = frame
	elseif info.type == 'Handle' then
		local i = 0
		local it = el:Lookup(i)
		if it then
			info.children = {}
		end
		while it do
			table.insert(info.children, SerializeElement(it))
			i = i + 1
			it = el:Lookup(i)
		end
	end
	return info
end

X.BreatheCall('MY_ShareKnowledge__UI', 1000, function()
	if not MY_Serendipity.bEnable then
		return
	end
	local rss = MY_RSS.Get('share-ui')
	if not rss then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	local res = {}
	for _, v in ipairs(rss) do
		local el, data = Station.Lookup(unpack(v.path)), nil
		if el then
			if X.IsTable(v.dataTranslator) then
				data = X.Get(el, v.dataTranslator)
			else
				data = SerializeElement(el)
				if v.dataTranslator then
					local translator = TRANSLATOR[v.dataTranslator]
					if translator then
						data = translator(data)
					else
						data = nil
					end
				end
			end
		end
		local szContent = X.EncodeJSON(data)
		if CACHE[v.id] ~= szContent then
			res[v.key] = data
			CACHE[v.id] = szContent
		end
	end
	if not X.IsEmpty(res) then
		X.EnsureAjax({
			url = MY_RSS.PUSH_BASE_URL .. '/api/share-ui',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				region = X.GetRegionOriginName(),
				server = X.GetServerOriginName(),
				time = GetCurrentTime(),
				data = X.EncodeJSON(res),
			},
			signature = X.SECRET['J3CX::SHARE_UI'],
		})
	end
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end

---------------
-- NPC 对话框
---------------
do
local FREQUENCY_LIMIT = 1000
local NEXT_AWAKE_TIME = 0

MY_RSS.RegisterAdapter('share-npc-chat', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, k in ipairs(data) do
			t[k] = true
		end
	end
	return t
end)

X.RegisterEvent('OPEN_WINDOW', 'MY_ShareKnowledge__Npc', function()
	if not MY_Serendipity.bEnable then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local dwTargetID = arg3
	local npc = X.GetNpc(dwTargetID)
	if not npc then
		return
	end
	local rss = MY_RSS.Get('share-npc-chat')
	if not rss or not rss[npc.dwTemplateID] then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	local szContent = arg1
	local map = X.GetMapInfo(me.GetMapID())
	local szDelayID
	local function fnAction(line)
		X.EnsureAjax({
			url = MY_RSS.PUSH_BASE_URL .. '/api/share-npc-chat',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				r = X.GetRegionOriginName(),
				s = X.GetServerOriginName(),
				t = GetCurrentTime(),
				c = szContent,
				cn = line and line.szCenterName or '', -- Center Name
				ci = line and line.dwCenterID or -1, -- Center ID
				li = line and line.nLineIndex or -1, -- Line Index
				mi = map and map.dwID, -- Map ID
				mn = map and map.szName, -- Map Name
				nt = npc.dwTemplateID, -- NPC Template ID
				nn = X.GetNpcName(npc.dwID), -- NPC Name
			},
			signature = X.SECRET['J3CX::SHARE_NPC_CHAT'],
		})
		X.DelayCall(szDelayID, false)
	end
	szDelayID = X.DelayCall(5000, fnAction)
	X.GetHLLineInfo({ dwMapID = me.GetMapID(), nCopyIndex = me.GetScene().nCopyIndex }, fnAction)
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end

---------------
-- 系统信息
---------------
do
local FREQUENCY_LIMIT = 0
local NEXT_AWAKE_TIME = 0

MY_RSS.RegisterAdapter('share-sysmsg', function(data)
	local t = {}
	if X.IsTable(data) then
		for _, szPattern in ipairs(data) do
			if X.IsString(szPattern) then
				table.insert(t, szPattern)
			end
		end
	end
	return t
end)

X.RegisterMsgMonitor('MSG_SYS', 'MY_ShareKnowledge__Sysmsg', function(szChannel, szMsg, nFont, bRich, r, g, b)
	if not MY_Serendipity.bEnable then
		return
	end
	local me = X.GetClientPlayer()
	if not me then
		return
	end
	local rss = MY_RSS.Get('share-sysmsg')
	if not rss then
		return
	end
	if GetTime() < NEXT_AWAKE_TIME then
		return
	end
	-- 跨服中免打扰
	if IsRemotePlayer(me.dwID) then
		return
	end
	-- 确认是真实系统消息
	if X.ContainsEchoMsgHeader(szMsg) then
		return
	end
	-- OutputMessage('MSG_SYS', "<image>path=\"UI/Image/Minimap/Minimap.UITex\" frame=184</image><text>text=\"“一只蠢盾盾”侠士正在为人传功，不经意间触发奇遇【雪山恩仇】！正是：侠心义行，偏遭奇症缠身；雪峰疗伤，却逢绝世奇缘。\" font=10 r=255 g=255 b=0 </text><text>text=\"\\\n\"</text>", true)
	-- “醉戈止战”侠士福缘非浅，触发奇遇【阴阳两界】，此千古奇缘将开启怎样的奇妙际遇，令人神往！
	-- 恭喜侠士江阙阙在25人英雄会战唐门中获得稀有掉落[夜话·白鹭]！
	if bRich then
		szMsg = GetPureText(szMsg)
	end
	for _, szPattern in ipairs(rss) do
		if string.find(szMsg, szPattern) then
			X.EnsureAjax({
				url = MY_RSS.PUSH_BASE_URL .. '/api/share-sysmsg',
				data = {
					l = X.ENVIRONMENT.GAME_LANG,
					L = X.ENVIRONMENT.GAME_EDITION,
					region = X.GetRegionOriginName(),
					server = X.GetServerOriginName(),
					content = szMsg,
					time = GetCurrentTime(),
				},
				signature = X.SECRET['J3CX::SHARE_SYSMSG'],
			})
			NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
			break
		end
	end
end)
end

---------------
-- 通用信息
---------------
do
local FREQUENCY_LIMIT = 1000
local NEXT_AWAKE_TIME = 0
local CURRENT_MSG_CHANNEL = {}

MY_RSS.RegisterAdapter('share-msg', function(data)
	local t = {}
	if X.IsTable(data) then
		for szChannel, aList in pairs(data) do
			local a = {}
			for _, s in ipairs(aList) do
				if X.IsString(s) then
					table.insert(a, s)
				end
			end
			t[szChannel] = a
		end
	end
	return t
end)

X.RegisterEvent('MY_RSS_UPDATE', function()
	for k, _ in pairs(CURRENT_MSG_CHANNEL) do
		X.RegisterMsgMonitor(k, 'MY_ShareKnowledge__MSG', false)
	end
	CURRENT_MSG_CHANNEL = {}
	local rss = MY_RSS.Get('share-msg')
	if not rss then
		return
	end
	for k, p in pairs(rss) do
		X.RegisterMsgMonitor(k, 'MY_ShareKnowledge__MSG', function(szChannel, szMsg, nFont, bRich, r, g, b, dwTalkerID, szName)
			if not MY_Serendipity.bEnable then
				return
			end
			if GetTime() < NEXT_AWAKE_TIME then
				return
			end
			local me = X.GetClientPlayer()
			if not me then
				return
			end
			-- 跨服中免打扰
			if IsRemotePlayer(me.dwID) then
				return
			end
			-- 确认是真实消息
			if X.ContainsEchoMsgHeader(szMsg) then
				return
			end
			if bRich then
				szMsg = GetPureText(szMsg)
				bRich = false
			end
			for _, s in ipairs(p) do
				if string.find(szMsg, s) then
					X.EnsureAjax({
						url = MY_RSS.PUSH_BASE_URL .. '/api/share-msg',
						data = {
							l = X.ENVIRONMENT.GAME_LANG,
							L = X.ENVIRONMENT.GAME_EDITION,
							region = X.GetRegionOriginName(),
							server = X.GetServerOriginName(),
							channel = szChannel,
							msg = szMsg,
							talkerId = dwTalkerID,
							talkerName = szName,
							time = GetCurrentTime(),
						},
						signature = X.SECRET['J3CX::SHARE_MSG'],
					})
					NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
					return
				end
			end
		end)
		CURRENT_MSG_CHANNEL[k] = true
	end
end)
end

---------------
-- 通用商店
---------------
do
local FREQUENCY_LIMIT = 1000
local NEXT_AWAKE_TIME = 0

MY_RSS.RegisterAdapter('share-shop', function(data)
	local t = {}
	if X.IsArray(data) then
		for _, dwShopNpcTemplateID in ipairs(data) do
			if X.IsNumber(dwShopNpcTemplateID) then
				t[dwShopNpcTemplateID] = true
			end
		end
	end
	return t
end)

local SHOP_OWNER_INFO = {}
X.RegisterEvent('SHOP_OPENSHOP', 'MY_ShareKnowledge__ShareShop', function()
	local rss = MY_RSS.Get('share-shop')
	if not rss then
		return
	end
	local dwShopID = arg0
	local txtNpcName = Station.Lookup('Normal/ShopPanel/Wnd_BG', 'Text_Title')
	if not txtNpcName then
		return
	end
	local szNpcName = txtNpcName:GetText()
	local KNpc
	for i, p in ipairs(X.GetNearNpc()) do
		if X.GetNpcName(p.dwID) == szNpcName then
			KNpc = p
			break
		end
	end
	if not KNpc then
		return
	end
	SHOP_OWNER_INFO[dwShopID] = KNpc.dwTemplateID
end)

local SHOP_CACHE = {}
local function GetItemKey(it)
	if it.nGenre == ITEM_GENRE.BOOK then
		return X.NumberBaseN(it.dwTabType, 32) .. '_'
			.. X.NumberBaseN(it.dwTabIndex, 32) .. '_'
			.. X.NumberBaseN(it.nBookID, 32)
	end
	return X.NumberBaseN(it.dwTabType, 32) .. '_' .. X.NumberBaseN(it.dwTabIndex, 32)
end
local function BreatheFlushShopCache()
	if NEXT_AWAKE_TIME > GetTime() then
		return
	end
	local rss = MY_RSS.Get('share-shop')
	if not rss then
		return
	end
	for dwShopID, tList in pairs(SHOP_CACHE) do
		local dwShopNpcTemplateID = SHOP_OWNER_INFO[dwShopID]
		if dwShopNpcTemplateID then
			if rss[dwShopNpcTemplateID] then
				local aList = {}
				for dwItemIndex, tItem in pairs(tList) do
					table.insert(aList, {
						dwItemIndex = dwItemIndex,
						dwTabType = tItem.dwTabType,
						dwTabIndex = tItem.dwTabIndex,
						nGenre = tItem.nGenre,
						nBookID = tItem.nBookID,
					})
				end
				table.sort(aList, function(a, b) return a.dwItemIndex > b.dwItemIndex end)

				local aItem = {}
				for _, it in ipairs(aList) do
					table.insert(aItem, GetItemKey(it))
				end
				local szItems = table.concat(aItem, '~')

				X.EnsureAjax({
					url = MY_RSS.PUSH_BASE_URL .. '/api/share-shop',
					data = {
						l = X.ENVIRONMENT.GAME_LANG,
						L = X.ENVIRONMENT.GAME_EDITION,
						region = X.GetRegionOriginName(),
						server = X.GetServerOriginName(),
						shop = dwShopID,
						npc = SHOP_OWNER_INFO[dwShopID],
						items = szItems,
						time = GetCurrentTime(),
					},
					signature = X.SECRET['J3CX::SHARE_SHOP'],
				})
				NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
			end
			SHOP_CACHE[dwShopID] = nil
			return
		end
	end
	X.BreatheCall('MY_ShareKnowledge__ShareShop', false)
end
X.RegisterEvent('SHOP_UPDATEITEM', 'MY_ShareKnowledge__ShareShop', function()
	local rss = MY_RSS.Get('share-shop')
	if not rss then
		return
	end
	local dwShopID, dwItemIndex = arg0, arg1
	if not SHOP_CACHE[dwShopID] then
		SHOP_CACHE[dwShopID] = {}
	end
	local dwItemID = GetShopItemID(dwShopID, dwItemIndex)
	local KItem = dwItemID and GetItem(dwItemID)
	if KItem then
		SHOP_CACHE[dwShopID][dwItemIndex] = {
			dwTabType = KItem.dwTabType,
			dwTabIndex = KItem.dwIndex,
			nGenre = KItem.nGenre,
			nBookID = KItem.nBookID,
		}
		X.BreatheCall('MY_ShareKnowledge__ShareShop', 3000, BreatheFlushShopCache)
	end
end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
