--------------------------------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.zhaiyiming.com/
-- @desc     : 扁平血条类 只做UI渲染控制
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@zhaiyiming.com)
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = 'MY_LifeBar/MY_LifeBar_LB'
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

local LB = class()
local HP = MY_LifeBar_HP
local CACHE = setmetatable({}, { __mode = 'v' })

local function InitConfigData(self)
	-- 配色
	self.r = 0
	self.g = 0
	self.b = 0
	self.a = 0
	self.cfx = nil
	self.font = 10
	self.scale = 1
	self.priority = 0
	self.priority_invalid = false
	-- 倒计时/名字/帮会/称号部分
	self.cd_visible = true
	self.cd_text = ''
	self.name_visible = true
	self.name_text = ''
	self.kungfu_visible = true
	self.kungfu_text = ''
	self.distance_visible = true
	self.distance = ''
	self.distance_fmt = ''
	self.tong_visible = true
	self.tong_text = ''
	self.title_visible = true
	self.title_text = ''
	self.texts_y = 100
	self.texts_height = 20
	self.texts_scale = 1
	self.texts_spacing = 1
	self.texts_invalid = true
	self.texts_lines = 0
	-- 血量部分
	self.life = 1
	self.max_life = 1
	-- 血量数值部分
	self.life_text_visible = true
	self.life_text_x = 0
	self.life_text_y = 42
	self.life_text_fmt = ''
	self.life_text_invalid = true
	-- 血条部分
	self.life_bar_visible = true
	self.life_bar_x = 0
	self.life_bar_y = 0
	self.life_bar_w = 0
	self.life_bar_h = 0
	self.life_bar_padding = 0
	self.life_bar_direction = 'LEFT_RIGHT'
	self.life_bar_invalid = true
	self.life_bar_border = 0
	self.life_bar_border_r = 0
	self.life_bar_border_g = 0
	self.life_bar_border_b = 0
	self.life_bar_border_invalid = true
	-- 特效
	self.sfx_file = nil
	self.sfx_scale = 1
	self.sfx_w = 0
	self.sfx_h = 0
	self.sfx_invalid = true
	-- 泡泡
	self.balloon_msg = ''
	self.balloon_start = 0
	self.balloon_during = 0
	self.balloon_offset_y = 0
	self.balloon_invalid = true
end

-- 构造函数
function LB:ctor(dwType, dwID)
	self.type = dwType
	self.id = dwID
	self.hp = HP(dwType, dwID)
	InitConfigData(self)
	return self
end

-- 创建UI
function LB:Create()
	if not self.hp.handle then
		self.hp:Create()
		self:SetInvalid('sfx', true)
		self:SetInvalid('balloon', true)
		self:SetInvalid('texts', true)
		self:SetInvalid('priority', true)
		self:SetInvalid('life_text', true)
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

-- 删除UI
function LB:Remove()
	self.hp:Remove()
	return self
end

function LB:SetInvalid(key, force)
	if force or self[key .. '_visible'] ~= false then
		self[key .. '_invalid'] = true
	end
	return self
end

-- 重绘无效区域
function LB:Paint(force)
	if self.hp.handle then
		self:DrawLifeBorder(force)
		self:DrawLife(force)
		self:DrawTexts(force)
		self:ApplySFX(force)
		self:ApplyBalloon(force)
		self:ApplyPriority(force)
	end
	return self
end

function LB:SetColor(r, g, b, a)
	if self.r ~= r or self.g ~= g
	or self.b ~= b or self.a ~= a then
		self.r = r
		self.g = g
		self.b = b
		self.a = a
		self:SetInvalid('life_bar')
		self:SetInvalid('life_text')
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetColorFx(cfx)
	if self.cfx ~= cfx then
		self.cfx = cfx
		self:SetInvalid('life_bar')
		self:SetInvalid('life_text')
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetScale(scale)
	if self.scale ~= scale then
		self.scale = scale
		self:SetInvalid('sfx', true)
		self:SetInvalid('balloon', true)
		self:SetInvalid('texts', true)
		self:SetInvalid('life_text', true)
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetPriority(priority)
	if self.priority ~= priority then
		self.priority = priority
		self:SetInvalid('priority', true)
	end
	return self
end

function LB:ApplyPriority(force)
	if self.priority_invalid or force then
		self.hp:SetPriority(self.priority)
		self.priority_invalid = false
	end
	return self
end

function LB:SetFont(font)
	if self.font ~= font then
		self.font = font
		self:SetInvalid('life_text')
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTextsPos(y, height)
	if self.texts_y ~= y or self.texts_height ~= height then
		self.texts_y = y
		self.texts_height = height
		self:SetInvalid('sfx', true)
		self:SetInvalid('balloon', true)
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTextsScale(scale)
	if self.texts_scale ~= scale then
		self.texts_scale = scale
		self:SetInvalid('texts', true)
		self:SetInvalid('life_text', true)
	end
	return self
