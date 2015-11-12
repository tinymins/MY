-----------------------------------------------
-- @Desc  : 仓库背包增强（搜索/对比）
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2014-11-25 10:40:14
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-08-13 23:07:33
-----------------------------------------------
MY_BagEx = {}
MY_BagEx.bEnable = true
RegisterCustomData("MY_BagEx.bEnable")
local _C = { tItemText = {} }
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Toolbox/lang/")

MY_BagEx.Enable = function(bEnable)
	MY_BagEx.bEnable = bEnable
	if bEnable then
		_C.OnBreathe()
	else
		_C.ClearHook()
	end
end

_C.OnFrameKeyDown = function()
	local szKey = GetKeyName(Station.GetMessageKey())
	if IsCtrlKeyDown() and szKey == "F" then
		MY.UI(this):children("#WndEditBox_KeyWord"):focus()
		if this.__MYBagEx_OnFrameKeyDown then
			this.__MYBagEx_OnFrameKeyDown()
		end
		return 1
	end
	if this.__MYBagEx_OnFrameKeyDown then
		return this.__MYBagEx_OnFrameKeyDown()
	end
	return 0
end

_C.ClearHook = function()
	MY.RegisterEvent("EXECUTE_BINDING.MY_BAGEX")

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
	:add("Normal/BigBankPanel/WndCheckBox_Compare")
	:add("Normal/GuildBankPanel/WndEditBox_KeyWord")
	:add("Normal/GuildBankPanel/WndCheckBox_Compare")
	:remove()
	
	MY.UI("Normal/BigBagPanel")
	:add("Normal/BigBankPanel")
	:add("Normal/GuildBankPanel")
	:each(function()
		this.bMYBagExHook = nil
		if this.OnFrameKeyDown == _C.OnFrameKeyDown then
			this.OnFrameKeyDown = this.__MYBagEx_OnFrameKeyDown
			this.__MYBagEx_OnFrameKeyDown = nil
		end
	end)
end

_C.Hook = function()
	MY.RegisterEvent("EXECUTE_BINDING.MY_BAGEX", function(e)
		local szName, bDown = arg0, arg1
		if Cursor.IsVisible()
		and szName == "OPENORCLOSEALLBAGS" and not bDown then
			local hFrame = Station.Lookup("Normal/BigBagPanel")
			if hFrame and hFrame:IsVisible() then
				Station.SetFocusWindow(hFrame)
			end
		end
	end)
	-- bag
	local hFrame = Station.Lookup("Normal/BigBagPanel")
	if hFrame and not hFrame.bMYBagExHook then
		hFrame.bMYBagExHook = true
		if hFrame and hFrame.OnFrameKeyDown ~= _C.OnFrameKeyDown then
			hFrame.__MYBagEx_OnFrameKeyDown = hFrame.OnFrameKeyDown
			hFrame.OnFrameKeyDown = _C.OnFrameKeyDown
		end
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
		
		MY.UI("Normal/BigBagPanel"):append("WndEditBox", "WndEditBox_KeyWord", {
			w = 100, h = 21, x = 60, y = 30,
			text = _C.szBagFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 20)
				XGUI(raw):width(nLen * 10)
				_C.szBagFilter = txt
				if not _C.bBagTimeLtd then
					MY.UI("Normal/BigBagPanel/CheckBox_Totle"):check(true)
				end
				_C.DoFilterBag()
			end,
		})
	end

	-- bank
	local hFrame = Station.Lookup("Normal/BigBankPanel")
	if hFrame and not hFrame.bMYBagExHook then
		hFrame.bMYBagExHook = true
		if hFrame and hFrame.OnFrameKeyDown ~= _C.OnFrameKeyDown then
			hFrame.__MYBagEx_OnFrameKeyDown = hFrame.OnFrameKeyDown
			hFrame.OnFrameKeyDown = _C.OnFrameKeyDown
		end
		MY.UI("Normal/BigBankPanel"):append("WndEditBox", "WndEditBox_KeyWord", {
			w = 150, h = 21, x = 280, y = 80,
			text = _C.szBankFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 15)
				nLen = math.min(nLen, 25)
				XGUI(raw):width(nLen * 10)
				_C.szBankFilter = txt
				_C.DoFilterBank(true)
			end,
		})
		_C.DoFilterBank()
		
		MY.UI("Normal/BigBankPanel")
		  :append("WndCheckBox", "WndCheckBox_Compare"):children("#WndCheckBox_Compare")
		  :width(100):pos(340, 56)
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
		if hFrame and hFrame.OnFrameKeyDown ~= _C.OnFrameKeyDown then
			hFrame.__MYBagEx_OnFrameKeyDown = hFrame.OnFrameKeyDown
			hFrame.OnFrameKeyDown = _C.OnFrameKeyDown
		end
		MY.UI("Normal/GuildBankPanel"):append("WndEditBox", "WndEditBox_KeyWord", {
			w = 100, h = 21, x = 60, y = 25,
			text = _C.szGuildBankFilter,
			placeholder = _L['Search'],
			onchange = function(raw, txt)
				local nLen = txt:len()
				nLen = math.max(nLen, 10)
				nLen = math.min(nLen, 25)
				XGUI(raw):width(nLen * 10)
				_C.szGuildBankFilter = txt
				_C.DoFilterGuildBank(true)
			end,
		})
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
		_C.DoCompareGuildBank()
	end
