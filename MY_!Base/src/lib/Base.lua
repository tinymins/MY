--------------------------------------------------------
-- This file is part of the JX3 Plugin Project.
-- @desc     : 基础函数枚举
-- @copyright: Copyright (c) 2009 Kingsoft Co., Ltd.
--------------------------------------------------------
-- ###################################################################################################################################################### --
-- : :,,,,,,.,.,.,.,.,......   ;jXFPqq5kFUL2r:.: . ..,.,..... :;iiii:ii7;..........,...,,,,,,:,:,,,:::,:::,:::::::::,:::::::::,:::,:,:::::::::::::::::::. --
-- ,                         ,uXSSS1S2U2Uuuuu7i,::.           ........:::                         . . . . . . . . . . . . . . . . . . . . . . . . . . ..  --
-- : :.,.,.,.,.,.....,...  :q@M0Pq555F5515u2u2UuYj7:         :,,,:,::::i:: ........,...,.,.,.,,,,,.,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:. --
-- , ,,.,.,.............  7OMEPF515u2u2UULJJujJYY7v7r.  . ....,,,.,,:,:,,.................,.,.,.,.,.,,:,,.,,,,:,:,:,:,:.,,,,,,,.,.,.,.,,,.,,,,:,,,,,,,:,. --
-- , ,.,...............  uBEkSU2U1u2uUJuvjuuLL7v77r;ri,.,,..   . ..,,,,..,.................,.,.,.,.,.,.,.,.,.,.,.,.,,,.,.,..           ....,,,.,,,,,.,,,  --
-- , ,,.,...............v5XXF21U1uFU2JUUuJjvvr7rriii:::.            ..:.. . ..................,...,.,.,.,.,,,.,.,.,.,....   :,;i7YLv7:.    ...,.,.,.,,,,  --
-- , ,................ :Uk1q2Pk5u11uJ55uvuYYv7rrii::,,.              ...    ...................,.,.,.,.,.,.,,,.,.,.,..: ..iO@@BMB@B@B@MMqui  ..,.,.,.,.:  --
-- . .,..............  iPFuUXXX2jJuLJJJvL7v7v7rii::,.                 ...    .................,...,.,.,.,.,.,.,.,.,. 2;iPFNXNE08kYGUSO@B@@@k:  ...,.,.,,. --
-- , ,.,.............. rS1jU1FF1U12jvL7vv7r777ii::...                  ...   . ....................,.,.,.,.,...:,...:5EZL7uE1r   j@P   :7NB@Bq, .,.,.,,:  --
-- . ...,............  iSLYuuU11qXX5122jY7rii::.::,..                   ,,    ........................,.,.,.. ,L,. rEJUi:5S,   :BBJ::.    .S@BM: .,.,.,,. --
-- , ,.,.,............ ;UYvuYjUF555FkSuY7i::.....:.,.                   .:.    . ..................,.,.,.....i7,:..OJr:.Lk  7SB@u. .L@BF    r@Br ..,.,.,  --
-- . ...,............. :SYLY5U1uuLv77ri:,.,.. . .....                   .,,    ................ .......... ,Y,  :.,vi,. rLr,1B2E@BX...O@r:   2@O  ..,.,.  --
-- , ,................  71LUFFSJ7r:,.,......         .                   ,,:.  . ......... ....i:. ... . i;Zr  . ruL. ,.::,7:.:@BB::ri,:X@q. ,B@  .....,  --
-- . ..................  JkFX1jiii:,,.......  ....    .                 ..:::::, .......  :.. .7,1  r7:.,ii@v rrL5.k .70;ri:71@0: .iMB@8r.,, .MB: ......  --
-- , ,..................  u817:,.:::.....,,::i::,,.   .                ..,:iiiir  ..... ,NJ . ::iLvu rL7JFiv::..E7 S8: :jL :5PUr,rjS1::PB@Bu ;PBi ,F7v ,  --
-- . .................... :X0,..755J7ri:::::::i....   .               ..,::i7777i ..... vOr  ivurvPr SUrjL:,20ii;r,uJr:rGPv : :r..:u@X   i,  8PX. .FL:.,. --
-- , ,...................  :E7 :vLriirr7i..:i7r:..   .               ..,:r,  ,ivL, ......:.  .Ui7ULY:r ;2jvu1B2JiL;v571vuikr7 i:rq7ii7i,    7B1, .,r...,  --
-- . .,..................   r5.:irvvu::iL   .::..       .           ..,::      .ii....... .,ii750i.i12,1iLv:v1O@8B8LJU:i, iNSiqJkviiru@@Br 1Ev. ......,.  --
-- , ,.....................  rr.:;i;:..iv.     ...   . .,.       ..,.:::i.   .   ..........,::i: .::i::,,.,:...,.....,,,:5UNur:,.:::..  :0BO:. ..,...,.,  --
-- . .,.,.................... :..::...:7:..   .,,.......:,......:::::,,:i:  . . ...........       ..  ..  .. ..   ..  . .::.. . .  .i7j0@Pi. .,.,.,.,.,,. --
-- , ,.,......................  .i:...ir.:. :, .,,.... ,ri::::.:::,:,::i,. ..........................,.,.,...,.,.,.,,,.....:i7rUX55qGP7:   ....,.,.,.,.:  --
-- . .,......................   .,ri:,LvjU;,,.  ..,.... rri::::::,:::::i, ..........................,.....,.....,.,.,.,...... . ..      ....,.,.,.,.,.,,. --
-- , ,.....,.................  78:.rii;7;r::.:,::,.. :i ,viiii:i:i:i:iir  .........................,.,.....,.,.,...,.,...,.,....... .,.....,.,.,.,.,.,.,  --
-- . ...,.....................UMMOr.:ir7vvvri:::,.. :5:  77iri;iiiiiii7i  ............................,.,.,.,.,...,.,...,.,.,.,....i F,::.,.,.,.,.,.,.,,  --
-- , ,.,...,.,.,.,...........i75ZMBkiii7LLii:i,. . :52   :jLrr;ri;;r7LJ: . ........................,.,.,.,.,.,.,.,.,.,.,.,.,.,.,..,N 5 Lv .....,.,.,.,.,  --
-- , .,.,...,.,........       ,7BOMMGuriiii::.. ..:Yq: .  .i7LuYL7vrrii. ...........................,...,...,.,.,.,...,...,.,...,.,0.山Uv ..,.,.,.,.,..,  --
-- , ,.....,.,......   ..,,.rLL77OM8N0Fu7ri::::::irPu. .,,   .:,,uq:    ...........................,.,.....,.,.....,.,...,.,.......:::,i...,.,.,.....,.,  --
-- . .,.,.,...... ..:iu2v7juEFurrrMO0SSSkuUJJ77iirkq: .,,......  .Y:  . ..........................,...,.,...,.,...,.,.,.,.,.,.,....:,,,::...,.,.,.....,.. --
-- , ,.,.......::;71FkU7jZZM5r;rP:rBOEXXSS2j7;ii71U: ,,:...,.:::,...   . ............................,.,...,.,.,.,.,.,.,.,.,.,....,7;Y71r .,.,.,.......,  --
-- . ...,....,:i7LY7rirL5SE5::;kj;iiSPFuuuL77i:iv;,.,,:.,,:,:,,,::::::,   ........................,.,.,.,...,.,.,.,.,.,...,.,.,....rJ河vi ....,.,.,.,.,,. --
-- , ,.,....,::7ri:ir7Jv7u1r;iiSrv2kv7:.rr  :v7Lr .:,:,,,,,:,::::::::::::,  .........................,.,.,.,.,...,.,...,.,.,...,...5.::S:....,.,.....,.,  --
-- . .,.,...:::ir;7777YirLJrvr:iiuE;i:  v:. ,iru. ,,,,:,:::,:::,:::::,::::: ..............................,.,.,.,.,.,.........,.,..   ........,.,.,...,.  --
-- , ,.,...:rvr:r7ir;J7iivr;r7i:ivX  i  :. ...vJ.,,:::::,,::::,:i:,:,::::::: ........................,.,.,...,.,...... .   ....,...:FL:..............,.,  --
-- . .... .rvLS:ir;iru7:riiirri:7q@.....,:. ..Br .::::,.::::,,ii:,::ii::::i:. ....................,.,.,.........,.....rFrYu:........0:k: .............,,  --
-- , ,... iuvL07:;iir57iir;rrrii78i .:i.:r:...v,..::,,,::::::ii:,::iir,::i:i, .............................,.......,..vq華0: ..... rU九r7........,.....,  --
-- . ... .LYuL05riii7Lurrrr;7;riYS .;rv::::..   ..::,,:::,:,ii:i::;:ri,::i::: ......................,.............,...JjN1Si..... ,r  ,r; ..,.........,.  --
-- , ,.. 7uLjuS0ri:r7Lvr;rir;rii1Z :rri7:::,......::,:::,:,ii:ir,iiir:::ii:i:  ......................,.......,.,.,....,.i:.:...,.. ,. ,. ............,.,  --
-- . .. :LYjjJPM7:ir7vv;rr7rrrirZMJ::iirr,:.......::::::::ii::7i:;ii;:::i::ii ..................,.,.,...,.......,.....  ,   ..... :GS7EGr ..,.....,.,.,,  --
-- , .. vv7jj11@u:i7rv7rr7rri7iL088v:iiiri,,.....::::::::ii:::Yi:r:r:::i:::;:. ......................,.,...,.,...,.,..v U:,7 .... :Ok轉0v .,.,...,...,.,  --
-- . . .227vjSFO0,irr77irrri;r7r20OO7:;;r;:,.....:i:::::ii:::i2:ii7i::iri:iii ..............,...,.......,.,.,...,.,...0 山iu .,.,..uv:v5r ....,.,.,...,.  --
-- , . i7XJvJPFEMr:rrrr7r;iiirir7S0MMU:iirr:.,.. :7i:r:::iii:YL::r7::rriii:i:  ................,...,...,...,.....,....Si57JJ ..,..     . ..........,.,.,  --
-- . ..;rjXvjkqX@O;r7rrii:iiri;i77YJ8BZ7,:ii,....:Y,iriiiii:i27:ivLr7ri:i::i: ................,.........,...,........  .. , .......v7777 ...,.,...,.....  --
-- . . 7rvkuuPqkO@YvLL77vuu7i;irvr;iYG8Bj,:rr:,..:.,:irriii:rSi:rLrvriii:i:i: .....................,.,.....,......... i::7ir ..,...FL風1 ..,...,.,.,...,  --
-- . ..7r7FFUkZ58BkrFU1UUFkriirrur7rrFNN@2,:Lr,,::::::irrii:uu:ivv7;i:::::ii: ..............................,.....,...GJ絕Nv .... :FLk1Si ....,...,.,.,.  --
-- . .,Li72kUkqXN@B7LUJujkur:irv7ivYiFjFE@87i,,:::::::,irr:ik7:7v7i:,,,::::i.  ........................,.,.....,.... ,FukL72 .....::.,.7L .......,...,.,  --
-- . .:LrrUk55EPqM@Pvuuu1FJriivv7:vu;uL7FSG7irr::::::::::7755:7SL;rrrrrri:ii. ..............................,...,.,..,i.r::r....,....  . ...,.....,.....  --
-- . .:L;rYk2FPEqMBE71U1USvr:rL7;rr1v1L7Uui7ri7vi:::::::::2ZriYvir77rr;rriii ....................,.,.......,.....,.,.... ........ :MqUuk: .......,.....,  --
-- . .;LrrL5F2PZOB7.Uj5J12rrirYr7rrj2Fj1EEGYv7r7jri::::::.vU71krii::i:iirri:......................,.,.,.,.,.....,.,...U77k27 .... ,uL飄P: ..,.,.,.......  --
-- . iiJrr7151SOM8 rNu1jS1i7:7vrr7i7F05FPZ8@1YJvvjvri;i:::,,:SEi,i,::iiiiri: ..........................,.,.....,...,. i:頂uF ..,..,5LYrFu .,.,.,.,...,.,  --
--   riv7irYFFk8@U FOYUF0vr7i;v77r7i2Zu1kk0M@kYYLLF7rri::::,:.U0u7i,,:iiii;: ...........................,.........,...U:uvuu .,.....    ,.....,.,...,...  --
--  .riLvii7YkXMB: GZ5j05;rLiii777rruMLLJjuFB@XjuLuUi;i::i:::::7USFUr:::::r: ................,.......,.,.........,.,.,: .  :...,.. L7iiri..,.,.,...,...,  --
-- :LLr7LiLLJ2qOq  ZOS5Pj;LYrirrL77iuMLrYLu75O@01LvYJr2vi;i::::,:iFUU7::iir. .................,.......,.,.,.,...,.,.. ..:.: ..,.,..uP絮7i ,.,...,.,...,.  --
-- rrL;rLr7Y1EO@r  XBONFr7L1;iir7Yri7@j777uJ;Y0@ZFuL7vqSrvrr:iii::UOLi:iiri. ..............................,.,.,.,.,..2u坐ki...... 7GSY5...,...,.....,.,  --
-- ::;;;7ir7vJZ;   vME5777J1J:ri7J7iiMXiLL2UJrv0@G1LivE7iYvr;irr::,7M5i,iir ..............,.....,...,...,.,...,.,.,...7i01;:.......7rL:vi.....,.,.,...,.  --
-- ,.::1SL:rv1X.   jkXvLLYJUFvr;iYvi:SOirLj11uvL0@Mui2E;.Yv7riiL:i:.iPFr:ii .........................,...,.,.......,..iivrii.......  .  ...,.....,.,...,  --
-- v:iFXZOFi,,     kFUujUJuYU12virLii7Mii;vJ15uYjX@@1v82.;7i7rLji:iii7rUv:: ............,.....,.............,.,.,.....  . ....,.............,.,.,.,.,,,,. --
-- Yi7JLuNOEJ:,:  .XNkY1uuYjvJLuri7riiZr:7rLUXuuYu18BGUN17iirvjYLri7:777qL ..................,...,...,...,...,.,.,.,..u7rrii.,.,...,.,.,.,.,.,...,...,.,  --
-- 7i;JY7ivuFXPGO.70ZZ2YUu2UuJYvY;rrr:PLi7v7YuFUUJJj5GMqPku;iLuLSvrrr;7LU1 ...............,.,...,.,.,...,.,.,...,.,.. 7L忘r,..,.,...,...,.,.,...,.....,.. --
-- ::7;7rirYj2UNOuMMXE5juuuuu12Yr7r7rij5::r7rvLUu221uJuEZk5ur77uS177;rruLr ..............,.,.,.,.,.....,.,.,.,.,.....:LY;7Lv...,.....,...,.,...,.,.....,  --
--  :1Liiirir7L7PXO@OSujuJuYYLJJ7rvrrirOi:ii77vvju55k51YU5X5U7rJk5LLrivJ7  .................,.,.....,...,...,.,.,..... ,::. ..,.,.,.,.....,.,.....,...,.. --
-- . LL7;ririrr71FYGBBNFuuJuJjLuv;r7rr:O1.:iirrvvJjU5XqNS2uFSFvLU1LY;rYv. ...............,.,.,.....,.,.,...,.,...,.,. :.,:ii...,...,...,...,.,...,...,.,  --
-- . iJ777ri;rvLU1,v2EBOZSSUujuuurrir;iL@i::ii;irrvLuu5XE0q221X1Ujv7Li.  .................,.,.,...,.,.,.,.,.....,.,...0L經17 .,...,.,.,...,...,.,.,.,.,.. --
-- , .7LLYr;r7;rrX::ivY5FXSP52UUuLr;i;iiqG.::iiiii;77LLjukPqS12NEFL0Bi  .............,.....,.,...,.,.............,....S57Ju; ..,...,.,.,.,.,...,...,.,.,  --
-- , .:vY7i;ririiMGr:::irrvL2U1uuJY7rii:iMr:iii:i:::i;77LLu1Pkkk1.M@@B@E: ............,.,...........,.,...,...,...,..:vr;Yj:......,.,.,.....,.,...,...,.  --
-- : . irii7iri:i@B@Yi:,,,,::i;v7LLjLL77i55irrrriiii:i:iir7YUP2F: B@B@2  ........................,.,.,...,...,.,.,.,..  ...,...,.,.,.,...,.,.,.,.,.,.,.,  --
-- , ...Y7v77rr:i1@BB5NFYvv777rirvLLYLjJu5krv7YJjLjJUjJvj1k1Yr7i  @B@Br ..................,.........,.,.,.,.,.,.,.,.,.,.............,.,.,.,.,.,.,.,.,.,,. --
-- : ,..:vLLvL7riiu@BZO@B@BBOMOMOOGEE8GMB@PJ2SU1kq2Lv2qPuv:,...   B@B@J .........................,.,.,.,.,.,.,.,.,.,.,....     :::,.  ...,.,,,.,,,.,.,.,  --
-- , ,,..rX2uvr;r:,jGLvvuSGM@MBGZ0NSS112ZMk7Lu2v;vSqXvi:      .   kB@M  ..............,.........,.,.,.,.,,,,,.,,,.,.,... .ir7U5uJJuUu7: ..,.,.,.,.,.,.,,. --
-- : ,.. ,FquLLvii::77::,:,:irvFXqXkUUYYLFSL77LSS;::i.    .. .... 7@BE  .......................,.,.,,,,,,,,,,,.,,,,,.. ,vuF:M@.     .7k1, ...,.,.,.,.,.:  --
-- , .,.. :uYvv77ii::i::i...i   .:rLU5YJLiY::.       ,  . .. .... 7B@O  ..........................,.,.,.,.,.,.,,,.,.. v1LFZS@  .,2XUL  rEF. ..,.,,,.,.:,. --
-- : :.,.. 7ujvv7rir:ii:,:.r7..:.. ....vLLi77LYLJ   .......,....  ;@BB  .........................,.,.,.,.,.,.,.,.,.. 5Ui05LMS . E@1@B@L..PM,...,.,.,,,.,  --
-- , ,,.,...LYv77rri;:i:.  ,:.,:....:.18kii7J7.rMU  ,.:..,,   ... iB@B  ......................,.,.,.,.,.,.,.,.,.,., 7P:Mv7JMM ..:jUi .q7:.PO....,.,.,.,,. --
-- , ,,,.,. :Y7L7riiiiiUZF7:  :ii:::::207.,.   .58.......   ...   :@B@  .....................,.,.,.,.,.,.,.,.,.,....E,kki.5LBS.........;i;:@v..,.,.,.,,,  --
-- ,.,,.,....rLvv7L77:,.i7Lu7   . ,.::JGkri:::.i8Y..  .   ...     :B@B  ..........,.........,...,.,.,.,.,.,.,.,.,..:q.@L: :NYO@8L:,ii::irr:q0:..,.,.,.,,. --
-- : :,,.,., .LXPq0u7rii::,,,i.        iYF1vi:;7,  ...        ..   @B@  .........,.,.........,.,.,.,.,.,.,.,.,.,.. rP.BL,. .7uv2M@0i:rii;7:1Zi...,.,.,.,  --
-- ,.::,,,,.. ::..2k1L7rLLvri,:.          .        .,....   ..,..  @@@. ..................,.....,.,.,.,.,.,.,.,.,..:Z PS.  ivuMOY;B@ui77r: 5Gi,.,.,.,.,,. --
-- :.:,,,,,,..     uX1L77JuXkL::.  . .            .. ....,,:,.     8@@. ...,.....,...,...,.,.,.,.,.,.,.,.,.,.,.,... 8;.@: LGrUviMO uBJrJv, @ui...,.,.,,,  --
-- :.,:,:,,.,.....  i,.    .72urri        .       ....,,,..     .. v@B, ....,.,.....,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.. iB,rM.vPrO@P.q, B@rL7:OO7:..,,,.,.,,. --
-- :.:,,,,,,,,.,.,  .:....   :SPYv:      ..    . ..,,,.... .    .. rB@: .,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,,,,,,,.,,,.. rBjvZjkk5OM:iri0@i7jB8L:,.,.,.,.,,:  --
-- :.::,:,:,,.,.,.....:::,.   .r5jv,  ...,. . ..,.... ..      ...  i@B: ,.,.,,,.,,,.,,,,,,,,,.,,,,,,,,,.,,,,,.,,,,,,. :OM11u2257vLvL@UJG@Xvi,.,.,,,,,,:,. --
-- :.:::::,,,:,,.,....,:,,,.     ::......: ... . .   ... .   ... . :@@i .,.,.,.,,,.,,,,,,,,:,:,:,:,:,:,,,,,:,:,:,:,:,...rZMOX1u1FkE@B8MZJ7:..,,:,,,:,,,:. --
-- :.::,:,,,:,,,,,,....::,,,,...  ..... ,,  ... . ..... ... ..     r@Br ,.,,,.,.,.,,,,,,,,:,:,:,:,:,:,:,,,:,,,:,:,:,,,,...iJPEO8OZ011uvi:.,.,,:,:,:,:,::. --
-- :.:::,:,,,,,:,,,.,..:::::,..  . ......,...... ..,.      .   .   rB@7 .,.,.,,,.,,,,,,,,:,:,:::,:,:,:,:,:,:,,,,,,,:,:,,.....::iii::,:.....,,:,:,:,:,:,:. --
-- :.::::,:,,,:,,,,.:,ri:::::::.........,.... .....   . ...   .    :@@7  .,.,,,,,,,,:,,,,,:,:,:,:,,,:,,,,,,,:,:,:,,,:,::,,,...........,.,,:,:,:,:,:,:,:,. --
-- :.:::,:,:,:,:,,,.:i:77;:,,:,,...,,:,:::...,..     . . . ... .   rB@7 i: ,,:,,,,,,,:,,,,,:,:,:,:,:,:,:,:,:,:,:,,,:,:,:,:,:,:,,.,,,,:,,::,:,:,,,:,:,,,:. --
-- :.::::,:,:,:,,,,,,ii:irL77r7rri:,,,i7LJZL:.                  .. v@BMu@u .,,:,,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,. --
-- :.:::::::::::,:::.:ii:iirrr;7rr7rirr7ii7Err::,:,:::,,,:::,..,.. UBM@@B@. .:,:,:::,:,:,:,:,:,:,:::::::::::::::::::::::::::::::::::::::::::::,:::::::::. --
-- : ............ ... ,,,.,..         .:;i:rir7rr;rii::..          k@BF :O@J. . ........................................................................  --
-- ###################################################################################################################################################### --

