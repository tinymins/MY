--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 扁平血条UI操作类 只做UI操作 不做任何逻辑判断
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar_HP'
local PLUGIN_NAME = 'MY_LifeBar'
local PLUGIN_ROOT = X.PACKET_INFO.ROOT .. PLUGIN_NAME
local MODULE_NAME = 'MY_LifeBar'
local _L = X.LoadLangPack(PLUGIN_ROOT .. '/lang/')
--------------------------------------------------------------------------------
if not X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^28.0.1') then
	return
end
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------

local HP = class()
local CACHE = setmetatable({}, {__mode = 'v'})
local REQUIRE_SORT = false

function HP:ctor(dwType, dwID) -- KGobject
	local hList = X.UI.GetShadowHandle('MY_LifeBar')
	local szName = dwType .. '_' .. dwID
	self.szName = szName
	self.dwType = dwType
	self.dwID = dwID
	self.handle = hList:Lookup(self.szName)
	return self
end

function HP:IsHandleValid()
	return self.handle and self.handle:IsValid()
end

-- 创建
function HP:Create()
	if not self:IsHandleValid() then
		local hList = X.UI.GetShadowHandle('MY_LifeBar')
		hList:AppendItemFromString(FormatHandle(string.format('name="%s"', self.szName)))
		local hItem = hList:Lookup(self.szName)
		hItem:AppendItemFromString('<shadow>name="hp_bg"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp_bg2"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp"</shadow>')
		hItem:AppendItemFromString('<shadow>name="lines"</shadow>')
		hItem:AppendItemFromString('<shadow>name="hp_title"</shadow>')
		hItem:AppendItemFromString('<sfx>name="sfx"</sfx>')
		REQUIRE_SORT = true
		self.handle = hItem
	end
	return self
end

-- 删除
function HP:Remove()
	if self:IsHandleValid() then
		local hList = X.UI.GetShadowHandle('MY_LifeBar')
		hList:RemoveItem(self.handle)
		self.handle = nil
	end
	return self
end

function HP:SetPriority(nPriority)
	if self:IsHandleValid() then
		self.handle:SetUserData(nPriority)
		REQUIRE_SORT = true
	end
	return self
end

function HP:ClearShadow(szShadowName)
	if self:IsHandleValid() then
		local sha = self.handle:Lookup(szShadowName)
		if sha then
			sha:ClearTriangleFanPoint()
		end
	end
	return self
end

-- 绘制名字/帮会/称号 等等 行文字
function HP:DrawTexts(aTexts, nY, nLineHeight, r, g, b, a, f, spacing, scale)
	if self:IsHandleValid() then
		local sha = self.handle:Lookup('lines')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		for _, szText in ipairs(aTexts) do
			if szText ~= '' then
				sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, 0, -nY}, f, szText, spacing, scale / X.GetFontScale() / X.GetUIScale())
				nY =  nY + nLineHeight
			end
		end
	end
	return self
end

-- 绘制血量百分比文字（减少重绘次数所以和Wordlines分离）
function HP:DrawLifeText(text, x, y, r, g, b, a, f, spacing, scale)
	if self:IsHandleValid() then
		local sha = self.handle:Lookup('hp_title')
		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, x, -y}, f, text, spacing, scale / X.GetFontScale() / X.GetUIScale())
	end
	return self
end

function HP:ClearLifeText()
	return self:ClearShadow('hp_title')
end

-- 填充边框 默认200的nAlpha
function HP:DrawBorder(szShadowName, szShadowName2, nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
	if self:IsHandleValid() then
		nAlpha = nAlpha or 200
		local handle = self.handle

		-- 绘制外边框
		local sha = handle:Lookup(szShadowName)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -(nWidth / 2 + nBorder) + nOffsetX, -(nHeight / 2 + nBorder) - nOffsetY

		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX + nWidth + nBorder * 2, bcY})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX + nWidth + nBorder * 2, bcY + nHeight + nBorder * 2})
		sha:AppendCharacterID(self.dwID, true, nR, nG, nB, nAlpha, {0, 0, 0, bcX, bcY + nHeight + nBorder * 2})

		-- 绘制内边框
		local sha = handle:Lookup(szShadowName2)
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX, bcY = -nWidth / 2 + nOffsetX, -nHeight / 2 - nOffsetY

		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, 30, 30, 30, nAlpha, {0, 0, 0, bcX, bcY + nHeight})
	end
	return self
