-----------------------------------------------
-- @Desc  : ���������UI��
-- @Author: ��һ�� @tinymins
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-03-10 19:37:14
-----------------------------------------------
MY = MY or {}
local _MY = {
	szIniFileEditBox   = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndEditBox.ini",
	szIniFileButton    = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndButton.ini",
	szIniFileCheckBox  = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndCheckBox.ini",
	szIniFileMainPanel = MY.GetAddonInfo().szFrameworkRoot .. "ui\\MainPanel.ini",
}
local _L = MY.LoadLangPack()
---------------------------------------------------------------------
-- ���ص� UI �������
---------------------------------------------------------------------
-------------------------------------
-- UI object class
-------------------------------------
_MY.UI = class()

-- ������Ԫ�� (�s�F����)�s��ߩ���
-- -- ����Ԫ���������Ե���table���ã���Ч���൱�� .eles[i].raw
-- setmetatable(_MY.UI, {  __call = function(me, ...) return me:ctor(...) end, __index = function(t, k) 
	-- if type(k) == "number" then
		-- return t.eles[k].raw
	-- elseif k=="new" then
		-- return t['ctor']
	-- end
-- end
-- , __metatable = true 
-- })

-----------------------------------------------------------
-- my ui common functions
-----------------------------------------------------------
-- ��ȡһ�������������Ԫ��
local GetChildren = function(root)
	if not root then return {} end
	local stack = { root }  -- ��ʼջ
	local children = {}     -- ����������Ԫ�� szTreePath => element ��ֵ��
	while #stack > 0 do     -- ѭ��ֱ��ջ��
		--### ��ջ: ����ջ��Ԫ��
		local raw = stack[#stack]
		table.remove(stack, #stack)
		if raw:GetType()=="Handle" then
			-- ����ǰ������Handle������Ԫ�ر�
			children[table.concat({ raw:GetTreePath(), '/Handle' })] = raw
			for i = 0, raw:GetItemCount() - 1, 1 do
				-- �����Ԫ����Handle/����ѹջ
				if raw:Lookup(i):GetType()=='Handle' then table.insert(stack, raw:Lookup(i))
				-- ����ѹ��������
				else children[table.concat({table.concat({ raw:Lookup(i):GetTreePath() }), i})] = raw:Lookup(i) end
			end
		else
			-- �����Handle������Handleѹջ������
			local status, handle = pcall(function() return raw:Lookup('','') end) -- raw����û��Lookup���� ��pcall����
			if status and handle then table.insert(stack, handle) end
			-- ����ǰ������Ԫ�ؼ�����Ԫ�ر�
			children[table.concat({ raw:GetTreePath() })] = raw
			--### ѹջ: ���ոյ�ջ��Ԫ�ص������Ӵ���ѹջ
			local status, sub_raw = pcall(function() return raw:GetFirstChild() end) -- raw����û��GetFirstChild���� ��pcall����
			while status and sub_raw do
				table.insert(stack, sub_raw)
				sub_raw = sub_raw:GetNext()
			end
		end
	end
	-- ��Ϊ������Ԫ�� �����Ƴ���һ��ѹջ��Ԫ�أ���Ԫ�أ�
	children[table.concat({ root:GetTreePath() })] = nil
	return children
end

-----------------------------------------------------------
-- my ui selectors -- same as jQuery -- by tinymins --
-----------------------------------------------------------
--
-- self.ele       : ui elements table
-- selt.ele[].raw : ui element itself    -- common functions will do with this
-- self.ele[].txt : ui element text box  -- functions like Text() will do with this
-- self.ele[].img : ui element image box -- functions like LoadImage() will do with this
--
-- ui object creator 
-- same as jQuery.$()
function _MY.UI:ctor(raw, tab)
	self.eles = self.eles or {}
	if type(raw)=="table" and type(raw.eles)=="table" then
		for i = 1, #raw.eles, 1 do
			table.insert(self.eles, raw.eles[i])
		end
		self.eles = raw.eles
	else
		-- farmat raw
		if type(raw)=="string" then raw = Station.Lookup(raw) end
		if raw then
			-- format tab
			local _tab = { raw = raw }
			if type(tab)=="table" then for k, v in pairs(tab) do _tab[k]=v end end
			_tab.type = raw.szMyuiType or raw:GetType()
			if not _tab.txt and _tab.type == "Text"        then _tab.txt = raw end
			if not _tab.img and _tab.type == "Image"       then _tab.img = raw end
			if not _tab.chk and _tab.type == "WndCheckBox" then _tab.chk = raw end
			if not _tab.chk and _tab.type == "WndRadioBox" then _tab.chk = raw end
			if not _tab.edt and _tab.type == "WndEdit"     then _tab.edt = raw end
			if not _tab.sdw and _tab.type == "Shadow"      then _tab.sdw = raw end
			if not _tab.hdl and _tab.type == "Handle"      then _tab.hdl = raw end
			if _tab.type=="WndEditBox" then
				_tab.wnd = _tab.wnd or raw
				_tab.hdl = _tab.hdl or raw:Lookup('','')
				_tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
				_tab.img = _tab.img or raw:Lookup('','Image_Default')
				_tab.phd = _tab.phd or raw:Lookup('','Text_PlaceHolder')
			elseif _tab.type=="WndComboBox" then
				_tab.wnd = _tab.wnd or raw
				_tab.hdl = _tab.hdl or raw:Lookup('','')
				_tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
				_tab.txt = _tab.txt or raw:Lookup('','Text_Default')
				_tab.img = _tab.img or raw:Lookup('','Image_Default')
			elseif _tab.type=="WndEditComboBox" or _tab.type=="WndAutoComplete" then
				_tab.wnd = _tab.wnd or raw
				_tab.hdl = _tab.hdl or raw:Lookup('','')
				_tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
				_tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
				_tab.img = _tab.img or raw:Lookup('','Image_Default')
				_tab.phd = _tab.phd or raw:Lookup('','Text_PlaceHolder')
			elseif _tab.type=="WndScrollBox" then
				_tab.wnd = _tab.wnd or raw
				_tab.hdl = _tab.hdl or raw:Lookup('','Handle_Scroll')
				_tab.txt = _tab.txt or raw:Lookup('','Handle_Scroll'):Lookup('Text_Default')
				_tab.img = _tab.img or raw:Lookup('','Image_Default')
				_tab.sbu = _tab.sbu or raw:Lookup('WndButton_Up')
				_tab.sbd = _tab.sbd or raw:Lookup('WndButton_Down')
				_tab.sbn = _tab.sbn or raw:Lookup('WndNewScrollBar_Default')
				_tab.shd = _tab.shd or raw:Lookup('','Handle_Scroll')
			elseif _tab.type=="WndFrame" then
				_tab.frm = _tab.frm or raw
				_tab.wnd = _tab.wnd or raw:Lookup("Window_Main")
				_tab.hdl = _tab.hdl or (_tab.wnd or _tab.frm):Lookup("", "")
				_tab.txt = _tab.txt or raw:Lookup("", "Text_Title")
			elseif string.sub(_tab.type, 1, 3) == "Wnd" then
				_tab.wnd = _tab.wnd or raw
				_tab.hdl = _tab.hdl or raw:Lookup('','')
				_tab.txt = _tab.txt or raw:Lookup('','Text_Default')
			else _tab.itm = raw end
			table.insert( self.eles, _tab )
		end
	end
	return self
end

-- clone
-- clone and return a new class
function _MY.UI:clone(eles)
	self:_checksum()
	eles = eles or self.eles
	local _eles = {}
	for i = 1, #eles, 1 do
		if eles[i].raw then table.insert(_eles, self:raw2ele(eles[i].raw)) end
	end
	return _MY.UI.new({eles = _eles})
end

-- conv raw to eles array
function _MY.UI:raw2ele(raw, tab)
	-- format tab
	local _tab = { raw = raw }
	if type(tab)=="table" then for k, v in pairs(tab) do _tab[k]=v end end
	_tab.type = raw.szMyuiType or raw:GetType()
	if not _tab.txt and _tab.type == "Text"        then _tab.txt = raw end
	if not _tab.img and _tab.type == "Image"       then _tab.img = raw end
	if not _tab.chk and _tab.type == "WndCheckBox" then _tab.chk = raw end
	if not _tab.chk and _tab.type == "WndRadioBox" then _tab.chk = raw end
	if not _tab.edt and _tab.type == "WndEdit"     then _tab.edt = raw end
	if not _tab.sdw and _tab.type == "Shadow"      then _tab.sdw = raw end
	if not _tab.hdl and _tab.type == "Handle"      then _tab.hdl = raw end
	if _tab.type=="WndEditBox" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','')
		_tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
		_tab.img = _tab.img or raw:Lookup('','Image_Default')
		_tab.phd = _tab.phd or raw:Lookup('','Text_PlaceHolder')
	elseif _tab.type=="WndComboBox" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','')
		_tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
		_tab.txt = _tab.txt or raw:Lookup('','Text_Default')
		_tab.img = _tab.img or raw:Lookup('','Image_Default')
	elseif _tab.type=="WndEditComboBox" or _tab.type=="WndAutoComplete" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','')
		_tab.cmb = _tab.cmb or raw:Lookup('Btn_ComboBox')
		_tab.edt = _tab.edt or raw:Lookup('WndEdit_Default')
		_tab.img = _tab.img or raw:Lookup('','Image_Default')
		_tab.phd = _tab.phd or raw:Lookup('','Text_PlaceHolder')
	elseif _tab.type=="WndScrollBox" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','Handle_Scroll')
		_tab.txt = _tab.txt or raw:Lookup('','Handle_Scroll'):Lookup('Text_Default')
		_tab.img = _tab.img or raw:Lookup('','Image_Default')
		_tab.sbu = _tab.sbu or raw:Lookup('WndButton_Up')
		_tab.sbd = _tab.sbd or raw:Lookup('WndButton_Down')
		_tab.sbn = _tab.sbn or raw:Lookup('WndNewScrollBar_Default')
		_tab.shd = _tab.shd or raw:Lookup('','Handle_Scroll')
	elseif _tab.type=="WndFrame" then
		_tab.frm = _tab.frm or raw
		_tab.wnd = _tab.wnd or raw:Lookup("Window_Main")
		_tab.hdl = _tab.hdl or (_tab.wnd or _tab.frm):Lookup("", "")
		_tab.txt = _tab.txt or raw:Lookup("", "Text_Title")
	elseif _tab.type=="WndSliderBox" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','')
		_tab.sld = _tab.sld or raw:Lookup("WndNewScrollBar_Default")
		_tab.txt = _tab.txt or raw:Lookup('','Text_Default')
	elseif string.sub(_tab.type, 1, 3) == "Wnd" then
		_tab.wnd = _tab.wnd or raw
		_tab.hdl = _tab.hdl or raw:Lookup('','')
		_tab.txt = _tab.txt or raw:Lookup('','Text_Default')
	else _tab.itm = raw end
	return _tab
end

--  del bad eles
-- (self) _checksum()
function _MY.UI:_checksum()
	for i = #self.eles, 1, -1 do
		local ele = self.eles[i]
		local status, err = true, 'szType'
		if (not ele.raw) or (not ele.raw.___id) then
			status, err = false, ''
		else
			status, err = pcall(function() return ele.raw:GetType() end)
		end
		if (not status) or (err=='') then table.remove(self.eles, i) end
	end
	return self
end

-- add a ele to object
-- same as jQuery.add()
function _MY.UI:add(raw, tab)
	self:_checksum()
	local eles = {}
	for i = 1, #self.eles, 1 do
		table.insert(eles, self.eles[i])
	end
	-- farmat raw
	if type(raw)=="string" then raw = Station.Lookup(raw) end
	-- insert into eles
	if raw then table.insert( eles, self:raw2ele(raw, tab) ) end
	return self:clone(eles)
end

-- delete elements from object
-- same as jQuery.not()
function _MY.UI:del(raw)
	self:_checksum()
	local eles = {}
	for i = 1, #self.eles, 1 do
		table.insert(eles, self.eles[i])
	end
	if type(raw) == "string" then
		-- delete ele those id/class fits filter:raw
		if string.sub(raw, 1, 1) == "#" then
			raw = string.sub(raw, 2)
			if string.sub(raw, 1, 1) == "^" then
				-- regexp
				for i = #eles, 1, -1 do
					if string.find(eles[i].raw:GetName(), raw) then
						table.remove(eles, i)
					end
				end
			else
				-- normal
				for i = #eles, 1, -1 do
					if eles[i].raw:GetName() == raw then
						table.remove(eles, i)
					end
				end
			end
		elseif string.sub(raw, 1, 1) == "." then
			raw = string.sub(raw, 2)
			if string.sub(raw, 1, 1) == "^" then
				-- regexp
				for i = #eles, 1, -1 do
					if string.find((eles[i].raw.szMyuiType or eles[i].raw:GetType()), raw) then
						table.remove(eles, i)
					end
				end
			else
				-- normal
				for i = #eles, 1, -1 do
					if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) == raw then
						table.remove(eles, i)
					end
				end
			end
		end
	else
		-- delete ele those treepath is the same as raw
		raw = table.concat({ raw:GetTreePath() })
		for i = #eles, 1, -1 do
			if table.concat({ eles[i].raw:GetTreePath() }) == raw then
				table.remove(eles, i)
			end
		end
	end
	return self:clone(eles)
end

-- filter elements from object
-- same as jQuery.filter()
function _MY.UI:filter(raw)
	self:_checksum()
	local eles = {}
	for i = 1, #self.eles, 1 do
		table.insert(eles, self.eles[i])
	end
	if type(raw) == "string" then
		-- delete ele those id/class not fits filter:raw
		if string.sub(raw, 1, 1) == "#" then
			raw = string.sub(raw, 2)
			if string.sub(raw, 1, 1) == "^" then
				-- regexp
				for i = #eles, 1, -1 do
					if not string.find(eles[i].raw:GetName(), raw) then
						table.remove(eles, i)
					end
				end
			else
				-- normal
				for i = #eles, 1, -1 do
					if eles[i].raw:GetName() ~= raw then
						table.remove(eles, i)
					end
				end
			end
		elseif string.sub(raw, 1, 1) == "." then
			raw = string.sub(raw, 2)
			if string.sub(raw, 1, 1) == "^" then
				-- regexp
				for i = #eles, 1, -1 do
					if not string.find((eles[i].raw.szMyuiType or eles[i].raw:GetType()), raw) then
						table.remove(eles, i)
					end
				end
			else
				-- normal
				for i = #eles, 1, -1 do
					if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) ~= raw then
						table.remove(eles, i)
					end
				end
			end
		end
	elseif type(raw)=="nil" then
		return self
	else
		-- delete ele those treepath is not the same as raw
		raw = table.concat({ raw:GetTreePath() })
		for i = #eles, 1, -1 do
			if table.concat({ eles[i].raw:GetTreePath() }) ~= raw then
				table.remove(eles, i)
			end
		end
	end
	return self:clone(eles)