-------------------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-------------------------------------------------------------------------------------------------------
local ipairs, pairs, next, pcall, select = ipairs, pairs, next, pcall, select
local string, math, table = string, math, table
-------------------------------------------------------------------------------------------------------
-- wstring 修正
-------------------------------------------------------------------------------------------------------
local wsub = _G.wstring.sub
local wstring = setmetatable({}, {
	__index = function(t, k)
		local v = _G.wstring[k]
		t[k] = v
		return v
	end,
})
wstring.find = StringFindW
wstring.sub = function(str, s, e)
	local nLen = wstring.len(str)
	if s < 0 then
		s = nLen + s + 1
	end
	if not e then
		e = nLen
	elseif e < 0 then
		e = nLen + e + 1
	end
	return wsub(str, s, e)
end
wstring.gsub = StringReplaceW
wstring.lower = StringLowerW
-------------------------------------------------------------------------------------------------------
-- 测试等级
-------------------------------------------------------------------------------------------------------
local DEBUG_LEVEL = SetmetaReadonly({
	PMLOG   = 0,
	LOG     = 1,
	WARNING = 2,
	ERROR   = 3,
	DEBUG   = 3,
	NONE    = 4,
})
-------------------------------------------------------------------------------------------------------
-- 游戏语言、游戏运营分支编码、游戏发行版编码、游戏版本号
-------------------------------------------------------------------------------------------------------
local _GAME_LANG_, _GAME_BRANCH_, _GAME_EDITION_, _GAME_VERSION_
local _GAME_PROVIDER_ = 'local'
do
	local szVersionLineFullName, szVersion, szVersionLineName, szVersionEx, szVersionName = GetVersion()
	_GAME_LANG_ = string.lower(szVersionLineName)
	if _GAME_LANG_ == 'classic' then
		_GAME_LANG_ = 'zhcn'
	end
	_GAME_BRANCH_ = string.lower(szVersionLineName)
	if _GAME_BRANCH_ == 'zhcn' then
		_GAME_BRANCH_ = 'remake'
	elseif _GAME_BRANCH_ == 'zhtw' then
		_GAME_BRANCH_ = 'intl'
	end
	_GAME_EDITION_ = string.lower(szVersionLineName .. '_' .. szVersionEx)
	_GAME_VERSION_ = string.lower(szVersion)

	if SM_IsEnable then
		local status, res = pcall(SM_IsEnable)
		if status and res then
			_GAME_PROVIDER_ = 'remote'
		end
	end
