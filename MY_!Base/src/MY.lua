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
local function clone(var)
	local szType = type(var)
	if szType == 'nil'
	or szType == 'boolean'
	or szType == 'number'
	or szType == 'string' then
		return var
	elseif szType == 'table' then
		local t = {}
		for key, val in pairs(var) do
			key = clone(key)
			val = clone(val)
			t[key] = val
		end
		return t
	elseif szType == 'function'
	or szType == 'userdata' then
		return nil
	else
		return nil
	end
end
local function empty(var)
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
local function table_r(var, level, indent)
	local t = {}
	local szType = type(var)
	if szType == 'nil' then
		insert(t, 'nil')
	elseif szType == 'number' then
		insert(t, tostring(var))
	elseif szType == 'string' then
		insert(t, string.format('%q', var))
	elseif szType == 'function' then
		local s = string.dump(var)
		insert(t, 'loadstring("')
		-- 'string slice too long'
		for i = 1, #s, 2000 do
			insert(t, concat({'', byte(s, i, i + 2000 - 1)}, '\\'))
		end
		insert(t, '")')
	elseif szType == 'boolean' then
		insert(t, tostring(var))
	elseif szType == 'table' then
		insert(t, '{')
		local s_tab_equ = '='
		if indent then
			s_tab_equ = ' = '
			if not empty(var) then
				insert(t, '\n')
			end
		end
		local nohash = true
		local key, val, lastkey, lastval, hasval
		local tlist, thash = {}, {}
		repeat
			key, val = next(var, lastkey)
			if key then
				-- judge if this is a pure list table
				if nohash and (
					type(key) ~= 'number'
					or (lastval == nil and key ~= 1) -- first loop and index is not 1 : hash table
					or (lastkey and lastkey + 1 ~= key)
				) then
					nohash = false
				end
				-- process to insert to table
				-- insert indent
				if indent then
					insert(t, rep(indent, level + 1))
				end
				-- insert key
				if nohash then -- pure list: do not need a key
				elseif type(key) == 'string' and key:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then -- a = val
					insert(t, key)
					insert(t, s_tab_equ)
				else -- [10010] = val -- ['.start with or contains special char'] = val
					insert(t, '[')
					insert(t, table_r(key, level + 1, indent))
					insert(t, ']')
					insert(t, s_tab_equ)
				end
				-- insert value
				insert(t, table_r(val, level + 1, indent))
				insert(t, ',')
				if indent then
					insert(t, '\n')
				end
				lastkey, lastval, hasval = key, val, true
			end
		until not key
		-- remove last `,` if no indent
		if not indent and hasval then
			remove(t)
		end
		-- insert `}` with indent
		if indent and not empty(var) then
			insert(t, rep(indent, level))
		end
		insert(t, '}')
	else --if (szType == 'userdata') then
		insert(t, '"')
		insert(t, tostring(var))
		insert(t, '"')
	end
	return concat(t)
end
local function var2str(var, indent, level)
	return table_r(var, level or 0, indent)
end
local str2var = str2var
if not str2var then
local szTempLog = 'interface/temp.log'
local szTempJx3dat = 'interface/temp.jx3dat'
function str2var(szText)
	Log(szTempLog, szText, 'clear close')
	CPath.Move(szTempLog, szTempJx3dat)
	local data = LoadLUAData(szTempJx3dat)
	CPath.DelFile(szTempJx3dat)
	return data
