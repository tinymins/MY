--------------------------------------------
-- @Desc  : 扁平血条UI操作类
--          只做UI操作 不做任何逻辑判断
-- @Author: 翟一鸣 @tinymins
-- @Date  : 2015-03-02 10:08:35
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-05-14 10:27:36
--------------------------------------------
local l_handle
XLifeBar = XLifeBar or {}
XLifeBar.HP = class()
local HP = XLifeBar.HP

function HP:ctor(dwID) -- KGobject
	if not l_handle then
		l_handle = XGUI.GetShadowHandle("XLifeBar")
	end
	self.dwID = dwID
	self.handle = l_handle:Lookup(tostring(self.dwID))
	return self
end
-- 创建
function HP:Create()
	-- Create handle
	if not l_handle:Lookup(tostring(self.dwID)) then
		l_handle:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
	end

	local handle = l_handle:Lookup(tostring(self.dwID))
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
	if l_handle:Lookup(tostring(self.dwID)) then
		l_handle:RemoveItem(l_handle:Lookup(tostring(self.dwID)))
	end
	return self
end

-- 绘制名字/帮会/称号 等等 行文字
-- rgbaf: 红,绿,蓝,透明度,字体
-- tWordlines: {[文字,高度偏移],...}
function HP:DrawWordlines(tWordlines, rgbaf)
	if self.handle then
		local r,g,b,a,f = unpack(rgbaf)
		local sha = self.handle:Lookup(string.format("lines_%s",self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		for _, aWordline in ipairs(tWordlines) do
			if aWordline[1] and #aWordline[1] > 0 then
				sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
			end
		end
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

	if aWordline[1] and #aWordline[1] > 0 then
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, aWordline[2], - aWordline[3] }, f, aWordline[1], 1, 1)
	end
	return self
end

-- 绘制读条名称（减少重绘次数所以和Wordlines分离）
function HP:DrawOTTitle(aWordline, rgbaf)
	if self.handle then
		local r,g,b,a,f = unpack(rgbaf)
		local sha = self.handle:Lookup(string.format("ot_title_%s",self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		if aWordline[1] and #aWordline[1] > 0 then
			sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, aWordline[2], - aWordline[3] }, f, aWordline[1], 1, 1)
		end
	end
	return self
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, szShadowName, szShadowName2)
	if self.handle then
		nAlpha = nAlpha or 200
		nWidth   = nWidth * Station.GetUIScale()
		nHeight  = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		local handle = self.handle

		-- 绘制外边框
		local sha = handle:Lookup(string.format(szShadowName,self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX,bcY = - nWidth / 2 + nOffsetX, (- nHeight) - nOffsetY

		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY+nHeight})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+nHeight})

		-- 绘制内边框
		local sha = handle:Lookup(string.format(szShadowName2,self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX,bcY = - (nWidth / 2 - 1) + nOffsetX, (- (nHeight - 1)) - nOffsetY

		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY+(nHeight - 2)})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(nHeight - 2)})
	end
	return self
end

-- 填充血条边框 默认200的nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	return self:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, "hp_bg_%s", "hp_bg2_%s")
end
-- 填充读条边框 默认200的nAlpha
function HP:DrawOTBarBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	return self:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, "ot_bg_%s", "ot_bg2_%s")
end

-- 填充矩形（进度条/血条）
-- rgbap: 红,绿,蓝,透明度,进度,绘制方向
function HP:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, szShadowName)
	if self.handle then
		local r,g,b,a,p,d = unpack(rgbapd)
		nWidth   = nWidth * Station.GetUIScale()
		nHeight  = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		if not p or p > 1 then
			p = 1
		elseif p < 0 then
			p = 0
		end -- fix
		local sha = self.handle:Lookup(string.format(szShadowName,self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()

		-- 计算实际绘制宽度高度起始位置
		local bcX, bcY = - (nWidth / 2 - 2) + nOffsetX, (- (nHeight - 2)) - nOffsetY
		if d == "TOP_BOTTOM" then
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == "BOTTOM_TOP" then
			bcY = bcY + (nHeight - 4) * (1 - p)
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == "RIGHT_LEFT" then
			bcX = bcX + (nWidth - 4) * (1 - p)
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		else -- if d == "LEFT_RIGHT" then
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		end

		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX, bcY })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX + nWidth, bcY })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX + nWidth, bcY + nHeight })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX, bcY + nHeight })
	end
	return self
end

-- 填充血条
function HP:DrawLifeBar(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd)
	return self:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, "hp_%s")
end

-- 填充读条
function HP:DrawOTBar(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd)
	return self:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, "ot_%s")
end
