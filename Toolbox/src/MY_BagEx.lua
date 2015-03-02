-----------------------------------------------
-- @Desc  : 仓库背包增强（搜索/对比）
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2014-11-25 10:40:14
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-03-02 14:22:39
-----------------------------------------------
MY_BagEx = {}
MY_BagEx.bEnable = true
RegisterCustomData("MY_BagEx.bEnable")
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")

MY_BagEx.Enable = function(bEnable)
	MY_BagEx.bEnable = bEnable
	if bEnable then
		_C.OnBreathe()
	else
		MY.UI("Normal/BigBagPanel/CheckBox_Totle")
		:add("Normal/BigBagPanel/CheckBox_Task")
		:add("Normal/BigBagPanel/CheckBox_Equipment")
		:add("Normal/BigBagPanel/CheckBox_Drug")
		:add("Normal/BigBagPanel/CheckBox_Material")
		:add("Normal/BigBagPanel/CheckBox_Book")
		:add("Normal/BigBagPanel/CheckBox_Grey")
		:onuievent('OnLButtonUp')
		
		MY.UI("Normal/GuildBankPanel"):children('#^CheckBox_%d$')
		:onuievent('OnLButtonUp')
		
		MY.UI("Normal/BigBagPanel/CheckBox_TimeLtd")
		:add("Normal/BigBagPanel/WndEditBox_KeyWord")
		:add("Normal/BigBankPanel/CheckBox_TimeLtd")
		:add("Normal/BigBankPanel/WndEditBox_KeyWord")
		:add("Normal/GuildBankPanel/WndEditBox_KeyWord")
		:remove()
		
		MY.UI("Normal/BigBagPanel")
		:add("Normal/BigBankPanel")
		:add("Normal/GuildBankPanel")
		:each(function()
			this.bMYBagExHook = nil
		end)
	end
end