end
end
local function Get(var, keys, dft)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			insert(ks, k)
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
local function Set(var, keys, val)
	local res = false
	if type(keys) == 'string' then
		local ks = {}
		for k in string.gmatch(keys, '[^%.]+') do
			insert(ks, k)
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
local function RandomChild(var)
	if type(var) == 'table' and #var > 0 then
		return var[random(1, #var)]
	end
end
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
				insert(oPatch, { k = k, v = patch })
			end
			tKeys[k] = true
		end
		for k, v in pairs(oBase) do
			if not tKeys[k] then
				bDiff = true
				insert(oPatch, { k = k, v = nil })
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
		-- other patch value
		return { v= oData }
	end
	-- empty patch
	return nil
end
local function ApplyPatch(oBase, oPatch, bNew)
	if bNew ~= false then
		oBase = clone(oBase)
		oPatch = clone(oPatch)
	end
	-- patch in dictionary type can only be a special value patch
	if IsDictionary(oPatch) then
		-- nil value patch
		if oPatch.t == 'nil' then
			return nil
		end
		-- raw value patch
		if oPatch.v then
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
local ipairs_r
do -- 选代器 倒序
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
local spairs, sipairs, spairs_r, sipairs_r
do -- 类型安全选代器
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
				insert(iters, {v, argv[i], j})
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
				insert(iters, {v, argv[i], j})
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
				insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, 0
end
function spairs_r(...)
	local argc = select('#', ...)
	local argv = {...}
	local iters = {}
	for i = 1, argc do
		if IsTable(argv[i]) then
			for j, v in pairs(argv[i]) do
				insert(iters, {v, argv[i], j})
			end
		end
	end
	return SafeIterR, iters, 0
end
end
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
local function GetTraceback(str)
	local traceback = debug and debug.traceback and debug.traceback():gsub('traceback:.*MY%.lua:%d+:%sin%sfunction%s\'GetTraceback\'[^\n]*', 'traceback:')
	if traceback then
		if str then
			str = str .. '\n' .. traceback
		else
			str = traceback
		end
	end
	return str or ''
end
local MENU_DIVIDER = { bDevide = true }
local EMPTY_TABLE = SetmetaReadonly({})
local XML_LINE_BREAKER = GetFormatText('\n')
---------------------------------------------------------------------------------------------
MY = {
	clone        = clone       ,
	empty        = empty       ,
	var2str      = var2str     ,
	str2var      = str2var     ,
	ipairs_r     = ipairs_r    ,
	spairs       = spairs      ,
	spairs_r     = spairs_r    ,
	sipairs      = sipairs     ,
	sipairs_r    = sipairs_r   ,
	IsArray      = IsArray     ,
	IsDictionary = IsDictionary,
	IsEquals     = IsEquals    ,
	IsNil        = IsNil       ,
	IsBoolean    = IsBoolean   ,
	IsNumber     = IsNumber    ,
	IsUserdata   = IsUserdata  ,
	IsEmpty      = IsEmpty     ,
	IsString     = IsString    ,
	IsTable      = IsTable     ,
	IsFunction   = IsFunction  ,
	Set          = Set         ,
	Get          = Get         ,
	GetPatch     = GetPatch    ,
	Class        = Class       ,
	ApplyPatch   = ApplyPatch  ,
	RandomChild  = RandomChild ,
	GetTraceback = GetTraceback,
	MENU_DIVIDER     = MENU_DIVIDER    ,
	EMPTY_TABLE      = EMPTY_TABLE     ,
	XML_LINE_BREAKER = XML_LINE_BREAKER,
	EQUIPMENT_SUIT_COUNT = EQUIPMENT_SUIT_COUNT or 4,
}
MY_DEBUG = SetmetaReadonly({
	LOG     = 0,
	PMLOG   = 0,
	WARNING = 1,
	ERROR   = 2,
})
---------------------------------------------------------------------------------------------
-- 本地函数变量
---------------------------------------------------------------------------------------------
local _BUILD_ = '20190131'
local _VERSION_ = 0x2012100
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
local _MENU_COLOR_ = {35, 180, 246}
local _MAX_PLAYER_LEVEL_ = 100
-----------------------------------------------
-- 私有函数
-----------------------------------------------
do local AddonInfo = SetmetaReadonly({
	szName          = _NAME_          ,
	szShortName     = _SHORT_NAME_    ,
	szUITexCommon   = _UITEX_COMMON_  ,
	szUITexPoster   = _UITEX_POSTER_  ,
	szUITexST       = _UITEX_ST_      ,
	dwVersion       = _VERSION_       ,
	szBuild         = _BUILD_         ,
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
	tMenuColor       = _MENU_COLOR_      ,
	dwMaxPlayerLevel = _MAX_PLAYER_LEVEL_,
})
function MY.GetAddonInfo()
	return AddonInfo
end
local function onPlayerEnterScene()
	_MAX_PLAYER_LEVEL_ = max(_MAX_PLAYER_LEVEL_, GetClientPlayer().nLevel)
end
RegisterEvent('PLAYER_ENTER_SCENE', onPlayerEnterScene)
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
	if _VERSION_ < dwMinVersion then
		MY.Sysmsg({
			_L('%s requires base library version upper than v%s, current at v%s.',
			szCaption, MY.GetVersion(dwMinVersion), MY.GetVersion()
		)})
		if not IsDebugClient() then
			return false
		end
	end
	return true
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
	RegisterEvent('RELOAD_UI_ADDON_BEGIN', OnExit)

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
