--------------------------------------------
-- @Desc  : 聊天辅助
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-29 14:24:10
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ChatFilter/lang/")
local TYPE_LIST = {
	"NEARBY", "SENCE", "WORLD", "TEAM", "RAID", "BATTLE_FIELD", "TONG",
	"FORCE", "CAMP", "WHISPER", "FRIENDS", "TONG_ALLIANCE", "SYSTEM",
}

local TYPE_CHANNELS = setmetatable({
	["NEARBY"       ] = {PLAYER_TALK_CHANNEL.NEARBY       },
	["SENCE"        ] = {PLAYER_TALK_CHANNEL.SENCE        },
	["WORLD"        ] = {PLAYER_TALK_CHANNEL.WORLD        },
	["TEAM"         ] = {PLAYER_TALK_CHANNEL.TEAM         },
	["RAID"         ] = {PLAYER_TALK_CHANNEL.RAID         },
	["BATTLE_FIELD" ] = {PLAYER_TALK_CHANNEL.BATTLE_FIELD },
	["TONG"         ] = {PLAYER_TALK_CHANNEL.TONG         },
	["FORCE"        ] = {PLAYER_TALK_CHANNEL.FORCE        },
	["CAMP"         ] = {PLAYER_TALK_CHANNEL.CAMP         },
	["WHISPER"      ] = {PLAYER_TALK_CHANNEL.WHISPER      },
	["FRIENDS"      ] = {PLAYER_TALK_CHANNEL.FRIENDS      },
	["TONG_ALLIANCE"] = {PLAYER_TALK_CHANNEL.TONG_ALLIANCE},
}, {__index = function(t, k) return EMPTY_TABLE end})
local TYPE_MSGS = setmetatable({
	["NEARBY"       ] = {"MSG_NORMAL"        },
	["SENCE"        ] = {"MSG_MAP"           },
	["WORLD"        ] = {"MSG_WORLD"         },
	["TEAM"         ] = {"MSG_PARTY"         },
	["RAID"         ] = {"MSG_TEAM"          },
	["BATTLE_FIELD" ] = {"MSG_BATTLE_FILED"  },
	["TONG"         ] = {"MSG_GUILD"         },
	["FORCE"        ] = {"MSG_SCHOOL"        },
	["CAMP"         ] = {"MSG_CAMP"          },
	["WHISPER"      ] = {"MSG_WHISPER"       },
	["FRIENDS"      ] = {"MSG_FRIEND"        },
	["TONG_ALLIANCE"] = {"MSG_GUILD_ALLIANCE"},
	["SYSTEM"       ] = {"MSG_SYS"           },
}, {__index = function(t, k) return EMPTY_TABLE end})

local TYPE_COLOR = setmetatable({
	["NEARBY"       ] = {255, 255, 255},
	["SENCE"        ] = {255, 126, 126},
	["WORLD"        ] = {252, 204, 204},
	["TEAM"         ] = {140, 178, 253},
	["RAID"         ] = { 73, 168, 241},
	["BATTLE_FIELD" ] = {255, 126, 126},
	["TONG"         ] = {  0, 200,  72},
	["FORCE"        ] = {  0, 255, 255},
	["CAMP"         ] = {155, 230,  58},
	["WHISPER"      ] = {202, 126, 255},
	["FRIENDS"      ] = {241, 114, 183},
	["TONG_ALLIANCE"] = {178, 240, 164},
	["SYSTEM"       ] = {255, 255, 0  },
}, {__index = function(t, k) return {255, 255, 255} end})
local TYPE_TITLE = setmetatable({
	["NEARBY"       ] = _L["nearby"     ],
	["SENCE"        ] = _L["map"        ],
	["WORLD"        ] = _L["world"      ],
	["TEAM"         ] = _L["team"       ],
	["RAID"         ] = _L["raid"       ],
	["BATTLE_FIELD" ] = _L["battlefield"],
	["TONG"         ] = _L["tong"       ],
	["FORCE"        ] = _L["force"      ],
	["CAMP"         ] = _L["camp"       ],
	["WHISPER"      ] = _L["whisper"    ],
	["FRIENDS"      ] = _L["firends"    ],
	["TONG_ALLIANCE"] = _L["alliance"   ],
	["SYSTEM"       ] = _L["system"     ],
}, {__index = function(t, k) return k end})

local DEFAULT_KW_CONFIG = {
	keyword = "",
	channel = {
		["NEARBY"       ] = true ,
		["SENCE"        ] = true ,
		["WORLD"        ] = true ,
		["TEAM"         ] = false,
		["RAID"         ] = false,
		["BATTLE_FIELD" ] = false,
		["TONG"         ] = false,
		["FORCE"        ] = true ,
		["CAMP"         ] = true ,
		["WHISPER"      ] = true ,
		["FRIENDS"      ] = false,
		["TONG_ALLIANCE"] = false,
		["SYSTEM"       ] = false,
	},
	ignoreAcquaintance = true,
	ignoreCase = true, ignoreEnEm = true, ignoreSpace = true,
}
MY_ChatBlock = {}
MY_ChatBlock.bBlockWords = true
MY_ChatBlock.tBlockWords = {}
RegisterCustomData("MY_ChatBlock.bBlockWords")

