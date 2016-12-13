--------------------------------------------
-- @Desc  : 聊天辅助
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 13:34:11
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ChatFilter/lang/")
local CHANNEL_LIST = {
	PLAYER_TALK_CHANNEL.NEARBY,
	PLAYER_TALK_CHANNEL.SENCE,
	PLAYER_TALK_CHANNEL.WORLD,
	PLAYER_TALK_CHANNEL.TEAM,
	PLAYER_TALK_CHANNEL.RAID,
	PLAYER_TALK_CHANNEL.BATTLE_FIELD,
	PLAYER_TALK_CHANNEL.TONG,
	PLAYER_TALK_CHANNEL.FORCE,
	PLAYER_TALK_CHANNEL.CAMP,
	PLAYER_TALK_CHANNEL.FRIENDS,
	PLAYER_TALK_CHANNEL.TONG_ALLIANCE,
}
local CHANNEL_COLOR = setmetatable({
	[PLAYER_TALK_CHANNEL.NEARBY       ] = {255, 255, 255},
	[PLAYER_TALK_CHANNEL.SENCE        ] = {255, 126, 126},
	[PLAYER_TALK_CHANNEL.WORLD        ] = {252, 204, 204},
	[PLAYER_TALK_CHANNEL.TEAM         ] = {140, 178, 253},
	[PLAYER_TALK_CHANNEL.RAID         ] = { 73, 168, 241},
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD ] = {255, 126, 126},
	[PLAYER_TALK_CHANNEL.TONG         ] = {  0, 200,  72},
	[PLAYER_TALK_CHANNEL.FORCE        ] = {  0, 255, 255},
	[PLAYER_TALK_CHANNEL.CAMP         ] = {155, 230,  58},
	[PLAYER_TALK_CHANNEL.FRIENDS      ] = {241, 114, 183},
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = {178, 240, 164},
}, {__index = function(t, k) return {255, 255, 255} end})
local CHANNEL_TITLE = setmetatable({
	[PLAYER_TALK_CHANNEL.NEARBY       ] = _L["nearby"     ],
	[PLAYER_TALK_CHANNEL.SENCE        ] = _L["map"        ],
	[PLAYER_TALK_CHANNEL.WORLD        ] = _L["world"      ],
	[PLAYER_TALK_CHANNEL.TEAM         ] = _L["team"       ],
	[PLAYER_TALK_CHANNEL.RAID         ] = _L["raid"       ],
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD ] = _L["battlefield"],
	[PLAYER_TALK_CHANNEL.TONG         ] = _L["tong"       ],
	[PLAYER_TALK_CHANNEL.FORCE        ] = _L["force"      ],
	[PLAYER_TALK_CHANNEL.CAMP         ] = _L["camp"       ],
	[PLAYER_TALK_CHANNEL.FRIENDS      ] = _L["firend"     ],
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = _L["alliance"   ],
}, {__index = function(t, k) return k end})