end

_C.OnBreathe = function()
	if MY_BagEx.bEnable then
		_C.Hook()
	end
end

_C.GetItemText = function(item)
	if item then
		if GetItemTip then
			local szKey = item.dwTabType .. ',' .. item.dwIndex
			if not _C.tItemText[szKey] then
				_C.tItemText[szKey] = ""
				_C.tItemText[szKey] = MY.Xml.GetPureText(GetItemTip(item))
			end
			return _C.tItemText[szKey]
		else
			return item.szName
		end
	else
		return ''
	end
end

-- 过滤背包
_C.DoFilterBag = function(bForce)
	if IsBagInSort and IsBagInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szBagFilter or _C.bBagTimeLtd then
		_C.FilterBags("Normal/BigBagPanel", _C.szBagFilter, _C.bBagTimeLtd)
		if _C.szBagFilter == "" then
			_C.szBagFilter = nil
		end
	end
end
-- 过滤仓库
_C.DoFilterBank = function(bForce)
	if IsBankInSort and IsBankInSort() then
		return
	end
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szBankFilter or _C.bBankTimeLtd then
		_C.FilterBags("Normal/BigBankPanel", _C.szBankFilter, _C.bBankTimeLtd)
		if _C.szBankFilter == "" then
			_C.szBankFilter = nil
		end
	end
end
-- 过滤帮会仓库
_C.DoFilterGuildBank = function(bForce)
	-- 优化性能 当过滤器为空时不遍历筛选
	if bForce or _C.szGuildBankFilter then
		_C.FilterBags("Normal/GuildBankPanel", _C.szGuildBankFilter)
		if _C.szGuildBankFilter == "" then
			_C.szGuildBankFilter = nil
		end
	end
end

local SimpleMatch = MY.String.SimpleMatch
-- 过滤仓库原始函数
_C.FilterBags = function(szTreePath, szFilter, bTimeLtd)
	szFilter = (szFilter or ""):gsub('[%[%]]', '')
	local me = GetClientPlayer()
	if empty(szFilter) and not bTimeLtd then
		XGUI(szTreePath):find(".Box"):alpha(255)
	else
		XGUI(szTreePath):find(".Box"):each(function(ui)
			if this.bBag then
				return
			end
			local bMatch = true
			local szBoxType, nUiId, dwBox, dwX, suitIndex, dwTabType, dwIndex = this:GetObject()
			if szBoxType == UI_OBJECT_ITEM then
				local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
				if item then
					if bTimeLtd and item.GetLeftExistTime() == 0 then
						bMatch = false
					end
					if not SimpleMatch(_C.GetItemText(item), szFilter) then
						bMatch = false
					end
				end
			end
			if bMatch then
				this:SetAlpha(255)
			else
				this:SetAlpha(50)
			end
		end)
	end
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
	if not MY_BagEx.bEnable then
		return
	end
	_C.OnBagItemUpdate()
	MY.DelayCall('MY_BagEx', _C.OnBagItemUpdate, 100)
end)
MY.RegisterEvent("GUILD_BANK_PANEL_UPDATE", function()
	if not MY_BagEx.bEnable then
		return
	end
	_C.OnBagItemUpdate()
end)
MY.RegisterInit('MY_BAGEX', function() MY.BreatheCall(_C.OnBreathe, 130) end)
MY.RegisterReload("MY_BAGEX", _C.ClearHook)
-- MY.RegisterEvent("SPECIAL_KEY_MSG", function(e)Output(e,arg0,arg1)end)