local TYPE_CHANNELMSGS_R = (function()
	local t = {}
	for eType, aChannel in pairs(TYPE_CHANNELS) do
		for _, nChannel in ipairs(aChannel) do
			if not t[nChannel] then
				t[nChannel] = {}
			end
			table.insert(t[nChannel], eType)
		end
	end
	for eType, aMsgType in pairs(TYPE_MSGS) do
		for _, szMsgType in ipairs(aMsgType) do
			if not t[szMsgType] then
				t[szMsgType] = {}
			end
			table.insert(t[szMsgType], eType)
		end
	end
	return t
end)()

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
function MY_ChatBlock.MatchBlockWord(talkData, talkType, dwTalkerID)
	local szText = ""
	if type(talkData) == "table" then
		for _, v in ipairs(talkData) do
			if v.text then
				szText = szText .. v.text
			end
		end
	elseif type(talkData) == "string" then
		szText = talkData
	end
	local bAcquaintance = dwTalkerID and (MY.GetFriend(dwTalkerID) or MY.GetFoe(dwTalkerID) or MY.GetTongMember(dwTalkerID))
	
	
	for _, bw in ipairs(MY_ChatBlock.tBlockWords) do
		local hasfilter = false
		for _, eType in ipairs(TYPE_CHANNELMSGS_R[talkType] or EMPTY_TABLE) do
			if bw.channel[eType] then
				hasfilter = true
				break
			end
		end
		if hasfilter and not (bw.ignoreAcquaintance and bAcquaintance)
		and MY.String.SimpleMatch(szText, bw.keyword, not bw.ignoreCase, not bw.ignoreEnEm, bw.ignoreSpace) then
			return true
		end
	end
end

do
local aChannel, aMsgType = {}, {}
for _, eType in ipairs(TYPE_LIST) do
	for _, nChannel in ipairs(TYPE_CHANNELS[eType]) do
		local exist = false
		for _, ch in ipairs(aChannel) do
			if ch == nChannel then
				exist = true
				break
			end
		end
		if not exist then
			table.insert(aChannel, nChannel)
		end
	end
	for _, szMsgType in ipairs(TYPE_MSGS[eType]) do
		local exist = false
		for _, ch in ipairs(aMsgType) do
			if ch == szMsgType then
				exist = true
				break
			end
		end
		if not exist then
			table.insert(aMsgType, szMsgType)
		end
	end
end
RegisterTalkFilter(function(nChannel, t, dwTalkerID, szName, bEcho, bOnlyShowBallon, bSecurity, bGMAccount, bCheater, dwTitleID, dwIdePetTemplateID)
	if MY_ChatBlock.bBlockWords and MY_ChatBlock.MatchBlockWord(t, nChannel, dwTalkerID) then
		return true
	end
end, aChannel)

RegisterMsgFilter(function(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName)
	if MY_ChatBlock.bBlockWords and MY_ChatBlock.MatchBlockWord(bRich and GetPureText(szMsg) or szMsg, szType, dwTalkerID) then
		return true
	end
end, aMsgType)
end

local function Chn2Str(ch)
	local aText = {}
	for _, eType in ipairs(TYPE_LIST) do
		if ch[eType] then
			table.insert(aText, TYPE_TITLE[eType])
		end
	end
	local szText
	if #aText == 0 then
		szText = _L['Disabled']
	elseif #aText == #TYPE_LIST then
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
	
	ui:append("WndCheckBox", {
		x = x, y = y, w = 70,
		text = _L['enable'],
		check = MY_ChatBlock.bBlockWords,
		oncheck = function(bCheck)
			MY_ChatBlock.bBlockWords = bCheck
		end,
	})
	x = x + 70
	
	local edit = ui:append('WndEditBox', {
		name = 'WndEditBox_Keyword',
		x = x, y = y, w = w - 160 - x, h = 25,
		placeholder = _L['Type keyword, right click list to config.'],
	}, true)
	x, y = 0, y + 30
	
	local list = ui:append("WndListBox", { x = x, y = y, w = w, h = h - 30 })
	-- 初始化list控件
	for _, bw in ipairs(MY_ChatBlock.tBlockWords) do
		list:listbox('insert', ChatBlock2Text(bw.keyword, bw.channel), bw.keyword, bw)
	end
	list:listbox('onmenu', function(hItem, text, id, data)
		local chns = data.channel
		local menu = {
			szOption = _L['Channels'],
		}
		for _, eType in ipairs(TYPE_LIST) do
			table.insert(menu, {
				szOption = _L("%s channel", TYPE_TITLE[eType]),
				rgb = TYPE_COLOR[eType],
				bCheck = true, bChecked = chns[eType],
				fnAction = function()
					chns[eType] = not chns[eType]
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
	ui:append("WndButton", {
		x = w - 160, y=  0, w = 80,
		text = _L["add"],
		onclick = function()
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
		end,
	})
	-- del
	ui:append("WndButton", {
		x = w - 80, y =  0, w = 80,
		text = _L["delete"],
		onclick = function()
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
		end,
	})
end
MY.RegisterPanel( "MY_ChatBlock", _L["chat filter"], _L['Chat'], "UI/Image/Common/Money.UITex|243", {255,255,0,200}, PS)
