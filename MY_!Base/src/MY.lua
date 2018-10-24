--------------------------------------------------------
-- This file is part of the JX3 Mingyi Plugin.
-- @link     : https://jx3.derzh.com/
-- @desc     : 茗伊插件主界面
-- @author   : 茗伊 @双梦镇 @追风蹑影
-- @modifier : Emil Zhai (root@derzh.com)
-- @copyright: Copyright (c) 2013 EMZ Kingsoft Co., Ltd.
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

---------------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
---------------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi, random = math.huge, math.pi, math.random
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
---------------------------------------------------------------------------------------------
local function Get(var, keys, dft)
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			insert(ak, k)
		end
		keys = ks
	end
	if type(keys) == 'table' then
		for _, k in ipairs(keys) do
			if type(var) == 'table' then
				var = var[k]
			else
				var = dft
				break
			end
		end
	end
	return var
end
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
local function RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[random(1, #var)]
	end
end
local function IsNil     (var) return type(var) == 'nil'      end
local function IsTable   (var) return type(var) == 'table'    end
local function IsNumber  (var) return type(var) == 'number'   end
local function IsString  (var) return type(var) == 'string'   end
local function IsBoolean (var) return type(var) == 'boolean'  end
local function IsFunction(var) return type(var) == 'function' end
---------------------------------------------------------------------------------------------
MY = {}
MY.Get = Get
MY.IsNil, MY.IsBoolean, MY.IsEmpty, MY.RandomChild = IsNil, IsBoolean, IsEmpty, RandomChild
MY.IsNumber, MY.IsString, MY.IsTable, MY.IsFunction = IsNumber, IsString, IsTable, IsFunction
---------------------------------------------------------------------------------------------
-- 本地函数变量
---------------------------------------------------------------------------------------------
local _BUILD_ = '20181017'
local _VERSION_ = 0x2011500
local _DEBUGLV_ = tonumber(LoadLUAData('interface/my.debug.level') or nil) or 4
local _DELOGLV_ = tonumber(LoadLUAData('interface/my.delog.level') or nil) or 4
local _NORESTM_ = tonumber(LoadLUAData('interface/my.nrtim.level') or nil) or -1
local _INTERFACE_ROOT_ = './Interface/'
local _ADDON_ROOT_     = _INTERFACE_ROOT_ .. 'MY/'
local _FRAMEWORK_ROOT_ = _INTERFACE_ROOT_ .. 'MY/MY_!Base/'
local _PSS_ST_         = _FRAMEWORK_ROOT_ .. 'image/ST.pss'
local _UITEX_ST_       = _FRAMEWORK_ROOT_ .. 'image/ST_UI.UITex'
local _UITEX_POSTER_   = _FRAMEWORK_ROOT_ .. 'image/Poster.UITex'
local _UITEX_COMMON_   = _FRAMEWORK_ROOT_ .. 'image/UICommon.UITex'
Log('[MY] Debug level ' .. _DEBUGLV_ .. ' / delog level ' .. _DELOGLV_)
---------------------------------------------------------------------------------------------

-- 多语言处理
-- (table) MY.LoadLangPack(void)
function MY.LoadLangPack(szLangFolder)
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/default') or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_..'lang/' .. szLang) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder)=='string' then
		szLangFolder = string.gsub(szLangFolder,'[/\\]+$','')
		local t2 = LoadLUAData(szLangFolder..'/default') or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		local t3 = LoadLUAData(szLangFolder..'/' .. szLang) or {}
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
local _L = MY.LoadLangPack()
local _NAME_       = _L['mingyi plugins']
local _SHORT_NAME_ = _L['mingyi plugin']
local _AUTHOR_     = _L['MingYi @ Double Dream Town']
-----------------------------------------------
-- 私有函数
-----------------------------------------------
local INI_PATH = _FRAMEWORK_ROOT_..'ui/MY.ini'
local C, D = {}, {}

do local AddonInfo = SetmetaReadonly({
	szName          = _NAME_          ,
	szShortName     = _SHORT_NAME_    ,
	szUITexCommon   = _UITEX_COMMON_  ,
	szUITexPoster   = _UITEX_POSTER_  ,
	szUITexST       = _UITEX_ST_      ,
	dwVersion       = _VERSION_       ,
	szBuildDate     = _BUILD_         ,
	nDebugLevel     = _DEBUGLV_       ,
	nLogLevel       = _DELOGLV_       ,
	szInterfaceRoot = _INTERFACE_ROOT_,
	szRoot          = _ADDON_ROOT_    ,
	szFrameworkRoot = _FRAMEWORK_ROOT_,
	szAuthor        = _AUTHOR_        ,
	tAuthor         = {
		[43567   ] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 体服
		[3007396 ] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 枫泾古镇
		[1600498 ] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 追风蹑影
		[4664780 ] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 日月明尊
		[17796954] = string.char( 0xDC, 0xF8, 0xD2, 0xC1, 0x40, 0xB0, 0xD7, 0xB5, 0xDB, 0xB3, 0xC7 ), -- 唯我独尊->枫泾古镇
		[385183  ] = string.char( 0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A ), -- 傲血戰意
		[1452025 ] = string.char( 0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A, 0xE4, 0xBC, 0x8A ), -- 巔峰再起
		[3627405 ] = string.char( 0xC1, 0xFA, 0xB5, 0xA8, 0xC9, 0xDF, 0x40, 0xDD, 0xB6, 0xBB, 0xA8, 0xB9, 0xAC ), -- 白帝
		-- [4662931] = string.char( 0xBE, 0xCD, 0xCA, 0xC7, 0xB8, 0xF6, 0xD5, 0xF3, 0xD1, 0xDB ), -- 日月明尊
		-- [3438030] = string.char( 0xB4, 0xE5, 0xBF, 0xDA, 0xB5, 0xC4, 0xCD, 0xF5, 0xCA, 0xA6, 0xB8, 0xB5 ), -- 枫泾古镇
	},
})
function MY.GetAddonInfo()
	return AddonInfo
end
end

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
function MY.class(className, super)
	if type(super) == 'string' then
		className, super = super
	end
	if not className then
		className = 'Unnamed Class'
	end
	local classPrototype = (function ()
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


---------------------------------------------------------------------------------------------
-- 界面开关
---------------------------------------------------------------------------------------------
function MY.GetFrame()
	return Station.Lookup('Normal/MY')
end

function MY.OpenPanel()
	if not MY.IsInitialized() then
		return
	end
	local frame = MY.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(INI_PATH, 'MY')
		frame:Hide()
		frame.bVisible = false
		D.CheckTutorial()
	end
	return frame
end

function MY.ClosePanel()
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	MY.SwitchTab()
	MY.HidePanel(false, true)
	Wnd.CloseWindow(frame)
end

function MY.ReopenPanel()
	if not MY.IsPanelOpened() then
		return
	end
	local bVisible = MY.IsPanelVisible()
	MY.ClosePanel()
	MY.OpenPanel()
	MY.TogglePanel(bVisible, true, true)
end

function MY.ShowPanel(bMute, bNoAnimate)
	local frame = MY.OpenPanel()
	if not frame:IsVisible() then
		frame:Show()
		frame.bVisible = true
		if not bNoAnimate then
			frame.bToggling = true
			tweenlite.from(300, frame, {
				relY = frame:GetRelY() - 10,
				alpha = 0,
				complete = function()
					frame.bToggling = false
				end,
			})
		end
		if not bMute then
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end
	end
	frame:BringToTop()
	MY.RegisterEsc('MY', MY.IsPanelVisible, function() MY.HidePanel() end)
end

function MY.HidePanel(bMute, bNoAnimate)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	if not frame.bToggling then
		if bNoAnimate then
			frame:Hide()
		else
			local nY = frame:GetRelY()
			local nAlpha = frame:GetAlpha()
			tweenlite.to(300, frame, {relY = nY + 10, alpha = 0, complete = function()
				frame:SetRelY(nY)
				frame:SetAlpha(nAlpha)
				frame:Hide()
				frame.bToggling = false
			end})
			frame.bToggling = true
		end
		frame.bVisible = false
	end
	if not bMute then
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	MY.RegisterEsc('MY')
	Wnd.CloseWindow('PopupMenuPanel')
end

function MY.TogglePanel(bVisible, ...)
	if bVisible == nil then
		if MY.IsPanelVisible() then
			MY.HidePanel()
		else
			MY.ShowPanel()
			MY.FocusPanel()
		end
	elseif bVisible then
		MY.ShowPanel(...)
		MY.FocusPanel()
	else
		MY.HidePanel(...)
	end
end

function MY.FocusPanel(bForce)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	if not bForce and not Cursor.IsVisible() then
		return
	end
	Station.SetFocusWindow(frame)
end

function MY.ResizePanel(nWidth, nHeight)
	local hFrame = MY.GetFrame()
	if not hFrame then
		return
	end
	MY.UI(hFrame):size(nWidth, nHeight)
end

function MY.IsPanelVisible()
	return MY.GetFrame() and MY.GetFrame():IsVisible()
end

-- if panel visible
function MY.IsPanelOpened()
	return Station.Lookup('Normal/MY')
end

-- (string, number) MY.GetVersion()
function MY.GetVersion(dwVersion)
	local dwVersion = dwVersion or _VERSION_
	local szVersion = string.format('%X.%X.%02X', dwVersion / 0x1000000,
		math.floor(dwVersion / 0x10000) % 0x100, math.floor(dwVersion / 0x100) % 0x100)
	if  dwVersion % 0x100 ~= 0 then
		szVersion = szVersion .. 'b' .. tostring(dwVersion % 0x100)
	end
	return szVersion, dwVersion
end

function MY.AssertVersion(szKey, szCaption, dwMinVersion)
	if _VERSION_ >= dwMinVersion then
		MY.Sysmsg({
			_L('%s requires base library version upper than %s, current at %s.',
			szCaption, MY.GetVersion(dwMinVersion), MY.GetVersion()
		)})
		return false
	end
	return true
end

---------------------------------------------------------------------------------------------
-- 事件注册
---------------------------------------------------------------------------------------------
do local INIT_FUNC_LIST = {}
local function OnInit()
	if not INIT_FUNC_LIST then
		return
	end
	MY.CreateDataRoot(MY_DATA_PATH.ROLE)
	MY.CreateDataRoot(MY_DATA_PATH.GLOBAL)
	MY.CreateDataRoot(MY_DATA_PATH.SERVER)

	for szKey, fnAction in pairs(INIT_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, 'INIT_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Initial function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	INIT_FUNC_LIST = nil
	-- 显示欢迎信息
	MY.Sysmsg({_L('%s, welcome to use mingyi plugins!', GetClientPlayer().szName) .. ' v' .. MY.GetVersion() .. ' Build ' .. _BUILD_})
end
RegisterEvent('LOADING_ENDING', OnInit) -- 不能用FIRST_LOADING_END 不然注册快捷键就全跪了

-- 注册初始化函数
-- RegisterInit(string id, function fn) -- 注册
-- RegisterInit(function fn)            -- 注册
-- RegisterInit(string id)              -- 注销
function MY.RegisterInit(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			INIT_FUNC_LIST[szKey] = fnAction
		else
			table.insert(INIT_FUNC_LIST, fnAction)
		end
	elseif szKey then
		INIT_FUNC_LIST[szKey] = nil
	end
end

function MY.IsInitialized()
	return not INIT_FUNC_LIST
end
end

do local EXIT_FUNC_LIST = {}
local function OnExit()
	for szKey, fnAction in pairs(EXIT_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, 'EXIT_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Exit function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	EXIT_FUNC_LIST = nil
end
RegisterEvent('GAME_EXIT', OnExit)
RegisterEvent('PLAYER_EXIT_GAME', OnExit)
RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

-- 注册游戏结束函数
-- RegisterExit(string id, function fn) -- 注册
-- RegisterExit(function fn)            -- 注册
-- RegisterExit(string id)              -- 注销
function MY.RegisterExit(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			EXIT_FUNC_LIST[szKey] = fnAction
		else
			table.insert(EXIT_FUNC_LIST, fnAction)
		end
	elseif szKey then
		EXIT_FUNC_LIST[szKey] = nil
	end
end
end

do local RELOAD_FUNC_LIST = {}
local function OnReload()
	for szKey, fnAction in pairs(RELOAD_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, 'RELOAD_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Reload function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	RELOAD_FUNC_LIST = nil
end
RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnReload)

-- 注册插件重载函数
-- RegisterReload(string id, function fn) -- 注册
-- RegisterReload(function fn)            -- 注册
-- RegisterReload(string id)              -- 注销
function MY.RegisterReload(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			RELOAD_FUNC_LIST[szKey] = fnAction
		else
			table.insert(RELOAD_FUNC_LIST, fnAction)
		end
	elseif szKey then
		RELOAD_FUNC_LIST[szKey] = nil
	end
end
end

do local IDLE_FUNC_LIST, TIME = {}, 0
local function OnIdle()
	local nTime = GetTime()
	if nTime - TIME < 20000 then
		return
	end
	for szKey, fnAction in pairs(IDLE_FUNC_LIST) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, 'IDLE_FUNC_LIST#' .. szKey)
		end
		MY.Debug({_L('Idle function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	TIME = nTime
end
RegisterEvent('ON_FRAME_CREATE', function()
	if arg0:GetName() == 'OptionPanel' then
		OnIdle()
	end
end)
RegisterEvent('BUFF_UPDATE', function()
	if arg1 then
		return
	end
	if arg0 == UI_GetClientPlayerID() and arg4 == 103 then
		DelayCall('MY_ON_IDLE', math.random(0, 10000), function()
			local me = GetClientPlayer()
			if me and me.GetBuff(103, 0) then
				OnIdle()
			end
		end)
	end
end)
BreatheCall('MY_ON_IDLE', function()
	if Station.GetIdleTime() > 300000 then
		OnIdle()
	end
end)

-- 注册游戏空闲函数 -- 用户存储数据等操作
-- RegisterIdle(string id, function fn) -- 注册
-- RegisterIdle(function fn)            -- 注册
-- RegisterIdle(string id)              -- 注销
function MY.RegisterIdle(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			IDLE_FUNC_LIST[szKey] = fnAction
		else
			table.insert(IDLE_FUNC_LIST, fnAction)
		end
	elseif szKey then
		IDLE_FUNC_LIST[szKey] = nil
	end
end
end

-- 注册游戏事件监听
-- MY.RegisterEvent(szEvent, fnAction) -- 注册
-- MY.RegisterEvent(szEvent) -- 注销
-- (string)  szEvent  事件，可在后面加一个点并紧跟一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
-- (function)fnAction 事件处理函数，arg0 ~ arg9，传入 nil 相当于取消该事件
--特别注意：当 fnAction 为 nil 并且 szKey 也为 nil 时会取消所有通过本函数注册的事件处理器
do local EVENT_LIST = {}
local function EventHandler(szEvent, ...)
	local tEvent = EVENT_LIST[szEvent]
	if tEvent then
		for k, v in pairs(tEvent) do
			local res, err = pcall(v, szEvent, ...)
			if not res then
				MY.Debug({err}, 'OnEvent#' .. szEvent .. '.' .. k, MY_DEBUG.ERROR)
			end
		end
	end
end

function MY.RegisterEvent(szEvent, fnAction)
	if type(szEvent) == 'table' then
		for _, szEvent in ipairs(szEvent) do
			MY.RegisterEvent(szEvent, fnAction)
		end
	elseif type(szEvent) == 'string' then
		local szKey = nil
		local nPos = StringFindW(szEvent, '.')
		if nPos then
			szKey = string.sub(szEvent, nPos + 1)
			szEvent = string.sub(szEvent, 1, nPos - 1)
		end
		if fnAction then
			if not EVENT_LIST[szEvent] then
				EVENT_LIST[szEvent] = {}
				RegisterEvent(szEvent, EventHandler)
			end
			if szKey then
				EVENT_LIST[szEvent][szKey] = fnAction
			else
				table.insert(EVENT_LIST[szEvent], fnAction)
			end
		else
			if szKey then
				if EVENT_LIST[szEvent] then
					EVENT_LIST[szEvent][szKey] = nil
				end
			else
				EVENT_LIST[szEvent] = {}
			end
		end
	end
end
end

do
local TUTORIAL_LIST = {}
function MY.RegisterTutorial(tOptions)
	if type(tOptions) ~= 'table' or not tOptions.szKey or not tOptions.szMessage then
		return
	end
	insert(TUTORIAL_LIST, MY.FullClone(tOptions))
end

local CHECKED = {}
local function GetNextTutorial()
	for _, p in ipairs(TUTORIAL_LIST) do
		if not CHECKED[p.szKey] and (not p.fnRequire or p.fnRequire()) then
			return p
		end
	end
end
MY.RegisterInit(function()
	CHECKED = MY.LoadLUAData({'config/tutorialed.jx3dat', MY_DATA_PATH.ROLE})
	if not IsTable(CHECKED) then
		CHECKED = {}
	end
end)
MY.RegisterExit(function() MY.SaveLUAData({'config/tutorialed.jx3dat', MY_DATA_PATH.ROLE}, CHECKED) end)

local function StepNext(bQuick)
	local tutorial = GetNextTutorial()
	if not tutorial then
		return
	end
	if bQuick then
		local menu = tutorial[1]
		for i, p in ipairs(tutorial) do
			if p.bDefault then
				menu = p
			end
		end
		if menu and menu.fnAction then
			menu.fnAction()
		end
		CHECKED[tutorial.szKey] = true
		return StepNext(bQuick)
	end
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = 'MY_Tutorial',
		szMessage = tutorial.szMessage,
		szAlignment = 'CENTER',
	}
	for _, p in ipairs(tutorial) do
		local menu = MY.FullClone(p)
		menu.fnAction = function()
			if p.fnAction then
				p.fnAction()
			end
			CHECKED[tutorial.szKey] = true
			StepNext()
		end
		insert(tMsg, menu)
	end
	MessageBox(tMsg)
end

function D.CheckTutorial()
	if not GetNextTutorial() then
		return
	end
	local nW, nH = Station.GetClientSize()
	local tMsg = {
		x = nW / 2, y = nH / 3,
		szName = 'MY_Tutorial',
		szMessage = _L['Welcome to use MY plugin, would you like to start quick tutorial now?'],
		szAlignment = 'CENTER',
		{
			szOption = _L['Quickset'],
			fnAction = function() StepNext(true) end,
		},
		{
			szOption = _L['Manually'],
			fnAction = function() StepNext() end,
		},
		{
			szOption = _L['Later'],
		},
	}
	MessageBox(tMsg)
end
end

do local BG_MSG_LIST = {}
------------------------------------
--            背景通讯             --
------------------------------------
-- ON_BG_CHANNEL_MSG
-- arg0: 消息szKey
-- arg1: 消息来源频道
-- arg2: 消息发布者ID
-- arg3: 消息发布者名字
-- arg4: 不定长参数数组数据
------------------------------------
local function OnBgMsg()
	local szMsgID, nChannel, dwID, szName, aParam, bSelf = arg0, arg1, arg2, arg3, arg4, arg2 == UI_GetClientPlayerID()
	if szMsgID and BG_MSG_LIST[szMsgID] then
		for szKey, fnAction in pairs(BG_MSG_LIST[szMsgID]) do
			local status, err = pcall(fnAction, szMsgID, nChannel, dwID, szName, bSelf, unpack(aParam))
			if not status then
				MY.Debug({err}, 'BG_EVENT#' .. szMsgID .. '.' .. szKey, MY_DEBUG.ERROR)
			end
		end
	end
end
RegisterEvent('ON_BG_CHANNEL_MSG', OnBgMsg)


-- MY.RegisterBgMsg('MY_CHECK_INSTALL', function(nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) MY.BgTalk(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- MY.RegisterBgMsg('MY_CHECK_INSTALL') -- 注销
-- MY.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01', function(nChannel, dwTalkerID, szTalkerName, bSelf, oDatas...) MY.BgTalk(szTalkerName, 'MY_CHECK_INSTALL_REPLY', oData) end) -- 注册
-- MY.RegisterBgMsg('MY_CHECK_INSTALL.RECEIVER_01') -- 注销
function MY.RegisterBgMsg(szMsgID, fnAction)
	if type(szMsgID) == 'table' then
		for _, szMsgID in ipairs(szMsgID) do
			MY.RegisterBgMsg(szMsgID, fnAction)
		end
		return
	end
	local szKey = nil
	local nPos = StringFindW(szMsgID, '.')
	if nPos then
		szKey = string.sub(szMsgID, nPos + 1)
		szMsgID = string.sub(szMsgID, 1, nPos - 1)
	end
	if fnAction then
		if not BG_MSG_LIST[szMsgID] then
			BG_MSG_LIST[szMsgID] = {}
		end
		if szKey then
			BG_MSG_LIST[szMsgID][szKey] = fnAction
		else
			table.insert(BG_MSG_LIST[szMsgID], fnAction)
		end
	else
		if szKey then
			BG_MSG_LIST[szMsgID][szKey] = nil
		else
			BG_MSG_LIST[szMsgID] = nil
		end
	end
end
end

-- MY.BgTalk(szName, szMsgID, ...)
-- MY.BgTalk(nChannel, szMsgID, ...)
function MY.BgTalk(nChannel, szMsgID, ...)
	local szTarget, me = '', GetClientPlayer()
	if not (me and nChannel) then
		return
	end
	-- channel
	if type(nChannel) == 'string' then
		szTarget = nChannel
		nChannel = PLAYER_TALK_CHANNEL.WHISPER
	end
	-- auto switch battle field
	if nChannel == PLAYER_TALK_CHANNEL.RAID
	and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- talk
	local tSay = {{ type = 'eventlink', name = 'BG_CHANNEL_MSG', linkinfo = szMsgID }}
	local tArg = {...}
	local nCount = select('#', ...) -- 这里有个坑 如果直接ipairs({...})可能会掉进坑： for遇到nil就中断了导致后续参数丢失
	for i = 1, nCount do
		table.insert(tSay, { type = 'eventlink', name = '', linkinfo = var2str(tArg[i]) })
	end
	me.Talk(nChannel, szTarget, tSay)
end
---------------------------------------------------------------------------------------------
-- 选项卡
---------------------------------------------------------------------------------------------
do local TABS_LIST = {
	{ id = _L['General'] },
	{ id = _L['Target'] },
	{ id = _L['Chat'] },
	{ id = _L['Battle'] },
	{ id = _L['Raid'] },
	{ id = _L['System'] },
	{ id = _L['Others'] },
}
--[[ tTabs:
	{
		{
			id = ,
			{
				[tab]
			}, {...}
		},
		{
			[category]
		}, {...}
	}
]]
function MY.RedrawCategory(szCategory)
	local frame = MY.GetFrame()
	if not frame then
		return
	end

	-- draw category
	local wndCategoryList = frame:Lookup('Wnd_Total/WndContainer_Category')
	wndCategoryList:Clear()
	for _, ctg in ipairs(TABS_LIST) do
		local nCount = 0
		for i, tab in ipairs(ctg) do
			if not (tab.bShielded and MY.IsShieldedVersion()) then
				nCount = nCount + 1
			end
		end
		if nCount > 0 then
			local chkCategory = wndCategoryList:AppendContentFromIni(INI_PATH, 'CheckBox_Category')
			chkCategory.szCategory = ctg.id
			chkCategory:Lookup('', 'Text_Category'):SetText(ctg.id)
			chkCategory.OnCheckBoxCheck = function()
				if chkCategory.bActived then
					return
				end
				wndCategoryList.szCategory = chkCategory.szCategory

				PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
				local p = chkCategory:GetParent():GetFirstChild()
				while p do
					if p.szCategory ~= chkCategory.szCategory then
						p.bActived = false
						p:Check(false)
					end
					p = p:GetNext()
				end
				MY.RedrawTabs(chkCategory.szCategory)
			end
			szCategory = szCategory or ctg.id
		end
	end
	wndCategoryList:FormatAllContentPos()

	MY.SwitchCategory(szCategory)
end

-- MY.SwitchCategory(szCategory)
function MY.SwitchCategory(szCategory)
	local frame = MY.GetFrame()
	if not frame then
		return
	end

	local container = frame:Lookup('Wnd_Total/WndContainer_Category')
	local chk = container:GetFirstChild()
	while(chk and chk.szCategory ~= szCategory) do
		chk = chk:GetNext()
	end
	if not chk then
		chk = container:GetFirstChild()
	end
	if chk then
		container.szCategory = chk.szCategory
		chk:Check(true)
	end
end

function MY.RedrawTabs(szCategory)
	local frame = MY.GetFrame()
	if not (frame and szCategory) then
		return
	end

	-- draw tabs
	local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	hTabs:Clear()

	for _, ctg in ipairs(TABS_LIST) do
		if ctg.id == szCategory then
			for i, tab in ipairs(ctg) do
				if not (tab.bShielded and MY.IsShieldedVersion()) then
					local hTab = hTabs:AppendItemFromIni(INI_PATH, 'Handle_Tab')
					hTab.szID = tab.szID
					hTab:Lookup('Text_Tab'):SetText(tab.szTitle)
					if tab.szIconTex == 'FromIconID' then
						hTab:Lookup('Image_TabIcon'):FromIconID(tab.dwIconFrame)
					elseif tab.dwIconFrame then
						hTab:Lookup('Image_TabIcon'):FromUITex(tab.szIconTex, tab.dwIconFrame)
					else
						hTab:Lookup('Image_TabIcon'):FromTextureFile(tab.szIconTex)
					end
					hTab:Lookup('Image_Bg'):FromUITex(_UITEX_COMMON_, 3)
					hTab:Lookup('Image_Bg_Active'):FromUITex(_UITEX_COMMON_, 1)
					hTab:Lookup('Image_Bg_Hover'):FromUITex(_UITEX_COMMON_, 2)
					hTab.OnItemLButtonClick = function()
						MY.SwitchTab(this.szID)
					end
					hTab.OnItemMouseEnter = function()
						this:Lookup('Image_Bg_Hover'):Show()
					end
					hTab.OnItemMouseLeave = function()
						this:Lookup('Image_Bg_Hover'):Hide()
					end
				end
			end
		end
	end
	hTabs:FormatAllItemPos()

	MY.SwitchTab()
end

function MY.SwitchTab(szID, bForceUpdate)
	local frame = MY.GetFrame()
	if not frame then
		return
	end

	local category, tab
	if szID then
		for _, ctg in ipairs(TABS_LIST) do
			for _, p in ipairs(ctg) do
				if p.szID == szID then
					category, tab = ctg, p
				end
			end
		end
		if not tab then
			MY.Debug({_L('Cannot find tab: %s', szID)}, 'MY.SwitchTab#' .. szID, MY_DEBUG.WARNING)
		end
	end

	-- check if category is right
	if category then
		local szCategory = frame:Lookup('Wnd_Total/WndContainer_Category').szCategory
		if category.id ~= szCategory then
			MY.SwitchCategory(category.id)
		end
	end

	-- check if tab is alreay actived and update tab active status
	if tab then
		-- get tab window
		local hTab
		local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
		for i = 0, hTabs:GetItemCount() - 1 do
			if hTabs:Lookup(i).szID == szID then
				hTab = hTabs:Lookup(i)
			end
		end
		if (not hTab) or (hTab.bActived and not bForceUpdate) then
			return
		end
		if not hTab.bActived then
			PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		end

		-- deal with ui response
		local hTabs = hTab:GetParent()
		for i = 0, hTabs:GetItemCount() - 1 do
			hTabs:Lookup(i).bActived = false
			hTabs:Lookup(i):Lookup('Image_Bg_Active'):Hide()
		end
		hTab.bActived = true
		hTab:Lookup('Image_Bg_Active'):Show()
	end

	-- get main panel
	local wnd = frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	local scroll = frame:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel')
	-- fire custom registered on switch event
	if wnd.OnPanelDeactive then
		local res, err = pcall(wnd.OnPanelDeactive, wnd)
		if not res then
			MY.Debug({err}, 'MY#OnPanelDeactive', MY_DEBUG.ERROR)
		end
	end
	-- clear all events
	wnd.OnPanelActive   = nil
	wnd.OnPanelDeactive = nil
	wnd.OnPanelResize   = nil
	wnd.OnPanelScroll   = nil
	-- reset main panel status
	scroll:SetScrollPos(0)
	wnd:Clear()
	wnd:Lookup('', ''):Clear()

	-- ready to draw
	if not tab then
		-- 欢迎页
		local ui = MY.UI(wnd)
		local w, h = ui:size()
		ui:append('Image', { name = 'Image_Adv', x = 0, y = 0, image = _UITEX_POSTER_, imageframe = (GetTime() % 2) })
		ui:append('Text', { name = 'Text_Adv', x = 10, y = 300, w = 557, font = 200 })
		ui:append('Text', { name = 'Text_Svr', x = 10, y = 345, w = 557, font = 204, text = MY.GetServer() .. ' (' .. MY.GetRealServer() .. ')', alpha = 220 })
		local x = 7
		-- 奇遇分享
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotify',
			text = _L['Show share notify.'],
			checked = MY_Serendipity.bEnable,
			oncheck = function()
				MY_Serendipity.bEnable = not MY_Serendipity.bEnable
			end,
			tip = _L['Monitor serendipity and show share notify.'],
			tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
		}, true):autoWidth():width()
		local xS0 = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityAutoShare',
			text = _L['Auto share.'],
			checked = MY_Serendipity.bAutoShare,
			oncheck = function()
				MY_Serendipity.bAutoShare = not MY_Serendipity.bAutoShare
			end,
		}, true):autoWidth():width()
		-- 自动分享子项
		x = xS0
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipitySilentMode',
			text = _L['Silent mode.'],
			checked = MY_Serendipity.bSilentMode,
			oncheck = function()
				MY_Serendipity.bSilentMode = not MY_Serendipity.bSilentMode
			end,
			autovisible = function() return MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		x = x + 5
		x = x + ui:append('WndEditBox', {
			x = x, y = 375, w = 150, h = 25,
			name = 'WndEditBox_SerendipitySilentMode',
			placeholder = _L['Realname, leave blank for anonymous.'],
			tip = _L['Realname, leave blank for anonymous.'],
			tippostype = MY_TIP_POSTYPE.BOTTOM_TOP,
			limit = 6,
			text = MY.LoadLUAData({'config/realname.jx3dat', MY_DATA_PATH.ROLE}) or GetClientPlayer().szName:gsub('@.-$', ''),
			onchange = function(szText)
				MY.SaveLUAData({'config/realname.jx3dat', MY_DATA_PATH.ROLE}, szText)
			end,
			autovisible = function() return MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		-- 手动分享子项
		x = xS0
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotifyTip',
			text = _L['Show notify tip.'],
			checked = MY_Serendipity.bPreview,
			oncheck = function()
				MY_Serendipity.bPreview = not MY_Serendipity.bPreview
			end,
			autovisible = function() return not MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		x = x + ui:append('WndCheckBox', {
			x = x, y = 375,
			name = 'WndCheckBox_SerendipityNotifySound',
			text = _L['Play notify sound.'],
			checked = MY_Serendipity.bSound,
			oncheck = function()
				MY_Serendipity.bSound = not MY_Serendipity.bSound
			end,
			autoenable = function() return not MY_Serendipity.bAutoShare end,
			autovisible = function() return not MY_Serendipity.bAutoShare end,
		}, true):autoWidth():width()
		-- 用户设置
		ui:append('WndButton', {
			x = 7, y = 405, w = 130,
			name = 'WndButton_UserPreferenceFolder',
			text = _L['Open user preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', MY_DATA_PATH.ROLE})
				if OpenFolder then
					OpenFolder(szRoot)
				else
					XGUI.OpenTextEditor(szRoot)
				end
					XGUI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 142, y = 405, w = 130,
			name = 'WndButton_ServerPreferenceFolder',
			text = _L['Open server preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', MY_DATA_PATH.SERVER})
				if OpenFolder then
					OpenFolder(szRoot)
				else
					XGUI.OpenTextEditor(szRoot)
				end
					XGUI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		ui:append('WndButton', {
			x = 277, y = 405, w = 130,
			name = 'WndButton_GlobalPreferenceFolder',
			text = _L['Open global preference folder'],
			onclick = function()
				local szRoot = MY.FormatPath({'', MY_DATA_PATH.GLOBAL})
				if OpenFolder then
					OpenFolder(szRoot)
				else
					XGUI.OpenTextEditor(szRoot)
				end
					XGUI.OpenTextEditor(szRoot)
			end,
		}, true):autoWidth()
		wnd.OnPanelResize = function(wnd)
			local w, h = MY.UI(wnd):size()
			local scaleH = w / 557 * 278
			local bottomH = 90
			if scaleH > h - bottomH then
				ui:children('#Image_Adv'):size((h - bottomH) / 278 * 557, (h - bottomH))
				ui:children('#Text_Adv'):pos(10, h - bottomH + 10)
				ui:children('#Text_Svr'):pos(10, h - bottomH + 35)
			else
				ui:children('#Image_Adv'):size(w, scaleH)
				ui:children('#Text_Adv'):pos(10, scaleH + 10)
				ui:children('#Text_Svr'):pos(10, scaleH + 35)
			end
			ui:children('#WndCheckBox_SerendipityNotify'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityAutoShare'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipitySilentMode'):top(scaleH + 65)
			ui:children('#WndEditBox_SerendipitySilentMode'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityNotifyTip'):top(scaleH + 65)
			ui:children('#WndCheckBox_SerendipityNotifySound'):top(scaleH + 65)
			ui:children('#WndButton_UserPreferenceFolder'):top(scaleH + 95)
			ui:children('#WndButton_ServerPreferenceFolder'):top(scaleH + 95)
			ui:children('#WndButton_GlobalPreferenceFolder'):top(scaleH + 95)
		end
		wnd.OnPanelResize(wnd)
		MY.BreatheCall(500, function()
			local player = GetClientPlayer()
			if player then
				ui:children('#Text_Adv'):text(_L('%s, welcome to use mingyi plugins!', player.szName) .. 'v' .. MY.GetVersion())
				return 0
			end
		end)
		wnd:FormatAllContentPos()
	else
		if tab.fn.OnPanelActive then
			local res, err = pcall(tab.fn.OnPanelActive, wnd)
			if not res then
				MY.Debug({err}, 'MY#OnPanelActive', MY_DEBUG.ERROR)
			end
			wnd:FormatAllContentPos()
		end
		wnd.OnPanelResize   = tab.fn.OnPanelResize
		wnd.OnPanelActive   = tab.fn.OnPanelActive
		wnd.OnPanelDeactive = tab.fn.OnPanelDeactive
		wnd.OnPanelScroll   = tab.fn.OnPanelScroll
	end
	wnd.szID = szID
end

function MY.RedrawTab(szID)
	if MY.GetCurrentTabID() == szID then
		MY.SwitchTab(szID, true)
	end
end

function MY.GetCurrentTabID()
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	return frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel').szID
end

-- 注册选项卡
-- (void) MY.RegisterPanel( szID, szTitle, szCategory, szIconTex, rgbaTitleColor, options )
-- szID            选项卡唯一ID
-- szTitle         选项卡按钮标题
-- szCategory      选项卡所在分类
-- szIconTex       选项卡图标文件|图标帧
-- rgbaTitleColor  选项卡文字rgba
-- options         选项卡各种响应函数 {
-- 	options.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
-- 	options.OnPanelDeactive(wnd)    选项卡取消激活
-- 	options.bShielded               国服和谐的选项卡
-- }
-- Ex： MY.RegisterPanel( 'Test', '测试标签', '测试', 'UI/Image/UICommon/ScienceTreeNode.UITex|123', {255,255,0,200}, { OnPanelActive = function(wnd) end } )
function MY.RegisterPanel(szID, szTitle, szCategory, szIconTex, rgbaTitleColor, options)
	local category
	for _, ctg in ipairs(TABS_LIST) do
		for i = #ctg, 1, -1 do
			if ctg[i].szID == szID then
				table.remove(ctg, i)
			end
		end
		if ctg.id == szCategory then
			category = ctg
		end
	end
	if szTitle == nil then
		return
	end

	if not category then
		table.insert(TABS_LIST, {
			id = szCategory,
		})
		category = TABS_LIST[#TABS_LIST]
	end
	-- format szIconTex
	if type(szIconTex) == 'number' then
		szIconTex = 'FromIconID|' .. szIconTex
	elseif type(szIconTex) ~= 'string' then
		szIconTex = 'UI/Image/Common/Logo.UITex|6'
	end
	local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
	if dwIconFrame then
		dwIconFrame = tonumber(dwIconFrame)
	end
	szIconTex = string.gsub(szIconTex, '%|.*', '')

	-- format other params
	if type(options)~='table' then options = {} end
	if type(rgbaTitleColor)~='table' then rgbaTitleColor = { 255, 255, 255, 255 } end
	if type(rgbaTitleColor[1])~='number' then rgbaTitleColor[1] = 255 end
	if type(rgbaTitleColor[2])~='number' then rgbaTitleColor[2] = 255 end
	if type(rgbaTitleColor[3])~='number' then rgbaTitleColor[3] = 255 end
	if type(rgbaTitleColor[4])~='number' then rgbaTitleColor[4] = 200 end
	table.insert( category, {
		szID        = szID       ,
		szTitle     = szTitle    ,
		szCategory  = szCategory ,
		szIconTex   = szIconTex  ,
		dwIconFrame = dwIconFrame,
		bShielded   = options.bShielded,
		rgbTitle    = { rgbaTitleColor[1], rgbaTitleColor[2], rgbaTitleColor[3] },
		alpha       = rgbaTitleColor[4],
		fn          = {
			OnPanelResize   = options.OnPanelResize  ,
			OnPanelActive   = options.OnPanelActive  ,
			OnPanelDeactive = options.OnPanelDeactive,
			OnPanelScroll   = options.OnPanelScroll  ,
		},
	})

	if MY.IsInitialized() then
		MY.RedrawCategory()
	end
end
end

---------------------------------------------------------------------------------------------
-- 窗口函数
---------------------------------------------------------------------------------------------
function MY.OnItemLButtonDBClick()
	local name = this:GetName()
	if name == 'Handle_DBClick' then
		this:GetRoot():Lookup('CheckBox_Maximize'):ToggleCheck()
	end
end

function MY.OnMouseWheel()
	local p = this
	while p do
		if p:GetType() == 'WndContainer' then
			return
		end
		p = p:GetParent()
	end
	return true
end

function MY.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Close' then
		MY.ClosePanel()
	elseif name == 'Btn_Weibo' then
		XGUI.OpenBrowser('https://weibo.com/zymah')
	end
end

function MY.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		local ui = MY.UI(this:GetRoot())
		C.anchor = ui:anchor()
		C.w, C.h = ui:size()
		ui:pos(0, 0):event('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
			ui:size(Station.GetClientSize())
		end):drag(false)
		MY.ResizePanel(Station.GetClientSize())
	end
end

function MY.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Maximize' then
		MY.ResizePanel(C.w, C.h)
		MY.UI(this:GetRoot())
			:event('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			:drag(true)
			:anchor(C.anchor)
	end
end

function MY.OnDragButtonBegin()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		this.fDragX, this.fDragY = Station.GetMessagePos()
		this.fDragW, this.fDragH = XGUI(this:GetRoot()):size()
	end
end

function MY.OnDragButton()
	local name = this:GetName()
	if name == 'Btn_Drag' then
		HideTip()
		local nX, nY = Station.GetMessagePos()
		local nDeltaX, nDeltaY = nX - this.fDragX, nY - this.fDragY
		local nW = math.max(this.fDragW + nDeltaX, 500)
		local nH = math.max(this.fDragH + nDeltaY, 300)
		MY.ResizePanel(nW, nH)
	end
end

function MY.OnFrameCreate()
	local fScale = 1 + math.max(Font.GetOffset() * 0.03, 0)
	this:Lookup('', 'Text_Title'):SetText(_L['mingyi plugins'] .. ' v' .. MY.GetVersion() .. ' Build ' .. _BUILD_)
	this:Lookup('', 'Text_Author'):SetText(_L['author\'s signature'])
	this:Lookup('', 'Image_Icon'):SetSize(30, 30)
	this:Lookup('', 'Image_Icon'):FromUITex(_UITEX_COMMON_, 0)
	this:Lookup('Wnd_Total/Btn_Weibo', 'Text_Default'):SetText(_L['author\'s weibo'])
	this:Lookup('Btn_Drag'):RegisterLButtonDrag()
	this.intact = true
	MY.RedrawCategory()
	MY.ResizePanel(780 * fScale, 540 * fScale)
	MY.ExecuteWithThis(this, D.OnSizeChanged)
	this:SetPoint('CENTER', 0, 0, 'CENTER', 0, 0)
	this:CorrectPos()
	this:RegisterEvent('UI_SCALED')
	XGUI(this):size(D.OnSizeChanged)
end

function MY.OnEvent(event)
	if event == 'UI_SCALED' then
		MY.ExecuteWithThis(this:Lookup('Wnd_Total/WndScroll_MainPanel/ScrollBar_MainPanel'), MY.OnScrollBarPosChanged)
		D.OnSizeChanged()
	end
end

function MY.OnScrollBarPosChanged()
	local name = this:GetName()
	if name == 'ScrollBar_MainPanel' then
		local wnd = this:GetParent():Lookup('WndContainer_MainPanel')
		if not wnd.OnPanelScroll then
			return
		end
		local scale = Station.GetUIScale()
		local scrollX, scrollY = wnd:GetStartRelPos()
		scrollX = scrollX == 0 and 0 or -scrollX / scale
		scrollY = scrollY == 0 and 0 or -scrollY / scale
		wnd.OnPanelScroll(wnd, scrollX, scrollY)
	end
end

function D.OnSizeChanged()
	local frame = this
	if not frame then
		return
	end
	-- fix size
	local nWidth, nHeight = frame:GetSize()
	local wnd = frame:Lookup('Wnd_Total')
	wnd:Lookup('WndContainer_Category'):SetSize(nWidth - 22, 32)
	wnd:Lookup('WndContainer_Category'):FormatAllContentPos()
	wnd:Lookup('Btn_Weibo'):SetRelPos(nWidth - 135, 55)
	wnd:Lookup('WndScroll_Tabs'):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):SetSize(171, nHeight - 102)
	wnd:Lookup('WndScroll_Tabs', ''):FormatAllItemPos()
	wnd:Lookup('WndScroll_Tabs/ScrollBar_Tabs'):SetSize(16, nHeight - 111)

	local hWnd = wnd:Lookup('', '')
	wnd:Lookup('', ''):SetSize(nWidth, nHeight)
	hWnd:Lookup('Image_Breaker'):SetSize(6, nHeight - 340)
	hWnd:Lookup('Image_TabBg'):SetSize(nWidth - 2, 33)
	hWnd:Lookup('Handle_DBClick'):SetSize(nWidth, 54)

	local bHideTabs = nWidth < 550
	wnd:Lookup('WndScroll_Tabs'):SetVisible(not bHideTabs)
	hWnd:Lookup('Image_Breaker'):SetVisible(not bHideTabs)

	if bHideTabs then
		nWidth = nWidth + 181
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(5)
	else
		wnd:Lookup('WndScroll_MainPanel'):SetRelX(186)
	end

	wnd:Lookup('WndScroll_MainPanel'):SetSize(nWidth - 191, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetSize(20, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetRelPos(nWidth - 209, 0)
	wnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel'):SetSize(nWidth - 201, nHeight - 100)
	wnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel', ''):SetSize(nWidth - 201, nHeight - 100)
	local hWndMainPanel = frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	if hWndMainPanel.OnPanelResize then
		local res, err = pcall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			MY.Debug({err}, 'MY#OnPanelResize', MY_DEBUG.ERROR)
		end
		hWndMainPanel:FormatAllContentPos()
	elseif hWndMainPanel.OnPanelActive then
		if hWndMainPanel.OnPanelDeactive then
			local res, err = pcall(hWndMainPanel.OnPanelDeactive, hWndMainPanel)
			if not res then
				MY.Debug({err}, 'MY#OnPanelResize->OnPanelDeactive', MY_DEBUG.ERROR)
			end
		end
		hWndMainPanel:Clear()
		hWndMainPanel:Lookup('', ''):Clear()
		local res, err = pcall(hWndMainPanel.OnPanelActive, hWndMainPanel)
		if not res then
			MY.Debug({err}, 'MY#OnPanelResize->OnPanelActive', MY_DEBUG.ERROR)
		end
		hWndMainPanel:FormatAllContentPos()
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	-- reset position
	local an = GetFrameAnchor(frame)
	frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
end

---------------------------------------------------
-- 事件、快捷键、菜单注册
---------------------------------------------------
if _DEBUGLV_ < 3 then
	if not (IsDebugClient and IsDebugClient()) then
		RegisterEvent('CALL_LUA_ERROR', function()
			print(arg0)
			OutputMessage('MSG_SYS', arg0)
		end)
	end
	TraceButton_AppendAddonMenu({{
		szOption = 'ReloadUIAddon',
		fnAction = function()
			ReloadUIAddon()
		end,
	}})
end

if _NORESTM_ >= 0 then
	local time = GetTime()

	local function OnExit()
		debug.sethook()
	end
	MY.RegisterExit('_NORESTM_', OnExit)

	local function OnBreathe()
		time = GetTime()
	end
	BreatheCall('_NORESTM_', OnBreathe)

	local function trace_line(event, line)
		local delay = GetTime() - time
		if delay < _NORESTM_ then
			return
		end
		Log('Response over ' .. delay .. ', ' .. debug.getinfo(2).short_src .. ':' .. line)
	end
	debug.sethook(trace_line, 'l')
end