end
-------------------------------------------------------------------------------------------------------
-- 本地函数变量
-------------------------------------------------------------------------------------------------------
local _BUILD_                 = '20220429'
local _VERSION_               = '11.0.3'
local _MENU_COLOR_            = {255, 165, 79}
local _INTERFACE_ROOT_        = 'Interface/'
local _NAME_SPACE_            = 'MY'
local _ADDON_ROOT_            = _INTERFACE_ROOT_ .. _NAME_SPACE_ .. '/'
local _DATA_ROOT_             = (_GAME_PROVIDER_ == 'remote' and (GetUserDataFolder() .. '/' .. GetUserAccount() .. '/interface/') or _INTERFACE_ROOT_) .. _NAME_SPACE_ .. '#DATA/'
local _FRAMEWORK_ROOT_        = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_!Base/'
local _UICOMPONENT_ROOT_      = _FRAMEWORK_ROOT_ .. 'ui/components/'
local _LOGO_UITEX_            = _FRAMEWORK_ROOT_ .. 'img/Logo.UITex'
local _LOGO_MAIN_FRAME_       = 0
local _LOGO_MENU_FRAME_       = 1
local _LOGO_MENU_HOVER_FRAME_ = 2
local _POSTER_UITEX_          = _ADDON_ROOT_ .. _NAME_SPACE_ .. '_Resource/img/Poster.UITex'
local _POSTER_FRAME_COUNT_    = 2
local _DEBUG_LEVEL_           = tonumber(LoadLUAData(_DATA_ROOT_ .. 'debug.level.jx3dat') or nil) or DEBUG_LEVEL.NONE
local _DELOG_LEVEL_           = math.min(tonumber(LoadLUAData(_DATA_ROOT_ .. 'delog.level.jx3dat') or nil) or DEBUG_LEVEL.NONE, _DEBUG_LEVEL_)
-------------------------------------------------------------------------------------------------------
-- 其它环境变量
-------------------------------------------------------------------------------------------------------
local _SERVER_ADDRESS_ = select(7, GetUserServer())
local _RUNTIME_OPTIMIZE_ = --[[#DEBUG BEGIN]](
	(IsDebugClient() or debug.traceback ~= nil)
	and _DEBUG_LEVEL_ == DEBUG_LEVEL.NONE
	and _DELOG_LEVEL_ == DEBUG_LEVEL.NONE
	and not IsLocalFileExist(_ADDON_ROOT_ .. 'secret.jx3dat')
) and not IsLocalFileExist(_DATA_ROOT_ .. 'no.runtime.optimize.jx3dat') or --[[#DEBUG END]]false

-------------------------------------------------------------------------------------------------------
-- 初始化调试工具
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 数据设为只读
-----------------------------------------------
local SetmetaReadonly = SetmetaReadonly
if not SetmetaReadonly then
	SetmetaReadonly = function(t)
		for k, v in pairs(t) do
			if type(v) == 'table' then
				t[k] = SetmetaReadonly(v)
			end
		end
		return setmetatable({}, {
			__index     = t,
			__newindex  = function() assert(false, 'table is readonly\n') end,
			__metatable = {
				const_table = t,
			},
		})
	end
end
local function SetmetaLazyload(t, _keyLoader, fallbackLoader)
	local keyLoader = {}
	for k, v in pairs(_keyLoader) do
		keyLoader[k] = v
	end
	return setmetatable(t, {
		__index = function(t, k)
			local loader = keyLoader[k]
			if loader then
				keyLoader[k] = nil
				if not next(keyLoader) then
					setmetatable(t, nil)
				end
			else
				loader = fallbackLoader
			end
			if loader then
				local v = loader(k)
				t[k] = v
				return v
			end
		end,
	})
end
local SHARED_MEMORY = _G.PLUGIN_SHARED_MEMORY
if type(SHARED_MEMORY) ~= 'table' then
	SHARED_MEMORY = {}
	_G.PLUGIN_SHARED_MEMORY = SHARED_MEMORY
end
---------------------------------------------------
-- 调试工具
---------------------------------------------------
local function ErrorLog(...)
	local aLine, xLine = {}, nil
	for i = 1, select('#', ...) do
		xLine = select(i, ...)
		aLine[i] = tostring(xLine)
	end
	local szFull = table.concat(aLine, '\n') .. '\n'
	Log('MSG_SYS', szFull)
	FireUIEvent('CALL_LUA_ERROR', szFull)
end
if _DEBUG_LEVEL_ < DEBUG_LEVEL.NONE then
	if not SHARED_MEMORY.ECHO_LUA_ERROR then
		RegisterEvent('CALL_LUA_ERROR', function()
			OutputMessage('MSG_SYS', 'CALL_LUA_ERROR:\n' .. arg0 .. '\n')
		end)
		SHARED_MEMORY.ECHO_LUA_ERROR = _NAME_SPACE_
	end
	if not SHARED_MEMORY.RELOAD_UI_ADDON then
		TraceButton_AppendAddonMenu({{
			szOption = 'ReloadUIAddon',
			fnAction = function()
				ReloadUIAddon()
			end,
		}})
		SHARED_MEMORY.RELOAD_UI_ADDON = _NAME_SPACE_
	end
end
Log('[' .. _NAME_SPACE_ .. '] Debug level ' .. _DEBUG_LEVEL_ .. ' / delog level ' .. _DELOG_LEVEL_)
-------------------------------------------------------------------------------------------------------
-- 加载语言包
-------------------------------------------------------------------------------------------------------
local function LoadLangPack(szLangFolder)
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/default') or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/' .. _GAME_LANG_) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder)=='string' then
		szLangFolder = string.gsub(szLangFolder,'[/\\]+$','')
		local t2 = LoadLUAData(szLangFolder..'/default') or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		local t3 = LoadLUAData(szLangFolder..'/' .. _GAME_LANG_) or {}
		for k, v in pairs(t3) do
			t0[k] = v
		end
	end
	setmetatable(t0, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t0
end
local _L = LoadLangPack(_FRAMEWORK_ROOT_ .. 'lang/lib/')
local _NAME_             = _L.PLUGIN_NAME
local _SHORT_NAME_       = _L.PLUGIN_SHORT_NAME
local _AUTHOR_           = _L.PLUGIN_AUTHOR
local _AUTHOR_WEIBO_     = _L.PLUGIN_AUTHOR_WEIBO
local _AUTHOR_WEIBO_URL_ = 'https://weibo.com/zymah'
local _AUTHOR_SIGNATURE_ = _L.PLUGIN_AUTHOR_SIGNATURE
local _AUTHOR_ROLES_     = {
	[ 3007396] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 梦江南
	[28564812] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1), -- 茗伊伊 梦江南
	[ 1600498] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 追风蹑影
	[ 4664780] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 日月明尊
	[17796954] = string.char(0xDC, 0xF8, 0xD2, 0xC1, 0x40, 0xB0, 0xD7, 0xB5, 0xDB, 0xB3, 0xC7), -- 茗伊@白帝城 梦江南
	[  385183] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A), -- 茗伊 傲血戰意
	[ 1452025] = string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A), -- 茗伊伊 巔峰再起
	[    1028] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 缘起稻香@缘起一区
	[     660] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 梦回长安@缘起一区
	[     280] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 烟雨扬州@缘起一区
	[     143] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 神都洛阳@缘起一区
	[    1259] = string.char(0xDC, 0xF8, 0xD2, 0xC1), -- 茗伊 天宝盛世@缘起一区
}
local _AUTHOR_HEADER_ = GetFormatText(_NAME_ .. ' ' .. _L['[Author]'], 8, 89, 224, 232)
local _AUTHOR_PROTECT_NAMES_ = {
	[string.char(0xDC, 0xF8, 0xD2, 0xC1)] = true, -- 简体
	[string.char(0xDC, 0xF8, 0xD2, 0xC1, 0xD2, 0xC1)] = true, -- 简体
	[string.char(0XE8, 0X8C, 0X97, 0XE4, 0XBC, 0X8A)] = true, -- 繁体
	[string.char(0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A)] = true, -- 繁体
}
local _AUTHOR_FAKE_HEADER_ = GetFormatText(_L['[Fake author]'], 8, 255, 95, 159)
-------------------------------------------------------------------------------------------------------
-- 通用函数
-------------------------------------------------------------------------------------------------------
-----------------------------------------------
-- 三元运算
-----------------------------------------------
local IIf = function(expr, truepart, falsepart)
	if expr then
		return truepart
	end
	return falsepart