end

function LB:SetTextsSpacing(spacing)
	if self.texts_spacing ~= spacing then
		self.texts_spacing = spacing
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetNameVisible(visible)
	if self.name_visible ~= visible then
		self.name_visible = visible
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetCD(text)
	if self.cd_text ~= text then
		self.cd_text = text
		self:SetInvalid('texts', true)
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetName(text)
	if self.name_text ~= text then
		self.name_text = text
		self:SetInvalid('texts', true)
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetDistanceVisible(visible)
	if self.distance_visible ~= visible then
		self.distance_visible = visible
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetDistance(distance)
	if self.distance ~= distance then
		self.distance = distance
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetDistanceFmt(fmt)
	if self.distance_fmt ~= fmt then
		self.distance_fmt = fmt
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetKungfuVisible(visible)
	if self.kungfu_visible ~= visible then
		self.kungfu_visible = visible
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetKungfu(text)
	if self.kungfu_text ~= text then
		self.kungfu_text = text
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTitleVisible(visible)
	if self.title_visible ~= visible then
		self.title_visible = visible
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTitle(text)
	if self.title_text ~= text then
		self.title_text = text
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTongVisible(visible)
	if self.tong_visible ~= visible then
		self.tong_visible = visible
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:SetTong(text)
	if self.tong_text ~= text then
		self.tong_text = text
		self:SetInvalid('texts', true)
	end
	return self
end

function LB:DrawTexts(force)
	if self.texts_invalid or force then
		local aTexts = {}
		local r, g, b, a, f = self.r, self.g, self.b, self.a, self.font
		if self.cfx then
			r, g, b, a = self.cfx(r, g, b, a)
		end
		if self.tong_visible and self.tong_text ~= '' then
			table.insert(aTexts, '[' .. self.tong_text .. ']')
		end
		if self.title_visible and self.title_text ~= '' then
			table.insert(aTexts, '<' .. self.title_text .. '>')
		end
		local text = ''
		if self.name_visible then
			if self.name_text and self.name_text ~= '' then
				text = text .. self.name_text
			end
			if self.kungfu_visible and self.kungfu_text and self.kungfu_text ~= '' then
				if text ~= '' then
					text = text .. _L.SPLIT_DOT
				end
				text = text .. self.kungfu_text
			end
			if self.distance_visible and self.distance and self.distance ~= 0 then
				if text ~= '' then
					text = text .. _L.SPLIT_DOT
				end
				text = text .. self.distance_fmt:format(self.distance)
			end
			table.insert(aTexts, text)
		end
		if self.cd_visible and self.cd_text ~= '' then
			table.insert(aTexts, self.cd_text)
		end
		self.hp:DrawTexts(aTexts, self.texts_y * self.scale, self.texts_height * self.texts_scale * self.scale, r, g, b, a, f, self.texts_spacing, self.texts_scale * self.scale)
		-- 刷新与文本行数有关的东西
		local texts_lines = #aTexts
		if self.texts_lines ~= texts_lines then
			self.texts_lines = texts_lines
			self:SetInvalid('sfx', true)
			self:SetInvalid('balloon', true)
		end
		self.texts_invalid = false
	end
	return self
end

-- 设置血量
function LB:SetLife(life, max_life)
	if self.life ~= life or self.max_life ~= max_life then
		self.life = life
		self.max_life = max_life
		self:SetInvalid('life_bar')
		self:SetInvalid('life_text')
	end
	return self
end

function LB:SetLifeBarVisible(life_bar_visible)
	if self.life_bar_visible ~= life_bar_visible then
		self.life_bar_visible = life_bar_visible
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetLifeBar(x, y, w, h, padding)
	if self.life_bar_x ~= x or self.life_bar_y ~= y or self.life_bar_w ~= w or self.life_bar_h ~= h or self.life_bar_padding ~= padding then
		self.life_bar_x = x
		self.life_bar_y = y
		self.life_bar_w = w
		self.life_bar_h = h
		self.life_bar_padding = padding
		self:SetInvalid('life_bar', true)
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetLifeBarBorder(n, r, g, b)
	if self.life_bar_border ~= n or self.life_bar_border_r ~= r or self.life_bar_border_g ~= g or self.life_bar_border_b ~= b then
		self.life_bar_border = n
		self.life_bar_border_r = r
		self.life_bar_border_g = g
		self.life_bar_border_b = b
		self:SetInvalid('life_bar_border', true)
	end
	return self
end

function LB:SetLifeTextVisible(life_text_visible)
	if self.life_text_visible ~= life_text_visible then
		self.life_text_visible = life_text_visible
		self:SetInvalid('life_text', true)
	end
	return self