end

-- get parent
-- same as jQuery.parent()
function _MY.UI:parent()
	self:_checksum()
	local parent = {}
	for _, ele in pairs(self.eles) do
		parent[table.concat{ele.raw:GetParent():GetTreePath()}] = ele.raw:GetParent()
	end
	local eles = {}
	for _, raw in pairs(parent) do
		-- insert into eles
		table.insert( eles, self:raw2ele(raw) )
	end
	return self:clone(eles)
end

-- get children
-- same as jQuery.children()
function _MY.UI:children(filter)
	self:_checksum()
	local child = {}
	local childHash = {}
	if type(filter)=="string" and string.sub(filter, 1, 1)=="#" and string.sub(filter, 2, 2)~="^" then
		filter = string.sub(filter, 2)
		for _, ele in pairs(self.eles) do
			local c = (ele.wnd or ele.raw):Lookup(filter)
			if c then
				table.insert(child, c)
				childHash[table.concat({ table.concat({ c:GetTreePath() }), filter })] = true
			end
		end
		local eles = {}
		for _, raw in ipairs(child) do
			-- insert into eles
			table.insert( eles, self:raw2ele(raw) )
		end
		return self:clone(eles)
	else
		for _, ele in pairs(self.eles) do
			local raw = (ele.wnd or ele.raw)
			if raw:GetType() == "Handle" then
				for i = 0, raw:GetItemCount() - 1, 1 do
					if not childHash[table.concat({ raw:Lookup(i):GetTreePath(), i })] then
						table.insert(child, raw:Lookup(i))
						childHash[table.concat({ table.concat({ raw:Lookup(i):GetTreePath() }), i })] = true
					end
				end
			else
				-- ��handle
				local status, handle = pcall(function() return raw:Lookup('','') end) -- raw����û��Lookup���� ��pcall����
				if status and handle and not childHash[table.concat{handle:GetTreePath(),'/Handle'}] then
					table.insert(child, handle)
					childHash[table.concat({handle:GetTreePath(),'/Handle'})] = true
				end
				-- �Ӵ���
				local status, sub_raw = pcall(function() return raw:GetFirstChild() end) -- raw����û��GetFirstChild���� ��pcall����
				while status and sub_raw do
					if not childHash[table.concat{sub_raw:GetTreePath()}] then
						table.insert( child, sub_raw )
						childHash[table.concat({sub_raw:GetTreePath()})] = true
					end
					sub_raw = sub_raw:GetNext()
				end
			end
		end
		local eles = {}
		for _, raw in ipairs(child) do
			-- insert into eles
			table.insert( eles, self:raw2ele(raw) )
		end
		return self:clone(eles):filter(filter)
	end
end

-- get child-item
function _MY.UI:item(filter)
	return self:hdl():children(filter)
end

-- find ele
-- same as jQuery.find()
function _MY.UI:find(filter)
	self:_checksum()
	local children = {}
	for _, ele in pairs(self.eles) do
		if ele.raw then for szTreePath, raw in pairs(GetChildren(ele.raw)) do
			children[szTreePath] = raw
		end end
	end
	local eles = {}
	for _, raw in pairs(children) do
		-- insert into eles
		table.insert( eles, self:raw2ele(raw) )
	end
	return self:clone(eles):filter(filter)
end

-- each
-- same as jQuery.each(function(){})
-- :each(_MY.UI each_self)  -- you can use 'this' to visit raw element likes jQuery
function _MY.UI:each(fn)
	self:_checksum()
	local eles = {}
	-- get a copy of ele list
	for _, ele in pairs(self.eles) do
		table.insert(eles, ele)
	end
	-- for each in the list call function
	for _, ele in pairs(eles) do
		local _this = this
		this = ele.raw
		pcall(fn, self:clone({{raw = ele.raw}}))
		this = _this
	end
	return self
end

-- eq
-- same as jQuery.eq(pos)
function _MY.UI:eq(pos)
	if pos then
		return self:slice(pos,pos)
	end
	return self
end

-- first
-- same as jQuery.first()
function _MY.UI:first()
	return self:slice(1,1)
end

-- last
-- same as jQuery.last()
function _MY.UI:last()
	return self:slice(-1,-1)
end

-- slice -- index starts from 1
-- same as jQuery.slice(selector, pos)
function _MY.UI:slice(startpos, endpos)
	self:_checksum()
	local eles = {}
	for i = 1, #self.eles, 1 do
		table.insert(eles, self.eles[i])
	end
	endpos = endpos or #eles
	if endpos < 0 then endpos = #eles + endpos + 1 end
	for i = #eles, endpos + 1, -1 do
		table.remove(eles)
	end
	if startpos < 0 then startpos = #eles + startpos + 1 end
	for i = startpos, 2, -1 do
		table.remove(eles, 1)
	end
	return self:clone(eles)
end

-- get raw
-- same as jQuery[index]
function _MY.UI:raw(index, key)
	self:_checksum()
	key = key or 'raw'
	local eles = self.eles
	if index < 0 then index = #eles + index + 1 end
	if index > 0 and index <= #eles then return eles[index][key] end
end

-- get ele
function _MY.UI:ele(index)
	self:_checksum()
	local eles, ele = self.eles, {}
	if index < 0 then index = #eles + index + 1 end
	if index > 0 and index <= #eles then 
		for k, v in pairs(eles[index]) do
			ele[k] = v
		end
	end
	return ele
end

-- get frm
function _MY.UI:frm(index)
	self:_checksum()
	local eles = {}
	if index < 0 then index = #self.eles + index + 1 end
	if index > 0 and index <= #self.eles and self.eles[index].frm then
		table.insert(eles, { raw = self.eles[index].frm })
	end
	return self:clone(eles)
end

-- get wnd
function _MY.UI:wnd(index)
	self:_checksum()
	local eles = {}
	if index < 0 then index = #self.eles + index + 1 end
	if index > 0 and index <= #self.eles and self.eles[index].wnd then
		table.insert(eles, { raw = self.eles[index].wnd })
	end
	return self:clone(eles)
end

-- get item
function _MY.UI:itm(index)
	self:_checksum()
	local eles = {}
	if index < 0 then index = #eles + index + 1 end
	if index > 0 and index <= #self.eles and self.eles[index].itm then
		table.insert(eles, { raw = self.eles[index].itm })
	end
	return self:clone(eles)
end

-- get handle
function _MY.UI:hdl(index)
	self:_checksum()
	local eles = {}
	if index then
		if index < 0 then index = #eles + index + 1 end
		if index > 0 and index <= #self.eles and self.eles[index].hdl then
			table.insert(eles, { raw = self.eles[index].hdl })
		end
	else
		for _, ele in ipairs(self.eles) do
			table.insert(eles, { raw = ele.hdl })
		end
	end
	return self:clone(eles)
end

-- get count
function _MY.UI:count()
	self:_checksum()
	return #self.eles
end

-----------------------------------------------------------
-- my ui opreation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
function _MY.UI:remove()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		pcall(function() ele.fnDestroy(ele.raw) end)
		if ele.raw:GetType() == "WndFrame" then
			Wnd.CloseWindow(ele.raw)
		elseif string.sub(ele.raw:GetType(), 1, 3) == "Wnd" then
			ele.raw:Destroy()
		else
			pcall(function()
				local h = ele.raw:GetParent()
				h:RemoveItem(ele.raw:GetIndex())
				h:FormatAllItemPos()
			end)
		end
	end
	self.eles = {}
	return self
end

