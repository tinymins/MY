--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 科举助手 (台服用)
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
local UI, GLOBAL, CONSTANT, wstring, lodash = X.UI, X.GLOBAL, X.CONSTANT, X.wstring, X.lodash
-------------------------------------------------------------------------------------------------------
local PLUGIN_NAME = 'MY_Toolbox'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_Toolbox'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^9.0.0') then
	return
end
X.RegisterRestriction('MY_ExamTip', { ['*'] = true, intl = false })
--------------------------------------------------------------------------
local LOCAL_DATA_CACHE -- 本地题库
local INPUT_DATA_CACHE = {} -- 玩家答题缓存
local REMOTE_DATA_CACHE = {} -- 从服务器获取到的数据缓存
local LAST_REMOTE_QUERY -- 最后一次网络查询的题目（防止重查）
local D = {}

local function DisplayMessage(szText)
	X.Sysmsg(_L['Exam tip'], szText)
end

local function IsCurrentQuestion(szQues)
	local frame = Station.Lookup('Normal/ExaminationPanel')
	if not frame then
		return
	end
	return frame:Lookup('', 'Handle_ExamContents'):Lookup(0):GetText() == szQues
end

local function ResolveAnswer(szAnsw)
	local frame = Station.Lookup('Normal/ExaminationPanel')
	if not frame then
		return
	end
	for i = 1, 4 do
		frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):SetFontColor(0, 0, 0)
	end
	if szAnsw then
		for i = 1, 4 do
			if frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):GetText() == szAnsw then
				frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i, 'Text_T1No' .. i):SetFontColor(255, 255, 0)
				frame:Lookup('Wnd_Type1/CheckBox_T1No' .. i):Check(true)
				return true
			end
		end
	end
	return false
end

local function QueryData(szQues)
	if LAST_REMOTE_QUERY == szQues then
		return
	end
	LAST_REMOTE_QUERY = szQues
	ResolveAnswer()
	DisplayMessage(_L['Querying, please wait...'])

	if not LOCAL_DATA_CACHE then
		LOCAL_DATA_CACHE = X.LoadLUAData({'config/examtip.jx3dat', X.PATH_TYPE.GLOBAL}, { passphrase = false })
			or X.LoadLUAData({'config/examtip.jx3dat', X.PATH_TYPE.GLOBAL})
			or {}
	end
	if LOCAL_DATA_CACHE[szQues] then
		for _, szAnsw in ipairs(LOCAL_DATA_CACHE[szQues]) do
			if ResolveAnswer(szAnsw) then
				return DisplayMessage(_L['Local exam data matched.'])
			end
		end
	end

	X.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = 'https://pull.j3cx.com/api/exam?'
			.. X.EncodePostData(X.UrlEncode({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				q = AnsiToUTF8(szQues),
			})),
		success = function(html, status)
			local res = X.JsonDecode(html)
			if not res or not IsCurrentQuestion(res.ques) then
				return
			end

			if #res.data == 0 then
				if res.more then
					DisplayMessage(_L['No result found, here\'s from open search engine:'] .. '\n' .. res.more)
				else
					DisplayMessage(_L['No result found.'])
				end
			else
				for _, rec in ipairs(res.data) do
					local ques, ans = UTF8ToAnsi(rec.ques), UTF8ToAnsi(rec.ans)
					if IsCurrentQuestion(ques) and ResolveAnswer(ans) then
						REMOTE_DATA_CACHE[ques] = ans
						return
					end
				end

				local szText = _L['No result matched, here\'s similar answers:']
				for _, rec in ipairs(res.data) do
					local ques, ans = UTF8ToAnsi(rec.ques), UTF8ToAnsi(rec.ans)
					szText = szText .. '\n' .. _L('Question: %s\nAnswer: %s', ques, ans)
				end
				DisplayMessage(szText)
			end
		end,
		error = function(html, status, connected)
			DisplayMessage(_L['Loading failed.'])
		end,
		timeout = 10000,
	})
end

function D.SubmitData(tExamData, bAllRight)
	if X.IsDebugServer() or not MY_Serendipity.bEnable then
		return
	end
	local data = {}
	for szQues, aBody in pairs(tExamData) do
		if not REMOTE_DATA_CACHE[szQues] then
			table.insert(aBody, 1, szQues)
			table.insert(data, X.ConvertToUTF8(aBody))
		end
	end
	if #data == 0 then
		return
	end
	X.Ajax({
		driver = 'auto', mode = 'auto', method = 'auto',
		url = 'https://push.j3cx.com/api/exam/uploads?'
			.. X.EncodePostData(X.UrlEncode(X.SignPostData({
				l = AnsiToUTF8(GLOBAL.GAME_LANG),
				L = AnsiToUTF8(GLOBAL.GAME_EDITION),
				data = X.JsonEncode(data),
				perfect = bAllRight and 1 or 0,
			}, X.SECRET.EXAM_UPLOADS))),
		success = function(html, status)
			local res = X.JsonDecode(html)
			if X.IsRestricted('MY_ExamTip') or not res then
				return
			end
			X.Sysmsg(_L['Exam tip'], _L('%s record(s) commited, %s record(s) accepted!', res.received, res.accepted))
		end,
	})