local DEFAULT_KW_CONFIG = {
	keyword = "",
	channel = {
		[PLAYER_TALK_CHANNEL.NEARBY       ] = true ,
		[PLAYER_TALK_CHANNEL.SENCE        ] = true ,
		[PLAYER_TALK_CHANNEL.WORLD        ] = true ,
		[PLAYER_TALK_CHANNEL.TEAM         ] = false,
		[PLAYER_TALK_CHANNEL.RAID         ] = false,
		[PLAYER_TALK_CHANNEL.BATTLE_FIELD ] = false,
		[PLAYER_TALK_CHANNEL.TONG         ] = false,
		[PLAYER_TALK_CHANNEL.FORCE        ] = true ,
		[PLAYER_TALK_CHANNEL.CAMP         ] = true ,
		[PLAYER_TALK_CHANNEL.FRIENDS      ] = false,
		[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = false,
	},
	ignoreAcquaintance = true,
	ignoreCase = true, ignoreEnEm = true, ignoreSpace = true,
}
MY_ChatBlock = {}
MY_ChatBlock.bBlockWords = true
MY_ChatBlock.tBlockWords = {}
RegisterCustomData("MY_ChatBlock.bBlockWords")

local function SaveBlockWords()
	MY.SaveLUAData({'config/chatblockwords.jx3dat', MY_DATA_PATH.GLOBAL}, {blockwords = MY_ChatBlock.tBlockWords})
	MY.StorageData("MY_CHAT_BLOCKWORD", MY_ChatBlock.tBlockWords)
end

local function LoadBlockWords()
	local szOrgPath, tOrgData = MY.GetLUADataPath('config/MY_CHAT/blockwords.$lang.jx3dat'), nil
	if IsLocalFileExist(szOrgPath) then
		tOrgData = MY.LoadLUAData(szOrgPath)
		CPath.DelFile(szOrgPath)
	end
	
	local tKeys = {}
	for i, bw in ipairs(MY_ChatBlock.tBlockWords) do
		tKeys[bw.keyword] = true
	end
	if tOrgData then
		for i, rec in ipairs(tOrgData) do
			local bw = clone(DEFAULT_KW_CONFIG)
			if type(rec) == "string" then
				bw.keyword = rec
			elseif type(rec) == "table" and type(rec[1]) == "string" then
				bw.keyword = rec[1]
			end
			if bw.keyword ~= "" and not tKeys[bw.keyword] then
				table.insert(MY_ChatBlock.tBlockWords, bw)
				tKeys[bw.keyword] = true
			end
		end
	end
	local data = MY.LoadLUAData({'config/chatblockwords.jx3dat', MY_DATA_PATH.GLOBAL})
	if data and data.blockwords then
		for i, bw in ipairs(data.blockwords) do
			bw = FormatDataStructure(bw, DEFAULT_KW_CONFIG)
			if bw.keyword ~= "" and not tKeys[bw.keyword] then
				table.insert(MY_ChatBlock.tBlockWords, bw)
				tKeys[bw.keyword] = true
			end
		end
	end
	
	if tOrgData then
		SaveBlockWords()
	end
end

MY.RegisterEvent("MY_PRIVATE_STORAGE_UPDATE", function()
	if arg0 == "MY_CHAT_BLOCKWORD" then
		MY_ChatBlock.tBlockWords = arg1
	end
end)
MY.RegisterInit('MY_CHAT_BW', LoadBlockWords)

local tNoneSpaceBlockWords = {}
function MY_ChatBlock.MatchBlockWord(tTalkData, nChannel, dwTalkerID)
	local szText = ""
	for _, v in ipairs(tTalkData) do
		if v.text then
			szText = szText .. v.text
		end
	end
	local bAcquaintance = dwTalkerID and (MY.GetFriend(dwTalkerID) or MY.GetFoe(dwTalkerID) or MY.GetTongMember(dwTalkerID))
	
	for _, bw in ipairs(MY_ChatBlock.tBlockWords) do
		if bw.channel[nChannel] and not (bw.ignoreAcquaintance and bAcquaintance)
		and MY.String.SimpleMatch(szText, bw.keyword, not bw.ignoreCase, not bw.ignoreEnEm, bw.ignoreSpace) then
			return true
		end
	end
end

RegisterTalkFilter(function(nChannel, t, dwTalkerID, szName, bEcho, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
	if MY_ChatBlock.bBlockWords and MY_ChatBlock.MatchBlockWord(t, nChannel, dwTalkerID) then
		return true
	end
end, CHANNEL_LIST)

local function Chn2Str(ch)
	local szAllChannel
	if ch.ALL then
		szAllChannel = _L["All channels"]
	end
	local aText = {}
	for _, nChannel in ipairs(CHANNEL_LIST) do
		if ch[nChannel] then
			table.insert(aText, CHANNEL_TITLE[nChannel])
		end
	end
	local szText
	if #aText == 0 then
		szText = _L['Disabled']
	elseif #aText == #CHANNEL_LIST then
		szText = _L["All channels"]
	else
		szText = table.concat(aText, ",")
	end
	return szText
end

local function ChatBlock2Text(szText, tChannel)
	return szText .. " (" .. Chn2Str(tChannel) .. ")"
end

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0
	LoadBlockWords()
	
	ui:append("WndCheckBox", "WndCheckBox_Enable"):children("#WndCheckBox_Enable")
	  :pos(x, y):width(70)
	  :text(_L['enable'])
	  :check(MY_ChatBlock.bBlockWords or false)
	  :check(function(bCheck)
	  	MY_ChatBlock.bBlockWords = bCheck
	  end)
	x = x + 70
	
	local edit = ui:append("WndEditBox", "WndEditBox_Keyword"):children("#WndEditBox_Keyword"):pos(x, y):size(w - 160 - x, 25)
	x, y = 0, y + 30
	
	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1'):pos(x, y):size(w, h - 30)
	-- 初始化list控件
	for _, bw in ipairs(MY_ChatBlock.tBlockWords) do
		list:listbox('insert', ChatBlock2Text(bw.keyword, bw.channel), bw.keyword, bw)
	end
	list:listbox('onmenu', function(hItem, text, id, data)
		local chns = data.channel
		local menu = {
			szOption = _L['Channels'],
		}
		for _, nChannel in ipairs(CHANNEL_LIST) do
			table.insert(menu, {
				szOption = _L("%s channel", CHANNEL_TITLE[nChannel]),
				rgb = CHANNEL_COLOR[nChannel],
				bCheck = true, bChecked = chns[nChannel],
				fnAction = function()
					chns[nChannel] = not chns[nChannel]
					XGUI(hItem):text(ChatBlock2Text(id, chns))
					SaveBlockWords()
				end,
			})
		end
		table.insert(menu, MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['ignore spaces'],
			bCheck = true, bChecked = data.ignoreSpace,
			fnAction = function()
				data.ignoreSpace = not data.ignoreSpace
				SaveBlockWords()
			end,
		})
		table.insert(menu, {
			szOption = _L['ignore enem'],
			bCheck = true, bChecked = data.ignoreEnEm,
			fnAction = function()
				data.ignoreEnEm = not data.ignoreEnEm
				SaveBlockWords()
			end,
		})
		table.insert(menu, {
			szOption = _L['ignore case'],
			bCheck = true, bChecked = data.ignoreCase,
			fnAction = function()
				data.ignoreCase = not data.ignoreCase
				SaveBlockWords()
			end,
		})
		table.insert(menu, {
			szOption = _L['ignore acquaintance'],
			bCheck = true, bChecked = data.ignoreAcquaintance,
			fnAction = function()
				data.ignoreAcquaintance = not data.ignoreAcquaintance
				SaveBlockWords()
			end,
		})
		table.insert(menu, MENU_DIVIDER)
		table.insert(menu, {
			szOption = _L['delete'],
			fnAction = function()
				list:listbox('delete', text, id)
				LoadBlockWords()
				for i = #MY_ChatBlock.tBlockWords, 1, -1 do
					if MY_ChatBlock.tBlockWords[i].keyword == id then
						table.remove(MY_ChatBlock.tBlockWords, i)
					end
				end
				SaveBlockWords()
			end,
		})
		return menu
	end):listbox('onlclick', function(hItem, text, id, data, selected)
		edit:text(id)
	end)
	-- add
	ui:append("WndButton", "WndButton_Add"):children("#WndButton_Add")
	  :pos(w - 160, 0):width(80)
	  :text(_L["add"])
	  :click(function()
	  	local szText = edit:text()
	  	-- 去掉前后空格
	  	szText = (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
	  	-- 验证是否为空
	  	if szText == "" then
	  		return
	  	end
	  	LoadBlockWords()
	  	-- 验证是否重复
	  	for i, bw in ipairs(MY_ChatBlock.tBlockWords) do
	  		if bw.keyword == szText then
	  			return
	  		end
	  	end
	  	-- 加入表
		local bw = clone(DEFAULT_KW_CONFIG)
		bw.keyword = szText
	  	table.insert(MY_ChatBlock.tBlockWords, 1, bw)
	  	SaveBlockWords()
	  	-- 更新UI
	  	list:listbox('insert', ChatBlock2Text(bw.keyword, bw.channel), bw.keyword, bw, 1)
	  end)
	-- del
	ui:append("WndButton", "WndButton_Del"):children("#WndButton_Del")
	  :pos(w - 80, 0):width(80)
	  :text(_L["delete"])
	  :click(function()
	  	for _, v in ipairs(list:listbox('select', 'selected')) do
	  		list:listbox('delete', v.text, v.id)
	  		LoadBlockWords()
	  		for i = #MY_ChatBlock.tBlockWords, 1, -1 do
	  			if MY_ChatBlock.tBlockWords[i].keyword == v.id then
	  				table.remove(MY_ChatBlock.tBlockWords, i)
	  			end
	  		end
	  		SaveBlockWords()
	  	end
	  end)
end
MY.RegisterPanel( "MY_ChatBlock", _L["chat filter"], _L['Chat'], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, PS)
