--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : ÏµÍ³º¯Êý¿â¡¤Æ´Òô
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------------------------------
local X = Boilerplate
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
do local PINYIN, PINYIN_CONSONANT
function X.Han2Pinyin(szText)
	if not X.IsString(szText) then
		return
	end
	if not PINYIN then
		PINYIN = X.LoadLUAData(X.PACKET_INFO.FRAMEWORK_ROOT .. 'data/pinyin/{$lang}.jx3dat', { passphrase = false })
		local tPinyinConsonant = {}
		for c, v in pairs(PINYIN) do
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
		PINYIN_CONSONANT = tPinyinConsonant
	end
	local aText = X.SplitString(szText, '')
	local aFull, nFullCount = {''}, 1
	local aConsonant, nConsonantCount = {''}, 1
	for _, szChar in ipairs(aText) do
		local aCharPinyin = PINYIN[szChar]
		if aCharPinyin and #aCharPinyin > 0 then
			for i = 2, #aCharPinyin do
				for j = 1, nFullCount do
					table.insert(aFull, aFull[j] .. aCharPinyin[i])
				end
			end
			for j = 1, nFullCount do
				aFull[j] = aFull[j] .. aCharPinyin[1]
			end
			nFullCount = nFullCount * #aCharPinyin
		else
			for j = 1, nFullCount do
				aFull[j] = aFull[j] .. szChar
			end
		end
		local aCharPinyinConsonant = PINYIN_CONSONANT[szChar]
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
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
