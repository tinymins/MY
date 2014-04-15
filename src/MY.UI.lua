MY = MY or {}
local _MY = {
    szIniFileEditBox = "Interface\\MY\\ui\\WndEditBox.ini",
    szIniFileButton = "Interface\\MY\\ui\\WndButton.ini",
    szIniFileCheckBox = "Interface\\MY\\ui\\WndCheckBox.ini",
    szIniFileMainPanel = "Interface\\MY\\ui\\MainPanel.ini",
}
---------------------------------------------------------------------
-- 本地的 UI 组件对象
---------------------------------------------------------------------
-------------------------------------
-- UI object class
-------------------------------------
_MY.UI = class()

-- 不会玩元表 (╯‵□′)╯︵┻━┻
-- -- 设置元表，这样可以当作table调用，其效果相当于 .eles[i].raw
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
-- 获取一个窗体的所有子元素
local GetChildren = function(root)
    local stack = { root }  -- 初始栈
    local children = {}     -- 保存所有子元素 szTreePath => element 键值对
    while #stack > 0 do     -- 循环直到栈空
        --### 弹栈: 弹出栈顶元素
        local raw = stack[#stack]
        table.remove(stack, #stack)
        -- 将当前弹出的元素加入子元素表
        children[table.concat({ raw:GetTreePath() })] = raw
        -- 如果有Handle则将所有Handle子元素加入子元素表
        local status, handle = pcall(function() return raw:Lookup('','') end) -- raw可能没有Lookup方法 用pcall包裹
        if status and handle then
            children[table.concat({ handle:GetTreePath(), '/Handle' })] = handle
            for i = 0, handle:GetItemCount() - 1, 1 do
                children[table.concat({ handle:Lookup(i):GetTreePath(), i })] = handle:Lookup(i)
            end
        end
        --### 压栈: 将刚刚弹栈的元素的所有子窗体压栈
        local status, sub_raw = pcall(function() return raw:GetFirstChild() end) -- raw可能没有GetFirstChild方法 用pcall包裹
        while status and sub_raw do
            table.insert(stack, sub_raw)
            sub_raw = sub_raw:GetNext()
        end
    end
    -- 因为是求子元素 所以移除第一个压栈的元素（父元素）
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
        -- format tab
        if type(tab)~="table" then tab = {} end
        local szType = raw.szMyuiType or raw:GetType()
        if not tab.txt and szType == "Text" then tab.txt = raw end
        if not tab.img and szType == "Image" then tab.img = raw end
        if not tab.chk and szType == "WndCheckBox" then tab.chk = raw end
        if not tab.edt and szType == "WndEdit" then tab.edt = raw end
        if not tab.sdw and szType == "Shadow" then tab.sdw = raw end
        if not tab.hdl and szType == "Handle" then tab.hdl = raw end
        if szType=="WndEditBox" then
            tab.wnd = tab.wnd or raw
            tab.hdl = tab.hdl or raw:Lookup('','')
            tab.edt = tab.edt or raw:Lookup('WndEdit_Default')
            tab.img = tab.img or raw:Lookup('','Image_Default')
        elseif string.sub(szType, 1, 3) == "Wnd" then
            tab.wnd = tab.wnd or raw
            tab.hdl = tab.hdl or raw:Lookup('','')
            tab.txt = tab.txt or raw:Lookup('','Text_Default')
        else tab.itm = raw end
        if raw then table.insert( self.eles, { raw = raw, wnd = tab.wnd, itm = tab.itm, hdl = tab.hdl, txt = tab.txt, img = tab.img, chk = tab.chk, edt = tab.edt, sdw = tab.sdw } ) end
    end
    return self
end

-- clone
-- clone and return a new class
function _MY.UI:clone(eles)
    eles = eles or self.eles
    return _MY.UI.new({eles = eles})
end

-- conv raw to eles array
function _MY.UI:raw2ele(raw, tab)
    -- format tab
    if type(tab)~="table" then tab = {} end
    local szType = raw.szMyuiType or raw:GetType()
    if not tab.txt and szType == "Text" then tab.txt = raw end
    if not tab.img and szType == "Image" then tab.img = raw end
    if not tab.chk and szType == "WndCheckBox" then tab.chk = raw end
    if not tab.edt and szType == "WndEdit" then tab.edt = raw end
    if not tab.sdw and szType == "Shadow" then tab.sdw = raw end
    if not tab.hdl and szType == "Handle" then tab.hdl = raw end
    if szType=="WndEditBox" then
        tab.wnd = tab.wnd or raw
        tab.hdl = tab.hdl or raw:Lookup('','')
        tab.edt = tab.edt or raw:Lookup('WndEdit_Default')
        tab.img = tab.img or raw:Lookup('','Image_Default')
    elseif string.sub(szType, 1, 3) == "Wnd" then
        tab.wnd = tab.wnd or raw
        tab.hdl = tab.hdl or raw:Lookup('','')
        tab.txt = tab.txt or raw:Lookup('','Text_Default')
    else tab.itm = raw end
    return { raw = raw, wnd = tab.wnd, itm = tab.itm, hdl = tab.hdl, txt = tab.txt, img = tab.img, chk = tab.chk, edt = tab.edt, sdw = tab.sdw }
end

-- add a ele to object
-- same as jQuery.add()
function _MY.UI:add(raw, tab)
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
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    if type(raw) == "string" then
        -- delete ele those id/class fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetName() == raw then
                    table.remove(eles, i)
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) == raw then
                    table.remove(eles, i)
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
    local eles = {}
    for i = 1, #self.eles, 1 do
        table.insert(eles, self.eles[i])
    end
    if type(raw) == "string" then
        -- delete ele those id/class not fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetName() ~= raw then
                    table.remove(eles, i)
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if (eles[i].raw.szMyuiType or eles[i].raw:GetType()) ~= raw then
                    table.remove(eles, i)
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

-- get child
-- same as jQuery.child()
function _MY.UI:child(filter)
    local child = {}
    local childHash = {}
    for _, ele in pairs(self.eles) do
        if ele.raw:GetType() == "Handle" then
            for i = 0, ele.raw:GetItemCount() - 1, 1 do
                if not childHash[table.concat({ ele.raw:Lookup(i):GetTreePath(), i })] then
                    table.insert(child, ele.raw:Lookup(i))
                    childHash[table.concat({ ele.raw:Lookup(i):GetTreePath(), i })] = true
                end
            end
        else
            -- 子handle
            local status, handle = pcall(function() return ele.raw:Lookup('','') end) -- raw可能没有Lookup方法 用pcall包裹
            if status and handle and not childHash[table.concat{handle:GetTreePath(),'/Handle'}] then
                table.insert(child, handle)
                childHash[table.concat({handle:GetTreePath(),'/Handle'})] = true
            end
            -- 子窗体
            local status, sub_raw = pcall(function() return ele.raw:GetFirstChild() end) -- raw可能没有GetFirstChild方法 用pcall包裹
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

-- get all children
-- same as jQuery.children(filter)
function _MY.UI:children(filter)
    local children = {}
    for _, ele in pairs(self.eles) do
        for szTreePath, raw in pairs(GetChildren(ele.raw)) do
            children[szTreePath] = raw
        end
    end
    local eles = {}
    for _, raw in pairs(children) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles):filter(filter)
