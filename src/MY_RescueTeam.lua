--
-- 救场专用
-- by 茗伊 @ 双梦镇 @ 荻花宫
-- Build 20140411
--
-- 主要功能:
-- 1.频道聊天监控
-- 2.指定条件退队/下线
-- 
local _L = MY.LoadLangPack()
local _MY_RescueTeam = { }
MY_RescueTeam = {
    
}

-- 插入聊天内容时监控聊天信息
_MY_RescueTeam.Chat_AppendItemFromString_Hook = function(h, szMsg)
    local i = h:GetItemCount()
	-- save animiate group into name
	szMsg = string.gsub(szMsg, "group=(%d+) </a", "group=%1 name=\"%1\" </a")
    h:_AppendItemFromString_MY_RescueTeam(szMsg)
	-- insert time
	local h2 = h:Lookup(i)
	if h2 and h2:GetType() == "Text" then
		local r, g, b = h2:GetFontColor()
		if r == 255 and g == 255 and b == 0 then
			return
		end
		local t =TimeToDate(GetCurrentTime())
		local szTime = GetFormatText(string.format("[%02d:%02d.%02d]", t.hour, t.minute, t.second), 10, r, g, b, 515, "", "timelink")
		h:InsertItemFromString(i, false, szTime)
	end
end
_MY_RescueTeam.Chat_AppendItemFromString_Empty = function(...)
    h:_AppendItemFromString_MY_RescueTeam(...)
end
-- hook chat panel
MY_RescueTeam.HookChatPanel = function()
	for i = 1, 10 do
		local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
		local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
		if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
            if not h._AppendItemFromString_MY_RescueTeam then
                -- 保存原始函数 用来兼容其他插件
                h._AppendItemFromString_MY_RescueTeam = h.AppendItemFromString
            end
            -- HOOK上自己的函数
            h.AppendItemFromString = _MY_RescueTeam.Chat_AppendItemFromString_Hook
        end
	end
end

MY.RegisterPanel( "RescueTeam", _L["rescue team helper"], "UI/Image/UICommon/LoginSchool.UITex|24", {255,0,0,200} )