end

function LB:SetLifeText(x, y, fmt)
	if self.life_text_x ~= x or self.life_text_y ~= y or self.life_text_fmt ~= fmt then
		self.life_text_x = x
		self.life_text_y = y
		self.life_text_fmt = fmt
		self:SetInvalid('life_text', true)
	end
	return self
end

-- 血条边框
function LB:DrawLifeBorder(force)
	if self.life_bar_border_invalid or force then
		if self.life_bar_visible then
			self.hp:DrawLifeBorder(
				self.life_bar_w * self.scale, self.life_bar_h * self.scale,
				self.life_bar_x * self.scale, self.life_bar_y * self.scale,
				self.life_bar_border,
				self.life_bar_border_r, self.life_bar_border_g, self.life_bar_border_b, self.a
			)
		else
			self.hp:ClearLifeBorder()
		end
		self.life_bar_border_invalid = false
	end
	return self
end

function LB:DrawLife(force)
	if self.life_bar_invalid or self.life_bar_border_invalid or self.life_text_invalid or force then
		local r, g, b, a, f = self.r, self.g, self.b, self.a, self.font
		if self.cfx then
			r, g, b, a = self.cfx(r, g, b, a)
		end
		if self.life_bar_invalid or force then
			if self.life_bar_visible then
				self.hp:DrawLifeBar(
					self.life_bar_w * self.scale, self.life_bar_h * self.scale,
					self.life_bar_x * self.scale, self.life_bar_y * self.scale,
					self.life_bar_padding, r, g, b, a,
					self.life / self.max_life, self.life_bar_direction
				)
			else
				self.hp:ClearLifeBar()
			end
			self.life_bar_invalid = false
		end
		if self.life_text_invalid or force then
			if self.life_text_visible then
				self.hp:DrawLifeText(
					self.life_text_fmt:format(100 * self.life / self.max_life),
					self.life_text_x * self.scale, self.life_text_y * self.scale,
					r, g, b, a, f,
					self.texts_spacing, self.texts_scale * self.scale
				)
			else
				self.hp:ClearLifeText()
			end
			self.life_text_invalid = false
		end
	end
	return self
end

function LB:SetSFX(file, scale, y, w, h)
	if self.sfx_file ~= file or self.sfx_y ~= y
	or self.sfx_scale ~= scale or self.sfx_w ~= w or self.sfx_h ~= h then
		self.sfx_file = file
		self.sfx_scale = scale or 0
		self.sfx_y = y or 0
		self.sfx_w = w or 0
		self.sfx_h = h or 0
		self:SetInvalid('sfx', true)
	end
	return self
end

function LB:ClearSFX()
	return self:SetSFX()
end

function LB:ApplySFX(force)
	if self.sfx_invalid or force then
		if self.sfx_file then
			self.hp:SetSFX(
				self.sfx_file,
				self.sfx_scale / Station.GetUIScale() * self.scale,
				self.sfx_w * self.sfx_scale / Station.GetUIScale() * self.scale,
				self.sfx_h * self.sfx_scale / Station.GetUIScale() * self.scale,
				(self.texts_y + self.texts_height * self.texts_scale * self.texts_lines + self.sfx_y) / Station.GetUIScale() * self.scale
			)
		else
			self.hp:ClearSFX()
		end
		self.sfx_invalid = false
	end
	return self
end

function LB:SetBalloon(msg, tick, during, offset_y)
	if self.balloon_msg ~= msg or self.balloon_start ~= tick or self.balloon_offset_y ~= offset_y then
		self.balloon_msg = msg
		self.balloon_start = tick
		self.balloon_during = during
		self.balloon_offset_y = offset_y
		self:SetInvalid('balloon', true)
	end
	return self
end

function LB:ClearBalloon()
	return self:SetBalloon()
end

function LB:ApplyBalloon(force)
	if self.balloon_invalid or force then
		if self.balloon_msg then
			self.hp:SetBalloon(
				self.balloon_msg,
				self.balloon_start,
				self.balloon_during,
				self.sfx_h * self.sfx_scale / Station.GetUIScale() * self.scale
				+ (self.texts_y
					+ self.texts_height * self.texts_scale * self.texts_lines
					+ self.sfx_y
					+ self.balloon_offset_y) / Station.GetUIScale() * self.scale
			)
		else
			self.hp:ClearBalloon()
		end
		self.balloon_invalid = false
	end
	return self
end

function MY_LifeBar_LB(dwType, dwID)
	if dwType == 'clear' then
		CACHE = {}
		HP('clear')
	else
		local szName = dwType .. '_' .. dwID
		if not CACHE[szName] then
			CACHE[szName] = LB.new(dwType, dwID)
		end
		return CACHE[szName]
	end
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