end

-- find ele
-- same as jQuery.find()
function _MY.UI:find(filter)
    return self:children():filter(filter)
end

-- each
-- same as jQuery.each(function(){})
function _MY.UI:each(fn)
    local eles = self.eles
    for _, ele in pairs(eles) do
        pcall(fn, ele.raw)
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
function _MY.UI:raw(index)
    local eles = self.eles
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #eles then return eles[index].raw end
end

-----------------------------------------------------------
-- my ui opreation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
function _MY.UI:remove()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.fnDestroy(ele.raw) end)
        if ele.raw:GetType() == "WndFrame" then
            Wnd.CloseWindow(self.raw)
        elseif string.sub(ele.raw:GetType(), 1, 3) == "Wnd" then
            ele.raw:Destroy()
        else
            ele.raw:GetParent():RemoveItem(ele.raw:GetIndex())
        end
    end
    self.eles = {}
    return self
end

-- xml string
_MY.tItemXML = {
	["Text"] = "<text>w=150 h=30 valign=1 font=162 eventid=371 </text>",
	["Image"] = "<image>w=100 h=100 eventid=257 </image>",
	["Box"] = "<box>w=48 h=48 eventid=525311 </text>",
	["Shadow"] = "<shadow>w=15 h=15 eventid=277 </shadow>",
	["Handle"] = "<handle>w=10 h=10</handle>",
}
-- append
-- similar as jQuery.append()
-- Instance:append(szName, szType, tArg)
-- Instance:append(szItemString)
function _MY.UI:append(szName, szType, tArg)
    if szType then
        for _, ele in pairs(self.eles) do
            if ( string.sub(szType, 1, 3) == "Wnd" and ele.wnd ) then
                -- append from ini file
                local szFile = "interface\\MY\\ui\\" .. szType .. ".ini"
                local frame = Wnd.OpenWindow(szFile, "MY_TempWnd")
                if not frame then
                    return MY.Debug(_L("Unable to open ini file [%s]", szFile)..'\n', 'MY#UI#append', 2)
                end
                local wnd = frame:Lookup(szType)
                if not wnd then
                    MY.Debug(_L("Can not find wnd component [%s]", szType)..'\n', 'MY#UI#append', 2)
                else
                    wnd.szMyuiType = szType
                    wnd:SetName(szName)
                    wnd:ChangeRelation(ele.wnd, true, true)
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
                    if hnd then hnd:SetName(szName) end
                else
                    -- append from ini
                    hnd = ele.hdl:AppendItemFromIni("interface\\MY\\ui\\HandleItems.ini","Handle_" .. szType, szName)
                end
                if not hnd then
                    return MY.Debug(_L("Unable to append handle item [%s]", szType)..'\n','MY#UI*append',2)
                end
            end
        end
    else
        for _, ele in pairs(self.eles) do
            if ele.hdl then
                -- append from xml
                local nCount = ele.hdl:GetItemCount()
                ele.hdl:AppendItemFromString(szName)
                local hnd 
                for i = nCount, ele.hdl:GetItemCount()-1, 1 do
                    hnd = ele.hdl:Lookup(i)
                    if hnd and hnd:GetName()=='' then hnd:SetName('Unnamed_Item'..i) end
                end
                ele.hdl:FormatAllItemPos()
                if nCount == ele.hdl:GetItemCount() then
                    return MY.Debug(_L("Unable to append handle item from string.")..'\n','MY#UI*append',2)
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
    for _, ele in pairs(self.eles) do
        if ele.hdl then
            pcall(function() ele.hdl:Clear() end)
        end
    end
    return self
