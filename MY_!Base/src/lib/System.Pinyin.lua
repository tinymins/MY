--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ÏµÍ³º¯Êý¿â¡¤Æ´Òô
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/System.Pinyin')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

-----------------------------------------------
-- ºº×Ö×ªÆ´Òô
-----------------------------------------------
local TONE_PATH = X.PACKET_INFO.ROOT .. X.NSFormatString('{$NS}_Resource') .. '/data/pinyin/tone.{$lang}.jx3dat'
local TONELESS_PATH = X.PACKET_INFO.ROOT .. X.NSFormatString('{$NS}_Resource') .. '/data/pinyin/toneless.{$lang}.jx3dat'
local TONE_PINYIN, TONE_PINYIN_CONSONANT
local TONELESS_PINYIN, TONELESS_PINYIN_CONSONANT

local function ConcatPinyin(szText, szNext, szSplitter)
	if szText == '' then
		return szNext
	end
	if szNext == '' then
		return szText
	end
	return szText .. szSplitter .. szNext
end

local function Han2Pinyin(szText, bTone, szSplitter)
	if not X.IsString(szText) then
		return
	end
	if szSplitter == true then
		if bTone then
			szSplitter = _L['\'']
		else
			szSplitter = '\''
		end
	elseif not X.IsString(szSplitter) then
		szSplitter = ''
	end
	local tPinyin, tPinyinConsonant
	if bTone then
		tPinyin, tPinyinConsonant = TONE_PINYIN, TONE_PINYIN_CONSONANT
	else
		tPinyin, tPinyinConsonant = TONELESS_PINYIN, TONELESS_PINYIN_CONSONANT
	end
	if not tPinyin then
		tPinyin = select(2, X.SafeCall(X.LoadLUAData(bTone and TONE_PATH or TONELESS_PATH, { passphrase = false }), string)) or {}
		tPinyinConsonant = {}
		for c, v in pairs(tPinyin) do
			local a, t = {}, {}
			for _, s in ipairs(v) do
				s = s:sub(1, 1)
				if not t[s] then
					t[s] = true
					table.insert(a, s)
				end
			end
			tPinyinConsonant[c] = a
		end
		if bTone then
			TONE_PINYIN, TONE_PINYIN_CONSONANT = tPinyin, tPinyinConsonant
		else
			TONELESS_PINYIN, TONELESS_PINYIN_CONSONANT = tPinyin, tPinyinConsonant
		end
	end
	local aText = X.SplitString(szText, '')
	local aFull, nFullCount = {''}, 1
	local aConsonant, nConsonantCount = {''}, 1
	for _, szChar in ipairs(aText) do
		local aCharPinyin = tPinyin[szChar]
		if aCharPinyin and #aCharPinyin > 0 then
			for i = 2, #aCharPinyin do
				for j = 1, nFullCount do
					table.insert(aFull, ConcatPinyin(aFull[j], aCharPinyin[i], szSplitter))
				end
			end
			for j = 1, nFullCount do
				aFull[j] = ConcatPinyin(aFull[j], aCharPinyin[1], szSplitter)
			end
			nFullCount = nFullCount * #aCharPinyin
		else
			for j = 1, nFullCount do
				aFull[j] = ConcatPinyin(aFull[j], szChar, szSplitter)
			end
		end
		local aCharPinyinConsonant = tPinyinConsonant[szChar]
		if aCharPinyinConsonant and #aCharPinyinConsonant > 0 then
			for i = 2, #aCharPinyinConsonant do
				for j = 1, nConsonantCount do
					table.insert(aConsonant, aConsonant[j] .. aCharPinyinConsonant[i])
				end
			end
			for j = 1, nConsonantCount do
				aConsonant[j] = aConsonant[j] .. aCharPinyinConsonant[1]
			end
			nConsonantCount = nConsonantCount * #aCharPinyinConsonant
		else
			for j = 1, nConsonantCount do
				aConsonant[j] = aConsonant[j] .. szChar
			end
		end
	end
	return aFull, aConsonant
end

function X.Han2Pinyin(szText, szSplitter)
	if not X.IsString(szText) then
		return
	end
	return Han2Pinyin(szText, false, szSplitter)
end

function X.Han2TonePinyin(szText, szSplitter)
	if not X.IsString(szText) then
		return
	end
	return Han2Pinyin(szText, true, szSplitter)
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