end

-- 填充血条边框 默认200的nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
	return self:DrawBorder('hp_bg', 'hp_bg2', nWidth, nHeight, nOffsetX, nOffsetY, nBorder, nR, nG, nB, nAlpha)
end
function HP:ClearLifeBorder()
	self:ClearShadow('hp_bg')
	self:ClearShadow('hp_bg2')
	return self
end

-- 填充矩形（进度条/血条）
-- rgbap: 红,绿,蓝,透明度,进度,绘制方向
function HP:DrawRect(szShadowName, nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
	if self:IsHandleValid() then
		nWidth = math.max(0, nWidth - nPadding * 2)
		nHeight = math.max(0, nHeight - nPadding * 2)
		if not p or p > 1 then
			p = 1
		elseif p < 0 then
			p = 0
		end -- fix
		local sha = self.handle:Lookup(szShadowName)

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()

		-- 计算实际绘制宽度高度起始位置
		local bcX, bcY = -nWidth / 2 + nOffsetX, -nHeight / 2 - nOffsetY
		if d == 'TOP_BOTTOM' then
			nWidth = nWidth
			nHeight = nHeight * p
		elseif d == 'BOTTOM_TOP' then
			bcY = bcY + nHeight * (1 - p)
			nWidth = nWidth
			nHeight = nHeight * p
		elseif d == 'RIGHT_LEFT' then
			bcX = bcX + nWidth * (1 - p)
			nWidth = nWidth * p
			nHeight = nHeight
		else -- if d == 'LEFT_RIGHT' then
			nWidth = nWidth * p
			nHeight = nHeight
		end

		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX + nWidth, bcY + nHeight})
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, {0, 0, 0, bcX, bcY + nHeight})
	end
	return self
end