end
-----------------------------------------------
-- 克隆数据
-----------------------------------------------
local function Clone(var)
	if type(var) == 'table' then
		local ret = {}
		for k, v in pairs(var) do
			ret[Clone(k)] = Clone(v)
		end
		return ret
	else
		return var
	end
end
-----------------------------------------------
-- Lua数据序列化
-----------------------------------------------
local EncodeLUAData = _G.var2str
-----------------------------------------------
-- Lua数据反序列化
-----------------------------------------------
local DecodeLUAData = _G.str2var or function(szText)
	local DECODE_ROOT = _DATA_ROOT_ .. '#cache/decode/'
	local DECODE_PATH = DECODE_ROOT .. GetCurrentTime() .. GetTime() .. math.random(0, 999999) .. '.jx3dat'
	CPath.MakeDir(DECODE_ROOT)
	SaveDataToFile(szText, DECODE_PATH)
	local data = LoadLUAData(DECODE_PATH)
	CPath.DelFile(DECODE_PATH)
	return data
end
-----------------------------------------------
-- 读取数据
-----------------------------------------------
local function Get(var, keys, dft)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		for _, k in ipairs(keys) do
			if type(var) == 'table' then
				var, res = var[k], true
			else
				var, res = dft, false
				break
			end
		end
	end
	if var == nil then
		var, res = dft, false
	end
	return var, res