_C.OnBreathe = function()
	if not MY_BagEx.bEnable then
		return
	end

	-- bag
	local hFrame = Station.Lookup("Normal/BigBagPanel")
	if hFrame and not hFrame.bMYBagExHook then
		hFrame.bMYBagExHook = true
		local x, y = Station.Lookup("Normal/BigBagPanel/CheckBox_Grey"):GetRelPos()
		local w, h = Station.Lookup("Normal/BigBagPanel/CheckBox_Grey"):Lookup('', ''):GetSize()
		MY.UI("Normal/BigBagPanel")
		  :append("WndRadioBox", "CheckBox_TimeLtd"):children("#CheckBox_TimeLtd")
		  :text(_L['Time Limited']):size(w + 10, h):pos(x + w, y)
		  :check(function(bChecked)
		  	_C.bBagTimeLtd = bChecked
		  	_C.DoFilterBag()
		  end):item("#Text_Default"):left(20)
		
		MY.UI("Normal/BigBagPanel/CheckBox_Totle")
		:add("Normal/BigBagPanel/CheckBox_Task")
		:add("Normal/BigBagPanel/CheckBox_Equipment")
		:add("Normal/BigBagPanel/CheckBox_Drug")
		:add("Normal/BigBagPanel/CheckBox_Material")
		:add("Normal/BigBagPanel/CheckBox_Book")
		:add("Normal/BigBagPanel/CheckBox_Grey")
		:onuievent('OnLButtonUp')
		:onuievent('OnLButtonUp', function()
			MY.UI("Normal/BigBagPanel/CheckBox_TimeLtd"):check(false)
		end)
		:add("Normal/BigBagPanel/CheckBox_TimeLtd")
		:group("filter_check")
		
		MY.UI("Normal/BigBagPanel")
		  :append("WndEditBox", "WndEditBox_KeyWord"):children("#WndEditBox_KeyWord")
		  :text(_C.szBagFilter or ""):size(100,21):pos(60, 30):placeholder(_L['Search'])
		  :change(function(txt)
		  	_C.szBagFilter = txt
		  	if not _C.bBagTimeLtd then
		  		MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true)
		  	end
		  	_C.DoFilterBag()
		  end)
	end

	-- bank
	local hFrame = Station.Lookup("Normal/BigBankPanel")
	if hFrame and not hFrame.bMYBagExHook then
		hFrame.bMYBagExHook = true
		
		MY.UI("Normal/BigBankPanel")
		  :append("WndEditBox", "WndEditBox_KeyWord"):children("#WndEditBox_KeyWord")
		  :text(_C.szBankFilter or ""):size(100,21):pos(280, 80):placeholder(_L['Search'])
		  :change(function(txt)
		  	_C.szBankFilter = txt
		  	_C.DoFilterBank(true)
		  end)
		_C.DoFilterBank()
		
		MY.UI("Normal/BigBankPanel")
		  :append("WndCheckBox", "WndCheckBox_Compare"):children("#WndCheckBox_Compare")
		  :width(100):pos(380, 80)
		  :text(_L['compare with bag'])
		  :check(_C.bCompareBank or false)
		  :check(function(bChecked)
		  	if bChecked then
		  		MY.UI("Normal/BigBankPanel/CheckBox_TimeLtd"):check(false)
		  	end
		  	_C.bCompareBank = bChecked
		  	_C.DoCompareBank(true)
		  end)
		_C.DoCompareBank()
		
		MY.UI("Normal/BigBankPanel")
		  :append("WndCheckBox", "CheckBox_TimeLtd"):children("#CheckBox_TimeLtd")
		  :width(100):pos(277, 56):alpha(200)
		  :text(_L['Time Limited'])
		  :check(_C.bBankTimeLtd or false)
		  :check(function(bChecked)
		  	if bChecked then
		  		MY.UI("Normal/BigBankPanel/WndCheckBox_Compare"):check(false)
		  	end
		  	_C.bBankTimeLtd = bChecked
		  	_C.DoFilterBank(true)
		  end)
		_C.DoFilterBank()
	end

	-- guild bank
	local hFrame = Station.Lookup("Normal/GuildBankPanel")
	if hFrame and not hFrame.bMYBagExHook then
		hFrame.bMYBagExHook = true
		MY.UI("Normal/GuildBankPanel")
		  :append("WndEditBox", "WndEditBox_KeyWord"):children("#WndEditBox_KeyWord")
		  :text(_C.szGuildBankFilter or ""):size(100,21):pos(60, 25):placeholder(_L['Search'])
		  :change(function(txt)
		  	_C.szGuildBankFilter = txt
		  	_C.DoFilterGuildBank(true)
		  end)
		_C.DoFilterGuildBank()
		
		MY.UI("Normal/GuildBankPanel")
		  :append("WndCheckBox", "WndCheckBox_Compare"):children("#WndCheckBox_Compare")
		  :width(100):pos(20, 475)
		  :text(_L['compare with bag'])
		  :check(_C.bCompareGuild or false)
		  :check(function(bChecked)
		  	_C.bCompareGuild = bChecked
		  	_C.DoCompareGuildBank(true)
		  end)
		_C.DoCompareBank()
		
		MY.UI("Normal/GuildBankPanel"):children('#^CheckBox_%d$')
		  :onuievent('OnLButtonUp')
		  :onuievent('OnLButtonUp', function()
		  	MY.DelayCall(function()
		  		_C.DoCompareGuildBank(true)
		  	end, 100)
		  end)
		
	end
end

