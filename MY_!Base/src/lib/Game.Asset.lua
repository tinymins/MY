--------------------------------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 游戏环境库
-- @copyright: Emil Zhai <root@zhaiyiming.com>
--------------------------------------------------------------------------------
---@class (partial) MY
local X = MY
--------------------------------------------------------------------------------
local MODULE_PATH = X.NSFormatString('{$NS}_!Base/lib/Game.Asset')
--------------------------------------------------------------------------------
--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'START')--[[#DEBUG END]]
--------------------------------------------------------------------------------
local _L = X.LoadLangPack(X.PACKET_INFO.FRAMEWORK_ROOT .. 'lang/lib/')
--------------------------------------------------------------------------------

do
local l_tGlobalEffect
function X.GetGlobalEffect(nID)
	if l_tGlobalEffect == nil then
		local szPath = 'represent\\common\\global_effect.txt'
		local tTitle = {
			{ f = 'i', t = 'nID'        },
			{ f = 's', t = 'szDesc'     },
			{ f = 'i', t = 'nPlayType'  },
			{ f = 'f', t = 'fPlaySpeed' },
			{ f = 'f', t = 'fScale'     },
			{ f = 's', t = 'szFilePath' },
			{ f = 'i', t = 'nWidth'     },
			{ f = 'i', t = 'nHeight'    },
		}
		l_tGlobalEffect = KG_Table.Load(szPath, tTitle, FILE_OPEN_MODE.NORMAL) or false
	end
	if not l_tGlobalEffect then
		return
	end
	local tLine = l_tGlobalEffect:Search(nID)
	if tLine then
		if not tLine.nWidth then
			tLine.nWidth = 0
		end
		if not tLine.nHeight then
			tLine.nHeight = 0
		end
	end
	return tLine
end
end

function X.GetCampImage(eCamp, bFight) -- ui\Image\UICommon\CommonPanel2.UITex
	local szUITex, nFrame
	if eCamp == CAMP.GOOD then
		if bFight then
			nFrame = 117
		else
			nFrame = 7
		end
	elseif eCamp == CAMP.EVIL then
		if bFight then
			nFrame = 116
		else
			nFrame = 5
		end
	end
	if nFrame then
		szUITex = 'ui\\Image\\UICommon\\CommonPanel2.UITex'
	end
	return szUITex, nFrame
end

-- 获取头像文件路径，帧序，是否动画
function X.GetMiniAvatar(dwAvatarID, nRoleType)
	-- mini avatar
	local RoleAvatar = X.GetGameTable('RoleAvatar', true)
	if RoleAvatar then
		local tInfo = RoleAvatar:Search(dwAvatarID)
		if tInfo then
			if nRoleType == ROLE_TYPE.STANDARD_MALE then
				return tInfo.szM2Image, tInfo.nM2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
				return tInfo.szF2Image, tInfo.nF2ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.STRONG_MALE then
				return tInfo.szM3Image, tInfo.nM3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.SEXY_FEMALE then
				return tInfo.szF3Image, tInfo.nF3ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
				return tInfo.szM1Image, tInfo.nM1ImgFrame, tInfo.bAnimate
			elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
				return tInfo.szF1Image, tInfo.nF1ImgFrame, tInfo.bAnimate
			end
		end
	end
end

-- 获取头像文件路径，帧序，是否动画
function X.GetForceAvatar(dwForceID)
	-- force avatar
	return X.Unpack(X.CONSTANT.FORCE_AVATAR[dwForceID])
end

-- 获取头像文件路径，帧序，是否动画
function X.GetPlayerAvatar(dwForceID, nRoleType, dwAvatarID)
	local szFile, nFrame, bAnimate
	-- mini avatar
	if dwAvatarID and dwAvatarID > 0 then
		szFile, nFrame, bAnimate = X.GetMiniAvatar(dwAvatarID, nRoleType)
	end
	-- force avatar
	if not szFile and dwForceID then
		szFile, nFrame, bAnimate = X.GetForceAvatar(dwForceID)
	end
	return szFile, nFrame, bAnimate
end

--[[#DEBUG BEGIN]]X.ReportModuleLoading(MODULE_PATH, 'FINISH')--[[#DEBUG END]]