end

function D.GatherDataFromPanel()
	local frame = Station.Lookup('Normal/ExaminationPanel')
	if not (frame and frame:IsVisible()) then
		return
	end
	local txtQues = frame:Lookup('', 'Handle_ExamContents'):Lookup(0)
	if not txtQues then
		return
	end
	local szQues, aBody = txtQues:GetText()
	-- 单选
	if not aBody then
		local wnd = frame:Lookup('Wnd_Type1')
		if wnd and wnd:IsVisible() then
			local aChoise, aChoosed = {}, {}
			for i = 1, 4 do
				local chk = wnd:Lookup('CheckBox_T1No' .. i)
				if chk and chk:IsVisible() then
					if chk:IsCheckBoxChecked() then
						table.insert(aChoosed, #aChoise)
					end
					table.insert(aChoise, chk:Lookup('', 'Text_T1No' .. i):GetText())
				end
			end
			aBody = { 1, aChoise, aChoosed }
		end
	end
	-- 多选
	if not aBody then
		local wnd = frame:Lookup('Wnd_Type2')
		if wnd and wnd:IsVisible() then
			local aChoise, aChoosed = {}, {}
			for i = 1, 4 do
				local chk = wnd:Lookup('CheckBox_T2No' .. i)
				if chk and chk:IsVisible() then
					if chk:IsCheckBoxChecked() then
						table.insert(aChoosed, #aChoise)
					end
					table.insert(aChoise, chk:Lookup('Text_T2No' .. i):GetText())
				end
			end
			aBody = { 2, aChoise, aChoosed }
		end
	end
	-- 问答题
	if not aBody then
		local wnd = frame:Lookup('Wnd_Type3')
		if wnd and wnd:IsVisible() then
			local edt = wnd:Lookup('Edit_Anwer')
			aBody = { 3, edt and edt:GetText() or '' }
		end
	end
	-- 看图单选
	if not aBody then
		local wnd = frame:Lookup('Wnd_Type4')
		if wnd and wnd:IsVisible() then
			local aChoise, aChoosed = {}, {}
			for i = 1, 4 do
				local chk = wnd:Lookup('CheckBox_T4No' .. i)
				if chk and chk:IsVisible() then
					if chk:IsCheckBoxChecked() then
						table.insert(aChoosed, #aChoise)
					end
					table.insert(aChoise, chk:Lookup('Text_T4No' .. i):GetText())
				end
			end
			aBody = { 4, aChoise, aChoosed }
		end
	end
	return szQues, aBody
end

do
local l_nExamPrintRemainSpace = 0
local function OnFrameBreathe()
	local szQues, aBody = D.GatherDataFromPanel()
	if not X.IsRestricted('MY_ExamTip') then
		QueryData(szQues)
	end
	if szQues and aBody then
		INPUT_DATA_CACHE[szQues] = aBody
	end
	l_nExamPrintRemainSpace = GetClientPlayer().GetExamPrintRemainSpace()
end

X.RegisterFrameCreate('ExaminationPanel', 'EXAM_TIP', function(name, frame)
	frame.OnFrameBreathe = OnFrameBreathe
end)

X.RegisterEvent('LOOT_ITEM', 'MY_EXAMTIP', function()
	if X.IsEmpty(INPUT_DATA_CACHE) then
		return
	end
	local item = GetItem(arg1)
	if item and item.nUiId == 65814 then
		local nBeforeExamPrintRemainSpace = l_nExamPrintRemainSpace
		local tExamData = X.Clone(INPUT_DATA_CACHE)
		INPUT_DATA_CACHE = {}
		X.DelayCall(2000, function()
			local bAllRight = nBeforeExamPrintRemainSpace - GetClientPlayer().GetExamPrintRemainSpace() == 100
			D.SubmitData(tExamData, bAllRight)
		end)
	end
end)
end

X.RegisterEvent('OPEN_WINDOW', 'MY_EXAMTIP', function()
	if X.IsEmpty(INPUT_DATA_CACHE) then
		return
	end
	if wstring.find(arg1, _L['<G>Congratulations you finished the exam, please visit Yangzhou next monday for result.']) then
		local tExamData = X.Clone(INPUT_DATA_CACHE)
		INPUT_DATA_CACHE = {}
		D.SubmitData(tExamData, false)
	end
end)

X.RegisterReload('MY_ExamTip', function()
	Wnd.CloseWindow('ExaminationPanel')
end)
