-----------------------------------------------
-- @Desc  : 科举助手 (台服用)
-- @Author: 茗伊 @ 双梦镇 @ 荻花宫
-- @Date  : 2014-07-30 09:21:13
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 14:49:52
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Toolbox/lang/")
local _C = {
	szQueryUrl = "http://jx3.derzh.com/exam/?l=%s&q=%s",
	szSubmitUrl = "http://jx3.derzh.com/exam/submit.php?l=%s&d=%s",
	tCached = {}, -- 玩家答题缓存
	tAccept = {}, -- 从服务器获取到的数据缓存
	tLastQu = "",
}
MY_ExamTip = {}

-- 获取题目和答案
MY_ExamTip.QueryData = function(szQues)
	if _C.tLastQu == szQues then
		return nil
	end
	
	_C.tLastQu = szQues
	MY_ExamTip.ShowResult(szQues, nil, _L["Querying, please wait..."])
	if not _C.tLocalQaS then
		_C.tLocalQaS = MY.LoadLUAData({"config/examtip.jx3dat", MY_DATA_PATH.GLOBAL}) or {}
	end
	if _C.tLocalQaS[szQues] then
		for _, szAnsw in ipairs(_C.tLocalQaS[szQues]) do
			if MY_ExamTip.ShowResult(szQues, szAnsw, szAnsw) then
				break
			end
		end
	else
		local _, _, szLang, _ = GetVersion()
		MY.RemoteRequest(string.format(_C.szQueryUrl, szLang, MY.UrlEncode(szQues)), function(settings, szContent)
			local data = MY.Json.Decode(szContent)
			if not data then
				return nil
			end
			
			local szTip = ''
			for _, p in ipairs(data.result) do
				szTip = szTip .. p.szQues .. '\n' .. p.szAnsw
			end
			
			if #data.result == 0 then
				szTip = _L["No result found. Here's from open search engine:"].."\n" .. szTip
			else
				for _, p in ipairs(data.result) do
					if MY_ExamTip.ShowResult(data.question, p.szAnsw, szTip) then
						_C.tAccept[data.question] = p.szAnsw
						break
					end
				end
			end
		end, function()
			MY_ExamTip.ShowResult(_C.tLastQu, nil, _L['Loading failed.'])
			_C.tLastQu = ""
		end, 10000)
	end
end
-- 提交玩家正确答案 -- 云数据来源
MY_ExamTip.SubmitData = function()
	local _, _, szLang, _ = GetVersion()
	local nCommited, nAccepted, nUnsubmit = 0, 0, 0
	-- MY_Anmerkungen.szNotePanelContent = string.format(_C.szSubmitUrl, szLang, MY.UrlEncode(MY.Json.Encode(_C.tCached)))
	for szQues, szAnsw in pairs(_C.tCached) do
		if not _C.tAccept[szQues] then
			nUnsubmit = nUnsubmit + 1
			MY.RemoteRequest(string.format(_C.szSubmitUrl, szLang, MY.UrlEncode(MY.Json.Encode({[szQues] = szAnsw}))), function(settings, szContent)
				local r = MY.Json.Decode(szContent)
				if r then
					nUnsubmit = nUnsubmit - 1
					nCommited = nCommited + r.received
					nAccepted = nAccepted + r.accepted
				end
				if not MY.IsShieldedVersion() and nUnsubmit == 0 then
					MY.Sysmsg({_L('%s record(s) commited, %s record(s) accepted!', nCommited, nAccepted)}, _L['exam tip'])
				end
			end)
		end
	end
end
-- 显示结果
MY_ExamTip.ShowResult = function(szQues, szAnsw, szTip)
	local hNext = Station.Lookup("Normal/ExaminationPanel/Btn_Next")
	local hSbmt = Station.Lookup("Normal/ExaminationPanel/Btn_Submit")
	local hQues = Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0)
	local hTxt1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1",'Text_T1No1')
	local hChk1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1")
	local hTxt2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2",'Text_T1No2')
	local hChk2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2")
	local hTxt3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3",'Text_T1No3')
	local hChk3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3")
	local hTxt4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4",'Text_T1No4')
	local hChk4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4")
	
	if hQues:GetText() ~= szQues then
		return false
	end
	hTxt1:SetFontColor(0, 0, 0)
	hTxt2:SetFontColor(0, 0, 0)
	hTxt3:SetFontColor(0, 0, 0)
	hTxt4:SetFontColor(0, 0, 0)
	
	if hTxt1:GetText() == szAnsw then
		hTxt1:SetFontColor(255, 255, 0)
		hChk1:Check(true)
	elseif hTxt2:GetText() == szAnsw then
		hTxt2:SetFontColor(255, 255, 0)
		hChk2:Check(true)
	elseif hTxt3:GetText() == szAnsw then
		hTxt3:SetFontColor(255, 255, 0)
		hChk3:Check(true)
	elseif hTxt4:GetText() == szAnsw then
		hTxt4:SetFontColor(255, 255, 0)
		hChk4:Check(true)
	else
		return false
	end
	return true
end
-- 收集结果
MY_ExamTip.CollectResult = function()
	local hQues = Station.Lookup("Normal/ExaminationPanel/","Handle_ExamContents"):Lookup(0)
	local hTxt1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1",'Text_T1No1')
	local hChk1 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No1")
	local hTxt2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2",'Text_T1No2')
	local hChk2 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No2")
	local hTxt3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3",'Text_T1No3')
	local hChk3 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No3")
	local hTxt4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4",'Text_T1No4')
	local hChk4 = Station.Lookup("Normal/ExaminationPanel/Wnd_Type1/CheckBox_T1No4")
	
	local szQues = hQues:GetText()
	local szAnsw
	
	if hChk1:IsCheckBoxChecked() then
		szAnsw = hTxt1:GetText()
	elseif hChk2:IsCheckBoxChecked() then
		szAnsw = hTxt2:GetText()
	elseif hChk3:IsCheckBoxChecked() then
		szAnsw = hTxt3:GetText()
	elseif hChk4:IsCheckBoxChecked() then
		szAnsw = hTxt4:GetText()
	end
	
	if szQues and szAnsw then
		_C.tCached[szQues] = szAnsw
	end
end
-- 时钟监控
_C.OnFrameBreathe = function()
	local frame = Station.Lookup("Normal/ExaminationPanel")
	if not (frame and frame:IsVisible()) then
		return
	end
	local hQues = frame:Lookup("", "Handle_ExamContents"):Lookup(0)
	if not hQues then
		return
	end
	local szQues = hQues:GetText()
	
	if not MY.IsShieldedVersion() then
		MY_ExamTip.QueryData(szQues)
	end
	MY_ExamTip.CollectResult(szQues)
	_C.nExamPrintRemainSpace = GetClientPlayer().GetExamPrintRemainSpace()
end
MY.RegisterEvent('ON_FRAME_CREATE.EXAM_TIP', function()
	if arg0:GetName() == "ExaminationPanel" then
		arg0.OnFrameBreathe = _C.OnFrameBreathe
	end
end)