-- xml string
_MY.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=371 </text>",
	["Image"] = "<image>w=100 h=100 eventid=371 </image>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </box>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>firstpostype=0 w=10 h=10</handle>",
}
-- append
-- similar as jQuery.append()
-- Instance:append(szName, szType, tArg)
-- Instance:append(szType, tArg)
-- Instance:append(szItemString)
function _MY.UI:append(arg0, arg1, arg2)
	self:_checksum()
	local szName, szType, tArg, szXml
	if type(arg0) == 'string' then
		if type(arg1) == 'string' then
			szType, szName, tArg = arg0, arg1, arg2
		elseif type(arg1) == 'table' then
			szType, tArg = arg0, arg1
		elseif #arg0 > 0 then
			szXml = arg0
		end
	end
	if szType then
		for _, ele in pairs(self.eles) do
			local ui
			if ( (ele.wnd or ele.frm) and ( string.sub(szType, 1, 3) == "Wnd" or string.sub(szType, -4) == ".ini" ) ) then
				-- append from ini file
				local szFile = szType
				if string.sub(szType, -4) == ".ini" then
					szType = string.gsub(szType,".*[/\\]","")
					szType = string.sub(szType,0,-5)
				else
					szFile = MY.GetAddonInfo().szFrameworkRoot .. "ui\\" .. szFile .. ".ini"
				end
				local frame = Wnd.OpenWindow(szFile, "MY_TempWnd")
				if not frame then
					return MY.Debug({_L("unable to open ini file [%s]", szFile)}, 'MY#UI#append', 2)
				end
				local wnd = frame:Lookup(szType)
				if not wnd then
					MY.Debug({_L("can not find wnd component [%s]", szType)}, 'MY#UI#append', 2)
				else
					wnd.szMyuiType = szType
					if szName then
						wnd:SetName(szName)
					end
					wnd:ChangeRelation((ele.wnd or ele.frm), true, true)
					if szType == "WndScrollBox" then
						wnd:Lookup('WndButton_Up').OnLButtonHold = function()
							wnd:Lookup("WndNewScrollBar_Default"):ScrollPrev(1)
						end
						wnd:Lookup('WndButton_Down').OnLButtonHold = function()
							wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(1)
						end
						wnd:Lookup('WndButton_Up').OnLButtonDown = function()
							wnd:Lookup("WndNewScrollBar_Default"):ScrollPrev(1)
						end
						wnd:Lookup('WndButton_Down').OnLButtonDown = function()
							wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(1)
						end
						wnd.OnMouseWheel = function()                                   -- listening Mouse Wheel
							local nDistance = Station.GetMessageWheelDelta()            -- get distance
							wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(nDistance) -- wheel scroll position
							return 1
						end
						wnd:Lookup("WndNewScrollBar_Default").OnScrollBarPosChanged = function()
							local nCurrentValue = this:GetScrollPos()
							wnd:Lookup("WndButton_Up"):Enable( nCurrentValue ~= 0 )
							wnd:Lookup("WndButton_Down"):Enable( nCurrentValue ~= this:GetStepCount() )
							wnd:Lookup("", "Handle_Scroll"):SetItemStartRelPos(0, - nCurrentValue * 10)
						end
						wnd.UpdateScroll = function()
							local hHandle     = wnd:Lookup("", "Handle_Scroll")
							local hScrollBar  = wnd:Lookup("WndNewScrollBar_Default")
							local hButtonUp   = wnd:Lookup("WndButton_Up")
							local hButtonDown = wnd:Lookup("WndButton_Down")
							local bBottom     = hScrollBar:GetStepCount() == hScrollBar:GetScrollPos()
							hHandle:FormatAllItemPos()
							local wA, hA = hHandle:GetAllItemSize()
							local w, h = hHandle:GetSize()
							local nStep = (hA - h) / 10
							if nStep > 0 then
								hScrollBar:Show()
								hButtonUp:Show()
								hButtonDown:Show()
							else
								hScrollBar:Hide()
								hButtonUp:Hide()
								hButtonDown:Hide()
							end
							local wb, hb = hScrollBar:GetSize()
							local _max = ( 100 > (hb * 1 / 2) and (hb * 1 / 2) ) or 100
							local _min = ( 50 > hb and (hb * 1 / 3) ) or 50
							local hs = hb - nStep
							local hs = ( hs > _max and _max ) or hs
							local hs = ( hs < _min and _min ) or hs
							hScrollBar:Lookup("WndButton_Scroll"):SetSize( 15, hs )
							hScrollBar:SetStepCount(nStep)
							if bBottom then hScrollBar:SetScrollPos(hScrollBar:GetStepCount()) end
						end
						pcall( wnd.UpdateScroll )
					elseif szType=='WndSliderBox' then
						wnd.bShowPercentage = true
						wnd.nOffset = 0
						wnd.tMyOnChange = {}
						wnd:Lookup("WndNewScrollBar_Default").FormatText = function(value, bPercentage)
							if bPercentage then
								return string.format("%.2f%%", value)
							else
								return value
							end
						end
						wnd:Lookup("WndNewScrollBar_Default").OnScrollBarPosChanged = function()
							local fnFormat = wnd:Lookup("WndNewScrollBar_Default").FormatText
							if wnd.bShowPercentage then
								local nCurrentPercentage = this:GetScrollPos() * 100 / this:GetStepCount()
								wnd:Lookup("", "Text_Default"):SetText(fnFormat(nCurrentPercentage, true))
								for _, fn in ipairs(wnd.tMyOnChange) do
									pcall(fn, nCurrentPercentage)
								end
							else
								local nCurrentValue = this:GetScrollPos() + wnd.nOffset
								wnd:Lookup("", "Text_Default"):SetText(fnFormat(nCurrentValue, false))
								for _, fn in ipairs(wnd.tMyOnChange) do
									pcall(fn, nCurrentValue)
								end
							end
						end
						wnd:Lookup("WndNewScrollBar_Default").OnMouseWheel = function()                                   -- listening Mouse Wheel
							local nDistance = Station.GetMessageWheelDelta()            -- get distance
							wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(-nDistance*2)            -- wheel scroll position
							return 1
						end
						wnd:Lookup("WndNewScrollBar_Default"):Lookup('Btn_Track').OnMouseWheel = function()               -- listening Mouse Wheel
							local nDistance = Station.GetMessageWheelDelta()            -- get distance
							wnd:Lookup("WndNewScrollBar_Default"):ScrollNext(-nDistance)            -- wheel scroll position
							return 1
						end
					elseif szType=='WndEditBox' then
						wnd:Lookup("WndEdit_Default").OnSetFocus = function()
							wnd:Lookup("", "Text_PlaceHolder"):Hide()
						end
						wnd:Lookup("WndEdit_Default").OnKillFocus = function()
							if wnd:Lookup("WndEdit_Default"):GetText() == "" then
								wnd:Lookup("", "Text_PlaceHolder"):Show()
							end
						end
					elseif szType=='WndAutoComplete' then
						local edt = wnd:Lookup("WndEdit_Default")
						edt.OnSetFocus = function()
							wnd:Lookup("", "Text_PlaceHolder"):Hide()
							-- check disabled
							if wnd.tMyAcOption.disabled or wnd.tMyAcOption.disabledTmp then
								return
							end
							MY.UI(wnd):autocomplete('search')
						end
						edt.OnEditChanged = function()
							-- disabled
							if wnd.tMyAcOption.disabled or wnd.tMyAcOption.disabledTmp or Station.GetFocusWindow() ~= this then
								return
							end
							-- placeholder
							local len = this:GetText():len()
							if len == 0 then
								wnd:Lookup("", "Text_PlaceHolder"):Show()
							else
								wnd:Lookup("", "Text_PlaceHolder"):Hide()
							end
							-- min search length
							if len >= wnd.tMyAcOption.minLength then
								-- delay search
								MY.DelayCall(wnd.tMyAcOption.delay, function()
									MY.UI(wnd):autocomplete('search')
									-- for compatible
									Station.SetFocusWindow(edt)
								end)
							else
								MY.UI(wnd):autocomplete('close')
							end
						end
						edt.OnKillFocus = function()
							if edt:GetText() == "" then
								wnd:Lookup("", "Text_PlaceHolder"):Show()
							end
							
							if Station.GetFocusWindow() and Station.GetFocusWindow():GetName() ~= 'PopupMenuPanel' then
								Wnd.CloseWindow("PopupMenuPanel")
							end
						end
						wnd.tMyAcOption = {
							beforeSearch = nil  , -- @param: wnd, option
							beforePopup  = nil  , -- @param: menu, wnd, option
							beforeDelete = nil  , -- @param: szOption, fnDoDelete, option
							afterDelete  = nil  , -- @param: szOption, option
							
							ignoreCase   = true ,  -- ignore case while matching
							anyMatch     = true ,  -- match any part of option list
							autoFill     = false,  -- auto fill edit with first match (conflict withanyMatch)
							delay        = 0    ,  -- delay time when edit changed
							disabled     = false,  -- disable autocomplete
							minLength    = 0    ,  -- the min length of the searching string
							maxOption    = 0    ,  -- the max number of displayed options (0 means no limitation)
							source       = {}   ,  -- option list
						}
					elseif szType == 'WndRadioBox' then
						MY.UI.RegisterUIEvent(wnd, 'OnLButtonUp', function()
							local p = wnd:GetParent():GetFirstChild()
							while p do
								if p ~= wnd and
								p.group == wnd.group and
								p:GetType() == 'WndCheckBox' and
								p:IsCheckBoxChecked() then
									p:Check(false)
								end
								p = p:GetNext()
							end
						end)
					elseif szType == 'WndListBox' then
						local hScroll = wnd:Lookup('', 'Handle_Scroll')
						hScroll.OnListItemHandleMouseEnter = function()
							MY.UI(this:Lookup('Image_Bg')):fadeIn(100)
						end
						hScroll.OnListItemHandleMouseLeave = function()
							MY.UI(this:Lookup('Image_Bg')):fadeTo(500,0)
						end
						hScroll.OnListItemHandleLButtonClick = function()
							if this:GetParent().OnListItemHandleCustomLButtonClick then
								local status, err = pcall(
									this:GetParent().OnListItemHandleCustomLButtonClick,
									this.text, this.id, this.data, not this.selected
								)
								if not status then
									MY.Debug({err}, 'WndListBox#CustomLButtonClick', 2)
								elseif err == false then
									return
								end
							end
							if not this.selected then
								if not hScroll.tMyLbOption.multiSelect then
									for i = hScroll:GetItemCount() - 1, 0, -1 do
										local hItem = hScroll:Lookup(i)
										if hItem.selected then
											hItem.selected = false
											hItem:Lookup('Image_Sel'):Hide()
										end
									end
								end
								this:Lookup('Image_Sel'):Show()
							else
								this:Lookup('Image_Sel'):Hide()
							end
							this.selected = not this.selected
						end
						hScroll.OnListItemHandleRButtonClick = function()
							if not this.selected then
								if not hScroll.tMyLbOption.multiSelect then
									for i = hScroll:GetItemCount() - 1, 0, -1 do
										local hItem = hScroll:Lookup(i)
										if hItem.selected then
											hItem.selected = false
											hItem:Lookup('Image_Sel'):Hide()
										end
									end
								end
								this.selected = true
								this:Lookup('Image_Sel'):Show()
							end
							if hScroll.GetListItemHandleMenu then
								PopupMenu(hScroll.GetListItemHandleMenu(this.text, this.id, this.data, this.selected))
							end
						end
						hScroll.tMyLbOption = {
							multiSelect = false,
						}
					end
					ui = MY.UI(wnd)
				end
				Wnd.CloseWindow(frame)
			elseif ( string.sub(szType, 1, 3) ~= "Wnd" and ele.hdl ) then
				local szXml = _MY.tItemXML[szType]
				local hnd
				if szXml then
					-- append from xml
					local nCount = ele.hdl:GetItemCount()
					ele.hdl:AppendItemFromString(szXml)
					hnd = ele.hdl:Lookup(nCount)
					if hnd and szName then
						hnd:SetName(szName)
					end
				else
					-- append from ini
					hnd = ele.hdl:AppendItemFromIni("interface\\MY\\.Framework\\ui\\HandleItems.ini","Handle_" .. szType, szName)
				end
				ele.hdl:FormatAllItemPos()
				if not hnd then
					return MY.Debug({_L("unable to append handle item [%s]", szType)},'MY#UI:append',2)
				else
					ui = MY.UI(hnd)
				end
			end
			if tArg and ui then
				if tArg.w       then ui:width (tArg.w      ) end
				if tArg.h       then ui:height(tArg.h      ) end
				if tArg.x       then ui:left  (tArg.x      ) end
				if tArg.y       then ui:top   (tArg.y      ) end
				if tArg.alpha   then ui:alpha (tArg.alpha  ) end
				if tArg.color   then ui:color (tArg.color  ) end
				if tArg.text    then ui:text  (tArg.text   ) end
				if tArg.font    then ui:font  (tArg.font   ) end
				if tArg.tip     then ui:tip   (tArg.tip    ) end
				if tArg.menu    then ui:menu  (tArg.menu   ) end
				if tArg.image   then if type(tArg.image) == 'table' then ui:image (unpack(tArg.image)) else ui:image(tArg.image) end end
				if tArg.onhover then ui:hover (tArg.onhover) end
				if tArg.onclick then ui:click (tArg.onclick) end
				if tArg.checked then ui:check (tArg.checked) end
				if tArg.oncheck then ui:check (tArg.oncheck) end
			end
		end
	elseif szXml then
		for _, ele in pairs(self.eles) do
			if ele.hdl then
				-- append from xml
				local nCount = ele.hdl:GetItemCount()
				pcall(function() ele.hdl:AppendItemFromString(szXml) end)
				local hnd 
				for i = nCount, ele.hdl:GetItemCount()-1, 1 do
					hnd = ele.hdl:Lookup(i)
					if hnd and hnd:GetName()=='' then hnd:SetName('Unnamed_Item'..i) end
				end
				ele.hdl:FormatAllItemPos()
				pcall( ele.raw.UpdateScroll )
				if nCount == ele.hdl:GetItemCount() then
					return MY.Debug({_L("unable to append handle item from string.")},'MY#UI:append',2)
				end
			end
		end
	end
	return self
end

-- clear
-- clear handle
-- (self) Instance:clear()
function _MY.UI:clear()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		if ele.hdl then
			pcall(function() ele.hdl:Clear() end)
		end
		if ele.sbu then
			ele.raw.UpdateScroll()
		end
	end
	return self
end

-----------------------------------------------------------
-- my ui property visitors
-----------------------------------------------------------

-- data set/get
function _MY.UI:data(key, value)
	self:_checksum()
	if key and value then -- set name
		for _, ele in pairs(self.eles) do
			pcall(function() ele.raw[key] = value end)
		end
		return self
	elseif key then -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw[key] end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:data' ,1) return nil end
	else
		return self
	end
end

-- show
function _MY.UI:show()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		pcall(function() ele.raw:Show() end)
		pcall(function() ele.hdl:Show() end)
	end
	return self
end

-- hide
function _MY.UI:hide()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		pcall(function() ele.raw:Hide() end)
		pcall(function() ele.hdl:Hide() end)
	end
	return self
end

-- visible
function _MY.UI:visible(bVisiable)
	self:_checksum()
	if type(bVisiable)=='boolean' then
		return self:toggle(bVisiable)
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw:IsVisible() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:visible' ,1) return nil end
	end
end