end
-----------------------------------------------
-- 设置数据
-----------------------------------------------
local function Set(var, keys, val)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			table.insert(ks, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		local n = #keys
		for i = 1, n do
			local k = keys[i]
			if type(var) == 'table' then
				if i == n then
					var[k], res = val, true
				else
					if var[k] == nil then
						var[k] = {}
					end
					var = var[k]
				end
			else
				break
			end
		end
	end
	return res
end
-----------------------------------------------
-- 打包拆包数据
-----------------------------------------------
local Pack = type(table.pack) == 'function'
	and table.pack
	or function(...)
		return { n = select("#", ...), ... }
	end
local Unpack = type(table.unpack) == 'function'
	and table.unpack
	or unpack
-----------------------------------------------
-- 数据长度
-----------------------------------------------
local function Len(t)
	if type(t) == 'table' then
		return t.n or #t
	end
	return #t
end
-----------------------------------------------
-- 合并数据
-----------------------------------------------
local function Assign(t, ...)
	for index = 1, select('#', ...) do
		local t1 = select(index, ...)
		if type(t1) == 'table' then
			for k, v in pairs(t1) do
				t[k] = v
			end
		end
	end
	return t
end
-----------------------------------------------
-- 判断是否为空
-----------------------------------------------
local function IsEmpty(var)
	local szType = type(var)
	if szType == 'nil' then
		return true
	elseif szType == 'boolean' then
		return var
	elseif szType == 'number' then
		return var == 0
	elseif szType == 'string' then
		return var == ''
	elseif szType == 'function' then
		return false
	elseif szType == 'table' then
		for _, _ in pairs(var) do
			return false
		end
		return true
	else
		return false
	end
end
-----------------------------------------------
-- 深度判断相等
-----------------------------------------------
local function IsEquals(o1, o2)
	if o1 == o2 then
		return true
	elseif type(o1) ~= type(o2) then
		return false
	elseif type(o1) == 'table' then
		local t = {}
		for k, v in pairs(o1) do
			if IsEquals(o1[k], o2[k]) then
				t[k] = true
			else
				return false
			end
		end
		for k, v in pairs(o2) do
			if not t[k] then
				return false
			end
		end
		return true
	end
	return false
end
-----------------------------------------------
-- 数组随机
-----------------------------------------------
local function RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[math.random(1, #var)]
	end
end
-----------------------------------------------
-- 基础类型判断
-----------------------------------------------
local function IsArray(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return false
		end
		i = i + 1
	end
	return true
end
local function IsDictionary(var)
	if type(var) ~= 'table' then
		return false
	end
	local i = 1
	for k, _ in pairs(var) do
		if k ~= i then
			return true
		end
		i = i + 1
	end
	return false
end
local function IsNil     (var) return type(var) == 'nil'      end
local function IsTable   (var) return type(var) == 'table'    end
local function IsNumber  (var) return type(var) == 'number'   end
local function IsString  (var) return type(var) == 'string'   end
local function IsBoolean (var) return type(var) == 'boolean'  end
local function IsFunction(var) return type(var) == 'function' end
local function IsUserdata(var) return type(var) == 'userdata' end
local function IsHugeNumber(var) return IsNumber(var) and not (var < math.huge and var > -math.huge) end
local function IsElement(element) return type(element) == 'table' and element.IsValid and element:IsValid() or false end
-----------------------------------------------
-- 创建数据补丁
-----------------------------------------------
local function GetPatch(oBase, oData)
	-- dictionary patch
	if IsDictionary(oData) or (IsDictionary(oBase) and IsTable(oData) and IsEmpty(oData)) then
		-- dictionary raw value patch
		if not IsTable(oBase) then
			return { v = oData }
		end
		-- dictionary children patch
		local tKeys, bDiff = {}, false
		local oPatch = {}
		for k, v in pairs(oData) do
			local patch = GetPatch(oBase[k], v)
			if not IsNil(patch) then
				bDiff = true
				table.insert(oPatch, { k = k, v = patch })
			end
			tKeys[k] = true
		end
		for k, v in pairs(oBase) do
			if not tKeys[k] then
				bDiff = true
				table.insert(oPatch, { k = k, v = nil })
			end
		end
		if not bDiff then
			return nil
		end
		return oPatch
	end
	if not IsEquals(oBase, oData) then
		-- nil value patch
		if IsNil(oData) then
			return { t = 'nil' }
		end
		-- table value patch
		if IsTable(oData) then
			return { v = oData }
		end
		-- other patch value
		return oData
	end
	-- empty patch
	return nil
end
-----------------------------------------------
-- 数据应用补丁
-----------------------------------------------
local function ApplyPatch(oBase, oPatch, bNew)
	if bNew ~= false then
		oBase = Clone(oBase)
		oPatch = Clone(oPatch)
	end
	-- patch in dictionary type can only be a special value patch
	if IsDictionary(oPatch) then
		-- nil value patch
		if oPatch.t == 'nil' then
			return nil
		end
		-- raw value patch
		if not IsNil(oPatch.v) then
			return oPatch.v
		end
	end
	-- dictionary patch
	if IsTable(oPatch) and IsDictionary(oPatch[1]) then
		if not IsTable(oBase) then
			oBase = {}
		end
		for _, patch in ipairs(oPatch) do
			if IsNil(patch.v) then
				oBase[patch.k] = nil
			else
				oBase[patch.k] = ApplyPatch(oBase[patch.k], patch.v, false)
			end
		end
		return oBase
	end
	-- empty patch
	if IsNil(oPatch) then
		return oBase
	end
	-- other patch value
	return oPatch
end
-----------------------------------------------
-- 选代器 倒序
-----------------------------------------------
local ipairs_r
do
local function fnBpairs(tab, nIndex)
	nIndex = nIndex - 1
	if nIndex > 0 then
		return nIndex, tab[nIndex]
	end
end
function ipairs_r(tab)
	return fnBpairs, tab, #tab + 1
end
end
-----------------------------------------------
-- 只读表选代器
-----------------------------------------------
-- -- 只读表字典枚举
-- local pairs_c = pairs_c or function(t, ...)
-- 	if type(t) == 'table' then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == 'table' and metatable.const_table then
-- 			return pairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return pairs(t, ...)
-- end
-- -- 只读表数组枚举
-- local ipairs_c = ipairs_c or function(t, ...)
-- 	if type(t) == 'table' then
-- 		local metatable = getmetatable(t)
-- 		if type(metatable) == 'table' and metatable.const_table then
-- 			return ipairs(metatable.const_table, ...)
-- 		end
-- 	end
-- 	return ipairs(t, ...)
-- end
-----------------------------------------------
-- 类型安全选代器
-----------------------------------------------
local spairs, sipairs, spairs_r, sipairs_r
do
local function SafeIter(a, i)
	i = i + 1
	if a[i] then
		return i, a[i][1], a[i][2], a[i][3]
	end
end
function sipairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIter, iters, 0
end
function spairs(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIter, iters, 0
end
local function SafeIterR(a, i)
	i = i - 1
	if i > 0 then
		return i, a[i][1], a[i][2], a[i][3]
	end
end
function sipairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in ipairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, #iters + 1
end
function spairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				table.insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, #iters + 1
end
end
-----------------------------------------------
-- 类
-----------------------------------------------
local Class
do
local function createInstance(c, ins, ...)
	if not ins then
		ins = c
	end
	if c.ctor then
		c.ctor(ins, ...)
	end
	return c
end
function Class(className, super)
	local classPrototype
	if type(super) == 'string' then
		className, super = super, nil
	end
	if not className then
		className = 'Unnamed Class'
	end
	classPrototype = (function ()
		local proxys = {}
		if super then
			proxys.super = super
			setmetatable(proxys, { __index = super })
		end
		return setmetatable({}, {
			__index = proxys,
			__tostring = function(t) return className .. ' (class prototype)' end,
			__call = function (...)
				return createInstance(setmetatable({}, {
					__index = classPrototype,
					__tostring = function(t) return className .. ' (class instance)' end,
				}), nil, ...)
			end,
		})
	end)()
	return classPrototype
end
end
-----------------------------------------------
-- 获取调用栈
-----------------------------------------------
local function GetTraceback(str)
	local traceback = debug and debug.traceback and debug.traceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	if traceback then
		if str then
			str = str .. '\n' .. traceback
		else
			str = traceback
		end
	end
	return str or ''
end
-----------------------------------------------
-- 安全调用
-----------------------------------------------
local Call, XpCall
do
local xpAction, xpArgs, xpErrMsg, xpTraceback, xpErrLog
local function CallHandler()
	return xpAction(Unpack(xpArgs))
end
local function CallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
	xpErrLog = (errMsg or '') .. '\n' .. xpTraceback
	Log(xpErrLog)
	FireUIEvent('CALL_LUA_ERROR', xpErrLog .. '\n')
end
local function XpCallErrorHandler(errMsg)
	xpErrMsg = errMsg
	xpTraceback = GetTraceback():gsub('^([^\n]+\n)[^\n]+\n', '%1')
end
function Call(arg0, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = arg0, Pack(...), nil, nil
	local res = Pack(xpcall(CallHandler, CallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return Unpack(res)
end
function XpCall(arg0, ...)
	xpAction, xpArgs, xpErrMsg, xpTraceback = arg0, Pack(...), nil, nil
	local res = Pack(xpcall(CallHandler, XpCallErrorHandler))
	if not res[1] then
		res[2] = xpErrMsg
		res[3] = xpTraceback
	end
	xpAction, xpArgs, xpErrMsg, xpTraceback = nil, nil, nil, nil
	return Unpack(res)
end
end
local function SafeCall(f, ...)
	if not IsFunction(f) then
		return false, 'NOT CALLABLE'
	end
	return Call(f, ...)
end
local function CallWithThis(context, f, ...)
	local _this = this
	this = context
	local rtc = Pack(Call(f, ...))
	this = _this
	return Unpack(rtc)
end
local function SafeCallWithThis(context, f, ...)
	local _this = this
	this = context
	local rtc = Pack(SafeCall(f, ...))
	this = _this
	return Unpack(rtc)
end

local NSFormatString
do local CACHE = {}
function NSFormatString(s)
	if not CACHE[s] then
		CACHE[s] = wstring.gsub(s, '{$NS}', _NAME_SPACE_)
	end
	return CACHE[s]
end
end

local function GetGameAPI(szAddon, szInside)
	local api = _G[szAddon]
	if not api and _DEBUG_LEVEL_ < DEBUG_LEVEL.NONE then
		local env = GetInsideEnv()
		if env then
			api = env[szInside or szAddon]
		end
	end
	return api
end

local function GetGameTable(szTable, bPringError)
	local b, t = (bPringError and Call or pcall)(function() return g_tTable[szTable] end)
	if b then
		return t
	end
end
-----------------------------------------------
-- 插件集信息
-----------------------------------------------
local PACKET_INFO
do
local tInfo = {
	NAME                  = _NAME_                 ,
	SHORT_NAME            = _SHORT_NAME_           ,
	VERSION               = _VERSION_              ,
	BUILD                 = _BUILD_                ,
	NAME_SPACE            = _NAME_SPACE_           ,
	DEBUG_LEVEL           = _DEBUG_LEVEL_          ,
	DELOG_LEVEL           = _DELOG_LEVEL_          ,
	INTERFACE_ROOT        = _INTERFACE_ROOT_       ,
	ROOT                  = _ADDON_ROOT_           ,
	DATA_ROOT             = _DATA_ROOT_            ,
	FRAMEWORK_ROOT        = _FRAMEWORK_ROOT_       ,
	UICOMPONENT_ROOT      = _UICOMPONENT_ROOT_     ,
	LOGO_UITEX            = _LOGO_UITEX_           ,
	LOGO_MAIN_FRAME       = _LOGO_MAIN_FRAME_      ,
	LOGO_MENU_FRAME       = _LOGO_MENU_FRAME_      ,
	LOGO_MENU_HOVER_FRAME = _LOGO_MENU_HOVER_FRAME_,
	POSTER_UITEX          = _POSTER_UITEX_         ,
	POSTER_FRAME_COUNT    = _POSTER_FRAME_COUNT_   ,
	AUTHOR                = _AUTHOR_               ,
	AUTHOR_WEIBO          = _AUTHOR_WEIBO_         ,
	AUTHOR_WEIBO_URL      = _AUTHOR_WEIBO_URL_     ,
	AUTHOR_SIGNATURE      = _AUTHOR_SIGNATURE_     ,
	AUTHOR_ROLES          = _AUTHOR_ROLES_         ,
	AUTHOR_HEADER         = _AUTHOR_HEADER_        ,
	AUTHOR_PROTECT_NAMES  = _AUTHOR_PROTECT_NAMES_ ,
	AUTHOR_FAKE_HEADER    = _AUTHOR_FAKE_HEADER_   ,
	MENU_COLOR            = _MENU_COLOR_           ,
}
PACKET_INFO = SetmetaReadonly(tInfo)
end
-----------------------------------------------
-- 枚举
-----------------------------------------------
local function KvpToObject(kvp)
	local t = {}
	for _, v in ipairs(kvp) do
		if not IsNil(v[1]) then
			t[v[1]] = v[2]
		end
	end
	return t
end

local ENVIRONMENT = setmetatable({}, {
	__index = setmetatable({
		GAME_LANG        = _GAME_LANG_       ,
		GAME_BRANCH      = _GAME_BRANCH_     ,
		GAME_EDITION     = _GAME_EDITION_    ,
		GAME_VERSION     = _GAME_VERSION_    ,
		GAME_PROVIDER    = _GAME_PROVIDER_   ,
		SERVER_ADDRESS   = _SERVER_ADDRESS_  ,
		RUNTIME_OPTIMIZE = _RUNTIME_OPTIMIZE_,
	}, { __index = _G.GLOBAL }),
	__newindex = function() end,
})

local SECRET = setmetatable(LoadLUAData(_ADDON_ROOT_ .. 'secret.jx3dat') or {}, {
	__index = function(_, k) return k end,
})

local PATH_TYPE = SetmetaReadonly({
	NORMAL = 0,
	DATA   = 1,
	ROLE   = 2,
	GLOBAL = 3,
	SERVER = 4,
})

---------------------------------------------------------------------------------------------
local X = {
	UI               = {}              ,
	wstring          = wstring         ,
	count_c          = count_c         ,
	pairs_c          = pairs_c         ,
	ipairs_c         = ipairs_c        ,
	ipairs_r         = ipairs_r        ,
	spairs           = spairs          ,
	spairs_r         = spairs_r        ,
	sipairs          = sipairs         ,
	sipairs_r        = sipairs_r       ,
	IsArray          = IsArray         ,
	IsDictionary     = IsDictionary    ,
	IsEquals         = IsEquals        ,
	IsNil            = IsNil           ,
	IsBoolean        = IsBoolean       ,
	IsNumber         = IsNumber        ,
	IsUserdata       = IsUserdata      ,
	IsHugeNumber     = IsHugeNumber    ,
	IsElement        = IsElement       ,
	IsEmpty          = IsEmpty         ,
	IsString         = IsString        ,
	IsTable          = IsTable         ,
	IsFunction       = IsFunction      ,
	IIf              = IIf             ,
	Clone            = Clone           ,
	Call             = Call            ,
	XpCall           = XpCall          ,
	SafeCall         = SafeCall        ,
	CallWithThis     = CallWithThis    ,
	SafeCallWithThis = SafeCallWithThis,
	SetmetaReadonly  = SetmetaReadonly ,
	SetmetaLazyload  = SetmetaLazyload ,
	ErrorLog         = ErrorLog        ,
	Set              = Set             ,
	Get              = Get             ,
	Pack             = Pack            ,
	Unpack           = Unpack          ,
	Len              = Len             ,
	Assign           = Assign          ,
	Class            = Class           ,
	GetPatch         = GetPatch        ,
	ApplyPatch       = ApplyPatch      ,
	EncodeLUAData    = EncodeLUAData   ,
	DecodeLUAData    = DecodeLUAData   ,
	RandomChild      = RandomChild     ,
	KvpToObject      = KvpToObject     ,
	GetTraceback     = GetTraceback    ,
	NSFormatString   = NSFormatString  ,
	GetGameAPI       = GetGameAPI      ,
	GetGameTable     = GetGameTable    ,
	LoadLangPack     = LoadLangPack    ,
	ENVIRONMENT      = ENVIRONMENT     ,
	SECRET           = SECRET          ,
	PATH_TYPE        = PATH_TYPE       ,
	DEBUG_LEVEL      = DEBUG_LEVEL     ,
	PACKET_INFO      = PACKET_INFO     ,
	SHARED_MEMORY    = SHARED_MEMORY   ,
}
_G[_NAME_SPACE_] = X
---------------------------------------------------------------------------------------------
