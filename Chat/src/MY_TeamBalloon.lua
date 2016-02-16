--------------------------------------------
-- @Desc  : ÁÄÌìÅÝÅÝ
-- @Author: µÔÒ»Ãù @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last Modified by:   µÔÒ»Ãù @tinymins
-- @Last Modified time: 2015-08-19 10:33:04
--------------------------------------------
local INI_PATH = MY.GetAddonInfo().szRoot .. "Chat/ui/MY_TeamBalloon.ini"
local DISPLAY_TIME = 5000
local ANIMATE_SHOW_TIME = 500
local ANIMATE_HIDE_TIME = 500
MY_TeamBalloon = { bEnable = true }
RegisterCustomData("MY_TeamBalloon.bEnable")

local function AppendBalloon(hFrame, dwID, szMsg)
	local hTotal = hFrame:Lookup("", "")
	local hBalloon = hTotal:Lookup("Balloon_" .. dwID)
	if not hBalloon then
		hBalloon = hTotal:AppendItemFromIni(INI_PATH, "Handle_Balloon", "Balloon_" .. dwID)
		hBalloon.dwID = dwID
	end
	hBalloon.nTime = GetTime()
	local hContent = hBalloon:Lookup("Handle_Content")
	hContent:Show()
	hContent:Clear()
	hContent:SetSize(300, 131)
	hContent:AppendItemFromString(szMsg)
	hContent:FormatAllItemPos()
	hContent:SetSizeByAllItemSize()
	
	-- Adjust balloon size
	local w, h = hContent:GetSize()
	w, h = w + 20, h + 20
	local image1 = hBalloon:Lookup("Image_Bg1")
	image1:SetSize(w, h)
	local image2 = hBalloon:Lookup("Image_Bg2")
	image2:SetRelPos(math.min(w - 16 - 8, 32), h - 4)
	hBalloon:SetSize(10000, 10000)
	hBalloon:FormatAllItemPos()
	hBalloon:SetSizeByAllItemSize()
		
	-- Show balloon
	local hWnd = Station.Lookup("Normal/Teammate")
	local hContent = hBalloon:Lookup("Handle_Content")
	local x, y, w, h, _
	if hWnd and hWnd:IsVisible() then
		local hTotal = hWnd:Lookup("", "")
		local nCount = hTotal:GetItemCount()
		for i = 0, nCount - 1 do
			local hI = hTotal:Lookup(i)
			if hI.dwID == dwID then
				w, h = hContent:GetSize()
				x, y = hI:GetAbsPos()
				x, y = x + 205, y - h - 2
			end
		end
	elseif CTM_GetMemberHandle then
		local hTotal = CTM_GetMemberHandle(dwID)
		if hTotal then
			_, h = hContent:GetSize()
			w, _ = hTotal:GetSize()
			x, y = hTotal:GetAbsPos()
			x, y = x + w, y - h - 2
		end
	end
	if x and y then
		hBalloon:SetRelPos(x, y)
		hBalloon:SetAbsPos(x, y)
	end
	hBalloon:SetAlpha(0)
	hFrame:BringToTop()
end


local function OnSay(hFrame, szMsg, dwID, nChannel)
	local player = GetClientPlayer()
	if player and player.dwID ~= dwID and (
		nChannel == PLAYER_TALK_CHANNEL.TEAM or
		nChannel == PLAYER_TALK_CHANNEL.RAID
	) and player.IsInParty() then
		local hTeam = GetClientTeam()
		if not hTeam then return end
		if hTeam.nGroupNum > 1 then
			return
		end
		local hGroup = hTeam.GetGroupInfo(0)
		for k, v in pairs(hGroup.MemberList) do
			if v == dwID then
				AppendBalloon(hFrame, dwID, szMsg, false)
			end
		end
	end
end

function MY_TeamBalloon.OnFrameCreate()
	this:RegisterEvent("PLAYER_SAY")
end

function MY_TeamBalloon.OnEvent(event)
	if event == "PLAYER_SAY" then
		OnSay(this, arg0, arg1, arg2)
	end
end

function MY_TeamBalloon.OnFrameBreathe()
	local hTotal = this:Lookup("", "")
	for i = 0, hTotal:GetItemCount() - 1 do
		local hBalloon = hTotal:Lookup(i)
		local nTick = GetTime() - hBalloon.nTime
		if nTick <= ANIMATE_SHOW_TIME then
			hBalloon:SetAlpha(nTick / ANIMATE_SHOW_TIME * 255)
		elseif nTick >= ANIMATE_SHOW_TIME + DISPLAY_TIME + ANIMATE_HIDE_TIME then
			hTotal:RemoveItem(hBalloon)
		elseif nTick >= ANIMATE_SHOW_TIME + DISPLAY_TIME then
			hBalloon:SetAlpha((1 - (nTick - ANIMATE_SHOW_TIME - DISPLAY_TIME) / ANIMATE_HIDE_TIME) * 255)
		end
	end
end

function MY_TeamBalloon.Enable(...)
	if select("#", ...) == 1 then
		MY_TeamBalloon.bEnable = not not ...
		if MY_TeamBalloon.bEnable then
			Wnd.OpenWindow(INI_PATH, "MY_TeamBalloon")
		else
			Wnd.CloseWindow("MY_TeamBalloon")
		end
	else
		return MY_TeamBalloon.bEnable
	end
end

MY.RegisterEvent("CUSTOM_DATA_LOADED.MY_TeamBalloon", function()
	if arg0 == "Role" then
		MY_TeamBalloon.Enable(MY_TeamBalloon.Enable())
		MY.RegisterEvent("CUSTOM_DATA_LOADED.MY_TeamBalloon")
	end
end)
