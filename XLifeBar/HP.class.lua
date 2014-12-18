--
-- 扁平血条UI操作类
-- 只做UI操作 不做任何逻辑判断
--
XLifeBar = XLifeBar or {}
XLifeBar.HP = class()
local HP = XLifeBar.HP

function HP:ctor(dwID, frame, handle) -- KGobject
    self.dwID = dwID
    self.frame = frame
    self.handle = handle
    return self
end
-- 创建
function HP:Create()
    -- Create handle
    local frame = self.frame
    if not frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
    end
    
    local handle = frame:Lookup("",tostring(self.dwID))
    if not handle:Lookup(string.format("hp_bg_%s",self.dwID)) then
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg2_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"lines_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"hp_title_%s\"</shadow>",self.dwID) )
        handle:AppendItemFromString( string.format("<shadow>name=\"ot_title_%s\"</shadow>",self.dwID) )
    end
    self.handle = handle
    return self
end

-- 删除
function HP:Remove()
    local frame = self.frame
    if frame:Lookup("",tostring(self.dwID)) then
        local Total = frame:Lookup("","")
        Total:RemoveItem(frame:Lookup("",tostring(self.dwID)))        
    end
    return self
end

-- 绘制名字/帮会/称号 等等 行文字
-- rgbaf: 红,绿,蓝,透明度,字体
-- tWordlines: {[文字,高度偏移],...}
function HP:DrawWordlines(tWordlines, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("lines_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    for _, aWordline in ipairs(tWordlines) do
        sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
    end
    return self
end

-- 绘制血量百分比文字（减少重绘次数所以和Wordlines分离）
function HP:DrawLifePercentage(aWordline, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("hp_title_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
end

-- 绘制读条名称（减少重绘次数所以和Wordlines分离）
function HP:DrawOTTitle(aWordline, rgbaf)
    if not self.handle then
        return
    end
    local r,g,b,a,f = unpack(rgbaf)
    local sha = self.handle:Lookup(string.format("ot_title_%s",self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
    sha:ClearTriangleFanPoint()
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
    
    return self
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, szShadowName, szShadowName2)
    if not self.handle then
        return
    end
    nAlpha = nAlpha or 200
    local handle = self.handle
    
    -- 绘制外边框
    local sha = handle:Lookup(string.format(szShadowName,self.dwID))
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()
    local bcX,bcY = - nWidth / 2 ,(- nHeight) - nOffsetY

    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY+nHeight})
    sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+nHeight})

    -- 绘制内边框
    local sha = handle:Lookup(string.format(szShadowName2,self.dwID))
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()        
    local bcX,bcY = - (nWidth / 2 - 1),(- (nHeight - 1)) - nOffsetY

    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY+(nHeight - 2)})
    sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(nHeight - 2)})        

    return self
end

-- 填充血条边框 默认200的nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetY, nAlpha)
    return self:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, "hp_bg_%s", "hp_bg2_%s")
end
-- 填充读条边框 默认200的nAlpha
function HP:DrawOTBarBorder(nWidth, nHeight, nOffsetY, nAlpha)
    return self:DrawBorder(nWidth, nHeight, nOffsetY, nAlpha, "ot_bg_%s", "ot_bg2_%s")
end

-- 填充矩形（进度条/血条）
-- rgbap: 红,绿,蓝,透明度,进度
function HP:DrawRect(nWidth, nHeight, nOffsetY, rgbap, szShadowName)
    if not self.handle then
        return
    end
    local r,g,b,a,p = unpack(rgbap)
    if p > 1 then p = 1 elseif p < 0 then p = 0 end -- fix
    local sha = self.handle:Lookup(string.format(szShadowName,self.dwID))
    
    sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
    sha:SetD3DPT(D3DPT.TRIANGLEFAN)
    sha:ClearTriangleFanPoint()
    
    local bcX,bcY = - (nWidth / 2 - 2),(- (nHeight - 2)) - nOffsetY
    nWidth = (nWidth - 4) * p -- 计算实际绘制宽度
    
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX,bcY})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX+nWidth,bcY})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX+nWidth,bcY+(nHeight - 4)})
    sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,bcX,bcY+(nHeight - 4)})
    
    return self
end

-- 填充血条
function HP:DrawLifebar(nWidth, nHeight, nOffsetY, rgbap)
    return self:DrawRect(nWidth, nHeight, nOffsetY, rgbap, "hp_%s")
end

-- 填充读条
function HP:DrawOTBar(nWidth, nHeight, nOffsetY, rgbap)
    return self:DrawRect(nWidth, nHeight, nOffsetY, rgbap, "ot_%s")
end