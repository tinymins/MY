--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 公共数据分享模块
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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
				url = 'https://push.j3cx.com/api/share-event',
				data = {
					l = X.ENVIRONMENT.GAME_LANG,
					L = X.ENVIRONMENT.GAME_EDITION,
					region = X.GetRealServer(1),
					server = X.GetRealServer(2),
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
			url = 'https://push.j3cx.com/api/share-ui',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				region = X.GetRealServer(1),
				server = X.GetRealServer(2),
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
	local me = GetClientPlayer()
	if not me then
		return
	end
	local dwTargetID = arg3
	local npc = GetNpc(dwTargetID)
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
			url = 'https://push.j3cx.com/api/share-npc-chat',
			data = {
				l = X.ENVIRONMENT.GAME_LANG,
				L = X.ENVIRONMENT.GAME_EDITION,
				r = X.GetRealServer(1),
				s = X.GetRealServer(2),
				t = GetCurrentTime(),
				c = szContent,
				cn = line and line.szCenterName or '', -- Center Name
				ci = line and line.dwCenterID or -1, -- Center ID
				li = line and line.nLineIndex or -1, -- Line Index
				mi = map and map.dwID, -- Map ID
				mn = map and map.szName, -- Map Name
				nt = npc.dwTemplateID, -- NPC Template ID
				nn = X.GetObjectName(npc), -- NPC Name
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
	local me = GetClientPlayer()
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
				url = 'https://push.j3cx.com/api/share-sysmsg',
				data = {
					l = X.ENVIRONMENT.GAME_LANG,
					L = X.ENVIRONMENT.GAME_EDITION,
					region = X.GetRealServer(1),
					server = X.GetRealServer(2),
					content = szMsg,
					time = GetCurrentTime(),
				},
				signature = X.SECRET['J3CX::SHARE_SYSMSG'],
			})
			break
		end
	end
	NEXT_AWAKE_TIME = GetTime() + FREQUENCY_LIMIT
end)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