end

-----------------------------------------------------------
-- my ui property visitors
-----------------------------------------------------------

-- show/hide eles
function _MY.UI:toggle(bShow)
    for _, ele in pairs(self.eles) do
        pcall(function() if bShow == false or (not bShow and ele.raw:IsVisible()) then ele.raw:Hide() ele.hdl:Hide() else ele.raw:Show() ele.hdl:Show() end end)
    end
    return self
end

-- get/set ui object text
function _MY.UI:text(szText)
    if szText then
        for _, ele in pairs(self.eles) do
            pcall(function() (ele.txt or ele.edt or ele.raw):SetText(szText) end)
        end
        return self
    else
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return (ele.txt or ele.edt or ele.raw):GetText() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:text' ,3) return nil end
    end
end

-- get/set ui object name
function _MY.UI:name(szText)
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
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:name' ,3) return nil end
    end
end

-- get/set ui alpha
function _MY.UI:alpha(nAlpha)
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
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:alpha' ,3) return nil end
    end
end


-- (number) Instance:font()
-- (self) Instance:font(number nFont)
function _MY.UI:font(nFont)
    if nFont then-- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetFontScheme(nFont) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetFontScheme() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:font' ,3) return nil end
    end
end

-- (number, number, number) Instance:color()
-- (self) Instance:color(number nRed, number nGreen, number nBlue)
function _MY.UI:color(nRed, nGreen, nBlue)
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
        if status then return r,g,b else MY.Debug(err..'\n','ERROR _MY.UI:color' ,3) return nil end
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
    if nLeft or nTop then
        for _, ele in pairs(self.eles) do
            local _nLeft, _nTop = ele.raw:GetRelPos()
            nLeft, nTop = nLeft or _nLeft, nTop or _nTop
            if ele.wnd then
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
        if status then return l, t else MY.Debug(err..'\n','ERROR _MY.UI:left|top|pos' ,1) return nil end
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
    if nWidth or nHeight then
        for _, ele in pairs(self.eles) do
            local _nWidth, _nHeight = ele.raw:GetSize()
            nWidth, nHeight = nWidth or _nWidth, nHeight or _nHeight
            if ele.wnd then
                pcall(function() ele.wnd:SetSize(nWidth, nHeight) end)
                pcall(function() ele.txt:SetSize(nWidth, nHeight) end)
                pcall(function() ele.img:SetSize(nWidth, nHeight) end)
                pcall(function() ele.edt:SetSize(nWidth-8, nHeight-4) end)
                pcall(function() ele.hdl:FormatAllItemPos() end)
            elseif ele.itm then
                pcall(function() (ele.itm or ele.raw):SetSize(nWidth, nHeight) end)
                pcall(function() (ele.itm or ele.raw):GetParent():FormatAllItemPos() end)
            end
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, w, h = pcall(function() return ele.raw:GetSize() end)
        -- if succeed then return its name
        if status then return w, h else MY.Debug(err..'\n','ERROR _MY.UI:height|width|size' ,1) return nil end
    end