-- 过滤背包
_C.DoFilterBag = function(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szBagFilter or _C.bBagTimeLtd then
		_C.FilterPackage("Normal/BigBagPanel/", _C.szBagFilter, _C.bBagTimeLtd)
		if _C.szBagFilter == "" then
			_C.szBagFilter = nil
		end
	end
end
-- 过滤仓库
_C.DoFilterBank = function(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szBankFilter or _C.bBankTimeLtd then
		_C.FilterPackage("Normal/BigBankPanel/", _C.szBankFilter, _C.bBankTimeLtd)
		if _C.szBankFilter == "" then
			_C.szBankFilter = nil
		end
	end
end
-- 过滤帮会仓库
_C.DoFilterGuildBank = function(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szGuildBankFilter then
		_C.FilterGuildPackage("Normal/GuildBankPanel/", _C.szGuildBankFilter)
		if _C.szGuildBankFilter == "" then
			_C.szGuildBankFilter = nil
		end
	end
end
-- 过滤背包原始函数
_C.FilterPackage = function(szTreePath, szFilter, bTimeLtd)
	szFilter = (szFilter or ""):gsub('[%[%]]', '')
	local me = GetClientPlayer()
	MY.UI(szTreePath):find(".Box"):each(function(ui)
		if this.bBag then return end
		local dwBox, dwX, bMatch = this.dwBox, this.dwX, true
		local item = me.GetItem(dwBox, dwX)
		if not item then return end
		if not wstring.find(item.szName, szFilter) then
			bMatch = false
		end
		if bTimeLtd and item:GetLeftExistTime() == 0 then
			bMatch = false
		end
		if bMatch then
			this:SetAlpha(255)
		else
			this:SetAlpha(50)
		end
	end)
end
-- 过滤帮会仓库原始函数
_C.FilterGuildPackage = function(szTreePath, szFilter)
	szFilter = (szFilter or ""):gsub('[%[%]]', '')
	local me = GetClientPlayer()
	MY.UI(szTreePath):find(".Box"):each(function(ui)
		local uIID, _, nPage, dwIndex = this:GetObjectData()
		if uIID < 0 then return end
		if not wstring.find(GetItemNameByUIID(uIID), szFilter) then
			this:SetAlpha(50)
		else
			this:SetAlpha(255)
		end
	end)
end

_C.DoCompareBank = function(bForce)
	if _C.bCompareBank then
		local frmBag = Station.Lookup("Normal/BigBagPanel")
		local frmBank = Station.Lookup("Normal/BigBankPanel")
		
		if frmBag and frmBank and frmBank:IsVisible() then
			MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true):check(false)
			_C.DoCompare(MY.UI(frmBag), MY.UI(frmBank))
		end
	else
		_C.DoFilterBag(bForce)
		_C.DoFilterBank(bForce)
	end
end

_C.DoCompareGuildBank = function(bForce)
	if _C.bCompareGuild then
		local frmBag = Station.Lookup("Normal/BigBagPanel")
		local frmGuildBank = Station.Lookup("Normal/GuildBankPanel")
		
		if frmBag and frmGuildBank and frmGuildBank:IsVisible() then
			MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true):check(false)
			_C.DoCompare(MY.UI(frmBag), MY.UI(frmGuildBank))
		end
	else
		_C.DoFilterBag(bForce)
		_C.DoFilterGuildBank(bForce)
	end
end

-- 过滤背包
_C.DoCompare = function(ui1, ui2)
	local itemlist1 = {}
	local itemlist2 = {}
	
	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist1[dwTabType .. ',' .. dwIndex] = true
		end
	end)
	ui2:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			itemlist2[dwTabType .. ',' .. dwIndex] = true
			
			if itemlist1[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
	ui1:find('.Box'):each(function(e)
		if this.bBag then return end
		local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
		if szBoxType == UI_OBJECT_ITEM then
			if itemlist2[dwTabType .. ',' .. dwIndex] then
				e:alpha(255)
			else
				e:alpha(50)
			end
		end
	end)
end

_C.OnBagItemUpdate = function()
	if _C.bCompareBank then
		_C.DoCompareBank()
	elseif _C.bCompareGuild then
		_C.DoCompareGuildBank()
	else
		_C.DoFilterBag()
		_C.DoFilterBank()
		_C.DoFilterGuildBank()
	end
end
-- 事件注册
MY.RegisterEvent("BAG_ITEM_UPDATE", function()
	_C.OnBagItemUpdate()
	MY.DelayCall('MY_BagEx', _C.OnBagItemUpdate, 100)
end)
MY.RegisterInit(function() MY.BreatheCall(_C.OnBreathe, 130) end)