-- enable or disable elements
function _MY.UI:enable(bEnable)
	self:_checksum()
	if type(bEnable)=='boolean' then
		for _, ele in pairs(self.eles) do
			pcall(function() (ele.chk or ele.wnd or ele.raw):Enable(bEnable) end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw:IsEnabled() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:enable' ,1) return nil end
	end
end

-- show/hide eles
function _MY.UI:toggle(bShow)
	self:_checksum()
	for _, ele in pairs(self.eles) do
		pcall(function() if bShow == false or (not bShow and ele.raw:IsVisible()) then ele.raw:Hide() ele.hdl:Hide() else ele.raw:Show() ele.hdl:Show() end end)
	end
	return self
end

-- drag area
-- (self) drag(boolean bEnableDrag) -- enable/disable drag
-- (self) drag(number x, number y, number w, number h) -- set drag positon and area
-- (self) drag(function fnOnDrag, function fnOnDragEnd)-- bind frame/item frag event handle
function _MY.UI:drag(x, y, w, h)
	self:_checksum()
	if type(x) == 'boolean' then
		for _, ele in pairs(self.eles) do
			pcall(function() (ele.frm or ele.raw):EnableDrag(x) end)
		end
		return self
	elseif type(x) == 'number' or
	type(y) == 'number' or
	type(w) == 'number' or
	type(h) == 'number' then
		for i = 1, #self.eles, 1 do
			local s, err =pcall(function()
				local _w, _h = self:eq(i):size()
				x, y, w, h = x or 0, y or 0, w or _w, h or _h
				self:frm(i):raw(1):SetDragArea(x, y, w, h)
			end)
		end
		return self
	elseif type(x) == 'function' or
	type(y) == 'function' or
	type(w) == 'function' then
		for _, ele in pairs(self.eles) do
			if ele.frm then
				if x then
					MY.UI.RegisterUIEvent(ele.frm, 'OnFrameDragSetPosEnd', x)
				end
				if y then
					MY.UI.RegisterUIEvent(ele.frm, 'OnFrameDragEnd', y)
				end
			elseif ele.itm then
				if x then
					MY.UI.RegisterUIEvent(ele.itm, 'OnItemLButtonDrag', x)
				end
				if y then
					MY.UI.RegisterUIEvent(ele.itm, 'OnItemLButtonDragEnd', y)
				end
			end
		end
		return self
	else
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return (ele.frm or ele.raw):IsDragable() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:drag' ,1) return nil end
	end
end

-- get/set ui object text
function _MY.UI:text(szText)
	self:_checksum()
	if szText then
		for _, ele in pairs(self.eles) do
			if type(szText)~="function" then
				pcall(function() (ele.txt or ele.edt or ele.raw):SetText(szText) end)
				pcall(function() (ele.txt or ele.edt or ele.raw):GetParent():FormatAllItemPos() end)
			end
			if ele.type == "WndScrollBox" then
				ele.raw.UpdateScroll()
			elseif ele.type == "WndSliderBox" and type(szText)=="function" then
				ele.sld.FormatText = szText
			elseif ele.type == "WndEditBox" then
				if szText=="" then
					ele.phd:Show()
				else
					ele.phd:Hide()
				end
			elseif ele.type == "Text" then
				if ele.raw.bAutoSize then
					ele.raw:AutoSize()
				end
			end
		end
		return self
	else
		-- select the first item
		local ele = self.eles[1]
		if ele then
			-- try to get its name
			local x = ele.txt or ele.edt or ele.raw
			-- if succeed then return its name
			if x and x.GetText then
				return x:GetText()
			end
		end
	end
end

-- get/set ui object text
function _MY.UI:placeholder(szText)
	self:_checksum()
	if szText then
		for _, ele in pairs(self.eles) do
			if ele.phd then ele.phd:SetText(szText) end
		end
		return self
	else
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.phd:GetText() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:text' ,3) return nil end
	end
end

-- ui autocomplete interface
function _MY.UI:autocomplete(method, arg1, arg2)
	self:_checksum()
	if method == 'option' and (type(arg1) == 'nil' or (type(arg1) == 'string' and type(arg2) == nil)) then -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its option
		if ele then
			return clone(ele.raw.tMyAcOption)
		end
	else -- set
		if method == 'option' then
			if type(arg1) == 'string' then
				arg1 = {
					[arg1] = arg2
				}
			end
			if type(arg1) == 'table' then
				for _, ele in pairs(self.eles) do
					ele.raw.tMyAcOption = ele.raw.tMyAcOption or {}
					for k, v in pairs(arg1) do
						ele.raw.tMyAcOption[k] = v
					end
				end
			end
		elseif method == 'close' then
			Wnd.CloseWindow('PopupMenuPanel')
		elseif method == 'destroy' then
			for _, ele in pairs(self.eles) do
				ele.raw:Lookup("WndEdit_Default").OnSetFocus = nil
				ele.raw:Lookup("WndEdit_Default").OnKillFocus = nil
				ele.raw:Lookup("", "Text_PlaceHolder"):Hide()
			end
		elseif method == 'disable' then
			self:autocomplete('option', 'disable', true)
		elseif method == 'enable' then
			self:autocomplete('option', 'disable', false)
		elseif method == 'search' then
			for _, ele in pairs(self.eles) do
				if ele.raw.tMyAcOption then
					local option = ele.raw.tMyAcOption
					if type(option.beforeSearch) == 'function' then
						option.beforeSearch(ele.raw, option)
					end
					local keyword = arg1 or ele.raw:Lookup("WndEdit_Default"):GetText()
					keyword = MY.String.PatternEscape(keyword)
					if not option.anyMatch then
						keyword = '^' .. keyword
					end
					if option.ignoreCase then
						keyword = StringLowerW(keyword)
					end
					local tOption = {}
					-- get matched list
					for _, src in ipairs(option.source) do
						local s = src
						if option.ignoreCase then
							s = StringLowerW(src)
						end
						if string.find(s, keyword) then
							table.insert(tOption, src)
						end
					end
					
					-- create menu
					local menu = {}
					for _, szOption in ipairs(tOption) do
						-- max option limit
						if option.maxOption > 0 and #menu >= option.maxOption then
							break
						end
						-- create new option
						local t = {
							szOption = szOption,
							fnAction = function()
								option.disabledTmp = true
								MY.UI(ele.raw):text(szOption)
								option.disabledTmp = nil
								Wnd.CloseWindow('PopupMenuPanel')
							end,
						}
						if option.beforeDelete or option.afterDelete then
							t.szIcon = "ui/Image/UICommon/CommonPanel2.UITex"
							t.nFrame = 49
							t.nMouseOverFrame = 51
							t.nIconWidth = 17
							t.nIconHeight = 17
							t.szLayer = "ICON_RIGHTMOST"
							t.fnClickIcon = function()
								local bSure = true
								local fnDoDelete = function()
									for i=#option.source, 1, -1 do
										if option.source[i] == szOption then
											table.remove(option.source, i)
										end
									end
									MY.UI(ele.raw):autocomplete('search')
								end
								if option.beforeDelete then
									bSure = option.beforeDelete(szOption, fnDoDelete, option)
								end
								if bSure ~= false then
									fnDoDelete()
								end
								if option.afterDelete then
									option.afterDelete(szOption, option)
								end
							end
						end
						table.insert(menu, t)
					end
					local nX, nY = ele.raw:GetAbsPos()
					local nW, nH = ele.raw:GetSize()
					menu.nMiniWidth = nW
					menu.x, menu.y = nX, nY + nH
					menu.bDisableSound = true
					menu.bShowKillFocus = true
					
					if type(option.beforePopup) == 'function' then
						option.beforePopup(menu, ele.raw, option)
					end
					-- popup menu
					if #menu > 0 then
						option.disabledTmp = true
						PopupMenu(menu)
						Station.SetFocusWindow(ele.raw:Lookup("WndEdit_Default"))
						option.disabledTmp = nil
					else
						Wnd.CloseWindow('PopupMenuPanel')
					end
				end
			end
		elseif method == 'insert' then
			if type(arg1) == 'string' then
				arg1 = { arg1 }
			end
			if type(arg1) == 'table' then
				for _, src in ipairs(arg1) do
					if type(src) == 'string' then
						for _, ele in pairs(self.eles) do
							for i=#ele.raw.tMyAcOption.source, 1, -1 do
								 if ele.raw.tMyAcOption.source[i] == src then
									table.remove(ele.raw.tMyAcOption.source, i)
								 end
							 end
							table.insert(ele.raw.tMyAcOption.source, src)
						end
					end
				end
			end
		elseif method == 'delete' then
			if type(arg1) == 'string' then
				arg1 = { arg1 }
			end
			if type(arg1) == 'table' then
				for _, src in ipairs(arg1) do
					if type(src) == 'string' then
						for _, ele in pairs(self.eles) do
							for i=#ele.raw.tMyAcOption.source, 1, -1 do
								 if ele.raw.tMyAcOption.source[i] == arg1 then
									table.remove(ele.raw.tMyAcOption.source, i)
								 end
							 end
						end
					end
				end
			end
		end
		return self
	end
end

-- ui listbox interface
function _MY.UI:listbox(method, arg1, arg2, arg3)
	self:_checksum()
	if method == 'option' and (type(arg1) == 'nil' or (type(arg1) == 'string' and type(arg2) == nil)) then -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its option
		if ele then
			return clone(ele.raw.tMyLbOption)
		end
	else -- set
		if method == 'option' then
			if type(arg1) == 'string' then
				arg1 = {
					[arg1] = arg2
				}
			end
			if type(arg1) == 'table' then
				for _, ele in pairs(self.eles) do
					ele.raw.tMyLbOption = ele.raw.tMyLbOption or {}
					for k, v in pairs(arg1) do
						ele.raw.tMyLbOption[k] = v
					end
				end
			end
		elseif method == 'select' then
			local tData = {}
			if arg1 == 'all' then
				for _, ele in pairs(self.eles) do
					if ele.type == 'WndListBox' then
						local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
						for i = 0, hScroll:GetItemCount() - 1, 1 do
							local hItem = hScroll:Lookup(i)
							table.insert(tData, { text = hItem.text, id = hItem.id, data = hItem.data, selected = hItem.selected })
						end
					end
				end
			elseif arg1 == 'unselected' then
				for _, ele in pairs(self.eles) do
					if ele.type == 'WndListBox' then
						local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
						for i = 0, hScroll:GetItemCount() - 1, 1 do
							local hItem = hScroll:Lookup(i)
							if not hItem.selected then
								table.insert(tData, { text = hItem.text, id = hItem.id, data = hItem.data, selected = hItem.selected })
							end
						end
					end
				end
			else--if arg1 == 'selected' then
				for _, ele in pairs(self.eles) do
					if ele.type == 'WndListBox' then
						local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
						for i = 0, hScroll:GetItemCount() - 1, 1 do
							local hItem = hScroll:Lookup(i)
							if hItem.selected then
								table.insert(tData, { text = hItem.text, id = hItem.id, data = hItem.data, selected = hItem.selected })
							end
						end
					end
				end
			end
			return tData
		elseif method == 'insert' then
			local text, id, data = arg1, arg2, arg3
			for _, ele in pairs(self.eles) do
				if ele.type == 'WndListBox' then
					local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
					local bExist
					if id then
						for i = hScroll:GetItemCount() - 1, 0, -1 do
							if hScroll:Lookup(i).id == id then
								bExist = true
							end
						end
					end
					if not bExist then
						local w, h = hScroll:GetSize()
						hScroll:AppendItemFromString('<handle>eventid=371 <image>w='..w..' h=25 path="UI/Image/Common/TextShadow.UITex" frame=5 alpha=0 name="Image_Bg" </image><image>w='..w..' h=25 path="UI/Image/Common/TextShadow.UITex" lockshowhide=1 frame=2 name="Image_Sel" </image><text>w='..w..' h=25 valign=1 name="Text_Default" </text></handle>')
						local hItem = hScroll:Lookup(hScroll:GetItemCount() - 1)
						hItem.id = id
						hItem.text = text
						hItem.data = data
						hItem:Lookup('Text_Default'):SetText(text)
						hItem.OnItemMouseEnter = hScroll.OnListItemHandleMouseEnter
						hItem.OnItemMouseLeave = hScroll.OnListItemHandleMouseLeave
						hItem.OnItemLButtonClick = hScroll.OnListItemHandleLButtonClick
						hItem.OnItemRButtonClick = hScroll.OnListItemHandleRButtonClick
						hScroll:FormatAllItemPos()
					end
				end
			end
		elseif method == 'update' then
			local text, id, data = arg1, arg2, arg3
			for _, ele in pairs(self.eles) do
				if ele.type == 'WndListBox' then
					local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
					for i = hScroll:GetItemCount() - 1, 0, -1 do
						if id and hScroll:Lookup(i).id == id then
							hScroll:Lookup(i).data = data
							hScroll:Lookup(i):Lookup('Text_Default'):SetText(text)
						end
					end
				end
			end
		elseif method == 'delete' then
			local text, id = arg1, arg2
			for _, ele in pairs(self.eles) do
				if ele.type == 'WndListBox' then
					local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
					for i = hScroll:GetItemCount() - 1, 0, -1 do
						if (id and hScroll:Lookup(i).id == id) or
						(not id and text and hScroll:Lookup(i).text == text) then
							hScroll:RemoveItem(i)
						end
					end
					hScroll:FormatAllItemPos()
				end
			end
		elseif method == 'clear' then
			for _, ele in pairs(self.eles) do
				if ele.type == 'WndListBox' then
					ele.raw:Lookup('', 'Handle_Scroll'):Clear()
				end
			end
		elseif method == 'multiSelect' then
			self:listbox('option', 'multiSelect', arg1)
		elseif method == 'onmenu' then
			if type(arg1) == 'function' then
				for _, ele in pairs(self.eles) do
					if ele.type == 'WndListBox' then
						ele.raw:Lookup('', 'Handle_Scroll').GetListItemHandleMenu = arg1
					end
				end
			end
		elseif method == 'onlclick' then
			if type(arg1) == 'function' then
				for _, ele in pairs(self.eles) do
					if ele.type == 'WndListBox' then
						ele.raw:Lookup('', 'Handle_Scroll').OnListItemHandleCustomLButtonClick = arg1
					end
				end
			end
		end
		return self
	end
end

-- get/set ui object name
function _MY.UI:name(szText)
	self:_checksum()
	if szText then -- set name
		for _, ele in pairs(self.eles) do
			pcall(function() ele.raw:SetName(szText) end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw:GetName() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:name' ,3) return nil end
	end
end

-- get/set ui object group
function _MY.UI:group(szText)
	self:_checksum()
	if szText then -- set group
		for _, ele in pairs(self.eles) do
			pcall(function() ele.raw.group = szText end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its group
		local status, err = pcall(function() return ele.raw.group end)
		-- if succeed then return its group
		if status then return err else MY.Debug({err},'ERROR _MY.UI:group' ,3) return nil end
	end
end

-- set ui penetrable
function _MY.UI:penetrable(bPenetrable)
	self:_checksum()
	if type(bPenetrable) == 'boolean' then -- set penetrable
		for _, ele in pairs(self.eles) do
			pcall(function() ele.raw.bPenetrable = bPenetrable end)
			pcall(function() ele.raw:SetMousePenetrable(bPenetrable) end)
			pcall(function() ele.wnd:SetMousePenetrable(bPenetrable) end)
		end
	end
	return self
end

-- get/set ui alpha
function _MY.UI:alpha(nAlpha)
	self:_checksum()
	if nAlpha then -- set name
		for _, ele in pairs(self.eles) do
			pcall(function() ele.raw:SetAlpha(nAlpha) end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw:GetAlpha() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:alpha' ,3) return nil end
	end
end

-- (self) Instance:fadeTo(nTime, nOpacity, callback)
function _MY.UI:fadeTo(nTime, nOpacity, callback)
	self:_checksum()
	if nTime and nOpacity then
		for i = 1, #self.eles, 1 do
			local ele = self:eq(i)
			local nStartAlpha = ele:alpha()
			local nStartTime = GetTime()
			local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
				return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- ����ģ��
			end
			if not ele:visible() then ele:alpha(0):toggle(true) end
			MY.BreatheCall(function() 
				ele:show()
				local nCurrentAlpha = fnCurrent(nStartAlpha, nOpacity, nTime, GetTime()-nStartTime)
				ele:alpha(nCurrentAlpha)
				-- MY.Debug(string.format('%d %d %d %d\n', nStartAlpha, nOpacity, nCurrentAlpha, (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity)), 'fade', 0)
				if (nStartAlpha - nCurrentAlpha)*(nCurrentAlpha - nOpacity) <= 0 then
					ele:alpha(nOpacity)
					pcall(callback, ele)
					return 0
				end
			end, "MY_FADE_" .. MY.UI.GetTreePath(ele:raw(1)))
		end
	end
	return self
end

-- (self) Instance:fadeIn(nTime, callback)
function _MY.UI:fadeIn(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i = 1, #self.eles, 1 do
		self:eq(i):fadeTo(nTime, self:eq(i):data('nOpacity') or 255, callback)
	end
	return self
end

-- (self) Instance:fadeOut(nTime, callback)
function _MY.UI:fadeOut(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i = 1, #self.eles, 1 do
		local ele = self:eq(i)
		if ele:alpha() > 0 then ele:data('nOpacity', ele:alpha()) end
	end
	self:fadeTo(nTime, 0, function(ele)
		ele:toggle(false)
		pcall(callback, ele)
	end)
	return self
end

-- (self) Instance:slideTo(nTime, nHeight, callback)
function _MY.UI:slideTo(nTime, nHeight, callback)
	self:_checksum()
	if nTime and nHeight then
		for i = 1, #self.eles, 1 do
			local ele = self:eq(i)
			local nStartValue = ele:height()
			local nStartTime = GetTime()
			local fnCurrent = function(nStart, nEnd, nTotalTime, nDuringTime)
				return ( nEnd - nStart ) * nDuringTime / nTotalTime + nStart -- ����ģ��
			end
			if not ele:visible() then ele:height(0):toggle(true) end
			MY.BreatheCall(function() 
				ele:show()
				local nCurrentValue = fnCurrent(nStartValue, nHeight, nTime, GetTime()-nStartTime)
				ele:height(nCurrentValue)
				-- MY.Debug(string.format('%d %d %d %d\n', nStartValue, nHeight, nCurrentValue, (nStartValue - nCurrentValue)*(nCurrentValue - nHeight)), 'slide', 0)
				if (nStartValue - nCurrentValue)*(nCurrentValue - nHeight) <= 0 then
					ele:height(nHeight):toggle( nHeight ~= 0 )
					pcall(callback)
					return 0
				end
			end)
		end
	end
	return self
end

-- (self) Instance:slideUp(nTime, callback)
function _MY.UI:slideUp(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i = 1, #self.eles, 1 do
		local ele = self:eq(i)
		if ele:height() > 0 then ele:data('nSlideTo', ele:height()) end
	end
	self:slideTo(nTime, 0, callback)
	return self
end

-- (self) Instance:slideDown(nTime, callback)
function _MY.UI:slideDown(nTime, callback)
	self:_checksum()
	nTime = nTime or 300
	for i = 1, #self.eles, 1 do
		self:eq(i):slideTo(nTime, self:eq(i):data('nSlideTo'), callback)
	end
	return self
end

-- (number) Instance:font()
-- (self) Instance:font(number nFont)
function _MY.UI:font(nFont)
	self:_checksum()
	if nFont then-- set name
		for _, ele in pairs(self.eles) do
			pcall(function() (ele.txt or ele.edt or ele.raw):SetFontScheme(nFont) end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, err = pcall(function() return ele.raw:GetFontScheme() end)
		-- if succeed then return its name
		if status then return err else MY.Debug({err},'ERROR _MY.UI:font' ,3) return nil end
	end
end

-- (number, number, number) Instance:color()
-- (self) Instance:color(number nRed, number nGreen, number nBlue)
function _MY.UI:color(nRed, nGreen, nBlue)
	self:_checksum()
	if type(nRed) == "table" then
		nBlue = nRed[3]
		nGreen = nRed[2]
		nRed = nRed[1]
	end
	if nBlue then
		for _, ele in pairs(self.eles) do
			pcall(function() ele.sdw:SetColorRGB(nRed, nGreen, nBlue) end)
			pcall(function() (ele.edt or ele.txt):SetFontColor(nRed, nGreen, nBlue) end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, r,g,b = pcall(function() if ele.sdw then return ele.sdw:GetColorRGB() else return (ele.edt or ele.txt):GetFontColor() end end)
		-- if succeed then return its name
		if status then return r,g,b else MY.Debug(r..'\n','ERROR _MY.UI:color' ,3) return nil end
	end
end

-- (number) Instance:left()
-- (self) Instance:left(number)
function _MY.UI:left(nLeft)
	if nLeft then
		return self:pos(nLeft, nil)
	else
		local l, t = self:pos()
		return l
	end
end

-- (number) Instance:top()
-- (self) Instance:top(number)
function _MY.UI:top(nTop)
	if nTop then
		return self:pos(nil, nTop)
	else
		local l, t = self:pos()
		return t
	end
end

-- (number, number) Instance:pos()
-- (self) Instance:pos(nLeft, nTop)
function _MY.UI:pos(nLeft, nTop)
	self:_checksum()
	if nLeft or nTop then
		for _, ele in pairs(self.eles) do
			local _nLeft, _nTop = ele.raw:GetRelPos()
			nLeft, nTop = nLeft or _nLeft, nTop or _nTop
			if ele.frm then
				pcall(function() (ele.frm or ele.raw):SetRelPos(nLeft, nTop) end)
			elseif ele.wnd then
				pcall(function() (ele.wnd or ele.raw):SetRelPos(nLeft, nTop) end)
			elseif ele.itm then
				pcall(function() (ele.itm or ele.raw):SetRelPos(nLeft, nTop) end)
				pcall(function() (ele.itm or ele.raw):GetParent():FormatAllItemPos() end)
			end
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, l, t = pcall(function() return ele.raw:GetRelPos() end)
		-- if succeed then return its name
		if status then return l, t else MY.Debug({l},'ERROR _MY.UI:left|top|pos' ,1) return nil end
	end
end

-- (anchor) Instance:anchor()
-- (self) Instance:anchor(anchor)
function _MY.UI:anchor(anchor)
	self:_checksum()
	if type(anchor) == 'table' then
		for _, ele in pairs(self.eles) do
			if ele.frm then
				pcall(function() 
					ele.frm:SetPoint(anchor.s, 0, 0, anchor.r, anchor.x, anchor.y)
					ele.frm:CorrectPos()
				end)
			end
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, anchor = pcall(function()
			ele.frm:CorrectPos()
			return GetFrameAnchor(ele.frm, anchor)
		end)
		-- if succeed then return its name
		if status then return anchor else MY.Debug({anchor},'ERROR _MY.UI:anchor' ,1) return nil end
	end
end

-- (number) Instance:width()
-- (self) Instance:width(number)
function _MY.UI:width(nWidth)
	if nWidth then
		return self:size(nWidth, nil)
	else
		local w, h = self:size()
		return w
	end
end

-- (number) Instance:height()
-- (self) Instance:height(number)
function _MY.UI:height(nHeight)
	if nHeight then
		return self:size(nil, nHeight)
	else
		local w, h = self:size()
		return h
	end
end

-- (number, number) Instance:size()
-- (self) Instance:size(nLeft, nTop)
function _MY.UI:size(nWidth, nHeight)
	self:_checksum()
	if nWidth or nHeight then
		for _, ele in pairs(self.eles) do
			local _nWidth, _nHeight = ele.raw:GetSize()
			nWidth, nHeight = nWidth or _nWidth, nHeight or _nHeight
			if ele.type == 'WndFrame' then
				local frm = ele.frm
				local hnd = frm:Lookup("", "")
				if frm.simple then
					local nWidthTitleBtnR = 0
					local p = frm:Lookup('WndContainer_TitleBtnR'):GetFirstChild()
					while p do
						nWidthTitleBtnR = nWidthTitleBtnR + (p:GetSize())
						p = p:GetNext()
					end
					frm:Lookup('', 'Text_Title'):SetSize(nWidth - nWidthTitleBtnR, 30)
					frm:Lookup('', 'Image_Title'):SetSize(nWidth, 30)
					frm:Lookup('', 'Shadow_Bg'):SetSize(nWidth, nHeight)
					frm:Lookup('WndContainer_TitleBtnR'):SetSize(nWidth, 30)
					frm:Lookup('WndContainer_TitleBtnR'):FormatAllContentPos()
					frm:SetSize(nWidth, nHeight)
					frm:SetDragArea(0, 0, nWidth, 30)
					hnd:SetSize(nWidth, nHeight)
					ele.wnd:SetSize(nWidth, nHeight - 30)
				elseif frm.intact then
					-- fix size
					if nWidth  < 132 then nWidth  = 132 end
					if nHeight < 150 then nHeight = 150 end
					-- set size
					frm:SetSize(nWidth, nHeight)
					frm:SetDragArea(0, 0, nWidth, 55)
					hnd:SetSize(nWidth, nHeight)
					hnd:Lookup("Image_BgT" ):SetSize(nWidth, 64)
					hnd:Lookup("Image_BgCT"):SetSize(nWidth - 32, 64)
					hnd:Lookup("Image_BgLC"):SetSize(8, nHeight - 149)
					hnd:Lookup("Image_BgCC"):SetSize(nWidth - 16, nHeight - 149)
					hnd:Lookup("Image_BgRC"):SetSize(8, nHeight - 149)
					hnd:Lookup("Image_BgCB"):SetSize(nWidth - 132, 85)
					hnd:Lookup("Text_Title"):SetSize(nWidth - 90, 30)
					hnd:FormatAllItemPos()
					local hClose = frm:Lookup("Btn_Close")
					if hClose then
						hClose:SetRelPos(nWidth - 35, 15)
					end
					local hMax = frm:Lookup("CheckBox_Maximize")
					if hMax then
						hMax:SetRelPos(nWidth - 63, 15)
					end
					if ele.wnd then
						ele.wnd:SetSize(nWidth - 40, nHeight - 90)
						ele.wnd:Lookup("", ""):SetSize(nWidth - 40, nHeight - 90)
					end
					-- reset position
					local an = GetFrameAnchor(frm)
					frm:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
				else
					ele.frm:SetSize(nWidth, nHeight)
					ele.hdl:SetSize(nWidth, nHeight)
				end
			elseif ele.type == "WndCheckBox" then
				ele.wnd:SetSize(nHeight, nHeight)
				ele.txt:SetSize(nWidth - nHeight - 1, nHeight)
				ele.txt:SetRelPos(nHeight + 1, 0)
				ele.hdl:SetSize(nWidth, nHeight)
				ele.hdl:FormatAllItemPos()
			elseif ele.type == "WndComboBox" then
				local w, h= ele.cmb:GetSize()
				ele.cmb:SetRelPos(nWidth-w-5, math.ceil((nHeight - h)/2))
				ele.cmb:Lookup("", ""):SetAbsPos(ele.hdl:GetAbsPos())
				ele.cmb:Lookup("", ""):SetSize(nWidth, nHeight)
				ele.wnd:SetSize(nWidth, nHeight)
				ele.hdl:SetSize(nWidth, nHeight)
				ele.img:SetSize(nWidth, nHeight)
				ele.hdl:FormatAllItemPos()
			elseif ele.type == "WndEditComboBox" or ele.type == "WndAutoComplete" then
				ele.wnd:SetSize(nWidth, nHeight)
				ele.hdl:SetSize(nWidth, nHeight)
				ele.phd:SetSize(nWidth, nHeight)
				ele.img:SetSize(nWidth, nHeight)
				ele.hdl:FormatAllItemPos()
				local w, h= ele.cmb:GetSize()
				ele.edt:SetSize(nWidth-10-w, nHeight-4)
				ele.cmb:SetRelPos(nWidth-w-5, (nHeight-h-1)/2+1)
			elseif ele.type == "WndRadioBox" then
				ele.wnd:SetSize(nHeight, nHeight)
				ele.txt:SetSize(nWidth - nHeight - 1, nHeight)
				ele.txt:SetRelPos(nHeight + 1, 0)
				ele.hdl:SetSize(nWidth, nHeight)
				ele.hdl:FormatAllItemPos()
			elseif ele.type == "WndEditBox" then
				ele.wnd:SetSize(nWidth, nHeight)
				ele.hdl:SetSize(nWidth, nHeight)
				ele.phd:SetSize(nWidth, nHeight)
				ele.img:SetSize(nWidth, nHeight)
				ele.edt:SetSize(nWidth-8, nHeight-4)
				ele.hdl:FormatAllItemPos()
			elseif ele.type == "Text" then
				ele.txt:SetSize(nWidth, nHeight)
				ele.txt:GetParent():FormatAllItemPos()
				ele.raw.bAutoSize = false
			elseif ele.type == "WndListBox" then
				ele.raw:SetSize(nWidth, nHeight)
				ele.raw:Lookup('Scroll_Default'):SetRelPos(nWidth - 15, 10)
				ele.raw:Lookup('Scroll_Default'):SetSize(15, nHeight - 20)
				ele.raw:Lookup('', ''):SetSize(nWidth, nHeight)
				ele.raw:Lookup('', 'Image_Default'):SetSize(nWidth, nHeight)
				local hScroll = ele.raw:Lookup('', 'Handle_Scroll')
				hScroll:SetSize(nWidth - 20, nHeight - 20)
				for i = hScroll:GetItemCount() - 1, 0, -1 do
					local hItem = hScroll:Lookup(i)
					hItem:Lookup('Image_Bg'):SetSize(nWidth - 20, 25)
					hItem:Lookup('Image_Sel'):SetSize(nWidth - 20, 25)
					hItem:Lookup('Text_Default'):SetSize(nWidth - 20, 25)
					hItem:FormatAllItemPos()
				end
				hScroll:FormatAllItemPos()
			elseif ele.wnd then
				pcall(function() ele.wnd:SetSize(nWidth, nHeight) end)
				pcall(function() ele.hdl:SetSize(nWidth, nHeight) end)
				pcall(function() ele.txt:SetSize(nWidth, nHeight) end)
				pcall(function() ele.img:SetSize(nWidth, nHeight) end)
				pcall(function() ele.edt:SetSize(nWidth-8, nHeight-4) end)
				pcall(function() ele.hdl:FormatAllItemPos() end)
			elseif ele.itm then
				pcall(function() (ele.itm or ele.raw):SetSize(nWidth, nHeight) end)
				pcall(function() (ele.itm or ele.raw):GetParent():FormatAllItemPos() end)
				pcall(function() ele.hdl:FormatAllItemPos() end)
			end
			if ele.sbu then
				ele.sbu:SetRelPos(nWidth-25, 10)
				ele.sbd:SetRelPos(nWidth-25, nHeight-30)
				ele.sbn:SetRelPos(nWidth-21.5, 30)
				ele.sbn:SetSize(15, nHeight-60)
				ele.shd:SetSize(nWidth-35, nHeight-20)
				ele.raw.UpdateScroll()
			end
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		if ele and ele.raw then
			-- try to get its name
			local status, w, h = pcall(function() return ele.raw:GetSize() end)
			-- if succeed then return its name
			if status then return w, h else MY.Debug({w},'ERROR _MY.UI:height|width|size' ,1) return nil end
		end
	end
end

-- (self) Instance:autosize() -- resize Text element by autosize
-- (self) Instance:autosize(bool bAutoSize) -- set if Text ele autosize
function _MY.UI:autosize(bAutoSize)
	self:_checksum()
	if bAutoSize == nil then
		for _, ele in pairs(self.eles) do
			if ele.type == 'Text' then
				ele.raw:AutoSize()
			end
		end
	elseif type(bAutoSize) == 'boolean' then
		for _, ele in pairs(self.eles) do
			if ele.type == 'Text' then
				ele.raw.bAutoSize = true
			end
		end
	end
	return self
end

-- (number, number) Instance:range()
-- (self) Instance:range(nMin, nMax)
function _MY.UI:range(nMin, nMax)
	self:_checksum()
	if type(nMin)=='number' and type(nMax)=='number' and nMax>nMin then
		for _, ele in pairs(self.eles) do
			if ele.type=="WndSliderBox" then
				ele.wnd.nOffset = nMin
				ele.sld:SetStepCount(nMax - nMin)
			end
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		if ele.type=="WndSliderBox" then
			return ele.wnd.nOffset, ele.sld:GetStepCount()
		end
	end
end

-- (number, number) Instance:value()
-- (self) Instance:value(nValue)
function _MY.UI:value(nValue)
	self:_checksum()
	if nValue then
		for _, ele in pairs(self.eles) do
			if ele.type=="WndSliderBox" then
				ele.sld:SetScrollPos(nValue - ele.wnd.nOffset)
			end
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		if ele.type=="WndSliderBox" then
			return ele.wnd.nOffset + ele.sld:GetScrollPos()
		end
	end
end


-- (boolean) Instance:multiLine()
-- (self) Instance:multiLine(bMultiLine)
function _MY.UI:multiLine(bMultiLine)
	self:_checksum()
	if type(bMultiLine)=='boolean' then
		for _, ele in pairs(self.eles) do
			pcall(function() ele.edt:SetMultiLine(bMultiLine) end)
			pcall(function() ele.edt:GetParent():FormatAllItemPos() end)
			pcall(function() ele.txt:SetMultiLine(bMultiLine) end)
			pcall(function() ele.txt:GetParent():FormatAllItemPos() end)
		end
		return self
	else -- get
		-- select the first item
		local ele = self.eles[1]
		-- try to get its name
		local status, bMultiLine = pcall(function() return (ele.edt or ele.txt):IsMultiLine() end)
		-- if succeed then return its name
		if status then return bMultiLine else MY.Debug({bMultiLine},'ERROR _MY.UI:multiLine' ,1) return nil end
	end
end

-- (self) Instance:image(szImageAndFrame)
-- (self) Instance:image(szImage, nFrame)
function _MY.UI:image(szImage, nFrame)
	self:_checksum()
	if szImage then
		nFrame = nFrame or string.gsub(szImage, '.*%|(%d+)', '%1')
		szImage = string.gsub(szImage, '%|.*', '')
		if nFrame then
			nFrame = tonumber(nFrame)
			for _, ele in pairs(self.eles) do
				pcall(function() ele.img:FromUITex(szImage, nFrame) end)
				pcall(function() ele.img:GetParent():FormatAllItemPos() end)
			end
		else
			for _, ele in pairs(self.eles) do
				pcall(function() ele.img:FromTextureFile(szImage) end)
				pcall(function() ele.img:GetParent():FormatAllItemPos() end)
			end
		end
	end
	return self
end

-- (self) Instance:frame(nFrame)
-- (number) Instance:frame()
function _MY.UI:frame(nFrame)
	self:_checksum()
	if nFrame then
		nFrame = tonumber(nFrame)
		for _, ele in pairs(self.eles) do
			pcall(function() ele.img:SetFrame(nFrame) end)
			pcall(function() ele.img:GetParent():FormatAllItemPos() end)
		end
	else
		-- select the first item
		local ele = self.eles[1]
		if ele and ele.type == 'Image' then
			-- try to get its frame
			local status, nFrame = pcall(function() return ele.raw:GetFrame() end)
			-- if succeed then return its name
			if status then return nFrame else MY.Debug({nFrame},'ERROR _MY.UI:frame' ,1) return nil end
		end
	end
	return self
end

-- (self) Instance:handleStyle(dwStyle)
function _MY.UI:handleStyle(dwStyle)
	self:_checksum()
	if dwStyle then
		for _, ele in pairs(self.eles) do
			pcall(function() ele.hdl:SetHandleStyle(dwStyle) end)
		end
	end
	return self
end

-- (self) _MY.UI:sliderStyle(bShowPercentage)
function _MY.UI:sliderStyle(bShowPercentage)
	self:_checksum()
	for _, ele in pairs(self.eles) do
		if ele.type=="WndSliderBox" then
			ele.wnd.bShowPercentage = bShowPercentage
		end
	end
	return self
end

-- (self) Instance:bringToTop()
function _MY.UI:bringToTop()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		pcall(function() ele.frm:BringToTop() end)
	end
	return self
end

-- (self) Instance:refresh()
function _MY.UI:refresh()
	self:_checksum()
	for _, ele in pairs(self.eles) do
		if ele.sbu then
			ele.raw.UpdateScroll()
		end
	end
	return self
end

-----------------------------------------------------------
-- my ui events handle
-----------------------------------------------------------

-- ��Frame���¼�
function _MY.UI:onevent(szEvent, fnEvent)
	self:_checksum()
	if type(szEvent) == "string" then
		local nPos, szKey = (StringFindW(szEvent, "."))
		if nPos then
			szKey = string.sub(szEvent, nPos + 1)
			szEvent = string.sub(szEvent, 1, nPos - 1)
		end
		if type(fnEvent)=="function" then
			for _, ele in pairs(self.eles) do
				if ele.frm then
					if not ele.frm.tMyOnEvent then
						ele.frm.tMyOnEvent = {}
						ele.frm.OnEvent = function(event)
							for _, p in ipairs(ele.frm.tMyOnEvent[event] or {}) do pcall(p.fn) end
						end
					end
					if not ele.frm.tMyOnEvent[szEvent] then
						ele.frm:RegisterEvent(szEvent)
						ele.frm.tMyOnEvent[szEvent] = {}
					end
					if szKey then
						for i = #ele.frm.tMyOnEvent[szEvent], 1, -1 do
							if ele.frm.tMyOnEvent[szEvent][i].id == szKey then
								table.remove(ele.frm.tMyOnEvent[szEvent], i)
							end
						end
					end
					table.insert(ele.frm.tMyOnEvent[szEvent], { id = szKey, fn = fnEvent })
				end
			end
		else
			for _, ele in pairs(self.eles) do
				if ele.frm and ele.frm.tMyOnEvent and ele.frm.tMyOnEvent[szEvent] then
					if szKey then
						for i = #ele.frm.tMyOnEvent[szEvent], 1, -1 do
							if ele.frm.tMyOnEvent[szEvent][i].id == szKey then
								table.remove(ele.frm.tMyOnEvent[szEvent], i)
							end
						end
					else
						ele.frm.tMyOnEvent[szEvent] = {}
					end
				end
			end
		end
	end
	return self
end

-- ��ele��UI�¼�
function _MY.UI:onuievent(szEvent, fnEvent)
	self:_checksum()
	if type(szEvent)~="string" then
		return self
	end
	if type(fnEvent)=="function" then
		for _, ele in pairs(self.eles) do
			MY.UI.RegisterUIEvent(ele.raw, szEvent, fnEvent)
		end
	else
		for _, ele in pairs(self.eles) do
			if ele.raw then
				if ele.raw['tMy' .. szEvent] then
					ele.raw['tMy' .. szEvent] = {}
				end
			end
		end
	end
	return self
end

--[[ customMode ����Frame��CustomMode
	(self) Instance:customMode(string szTip, function fnOnEnterCustomMode, function fnOnLeaveCustomMode)
]]
function _MY.UI:customMode(szTip, fnOnEnterCustomMode, fnOnLeaveCustomMode, szPoint)
	self:_checksum()
	if type(szTip)=="string" then
		self:onevent("ON_ENTER_CUSTOM_UI_MODE", function()
			UpdateCustomModeWindow(this, szTip, this.bPenetrable)
		end):onevent("ON_LEAVE_CUSTOM_UI_MODE", function()
			UpdateCustomModeWindow(this, szTip, this.bPenetrable)
		end)
		if type(fnOnEnterCustomMode)=="function" then
			self:onevent("ON_ENTER_CUSTOM_UI_MODE", function()
				pcall(fnOnEnterCustomMode, GetFrameAnchor(this, szPoint))
			end)
		end
		if type(fnOnLeaveCustomMode)=="function" then
			self:onevent("ON_LEAVE_CUSTOM_UI_MODE", function()
				pcall(fnOnLeaveCustomMode, GetFrameAnchor(this, szPoint))
			end)
		end
	end
	return self
end

--[[ breathe ����Frame��breathe
	(self) Instance:breathe(function fnOnFrameBreathe)
]]
function _MY.UI:breathe(fnOnFrameBreathe)
	self:_checksum()
	if type(fnOnFrameBreathe)=="function" then
		for _, ele in pairs(self.eles) do
			if ele.frm then MY.UI.RegisterUIEvent(ele.frm, "OnFrameBreathe", fnOnFrameBreathe) end
		end
	end
	return self
end

--[[ menu �����˵�
	:menu(table menu)  �����˵�menu
	:menu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:menu(lmenu, rmenu, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		rmenu = rmenu or lmenu
	end
	-- pop menu function
	local fnPopMenu = function(raw, menu)
		local _menu = nil
		local nX, nY = raw:GetAbsPos()
		local nW, nH = raw:GetSize()
		if type(menu) == "function" then
			_menu = menu()
		else
			_menu = menu
		end
		_menu.nMiniWidth = nW
		_menu.x = nX
		_menu.y = nY + nH
		PopupMenu(_menu)
	end
	-- bind left click
	if lmenu then 
		self:each(function(eself)
			eself:lclick(function() fnPopMenu(eself:raw(1), lmenu) end)
		end)
	end
	-- bind right click
	if rmenu then 
		self:each(function(eself)
			eself:rclick(function() fnPopMenu(eself:raw(1), rmenu) end)
		end)
	end
	return self
end

--[[ lmenu ��������˵�
	:lmenu(table menu)  �����˵�menu
	:lmenu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:lmenu(menu)
	return self:menu(menu, nil, true)
end

--[[ rmenu �����Ҽ��˵�
	:lmenu(table menu)  �����˵�menu
	:lmenu(functin fn)  �����˵�function����ֵtable
]]
function _MY.UI:rmenu(menu)
	return self:menu(nil, menu, true)
end

--[[ click ��굥���¼�
	same as jQuery.click()
	:click(fnAction) ��
	:click()         ����
	:click(number n) ����
	n: 1    ���
	   0    �м�
	  -1    �Ҽ�
]]
function _MY.UI:click(fnLClick, fnRClick, fnMClick, bNoAutoBind)
	self:_checksum()
	if type(fnLClick)=="function" or type(fnMClick)=="function" or type(fnRClick)=="function" then
		if not bNoAutoBind then
			fnMClick = fnMClick or fnLClick
			fnRClick = fnRClick or fnLClick
		end
		for _, ele in pairs(self.eles) do
			if type(fnLClick)=="function" then
				if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd ,'OnLButtonClick'     , function() fnLClick(MY.Const.Event.Mouse.LBUTTON, ele.raw) end) end
				if ele.itm then MY.UI.RegisterUIEvent(ele.itm ,'OnItemLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON, ele.raw) end) end
				if ele.hdl then MY.UI.RegisterUIEvent(ele.hdl ,'OnItemLButtonClick' , function() fnLClick(MY.Const.Event.Mouse.LBUTTON, ele.raw) end) end
				if ele.cmb then MY.UI.RegisterUIEvent(ele.cmb ,'OnLButtonClick'     , function() fnLClick(MY.Const.Event.Mouse.LBUTTON, ele.raw) end) end
			end
			if type(fnMClick)=="function" then
				
			end
			if type(fnRClick)=="function" then
				if ele.wnd then MY.UI.RegisterUIEvent(ele.wnd ,'OnRButtonClick'     , function() fnRClick(MY.Const.Event.Mouse.RBUTTON, ele.raw) end) end
				if ele.itm then MY.UI.RegisterUIEvent(ele.itm ,'OnItemRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON, ele.raw) end) end
				if ele.hdl then MY.UI.RegisterUIEvent(ele.hdl ,'OnItemRButtonClick' , function() fnRClick(MY.Const.Event.Mouse.RBUTTON, ele.raw) end) end
				if ele.cmb then MY.UI.RegisterUIEvent(ele.cmb ,'OnRButtonClick'     , function() fnRClick(MY.Const.Event.Mouse.RBUTTON, ele.raw) end) end
			end
		end
	else
		local nFlag = fnLClick or fnMClick or fnRClick or MY.Const.Event.Mouse.LBUTTON
		if nFlag==MY.Const.Event.Mouse.LBUTTON then
			for _, ele in pairs(self.eles) do
				if ele.wnd then local _this = this this = ele.wnd pcall(ele.wnd.OnLButtonClick) this = _this end
				if ele.itm then local _this = this this = ele.itm pcall(ele.itm.OnItemLButtonClick) this = _this end
			end
		elseif nFlag==MY.Const.Event.Mouse.MBUTTON then
			
		elseif nFlag==MY.Const.Event.Mouse.RBUTTON then
			for _, ele in pairs(self.eles) do
				if ele.wnd then local _this = this this = ele.wnd pcall(ele.wnd.OnRButtonClick) this = _this end
				if ele.itm then local _this = this this = ele.itm pcall(ele.itm.OnItemRButtonClick) this = _this end
			end
		end
	end
	return self
end

--[[ lclick �����������¼�
	same as jQuery.lclick()
	:lclick(fnAction) ��
	:lclick()         ����
]]
function _MY.UI:lclick(fnLClick)
	return self:click(fnLClick or MY.Const.Event.Mouse.LBUTTON, nil, nil, true)
end

--[[ rclick ����Ҽ������¼�
	same as jQuery.rclick()
	:rclick(fnAction) ��
	:rclick()         ����
]]
function _MY.UI:rclick(fnRClick)
	return self:click(nil, fnRClick or MY.Const.Event.Mouse.RBUTTON, nil, true)
end

--[[ hover �����ͣ�¼�
	same as jQuery.hover()
	:hover(fnHover[, fnLeave]) ��
]]
function _MY.UI:hover(fnHover, fnLeave, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then fnLeave = fnLeave or fnHover end
	if fnHover then
		for _, ele in pairs(self.eles) do
			local wnd = ele.edt or ele.wnd
			local itm = ele.itm or ele.itm
			if wnd then MY.UI.RegisterUIEvent(wnd, 'OnMouseEnter' , function() fnHover(true, this:PtInWindow(Cursor.GetPos())) end)
			elseif itm then MY.UI.RegisterUIEvent(itm, 'OnItemMouseEnter', function() fnHover(true, this:PtInItem(Cursor.GetPos())) end) end
		end
	end
	if fnLeave then
		for _, ele in pairs(self.eles) do
			local wnd = ele.edt or ele.wnd
			local itm = ele.itm or ele.itm
			if wnd then MY.UI.RegisterUIEvent(wnd, 'OnMouseLeave' , function() fnLeave(false, this:PtInWindow(Cursor.GetPos())) end)
			elseif itm then MY.UI.RegisterUIEvent(itm, 'OnItemMouseLeave', function() fnLeave(false, this:PtInItem(Cursor.GetPos())) end) end
		end
	end
	return self
end

--[[ tip �����ͣ��ʾ
	(self) Instance:tip( tip[, nPosType[, tOffset[, bNoEncode] ] ] ) ��tip�¼�
	string|function tip:Ҫ��ʾ�������ı������л���DOM�ı��򷵻�ǰ���ı��ĺ���
	number nPosType:    ��ʾλ�� ��ЧֵΪMY.Const.UI.Tip.ö��
	table tOffset:      ��ʾ��ƫ�����ȸ�����Ϣ{ x = x, y = y, hide = MY.Const.UI.Tip.Hideö��, nFont = ����, r, g, b = ����ɫ }
	boolean bNoEncode:  ��szTipΪ���ı�ʱ�����������Ϊfalse ��szTipΪ��ʽ����DOM�ַ���ʱ���øò���Ϊtrue
]]
function _MY.UI:tip(tip, nPosType, tOffset, bNoEncode)
	tOffset = tOffset or {}
	tOffset.x = tOffset.x or 0
	tOffset.y = tOffset.y or 0
	tOffset.w = tOffset.w or 450
	tOffset.hide = tOffset.hide or MY.Const.UI.Tip.HIDE
	tOffset.nFont = tOffset.nFont or 136
	nPosType = nPosType or MY.Const.UI.Tip.POS_FOLLOW_MOUSE
	return self:hover(function()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		if nPosType == MY.Const.UI.Tip.POS_FOLLOW_MOUSE then
			x, y = Cursor.GetPos()
			x, y = x - 0, y - 40
		end
		x, y = x + tOffset.x, y + tOffset.y
		local szTip = tip
		if type(szTip) == 'function' then
			szTip = szTip()
		end
		if not bNoEncode then
			szTip = GetFormatText(szTip, tOffset.nFont, tOffset.r, tOffset.g, tOffset.b)
		end
		OutputTip(szTip, tOffset.w, {x, y, w, h}, nPosType)
	end, function()
		if tOffset.hide == MY.Const.UI.Tip.HIDE then
			HideTip(false)
		elseif tOffset.hide == MY.Const.UI.Tip.ANIMATE_HIDE then
			HideTip(true)
		end
	end, true)
end

--[[ check ��ѡ��״̬�仯
	:check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) ��
	:check()                �����Ƿ��ѹ�ѡ
	:check(bool bChecked)   ��ѡ/ȡ����ѡ
]]
function _MY.UI:check(fnCheck, fnUncheck, bNoAutoBind)
	self:_checksum()
	if not bNoAutoBind then
		fnUncheck = fnUncheck or fnCheck
	end
	if type(fnCheck)=="function" or type(fnUncheck)=="function" then
		for _, ele in pairs(self.eles) do
			if ele.chk then
				if type(fnCheck)=="function" then MY.UI.RegisterUIEvent(ele.chk, 'OnCheckBoxCheck' , function() fnCheck(true) end) end
				if type(fnUncheck)=="function" then MY.UI.RegisterUIEvent(ele.chk, 'OnCheckBoxUncheck' , function() fnUncheck(false) end) end
			end
		end
		return self
	elseif type(fnCheck) == "boolean" then
		for _, ele in pairs(self.eles) do
			if ele.chk then ele.chk:Check(fnCheck) end
		end
		return self
	elseif not fnCheck then
		-- select the first item
		local ele = self.eles[1]
		-- try to get its check status
		if ele and ele.chk then
			return ele.chk:IsCheckBoxChecked()
		end
	else
		MY.Debug({'fnCheck:'..type(fnCheck)..' fnUncheck:'..type(fnUncheck)}, 'ERROR _MY.UI:check' ,1)
	end
end

--[[ change ��������ֱ仯
	:change(fnOnChange) ��
	:change()   ���ô�����
]]
function _MY.UI:change(fnOnChange)
	self:_checksum()
	if fnOnChange then
		for _, ele in pairs(self.eles) do
			if ele.edt then
				MY.UI.RegisterUIEvent(ele.edt, 'OnEditChanged', function() pcall(fnOnChange,ele.edt:GetText()) end)
			end
			if ele.type=="WndSliderBox" then
				table.insert(ele.wnd.tMyOnChange, fnOnChange)
			end
		end
		return self
	else
		for _, ele in pairs(self.eles) do
			if ele.edt then local _this = this this = ele.edt pcall(ele.edt.OnEditChanged) this = _this  end
			if ele.type=="WndSliderBox" then
				local _this = this this = ele.sld pcall(ele.sld.OnScrollBarPosChanged) this = _this
			end
		end
		return self
	end
end

-- OnGetFocus ��ȡ����

-----------------------------------------------------------
-- MY.UI
-----------------------------------------------------------

MY.UI = MY.UI or {}
MY.Const = MY.Const or {}
MY.Const.Event = MY.Const.Event or {}
MY.Const.Event.Mouse = MY.Const.Event.Mouse or {}
MY.Const.Event.Mouse.LBUTTON = 1
MY.Const.Event.Mouse.MBUTTON = 0
MY.Const.Event.Mouse.RBUTTON = -1
MY.Const.UI = MY.Const.UI or {}
MY.Const.UI.Tip = MY.Const.UI.Tip or {}
MY.Const.UI.Tip.POS_FOLLOW_MOUSE = 0
MY.Const.UI.Tip.POS_LEFT         = 1
MY.Const.UI.Tip.POS_RIGHT        = 2
MY.Const.UI.Tip.POS_TOP          = 3
MY.Const.UI.Tip.POS_BOTTOM       = 4
MY.Const.UI.Tip.POS_RIGHT_BOTTOM = 5
MY.Const.UI.Slider = MY.Const.UI.Slider or {}
MY.Const.UI.Slider.SHOW_VALUE    = false
MY.Const.UI.Slider.SHOW_PERCENT  = true

MY.Const.UI.Tip.NO_HIDE      = 100
MY.Const.UI.Tip.HIDE         = 101
MY.Const.UI.Tip.ANIMATE_HIDE = 102

-- ����Ԫ���������Ե����������ã���Ч���൱�� MY.UI.Fetch
setmetatable(MY.UI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

--[[ ���캯�� ����jQuery: $(selector) ]]
MY.UI.Fetch = function(selector, tab) return _MY.UI.new(selector, tab) end
-- ��UI�¼�
MY.UI.RegisterUIEvent = function(raw, szEvent, fnEvent)
	if not raw['tMy'..szEvent] then
		-- init onXXX table
		raw['tMy'..szEvent] = { raw[szEvent] }
		-- init onXXX function
		raw[szEvent] = function(...)
			for _, fn in ipairs(raw['tMy'..szEvent]) do
				local tReturn
				for _, fn in ipairs(raw['tMy' .. szEvent] or {}) do 
					local t = { pcall(fn, ...) }
					if not t[1] then
						MY.Debug({t[2]}, MY.UI.GetTreePath(raw) .. '#' .. szEvent, 2)
					elseif not tReturn then
						table.remove(t, 1)
						tReturn = t
					end
				end
				if tReturn then
					return unpack(tReturn)
				end
			 end
		end
	end
	if fnEvent then
		table.insert(raw['tMy'..szEvent], fnEvent)
	end
end

---------------------------------------------------
-- create new frame
-- (ui) MY.UI.CreateFrame(string szName, table opt)
-- @param string szName: the ID of frame
-- @param table  opt   : options
---------------------------------------------------
MY.UI.CreateFrame = function(szName, opt)
	if type(opt) ~= 'table' then
		opt = {}
	end
	if not (
		opt.level == 'Normal'  or opt.level == 'Lowest'  or opt.level == 'Topmost'  or
		opt.level == 'Normal1' or opt.level == 'Lowest1' or opt.level == 'Topmost1' or
		opt.level == 'Normal2' or opt.level == 'Lowest2' or opt.level == 'Topmost2'
	) then
		opt.level = "Normal"
	end
	-- calc ini file path
	local szIniFile = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndFrame.ini"
	if opt.simple then
		szIniFile = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndFrameSimple.ini"
	elseif opt.empty then
		szIniFile = MY.GetAddonInfo().szFrameworkRoot .. "ui\\WndFrameEmpty.ini"
	end
	
	-- close and reopen exist frame
	local frm = Station.Lookup(opt.level .. '/' .. szName)
	if frm then
		Wnd.CloseWindow(frm)
	end
	frm = Wnd.OpenWindow(szIniFile, szName)
	frm:ChangeRelation(opt.level)
	frm:Show()
	
	-- init frame
	if opt.esc then
		MY.RegisterEsc('Frame_Close_' .. szName, function()
			return true
		end, function()
			if frm.OnCloseButtonClick then
				local status, res = pcall(frm.OnCloseButtonClick)
				if status and res then
					return
				end
			end
			Wnd.CloseWindow(frm)
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
			MY.RegisterEsc('Frame_Close_' .. szName)
		end)
	end
	if opt.simple then
		frm.simple = true
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		-- top right buttons
		if not opt.close then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Close'):Destroy()
		else
			frm:Lookup("WndContainer_TitleBtnR/Wnd_Close/Btn_Close").OnLButtonClick = function()
				if frm.OnCloseButtonClick then
					local status, res = pcall(frm.OnCloseButtonClick)
					if status and res then
						return
					end
				end
				Wnd.CloseWindow(frm)
				PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
			end
		end
		if opt.onrestore then
			MY.UI.RegisterUIEvent(frm, 'OnRestore', opt.onrestore)
		end
		if not opt.minimize then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Minimize'):Destroy()
		else
			if opt.onminimize then
				MY.UI.RegisterUIEvent(frm, 'OnMinimize', opt.onminimize)
			end
			frm:Lookup("WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize").OnCheckBoxCheck = function()
				if frm.bMaximize then
					frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize"):Check(false)
				else
					frm.w, frm.h = frm:GetSize()
				end
				frm:Lookup('Window_Main'):Hide()
				frm:Lookup('', 'Shadow_Bg'):Hide()
				frm:SetSize(frm.w, 30)
				local hMax = frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize")
				if hMax then
					hMax:Enable(false)
				end
				if frm.OnMinimize then
					local status, res = pcall(frm.OnMinimize, frm:Lookup('Window_Main'))
					if status and res then
						return
					end
				end
				frm.bMinimize = true
			end
			frm:Lookup("WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize").OnCheckBoxUncheck = function()
				frm:Lookup('Window_Main'):Show()
				frm:Lookup('', 'Shadow_Bg'):Show()
				frm:SetSize(frm.w, frm.h)
				local hMax = frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize")
				if hMax then
					hMax:Enable(true)
				end
				if frm.OnRestore then
					local status, res = pcall(frm.OnRestore, frm:Lookup('Window_Main'))
					if status and res then
						return
					end
				end
				frm.bMinimize = false
			end
		end
		if not opt.maximize then
			frm:Lookup('WndContainer_TitleBtnR/Wnd_Maximize'):Destroy()
		else
			if opt.onmaximize then
				MY.UI.RegisterUIEvent(frm, 'OnMaximize', opt.onmaximize)
			end
			frm:Lookup('WndContainer_TitleBtnR').OnLButtonDBClick = function()
				frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize"):ToggleCheck()
			end
			frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize").OnCheckBoxCheck = function()
				if frm.bMinimize then
					frm:Lookup("WndContainer_TitleBtnR/Wnd_Minimize/CheckBox_Minimize"):Check(false)
				else
					frm.anchor = GetFrameAnchor(frm)
					frm.w, frm.h = frm:GetSize()
				end
				local w, h = Station.GetClientSize()
				MY.UI(frm):pos(0, 0):drag(false):size(w, h):onevent('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
					local w, h = Station.GetClientSize()
					MY.UI(frm):pos(0, 0):size(w, h)
				end)
				if frm.OnMaximize then
					local status, res = pcall(frm.OnMaximize, frm:Lookup('Window_Main'))
					if status and res then
						return
					end
				end
				frm.bMaximize = true
			end
			frm:Lookup("WndContainer_TitleBtnR/Wnd_Maximize/CheckBox_Maximize").OnCheckBoxUncheck = function()
				MY.UI(frm)
				  :onevent('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
				  :size(frm.w, frm.h)
				  :anchor(frm.anchor)
				  :drag(true)
				if frm.OnRestore then
					local status, res = pcall(frm.OnRestore, frm:Lookup('Window_Main'))
					if status and res then
						return
					end
				end
				frm.bMaximize = false
			end
		end
		-- frame properties
		if opt.alpha then
			frm:Lookup('', 'Image_Title'):SetAlpha(opt.alpha * 1.4)
			frm:Lookup('', 'Shadow_Bg'):SetAlpha(opt.alpha /255 * 200)
		end
	elseif not opt.empty then
		frm.intact = true
		frm:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frm:Lookup("Btn_Close").OnLButtonClick = function()
			if frm.OnCloseButtonClick then
				local status, res = pcall(frm.OnCloseButtonClick)
				if status and res then
					return
				end
			end
			Wnd.CloseWindow(frm)
		end
		-- load bg uitex
		local szUITexCommon = MY.GetAddonInfo().szUITexCommon
		for k, v in pairs({
			['Image_BgLT'] = 9,
			['Image_BgCT'] = 8,
			['Image_BgRT'] = 7,
			['Image_BgT' ] = 6,
		}) do
			local h = frm:Lookup('', k)
			h:FromUITex(szUITexCommon, v)
		end
	end
	return MY.UI(frm)
end

-- ��ȡɫ��
MY.UI.OpenColorPicker = function(callback, t)
	if t then
		return OpenColorTablePanel(callback,nil,nil,t)
	end
	local ui = MY.UI.CreateFrame("_MY_ColorTable", { simple = true, close = true, esc = true })
	  :size(900, 500):text(_L["color picker"]):anchor({s='CENTER', r='CENTER', x=0, y=0})
	local fnHover = function(bHover, r, g, b)
		if bHover then
			this:SetAlpha(255)
			ui:item("#Select"):color(r, g, b)
			ui:item("#Select_Text"):text(string.format("r=%d, g=%d, b=%d", r, g, b))
		else
			this:SetAlpha(200)
			ui:item("#Select"):color(255, 255, 255)
			ui:item("#Select_Text"):text(g_tStrings.STR_NONE)
		end
	end
	local fnClick = function( ... )
		if callback then callback( ... ) end
		if not IsCtrlKeyDown() then
			ui:remove()
		end
	end
	for nRed = 1, 8 do
		for nGreen = 1, 8 do
			for nBlue = 1, 8 do
				local x = 20 + ((nRed - 1) % 4) * 220 + (nGreen - 1) * 25
				local y = 10 + math.modf((nRed - 1) / 4) * 220 + (nBlue - 1) * 25
				local r, g, b  = nRed * 32 - 1, nGreen * 32 - 1, nBlue * 32 - 1
				ui:append("Shadow", {
					w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
					onhover = function(bHover)
						fnHover(bHover, r, g, b)
					end,
					onclick = function()
						fnClick(r, g, b)
					end,
				})
			end
		end
	end
	
	for i = 1, 16 do
		local x = 480 + (i - 1) * 25
		local y = 435
		local r, g, b  = i * 16 - 1, i * 16 - 1, i * 16 - 1
		ui:append("Shadow", {
			w = 23, h = 23, x = x, y = y, color = { r, g, b }, alpha = 200,
			onhover = function(bHover)
				fnHover(bHover, r, g, b)
			end,
			onclick = function()
				fnClick(r, g, b)
			end,
		})
	end
	ui:append("Shadow", "Select", { w = 25, h = 25, x = 20, y = 435 })
	ui:append("Text", "Select_Text", { x = 65, y = 435 })
	Station.SetFocusWindow(ui:raw(1))
	-- OpenColorTablePanel(callback,nil,nil,t)
	--  or {
	--     { r = 0,   g = 255, b = 0  },
	--     { r = 0,   g = 255, b = 255},
	--     { r = 255, g = 0  , b = 0  },
	--     { r = 40,  g = 140, b = 218},
	--     { r = 211, g = 229, b = 37 },
	--     { r = 65,  g = 50 , b = 160},
	--     { r = 170, g = 65 , b = 180},
	-- }
end

-- ������ѡ��
MY.UI.OpenFontPicker = function(callback, t)
	local w, h = 820, 640
	local ui = MY.UI.CreateFrame("_MY_Color_Picker", { simple = true, close = true, esc = true })
	  :size(w, h):text(_L["color picker"]):anchor({s='CENTER', r='CENTER', x=0, y=0})
	
	for i = 0, 255 do
		local txt = ui:append("Text", "Text_"..i, {
			w = 70, x = i % 10 * 80 + 20, y = math.floor(i / 10) * 25,
			font = i, alpha = 200, text = _L("Font %d", i)
		}):item("#Text_"..i)
		  :click(function()
		  	if callback then callback(i) end
		  	ui:remove()
		  end)
		  :hover(function()
		  	MY.UI(this):alpha(255)
		  end,function()
		  	MY.UI(this):alpha(200)
		  end)
		-- remove unexist font
		if txt:font() ~= i then
			txt:remove()
		end
	end
	Station.SetFocusWindow(ui:raw(1))
end
-- ���ı��б�༭��
MY.UI.OpenListEditor = function(szFrameName, tTextList, OnAdd, OnDel)
	local muDel
	local AddListItem = function(muList, szText)
		local i = muList:hdl(1):children():count()
		local muItem = muList:append('<handle><image>w=300 h=25 eventid=371 name="Image_Bg" </image><text>name="Text_Default" </text></handle>'):hdl(1):children():last()
		local hHandle = muItem:raw(1)
		hHandle.Value = szText
		local hText = muItem:children("#Text_Default"):pos(10, 2):text(szText or ""):raw(1)
		muItem:children("#Image_Bg"):image("UI/Image/Common/TextShadow.UITex",5):alpha(0):hover(function(bIn)
			if hHandle.Selected then return nil end
			if bIn then
				MY.UI(this):fadeIn(100)
			else
				MY.UI(this):fadeTo(500,0)
			end
		end):click(function(nButton)
			if nButton == MY.Const.Event.Mouse.RBUTTON then
				hHandle.Selected = true
				PopupMenu({{
					szOption = _L["delete"],
					fnAction = function()
						muDel:click()
					end,
				}})
			else
				hHandle.Selected = not hHandle.Selected
			end
			if hHandle.Selected then
				MY.UI(this):image("UI/Image/Common/TextShadow.UITex",2)
			else
				MY.UI(this):image("UI/Image/Common/TextShadow.UITex",5)
			end
		end)
	end
	local ui = MY.UI.CreateFrame(szFrameName)
	ui:append("Image", "Image_Spliter"):find("#Image_Spliter"):pos(-10,25):size(360, 10):image("UI/Image/UICommon/Commonpanel.UITex",42)
	local muEditBox = ui:append("WndEditBox", "WndEditBox_Keyword"):find("#WndEditBox_Keyword"):pos(0,0):size(170, 25)
	local muList = ui:append("WndScrollBox", "WndScrollBox_KeywordList"):find("#WndScrollBox_KeywordList"):handleStyle(3):pos(0,30):size(340, 380)
	-- add
	ui:append("WndButton", "WndButton_Add"):find("#WndButton_Add"):pos(180,0):width(80):text(_L["add"]):click(function()
		local szText = muEditBox:text()
		-- �����
		if OnAdd then
			if OnAdd(szText) ~= false then
				AddListItem(muList, szText)
			end
		else
			AddListItem(muList, szText)
		end
	end)
	-- del
	muDel = ui:append("WndButton", "WndButton_Del"):find("#WndButton_Del"):pos(260,0):width(80):text(_L["delete"]):click(function()
		muList:hdl(1):children():each(function(ui)
			if this.Selected then
				if OnDel then
					OnDel(this.Value)
				end
				ui:remove()
			end
		end)
	end)
	-- insert data to ui
	for i, v in ipairs(tTextList) do
		AddListItem(muList, v)
	end
	return ui
end
-- �������
MY.UI.OpenInternetExplorer = function(szAddr, bDisableSound)
	local nIndex, nLast = nil, nil
	for i = 1, 10, 1 do
		if not _MY.IsInternetExplorerOpened(i) then
			nIndex = i
			break
		elseif not nLast then
			nLast = i
		end
	end
	if not nIndex then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
		return nil
	end
	local x, y = _MY.IE_GetNewIEFramePos()
	local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
	frame.bIE = true
	frame.nIndex = nIndex

	frame:BringToTop()
	if nLast then
		frame:SetAbsPos(x, y)
		frame:CorrectPos()
		frame.x = x
		frame.y = y
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		frame.x, frame.y = frame:GetAbsPos()
	end
	local webPage = frame:Lookup("WebPage_Page")
	if szAddr then
		webPage:Navigate(szAddr)
	end
	Station.SetFocusWindow(webPage)
	if not bDisableSound then
		PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
	end
	return webPage
end
-- �ж�������Ƿ��ѿ���
_MY.IsInternetExplorerOpened = function(nIndex)
	local frame = Station.Lookup("Topmost/IE"..nIndex)
	if frame and frame:IsVisible() then
		return true
	end
	return false
end
-- ��ȡ���������λ��
_MY.IE_GetNewIEFramePos = function()
	local nLastTime = 0
	local nLastIndex = nil
	for i = 1, 10, 1 do
		local frame = Station.Lookup("Topmost/IE"..i)
		if frame and frame:IsVisible() then
			if frame.nOpenTime > nLastTime then
				nLastTime = frame.nOpenTime
				nLastIndex = i
			end
		end
	end
	if nLastIndex then
		local frame = Station.Lookup("Topmost/IE"..nLastIndex)
		x, y = frame:GetAbsPos()
		local wC, hC = Station.GetClientSize()
		if x + 890 <= wC and y + 630 <= hC then
			return x + 30, y + 30
		end
	end
	return 40, 40
end

--[[ append an item to parent
	MY.UI.Append(hParent, szName, szType, tArg)
	hParent     -- an Window, Handle or MY.UI object
	szName      -- name of the object inserted
	tArg        -- param like width, height, left, right, etc.
]]
MY.UI.Append = function(hParent, szName, szType, tArg)
	return MY.UI(hParent):append(szName, szType, tArg)
end

MY.UI.GetTreePath = function(raw)
	local tTreePath = { (raw:GetTreePath()):sub(1, -2) }
	while(raw and raw:GetType():sub(1, 3) ~= 'Wnd') do
		local szName = raw:GetName()
		if not szName or szName == '' then
			table.insert(tTreePath, 2, raw:GetIndex())
		else
			table.insert(tTreePath, 2, szName)
		end
		raw = raw:GetParent()
	end
	return table.concat(tTreePath, '/')
end
