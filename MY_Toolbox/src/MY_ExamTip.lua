-----------------------------------------------
-- @Desc  : 科举助手 (台服用)
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-07-30 09:21:13
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 14:49:52
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Toolbox/lang/")
local QUERY_URL = "https://jx3.derzh.com/api/exam?l=%s&q=%s"
local SUBMIT_URL = "https://jx3.derzh.com/api/exam"
local l_tLocal -- 本地题库
local l_tCached = {} -- 玩家答题缓存
local l_tAccept = {} -- 从服务器获取到的数据缓存
local l_szLastQueryQues -- 最后一次网络查询的题目（防止重查）

local function DisplayMessage(szText)
	MY.Sysmsg({szText}, _L['exam tip'])
end

local function IsCurrentQuestion(szQues)
	local frame = Station.Lookup('Normal/ExaminationPanel')
	if not frame then
		return
	end
	return frame:Lookup("", "Handle_ExamContents"):Lookup(0):GetText() == szQues
end

local function ResolveAnswer(szAnsw)
	local frame = Station.Lookup('Normal/ExaminationPanel')
	if not frame then
		return
	end
	for i = 1, 4 do
		frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):SetFontColor(0, 0, 0)
	end
	for i = 1, 4 do
		if frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):GetText() == szAnsw then
			frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):SetFontColor(255, 255, 0)
			frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i):Check(true)
			return true
		end
	end
	return false
end

local function QueryData(szQues)
	if l_szLastQueryQues == szQues then
		return
	end
	l_szLastQueryQues = szQues
	DisplayMessage(_L["Querying, please wait..."])

	if not l_tLocal then
		l_tLocal = MY.LoadLUAData({"config/examtip.jx3dat", MY_DATA_PATH.GLOBAL}) or {}
	end
	if l_tLocal[szQues] then
		for _, szAnsw in ipairs(l_tLocal[szQues]) do
			if ResolveAnswer(szAnsw) then
				return DisplayMessage(_L["Local exam data matched."])
			end
		end
	end

	local _, _, szLang, _ = GetVersion()
	MY.Ajax({
		type = 'get',
		url = QUERY_URL:format(szLang, MY.UrlEncode(szQues)),
		success = function(szContent, status)
			local res = MY.JsonDecode(szContent)
			if not res or not IsCurrentQuestion(res.ques) then
				return
			end

			if #res.data == 0 then
				if res.more then
					DisplayMessage(_L["No result found, here's from open search engine:"] .. "\n" .. res.more)
				else
					DisplayMessage(_L["No result found."])
				end
			else
				for _, rec in ipairs(res.data) do
					if IsCurrentQuestion(rec.ques) and ResolveAnswer(rec.ques, rec.ans) then
						l_tAccept[rec.ques] = rec.ans
						return
					end
				end

				local szText = _L['No result matched, here\'s similar answers:']
				for _, rec in ipairs(res.data) do
					szText = szText .. '\n' .. _L('Question: %s\nAnswer: %s', rec.ques, rec.ans)
				end
				DisplayMessage(szText)
			end
		end,
		error = function(html, status, connected)
			if not connected then
				l_szLastQueryQues = ""
			end
			DisplayMessage(_L['Loading failed.'])
		end,
		timeout = 10000,
	})
end

local function SubmitData()
	local data = {}
	for szQues, szAnsw in pairs(l_tCached) do
		if not l_tAccept[szQues] then
			table.insert(data, { ques = szQues, ans = szAnsw })
		end
	end
	if #data == 0 then
		return
	end
	MY.Ajax({
		type = 'post/json',
		url = SUBMIT_URL,
		data = {
			lang = select(3, GetVersion()),
			data = data,
		},
		success = function(html, status)
			local res = MY.JsonDecode(html)
			if MY.IsShieldedVersion() or not res then
				return
			end
			MY.Sysmsg({_L('%s record(s) commited, %s record(s) accepted!', r.received, r.accepted)}, _L['exam tip'])
		end,
	})
end

do
local l_nExamPrintRemainSpace = 0
local function OnFrameBreathe()
	local frame = Station.Lookup("Normal/ExaminationPanel")
	if not (frame and frame:IsVisible()) then
		return
	end
	local txtQues = frame:Lookup("", "Handle_ExamContents"):Lookup(0)
	if not txtQues then
		return
	end
	local szQues = txtQues:GetText()
	if not MY.IsShieldedVersion() then
		QueryData(szQues)
	end
	local szAnsw
	for i = 1, 4 do
		if frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i):IsCheckBoxChecked() then
			szAnsw = frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):GetText()
			break
		end
	end
	if szQues and szAnsw then
		l_tCached[szQues] = szAnsw
	end
	l_nExamPrintRemainSpace = GetClientPlayer().GetExamPrintRemainSpace()
end

local function OnFrameCreate()
	if arg0:GetName() == "ExaminationPanel" then
		arg0.OnFrameBreathe = OnFrameBreathe
	end
end
MY.RegisterEvent('ON_FRAME_CREATE.EXAM_TIP', OnFrameCreate)

local function OnLoot()
	local item = GetItem(arg1)
	if item and item.nUiId == 65814 then
		local nBeforeExamPrintRemainSpace = l_nExamPrintRemainSpace
		MY.DelayCall(function()
			if nBeforeExamPrintRemainSpace - GetClientPlayer().GetExamPrintRemainSpace() == 100 then
				SubmitData()
			end
		end, 2000)
	end
end
MY.RegisterEvent("LOOT_ITEM.MY_EXAMTIP", OnLoot)
end