end

-- (boolean) Instance:multiLine()
-- (self) Instance:multiLine(bMultiLine)
function _MY.UI:multiLine(bMultiLine)
    if type(bMultiLine)=='boolean' then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.edt:SetMultiLine(bMultiLine) end)
            pcall(function() ele.txt:SetMultiLine(bMultiLine) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, bMultiLine = pcall(function() return (ele.edt or ele.txt):IsMultiLine() end)
        -- if succeed then return its name
        if status then return bMultiLine else MY.Debug(err..'\n','ERROR _MY.UI:multiLine' ,1) return nil end
    end
end

-----------------------------------------------------------
-- my ui events handle
-----------------------------------------------------------

--[[ click 鼠标单击事件
    same as jQuery.click()
    :click(fnAction) 绑定
    :click()         触发
]]
function _MY.UI:click(fn)
    for _, ele in pairs(self.eles) do
        if fn then
            if ele.wnd then ele.wnd.OnLButtonClick = fn end
            if ele.itm then ele.itm.OnItemLButtonClick = fn end
        else
            if ele.wnd then pcall(ele.wnd.OnLButtonClick) end
            if ele.itm then pcall(ele.wnd.OnItemLButtonClick) end
        end
    end
    return self
end

--[[ hover 鼠标悬停事件
    same as jQuery.hover()
    :hover(fnHover[, fnLeave]) 绑定
]]
function _MY.UI:hover(fnHover, fnLeave)
    fnLeave = fnLeave or fnHover
    if fnHover then
        for _, ele in pairs(self.eles) do
            if ele.wnd then ele.wnd.OnMouseEnter = function() fnHover(true) end end
            if ele.wnd then ele.wnd.OnMouseLeave = function() fnLeave(false) end end
            if ele.itm then ele.itm.OnItemMouseEnter = function() fnHover(true) end end
            if ele.itm then ele.itm.OnItemMouseLeave = function() fnLeave(false) end end
        end
    end
    return self
end

--[[ check 复选框状态变化
    :check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) 绑定
    :check()                返回是否已勾选
    :check(bool bChecked)   勾选/取消勾选
]]
function _MY.UI:check(fnCheck, fnUncheck)
    fnUncheck = fnUncheck or fnCheck
    if type(fnCheck)=="function" then
        for _, ele in pairs(self.eles) do
            if ele.chk then ele.chk.OnCheckBoxCheck = function() fnCheck(true) end end
            if ele.chk then ele.chk.OnCheckBoxUncheck = function() fnUncheck(false) end end
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
        -- try to get its name
        local status, err = pcall(function() return ele.chk:IsCheckBoxChecked() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err..'\n','ERROR _MY.UI:check' ,1) return nil end
    else
        MY.Debug('fnCheck:'..type(fnCheck)..' fnUncheck:'..type(fnUncheck)..'\n', 'ERROR _MY.UI:check' ,1)
    end
end

--[[ change 输入框文字变化
    :change(fnOnEditChanged) 绑定
    :change()   调用处理函数
]]
function _MY.UI:change(fnOnEditChanged)
    if fnOnEditChanged then
        for _, ele in pairs(self.eles) do
            if ele.edt then ele.edt.OnEditChanged = function() pcall(fnOnEditChanged,ele.edt:GetText()) end end
        end
        return self
    else
        for _, ele in pairs(self.eles) do
            if ele.edt then pcall(ele.edt.OnEditChanged) end
        end
        return self
    end
end

-- OnGetFocus 获取焦点

-----------------------------------------------------------
-- MY.UI
-----------------------------------------------------------

MY.UI = MY.UI or {}

-- 设置元表，这样可以当作函数调用，其效果相当于 MY.UI.Fetch
setmetatable(MY.UI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

--[[ 构造函数 类似jQuery: $(selector) ]]
MY.UI.Fetch = function(selector, tab) return _MY.UI.new(selector, tab) end

-- 打开浏览器
MY.UI.OpenInternetExplorer = function(szAddr, bDisableSound)
    local nIndex, nLast = nil, nil
    for i = 1, 10, 1 do
        if not _MY.UI.IsInternetExplorerOpened(i) then
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
    local x, y = _MY.UI.IE_GetNewIEFramePos()
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
-- 判断浏览器是否已开启
_MY.UI.IsInternetExplorerOpened = function(nIndex)
    local frame = Station.Lookup("Topmost/IE"..nIndex)
    if frame and frame:IsVisible() then
        return true
    end
    return false
end
-- 获取浏览器绝对位置
_MY.UI.IE_GetNewIEFramePos = function()
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

MY.Debug("ui plugins inited!\n",nil,0)