-- 填充血条
function HP:DrawLifeBar(nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
	return self:DrawRect('hp', nWidth, nHeight, nOffsetX, nOffsetY, nPadding, r, g, b, a, p, d)
end

function HP:ClearLifeBar()
	return self:ClearShadow('hp')
end

-- 设置头顶特效
-- szFile 特效文件
-- fScale 特效缩放
-- nWidth 缩放后的特效UI宽度
-- nHeight 缩放后的特效UI高度
function HP:SetSFX(szFile, fScale, nWidth, nHeight, nOffsetY)
	if self:IsHandleValid() then
		local sfx = self.handle:Lookup('sfx')
		local szKey = 'MY_LIFEBAR_HP_SFX_' .. self.dwType .. '_' .. self.dwID
		local dwCtcType = self.dwType == TARGET.DOODAD and CTCT.DOODAD_POS_2_SCREEN_POS or CTCT.CHARACTER_TOP_2_SCREEN_POS
		if szFile then
			sfx:LoadSFX(szFile)
			sfx:SetModelScale(fScale)
			sfx:Play(true)
			sfx:Show()
			X.RenderCall(szKey, function()
				if sfx and sfx:IsValid() then
					local nX, nY, bFront = X.CThreadCoor(dwCtcType, self.dwID)
					nX, nY = Station.AdjustToOriginalPos(nX, nY)
					sfx:SetAbsPos(nX, nY - nHeight / 2 - nOffsetY)
				else
					X.CThreadCoor(dwCtcType, self.dwID, szKey, false)
					X.RenderCall(szKey, false)
				end
			end)
			X.CThreadCoor(dwCtcType, self.dwID, szKey, true)
		else
			sfx:Hide()
			X.RenderCall(szKey, false)
			X.CThreadCoor(dwCtcType, self.dwID, szKey, false)
		end
	end
	return self
end

function HP:ClearSFX()
	return self:SetSFX()
end

function HP:SetBalloon(szMsg, nStartTick, nDuring, nOffsetY)
	if self:IsHandleValid() then
		local balloon = self.handle:Lookup('balloon')
		local szKey = 'MY_LIFEBAR_HP_BALLOON_' .. self.dwType .. '_' .. self.dwID
		local dwCtcType = self.dwType == TARGET.DOODAD and CTCT.DOODAD_POS_2_SCREEN_POS or CTCT.CHARACTER_TOP_2_SCREEN_POS
		if not X.IsEmpty(szMsg) then
			if not balloon then
				self.handle:AppendItemFromString('<handle>name="balloon" handletype=0 <image>name="Image_Bg1" path="ui\\Image\\UICommon\\CommonPanel.UITex" frame=21 postype=0 imagetype=10</image><image>name="Image_Bg2" path="ui\\Image\\Common\\CommonPanel.UITex" frame=71 postype=0 disablescale=1</image><handle>name="content" x=15 y=10 handletype=4 valign=2 </handle></handle>')
				balloon = self.handle:Lookup('balloon')
			end
			local hContent = balloon:Lookup('content')
			hContent:Clear()
			hContent:SetW(350)
			hContent:AppendItemFromString(szMsg)
			hContent:SetSizeByAllItemSize()
			balloon:SetSize(math.max(hContent:GetW() + 30, 50), hContent:GetH() + 20)
			balloon:Lookup('Image_Bg1'):SetSize(balloon:GetSize())
			balloon:Lookup('Image_Bg2'):SetRelPos(math.min(balloon:GetW() * 3 / 4, balloon:GetW() - balloon:Lookup('Image_Bg2'):GetW() - 10), balloon:GetH() - 3)
			balloon:FormatAllItemPos()
			local nEndTick = nStartTick + nDuring
			local nAnimationTime = math.min(nDuring / 5, 1000)
			balloon:Show()
			balloon:SetAlpha(0)
			local nTick, nX, nY, bFront, nAni
			X.RenderCall(szKey, function()
				nTick = GetTime()
				if balloon and balloon:IsValid() and nTick <= nEndTick then
					nX, nY, bFront = X.CThreadCoor(dwCtcType, self.dwID)
					nX, nY = Station.AdjustToOriginalPos(nX, nY)
					balloon:SetAbsPos(nX - balloon:GetW() / 2, nY - nOffsetY - balloon:GetH())
					nAni = math.min((nTick - nStartTick) * 2, nEndTick - nTick) -- 出现比消失快一倍比较舒服
					balloon:SetAlpha(nAni > nAnimationTime and 255 or nAni / nAnimationTime * 255)
				else
					if balloon and balloon:IsValid() then
						balloon:Hide()
					end
					X.CThreadCoor(dwCtcType, self.dwID, szKey, false)
					X.RenderCall(szKey, false)
				end
			end)
			X.CThreadCoor(dwCtcType, self.dwID, szKey, true)
		else
			if balloon and balloon:IsValid() then
				balloon:Hide()
			end
			X.RenderCall(szKey, false)
			X.CThreadCoor(dwCtcType, self.dwID, szKey, false)
		end
	end
	return self
end

function HP:ClearBalloon()
	return self:SetBalloon()
end

function MY_LifeBar_HP(dwType, dwID)
	if dwType == 'clear' then
		CACHE = {}
		X.UI.GetShadowHandle('MY_LifeBar'):Clear()
	else
		local szName = dwType .. '_' .. dwID
		if not CACHE[szName] then
			CACHE[szName] = HP.new(dwType, dwID)
		end
		return CACHE[szName]
	end
end

do local hList
local function onBreathe()
	if REQUIRE_SORT then
		if not (hList and hList:IsValid()) then
			hList = X.UI.GetShadowHandle('MY_LifeBar')
		end
		hList:Sort()
		REQUIRE_SORT = false
	end
end
X.BreatheCall('MY_LifeBar_HP', onBreathe)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
