--------------------------------------------
-- @Desc  : 茗伊插件主界面
-- @Author: 茗伊 @双梦镇 @追风蹑影
-- @Date  : 2014-11-24 08:40:30
-- @Email : admin@derzh.com
-- @Last Modified by:   翟一鸣 @tinymins
-- @Last Modified time: 2015-05-18 09:45:00
-- @Ref: 借鉴大量海鳗源码 @haimanchajian.com
--------------------------------------------
-- ####################################################################################################################################
-- # # # # #   # # # # #                                       #                         #           #                 # # # # # #     
--   #     #     #     #                           # # # #   # # # # #                   #     # # # # # # #   # # # #           #     
--     #   #       #   #                           #     #   #       #                 #       #           #       #     #       #     
--   #     #     #     #                           #     #   #   #   #                 #   #   # # # # # # #       #     #       #     
--       #     #                                   #     #   #     # #                 # #     #                 #       #       #     
--     # # # # # # # # #                           #     #   #                           #     # # # # # # #     # # #   # # # # # #   
--   # #       #           # # # # # # # # # # #   #     #   # # # # # #               #       #   #   #   #   # #   #             #   
-- #   # # # # # # # #                             #     #             #               # #   # #   #   #   #     #   #             #   
--     #       #                                   # # # #             #                       # # # # # # #     #   # # # # # #   #   
--     # # # # # # # #                             #     # # # # # #   #                   #   #   #   #   #     # # #             #   
--     #       #                                                       #               # #     #   #   #   #     #   #             #   
--     # # # # # # # # #                                           # #                         #         # #                   # #     
-- ######################################################################################################################################################
-- : :,,,,,,.,.,.,.,.,......   ;jXFPqq5kFUL2r:.: . ..,.,..... :;iiii:ii7;..........,...,,,,,,:,:,,,:::,:::,:::::::::,:::::::::,:::,:,:::::::::::::::::::.
-- ,                         ,uXSSS1S2U2Uuuuu7i,::.           ........:::                         . . . . . . . . . . . . . . . . . . . . . . . . . . .. 
-- : :.,.,.,.,.,.....,...  :q@M0Pq555F5515u2u2UuYj7:         :,,,:,::::i:: ........,...,.,.,.,,,,,.,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:.
-- , ,,.,.,.............  7OMEPF515u2u2UULJJujJYY7v7r.  . ....,,,.,,:,:,,.................,.,.,.,.,.,,:,,.,,,,:,:,:,:,:.,,,,,,,.,.,.,.,,,.,,,,:,,,,,,,:,.
-- , ,.,...............  uBEkSU2U1u2uUJuvjuuLL7v77r;ri,.,,..   . ..,,,,..,.................,.,.,.,.,.,.,.,.,.,.,.,.,,,.,.,..           ....,,,.,,,,,.,,, 
-- , ,,.,...............v5XXF21U1uFU2JUUuJjvvr7rriii:::.            ..:.. . ..................,...,.,.,.,.,,,.,.,.,.,....   :,;i7YLv7:.    ...,.,.,.,,,, 
-- , ,................ :Uk1q2Pk5u11uJ55uvuYYv7rrii::,,.              ...    ...................,.,.,.,.,.,.,,,.,.,.,..: ..iO@@BMB@B@B@MMqui  ..,.,.,.,.: 
-- . .,..............  iPFuUXXX2jJuLJJJvL7v7v7rii::,.                 ...    .................,...,.,.,.,.,.,.,.,.,. 2;iPFNXNE08kYGUSO@B@@@k:  ...,.,.,,.
-- , ,.,.............. rS1jU1FF1U12jvL7vv7r777ii::...                  ...   . ....................,.,.,.,.,...:,...:5EZL7uE1r   j@P   :7NB@Bq, .,.,.,,: 
-- . ...,............  iSLYuuU11qXX5122jY7rii::.::,..                   ,,    ........................,.,.,.. ,L,. rEJUi:5S,   :BBJ::.    .S@BM: .,.,.,,.
-- , ,.,.,............ ;UYvuYjUF555FkSuY7i::.....:.,.                   .:.    . ..................,.,.,.....i7,:..OJr:.Lk  7SB@u. .L@BF    r@Br ..,.,., 
-- . ...,............. :SYLY5U1uuLv77ri:,.,.. . .....                   .,,    ................ .......... ,Y,  :.,vi,. rLr,1B2E@BX...O@r:   2@O  ..,.,. 
-- , ,................  71LUFFSJ7r:,.,......         .                   ,,:.  . ......... ....i:. ... . i;Zr  . ruL. ,.::,7:.:@BB::ri,:X@q. ,B@  ....., 
-- . ..................  JkFX1jiii:,,.......  ....    .                 ..:::::, .......  :.. .7,1  r7:.,ii@v rrL5.k .70;ri:71@0: .iMB@8r.,, .MB: ...... 
-- , ,..................  u817:,.:::.....,,::i::,,.   .                ..,:iiiir  ..... ,NJ . ::iLvu rL7JFiv::..E7 S8: :jL :5PUr,rjS1::PB@Bu ;PBi ,F7v , 
-- . .................... :X0,..755J7ri:::::::i....   .               ..,::i7777i ..... vOr  ivurvPr SUrjL:,20ii;r,uJr:rGPv : :r..:u@X   i,  8PX. .FL:.,.
-- , ,...................  :E7 :vLriirr7i..:i7r:..   .               ..,:r,  ,ivL, ......:.  .Ui7ULY:r ;2jvu1B2JiL;v571vuikr7 i:rq7ii7i,    7B1, .,r..., 
-- . .,..................   r5.:irvvu::iL   .::..       .           ..,::      .ii....... .,ii750i.i12,1iLv:v1O@8B8LJU:i, iNSiqJkviiru@@Br 1Ev. ......,. 
-- , ,.....................  rr.:;i;:..iv.     ...   . .,.       ..,.:::i.   .   ..........,::i: .::i::,,.,:...,.....,,,:5UNur:,.:::..  :0BO:. ..,...,., 
-- . .,.,.................... :..::...:7:..   .,,.......:,......:::::,,:i:  . . ...........       ..  ..  .. ..   ..  . .::.. . .  .i7j0@Pi. .,.,.,.,.,,.
-- , ,.,......................  .i:...ir.:. :, .,,.... ,ri::::.:::,:,::i,. ..........................,.,.,...,.,.,.,,,.....:i7rUX55qGP7:   ....,.,.,.,.: 
-- . .,......................   .,ri:,LvjU;,,.  ..,.... rri::::::,:::::i, ..........................,.....,.....,.,.,.,...... . ..      ....,.,.,.,.,.,,.
-- , ,.....,.................  78:.rii;7;r::.:,::,.. :i ,viiii:i:i:i:iir  .........................,.,.....,.,.,...,.,...,.,....... .,.....,.,.,.,.,.,., 
-- . ...,.....................UMMOr.:ir7vvvri:::,.. :5:  77iri;iiiiiii7i  ............................,.,.,.,.,...,.,...,.,.,.,....i F,::.,.,.,.,.,.,.,, 
-- , ,.,...,.,.,.,...........i75ZMBkiii7LLii:i,. . :52   :jLrr;ri;;r7LJ: . ........................,.,.,.,.,.,.,.,.,.,.,.,.,.,.,..,N 5 Lv .....,.,.,.,., 
-- , .,.,...,.,........       ,7BOMMGuriiii::.. ..:Yq: .  .i7LuYL7vrrii. ...........................,...,...,.,.,.,...,...,.,...,.,0.山Uv ..,.,.,.,.,.., 
-- , ,.....,.,......   ..,,.rLL77OM8N0Fu7ri::::::irPu. .,,   .:,,uq:    ...........................,.,.....,.,.....,.,...,.,.......:::,i...,.,.,.....,., 
-- . .,.,.,...... ..:iu2v7juEFurrrMO0SSSkuUJJ77iirkq: .,,......  .Y:  . ..........................,...,.,...,.,...,.,.,.,.,.,.,....:,,,::...,.,.,.....,..
-- , ,.,.......::;71FkU7jZZM5r;rP:rBOEXXSS2j7;ii71U: ,,:...,.:::,...   . ............................,.,...,.,.,.,.,.,.,.,.,.,....,7;Y71r .,.,.,......., 
-- . ...,....,:i7LY7rirL5SE5::;kj;iiSPFuuuL77i:iv;,.,,:.,,:,:,,,::::::,   ........................,.,.,.,...,.,.,.,.,.,...,.,.,....rJ河vi ....,.,.,.,.,,.
-- , ,.,....,::7ri:ir7Jv7u1r;iiSrv2kv7:.rr  :v7Lr .:,:,,,,,:,::::::::::::,  .........................,.,.,.,.,...,.,...,.,.,...,...5.::S:....,.,.....,., 
-- . .,.,...:::ir;7777YirLJrvr:iiuE;i:  v:. ,iru. ,,,,:,:::,:::,:::::,::::: ..............................,.,.,.,.,.,.........,.,..   ........,.,.,...,. 
-- , ,.,...:rvr:r7ir;J7iivr;r7i:ivX  i  :. ...vJ.,,:::::,,::::,:i:,:,::::::: ........................,.,.,...,.,...... .   ....,...:FL:..............,., 
-- . .... .rvLS:ir;iru7:riiirri:7q@.....,:. ..Br .::::,.::::,,ii:,::ii::::i:. ....................,.,.,.........,.....rFrYu:........0:k: .............,, 
-- , ,... iuvL07:;iir57iir;rrrii78i .:i.:r:...v,..::,,,::::::ii:,::iir,::i:i, .............................,.......,..vq華0: ..... rU九r7........,....., 
-- . ... .LYuL05riii7Lurrrr;7;riYS .;rv::::..   ..::,,:::,:,ii:i::;:ri,::i::: ......................,.............,...JjN1Si..... ,r  ,r; ..,.........,. 
-- , ,.. 7uLjuS0ri:r7Lvr;rir;rii1Z :rri7:::,......::,:::,:,ii:ir,iiir:::ii:i:  ......................,.......,.,.,....,.i:.:...,.. ,. ,. ............,., 
-- . .. :LYjjJPM7:ir7vv;rr7rrrirZMJ::iirr,:.......::::::::ii::7i:;ii;:::i::ii ..................,.,.,...,.......,.....  ,   ..... :GS7EGr ..,.....,.,.,, 
-- , .. vv7jj11@u:i7rv7rr7rri7iL088v:iiiri,,.....::::::::ii:::Yi:r:r:::i:::;:. ......................,.,...,.,...,.,..v U:,7 .... :Ok轉0v .,.,...,...,., 
-- . . .227vjSFO0,irr77irrri;r7r20OO7:;;r;:,.....:i:::::ii:::i2:ii7i::iri:iii ..............,...,.......,.,.,...,.,...0 山iu .,.,..uv:v5r ....,.,.,...,. 
-- , . i7XJvJPFEMr:rrrr7r;iiirir7S0MMU:iirr:.,.. :7i:r:::iii:YL::r7::rriii:i:  ................,...,...,...,.....,....Si57JJ ..,..     . ..........,.,., 
-- . ..;rjXvjkqX@O;r7rrii:iiri;i77YJ8BZ7,:ii,....:Y,iriiiii:i27:ivLr7ri:i::i: ................,.........,...,........  .. , .......v7777 ...,.,...,..... 
-- . . 7rvkuuPqkO@YvLL77vuu7i;irvr;iYG8Bj,:rr:,..:.,:irriii:rSi:rLrvriii:i:i: .....................,.,.....,......... i::7ir ..,...FL風1 ..,...,.,.,..., 
-- . ..7r7FFUkZ58BkrFU1UUFkriirrur7rrFNN@2,:Lr,,::::::irrii:uu:ivv7;i:::::ii: ..............................,.....,...GJ絕Nv .... :FLk1Si ....,...,.,.,. 
-- . .,Li72kUkqXN@B7LUJujkur:irv7ivYiFjFE@87i,,:::::::,irr:ik7:7v7i:,,,::::i.  ........................,.,.....,.... ,FukL72 .....::.,.7L .......,...,., 
-- . .:LrrUk55EPqM@Pvuuu1FJriivv7:vu;uL7FSG7irr::::::::::7755:7SL;rrrrrri:ii. ..............................,...,.,..,i.r::r....,....  . ...,.....,..... 
-- . .:L;rYk2FPEqMBE71U1USvr:rL7;rr1v1L7Uui7ri7vi:::::::::2ZriYvir77rr;rriii ....................,.,.......,.....,.,.... ........ :MqUuk: .......,....., 
-- . .;LrrL5F2PZOB7.Uj5J12rrirYr7rrj2Fj1EEGYv7r7jri::::::.vU71krii::i:iirri:......................,.,.,.,.,.....,.,...U77k27 .... ,uL飄P: ..,.,.,....... 
-- . iiJrr7151SOM8 rNu1jS1i7:7vrr7i7F05FPZ8@1YJvvjvri;i:::,,:SEi,i,::iiiiri: ..........................,.,.....,...,. i:頂uF ..,..,5LYrFu .,.,.,.,...,., 
--   riv7irYFFk8@U FOYUF0vr7i;v77r7i2Zu1kk0M@kYYLLF7rri::::,:.U0u7i,,:iiii;: ...........................,.........,...U:uvuu .,.....    ,.....,.,...,... 
--  .riLvii7YkXMB: GZ5j05;rLiii777rruMLLJjuFB@XjuLuUi;i::i:::::7USFUr:::::r: ................,.......,.,.........,.,.,: .  :...,.. L7iiri..,.,.,...,..., 
-- :LLr7LiLLJ2qOq  ZOS5Pj;LYrirrL77iuMLrYLu75O@01LvYJr2vi;i::::,:iFUU7::iir. .................,.......,.,.,.,...,.,.. ..:.: ..,.,..uP絮7i ,.,...,.,...,. 
-- rrL;rLr7Y1EO@r  XBONFr7L1;iir7Yri7@j777uJ;Y0@ZFuL7vqSrvrr:iii::UOLi:iiri. ..............................,.,.,.,.,..2u坐ki...... 7GSY5...,...,.....,., 
-- ::;;;7ir7vJZ;   vME5777J1J:ri7J7iiMXiLL2UJrv0@G1LivE7iYvr;irr::,7M5i,iir ..............,.....,...,...,.,...,.,.,...7i01;:.......7rL:vi.....,.,.,...,. 
-- ,.::1SL:rv1X.   jkXvLLYJUFvr;iYvi:SOirLj11uvL0@Mui2E;.Yv7riiL:i:.iPFr:ii .........................,...,.,.......,..iivrii.......  .  ...,.....,.,..., 
-- v:iFXZOFi,,     kFUujUJuYU12virLii7Mii;vJ15uYjX@@1v82.;7i7rLji:iii7rUv:: ............,.....,.............,.,.,.....  . ....,.............,.,.,.,.,,,,.
-- Yi7JLuNOEJ:,:  .XNkY1uuYjvJLuri7riiZr:7rLUXuuYu18BGUN17iirvjYLri7:777qL ..................,...,...,...,...,.,.,.,..u7rrii.,.,...,.,.,.,.,.,...,...,., 
-- 7i;JY7ivuFXPGO.70ZZ2YUu2UuJYvY;rrr:PLi7v7YuFUUJJj5GMqPku;iLuLSvrrr;7LU1 ...............,.,...,.,.,...,.,.,...,.,.. 7L忘r,..,.,...,...,.,.,...,.....,..
-- ::7;7rirYj2UNOuMMXE5juuuuu12Yr7r7rij5::r7rvLUu221uJuEZk5ur77uS177;rruLr ..............,.,.,.,.,.....,.,.,.,.,.....:LY;7Lv...,.....,...,.,...,.,....., 
--  :1Liiirir7L7PXO@OSujuJuYYLJJ7rvrrirOi:ii77vvju55k51YU5X5U7rJk5LLrivJ7  .................,.,.....,...,...,.,.,..... ,::. ..,.,.,.,.....,.,.....,...,..
-- . LL7;ririrr71FYGBBNFuuJuJjLuv;r7rr:O1.:iirrvvJjU5XqNS2uFSFvLU1LY;rYv. ...............,.,.,.....,.,.,...,.,...,.,. :.,:ii...,...,...,...,.,...,...,., 
-- . iJ777ri;rvLU1,v2EBOZSSUujuuurrir;iL@i::ii;irrvLuu5XE0q221X1Ujv7Li.  .................,.,.,...,.,.,.,.,.....,.,...0L經17 .,...,.,.,...,...,.,.,.,.,..
-- , .7LLYr;r7;rrX::ivY5FXSP52UUuLr;i;iiqG.::iiiii;77LLjukPqS12NEFL0Bi  .............,.....,.,...,.,.............,....S57Ju; ..,...,.,.,.,.,...,...,.,., 
-- , .:vY7i;ririiMGr:::irrvL2U1uuJY7rii:iMr:iii:i:::i;77LLu1Pkkk1.M@@B@E: ............,.,...........,.,...,...,...,..:vr;Yj:......,.,.,.....,.,...,...,. 
-- : . irii7iri:i@B@Yi:,,,,::i;v7LLjLL77i55irrrriiii:i:iir7YUP2F: B@B@2  ........................,.,.,...,...,.,.,.,..  ...,...,.,.,.,...,.,.,.,.,.,.,., 
-- , ...Y7v77rr:i1@BB5NFYvv777rirvLLYLjJu5krv7YJjLjJUjJvj1k1Yr7i  @B@Br ..................,.........,.,.,.,.,.,.,.,.,.,.............,.,.,.,.,.,.,.,.,.,,.
-- : ,..:vLLvL7riiu@BZO@B@BBOMOMOOGEE8GMB@PJ2SU1kq2Lv2qPuv:,...   B@B@J .........................,.,.,.,.,.,.,.,.,.,.,....     :::,.  ...,.,,,.,,,.,.,., 
-- , ,,..rX2uvr;r:,jGLvvuSGM@MBGZ0NSS112ZMk7Lu2v;vSqXvi:      .   kB@M  ..............,.........,.,.,.,.,,,,,.,,,.,.,... .ir7U5uJJuUu7: ..,.,.,.,.,.,.,,.
-- : ,.. ,FquLLvii::77::,:,:irvFXqXkUUYYLFSL77LSS;::i.    .. .... 7@BE  .......................,.,.,,,,,,,,,,,.,,,,,.. ,vuF:M@.     .7k1, ...,.,.,.,.,.: 
-- , .,.. :uYvv77ii::i::i...i   .:rLU5YJLiY::.       ,  . .. .... 7B@O  ..........................,.,.,.,.,.,.,,,.,.. v1LFZS@  .,2XUL  rEF. ..,.,,,.,.:,.
-- : :.,.. 7ujvv7rir:ii:,:.r7..:.. ....vLLi77LYLJ   .......,....  ;@BB  .........................,.,.,.,.,.,.,.,.,.. 5Ui05LMS . E@1@B@L..PM,...,.,.,,,., 
-- , ,,.,...LYv77rri;:i:.  ,:.,:....:.18kii7J7.rMU  ,.:..,,   ... iB@B  ......................,.,.,.,.,.,.,.,.,.,., 7P:Mv7JMM ..:jUi .q7:.PO....,.,.,.,,.
-- , ,,,.,. :Y7L7riiiiiUZF7:  :ii:::::207.,.   .58.......   ...   :@B@  .....................,.,.,.,.,.,.,.,.,.,....E,kki.5LBS.........;i;:@v..,.,.,.,,, 
-- ,.,,.,....rLvv7L77:,.i7Lu7   . ,.::JGkri:::.i8Y..  .   ...     :B@B  ..........,.........,...,.,.,.,.,.,.,.,.,..:q.@L: :NYO@8L:,ii::irr:q0:..,.,.,.,,.
-- : :,,.,., .LXPq0u7rii::,,,i.        iYF1vi:;7,  ...        ..   @B@  .........,.,.........,.,.,.,.,.,.,.,.,.,.. rP.BL,. .7uv2M@0i:rii;7:1Zi...,.,.,., 
-- ,.::,,,,.. ::..2k1L7rLLvri,:.          .        .,....   ..,..  @@@. ..................,.....,.,.,.,.,.,.,.,.,..:Z PS.  ivuMOY;B@ui77r: 5Gi,.,.,.,.,,.
-- :.:,,,,,,..     uX1L77JuXkL::.  . .            .. ....,,:,.     8@@. ...,.....,...,...,.,.,.,.,.,.,.,.,.,.,.,... 8;.@: LGrUviMO uBJrJv, @ui...,.,.,,, 
-- :.,:,:,,.,.....  i,.    .72urri        .       ....,,,..     .. v@B, ....,.,.....,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.. iB,rM.vPrO@P.q, B@rL7:OO7:..,,,.,.,,.
-- :.:,,,,,,,,.,.,  .:....   :SPYv:      ..    . ..,,,.... .    .. rB@: .,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,,,,,,,.,,,.. rBjvZjkk5OM:iri0@i7jB8L:,.,.,.,.,,: 
-- :.::,:,:,,.,.,.....:::,.   .r5jv,  ...,. . ..,.... ..      ...  i@B: ,.,.,,,.,,,.,,,,,,,,,.,,,,,,,,,.,,,,,.,,,,,,. :OM11u2257vLvL@UJG@Xvi,.,.,,,,,,:,.
-- :.:::::,,,:,,.,....,:,,,.     ::......: ... . .   ... .   ... . :@@i .,.,.,.,,,.,,,,,,,,:,:,:,:,:,:,,,,,:,:,:,:,:,...rZMOX1u1FkE@B8MZJ7:..,,:,,,:,,,:.
-- :.::,:,,,:,,,,,,....::,,,,...  ..... ,,  ... . ..... ... ..     r@Br ,.,,,.,.,.,,,,,,,,:,:,:,:,:,:,:,,,:,,,:,:,:,,,,...iJPEO8OZ011uvi:.,.,,:,:,:,:,::.
-- :.:::,:,,,,,:,,,.,..:::::,..  . ......,...... ..,.      .   .   rB@7 .,.,.,,,.,,,,,,,,:,:,:::,:,:,:,:,:,:,,,,,,,:,:,,.....::iii::,:.....,,:,:,:,:,:,:.
-- :.::::,:,,,:,,,,.:,ri:::::::.........,.... .....   . ...   .    :@@7  .,.,,,,,,,,:,,,,,:,:,:,:,,,:,,,,,,,:,:,:,,,:,::,,,...........,.,,:,:,:,:,:,:,:,.
-- :.:::,:,:,:,:,,,.:i:77;:,,:,,...,,:,:::...,..     . . . ... .   rB@7 i: ,,:,,,,,,,:,,,,,:,:,:,:,:,:,:,:,:,:,:,,,:,:,:,:,:,:,,.,,,,:,,::,:,:,,,:,:,,,:.
-- :.::::,:,:,:,,,,,,ii:irL77r7rri:,,,i7LJZL:.                  .. v@BMu@u .,,:,,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,.
-- :.:::::::::::,:::.:ii:iirrr;7rr7rirr7ii7Err::,:,:::,,,:::,..,.. UBM@@B@. .:,:,:::,:,:,:,:,:,:,:::::::::::::::::::::::::::::::::::::::::::::,:::::::::.
-- : ............ ... ,,,.,..         .:;i:rir7rr;rii::..          k@BF :O@J. . ........................................................................ 
-- ######################################################################################################################################################

MY = {}
-- ##################################################################################################################################################
--             #                 #         #           # # # # # # # #             #       #                   #               # # # # # # # # #     
--             #                 #         #                       #           #   #   #   #         # # # # # # # # # # #     #       #       #     
--   # # # # # # # # # # #       #     #   #   # #   #           #       #         #       #               #       #           #         #     #     
--             #                 #     #   # #   #   #   #     #     #   #   # # # # # #   # # # #     #   #       #   #     # # # # # # # # # # #   
--           # # #           # # # #   # # #     #   #     #   #   #     #       # #     #     #     #     #       #     #     #       #       #     
--         #   #   #             #   # #   #     #   #         #         #     #   # #     #   #                               # # # # # # # # #     
--         #   #   #             #     #   #     #   #     #   #   #     #   #     #   #   #   #       # # # # # # # #         #       #       #     
--       #     #     #           #     #   #   # #   #   #     #     #   #       #         #   #         #           #         # # # # # # # # #     
--     #       #       #         #     #   #         #         #         #   # # # # #     #   #           #       #                   #             
--   #   # # # # # # #   #       # #   #         #   #       # #         #     #     #       #               # # #             # # # # # # # # #     
--             #             # #       #         #   #                   #       # #       #   #         # #       # #                 #             
--             #                         # # # # #   # # # # # # # # # # #   # #     #   #       #   # #               # #   # # # # # # # # # # #   
-- ##################################################################################################################################################
local _DEBUG_ = tonumber(LoadLUAData('interface/my.debug.level') or nil) or 4
local _BUILD_ = "20150513"
local _VERSION_ = 0x2003400
local _ADDON_ROOT_ = '/Interface/MY/'
local _FRAMEWORK_ROOT_ = '/Interface/MY/.Framework/'

-- 多语言处理
-- (table) MY.LoadLangPack(void)
MY.LoadLangPack = function(szLangFolder)
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData(_FRAMEWORK_ROOT_.."lang\\default") or {}
	local t1 = LoadLUAData(_FRAMEWORK_ROOT_.."lang\\" .. szLang) or {}
	for k, v in pairs(t1) do
		t0[k] = v
	end
	if type(szLangFolder)=="string" then
		szLangFolder = string.gsub(szLangFolder,"[/\\]+$","")
		local t2 = LoadLUAData(szLangFolder.."\\default") or {}
		for k, v in pairs(t2) do
			t0[k] = v
		end
		local t3 = LoadLUAData(szLangFolder.."\\" .. szLang) or {}
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
-----------------------------------------------
-- 私有函数
-----------------------------------------------
local _MY = {
	frame              = nil,
	hBox               = nil,
	bLoaded            = false,
	dwVersion          = _VERSION_,
	nDebugLevel        = _DEBUG_,
	szBuildDate        = _BUILD_,
	szName             = _L["mingyi plugins"],
	szShortName        = _L["mingyi plugin"],
	szIniFile          = _FRAMEWORK_ROOT_.."ui\\MY.ini",
	szUITexCommon      = _FRAMEWORK_ROOT_.."image\\UICommon.UITex",
	szUITexPoster      = _FRAMEWORK_ROOT_.."image\\Poster.UITex",
	szIniFileMainPanel = _FRAMEWORK_ROOT_.."ui\\MainPanel.ini",
	
	tTabs = {   -- 标签页
		{ id = _L["General"], },
		{ id = _L["Target"] , },
		{ id = _L["Battle"] , },
		{ id = _L["Others"] , },
	},
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
	tEvent = {},        -- 游戏事件绑定
	tInitFun = {},      -- 初始化函数
}
_MY.tAddonInfo = SetmetaReadonly({
	szName          = _MY.szName                      ,
	szShortName     = _MY.szShortName                 ,
	szUITexCommon   = _MY.szUITexCommon               ,
	szUITexPoster   = _MY.szUITexPoster               ,
	dwVersion       = _VERSION_                       ,
	szBuildDate     = _BUILD_                         ,
	nDebugLevel     = _DEBUG_                         ,
	szRoot          = _ADDON_ROOT_                    ,
	szFrameworkRoot = _FRAMEWORK_ROOT_                ,
	szAuthor        = _L['MingYi @ Double Dream Town'],
	tAuthor         = {
		[43567  ] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 体服
		[3007396] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 枫泾古镇
		[1600498] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 追风蹑影
		[4664780] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 日月明尊
		[385183 ] = string.char( 0xE8, 0x8C, 0x97, 0xE4, 0xBC, 0x8A ), -- 傲血戰意
		[3627405] = string.char( 0xC1, 0xFA, 0xB5, 0xA8, 0xC9, 0xDF, 0x40, 0xDD, 0xB6, 0xBB, 0xA8, 0xB9, 0xAC ), -- 白帝
		-- [4662931] = string.char( 0xBE, 0xCD, 0xCA, 0xC7, 0xB8, 0xF6, 0xD5, 0xF3, 0xD1, 0xDB ), -- 日月明尊
		-- [3438030] = string.char( 0xB4, 0xE5, 0xBF, 0xDA, 0xB5, 0xC4, 0xCD, 0xF5, 0xCA, 0xA6, 0xB8, 0xB5 ), -- 枫泾古镇
	},
})
MY.GetAddonInfo = function()
	return _MY.tAddonInfo
end
_MY.Init = function()
	if _MY.bLoaded then
		return
	end
	_MY.bLoaded = true
	-- init functions
	for szKey, fnAction in pairs(_MY.tInitFun) do
		local nStartTick = GetTickCount()
		local status, err = pcall(fnAction)
		if not status then
			MY.Debug({err}, "_MY.tInitFun#" .. szKey)
		end
		-- performance monitor
		MY.Debug({_L('Initial function <%s> executed in %dms.', szKey, GetTickCount() - nStartTick)}, _L['PMTool'], MY_DEBUG.LOG)
	end
	_MY.tInitFun = nil
	-- 加载主窗体
	MY.OpenPanel(true, true)
	MY.ClosePanel(true)
	-- 显示欢迎信息
	MY.Sysmsg({_L("%s, welcome to use mingyi plugins!", GetClientPlayer().szName) .. " v" .. MY.GetVersion() .. ' Build ' .. _MY.szBuildDate})
end

-- ##################################################################################################
--     # # # # # # # # #                                                         #           #       
--     #       #       #     # # # # # # # # # # #     # # # # # # # # #           #       #         
--     # # # # # # # # #               #                   #       #                                 
--     #       #       #             #                     #       #           # # # # # # # # #     
--     # # # # # # # # #       # # # # # # # # # #         #       #                   #             
--             #               #     #     #     #         #       #                   #             
--         # #   # #           #     # # # #     #   # # # # # # # # # # #   # # # # # # # # # # #   
--   # # #           # # #     #     #     #     #         #       #                   #             
--         #       #           #     # # # #     #         #       #                 #   #           
--         #       #           #     #     #     #       #         #               #       #         
--       #         #           # # # # # # # # # #       #         #             #           #       
--     #           #           #                 #     #           #         # #               # #   
-- ##################################################################################################
-- close window
MY.ClosePanel = function(bMute, bRealClose)
	local hFrame = MY.GetFrame()
	if hFrame then
		if not bRealClose then
			hFrame:Hide()
		else
			Wnd.CloseWindow(hFrame)
		end
		Wnd.CloseWindow("PopupMenuPanel")
		if not bMute then
			PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
		end
	end
	MY.RegisterEsc('MY')
end

-- open window
MY.OpenPanel = function(bMute, bNoFocus)
	local hFrame = MY.GetFrame()
	if not hFrame then
		hFrame = Wnd.OpenWindow(_MY.szIniFile, "MY")
		hFrame.intact = true
		hFrame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		hFrame:CorrectPos()
		
		-- update some ui handle
		_MY.hBox = hFrame:Lookup("", "Box_1")
		hFrame:Lookup("", "Text_Title"):SetText(_L['mingyi plugins'] .. " v" .. MY.GetVersion() .. ' Build ' .. _MY.szBuildDate)
		hFrame:Lookup("Wnd_Total", "Handle_DBClick").OnItemLButtonDBClick = function()
			hFrame:Lookup('CheckBox_Maximize'):ToggleCheck()
		end
		-- load bg uitex
		local szUITexCommon = MY.GetAddonInfo().szUITexCommon
		for k, v in pairs({
			['Image_BgLT'] = 9,
			['Image_BgCT'] = 8,
			['Image_BgRT'] = 7,
			['Image_BgT' ] = 6,
		}) do
			hFrame:Lookup('', k):FromUITex(szUITexCommon, v)
		end
		-- bind close button event
		MY.UI(hFrame):children("#Btn_Close"):click(function() MY.ClosePanel() end)
		MY.UI(hFrame):children("#CheckBox_Maximize"):check(function()
			local ui = MY.UI(hFrame)
			_MY.anchor = ui:anchor()
			_MY.w, _MY.h = ui:size()
			ui:pos(0, 0):onevent('UI_SCALED.FRAME_MAXIMIZE_RESIZE', function()
				ui:size(Station.GetClientSize())
			end):drag(false)
			MY.ResizePanel(Station.GetClientSize())
		end, function()
			MY.ResizePanel(_MY.w, _MY.h)
			MY.UI(hFrame)
			  :onevent('UI_SCALED.FRAME_MAXIMIZE_RESIZE')
			  :drag(true)
			  :anchor(_MY.anchor)
		end)
		-- update author infomation button
		MY.UI(MY.GetFrame()):children("#Wnd_Total"):children("#Btn_Weibo")
		  :text(_L['author\'s weibo'])
		  :click(function()
		  	MY.UI.OpenInternetExplorer("http://weibo.com/zymah")
		  end)
		-- updaet logo image
		MY.UI(MY.GetFrame()):item('#Image_Icon')
		  :size(30, 30)
		  :image(_MY.szUITexCommon, 0)
		-- update category
		MY.RedrawCategory()
	end
	hFrame:Show()
	if not bNoFocus then
		hFrame:BringToTop()
		Station.SetFocusWindow(hFrame)
	end
	if not bMute then
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	MY.RegisterEsc('MY', MY.IsPanelVisible, function() MY.ClosePanel() end)
end

-- toggle panel
MY.TogglePanel = function()
	if MY.IsPanelVisible() then
		MY.ClosePanel()
	else
		MY.OpenPanel()
	end
end

-- reopen panel
MY.ReopenPanel = function()
	local bVisible = MY.IsPanelVisible()
	MY.ClosePanel(true, true)
	MY.OpenPanel(true, true)
	if not bVisible then
		MY.ClosePanel(true)
	end
end

-- resize panel
MY.ResizePanel = function(nWidth, nHeight)
	local hFrame = MY.GetFrame()
	if not hFrame then
		return
	end
	local _w, _h = hFrame:GetSize()
	nWidth, nHeight = nWidth or _w, nHeight or _h
	
	MY.UI(hFrame):size(nWidth, nHeight)
	hFrame:Lookup('', 'Text_Author'):SetRelPos(0, nHeight - 41)
	hFrame:Lookup('', 'Text_Author'):SetSize(nWidth - 31, 20)
	hFrame:Lookup('', ''):FormatAllItemPos()
	local hWnd = hFrame:Lookup('Wnd_Total')
	local hTotal = hWnd:Lookup('', '')
	hTotal:SetSize(nWidth, nHeight)
	hTotal:Lookup('Image_Breaker'):SetSize(6, nHeight - 340)
	hTotal:Lookup('Image_TabBg'):SetSize(nWidth - 2, 33)
	hTotal:Lookup('Handle_DBClick'):SetSize(nWidth, 54)
	hWnd:SetSize(nWidth, nHeight)
	hWnd:Lookup('WndContainer_Category'):SetSize(nWidth - 22, 32)
	hWnd:Lookup('WndContainer_Category'):FormatAllContentPos()
	hWnd:Lookup('Btn_Weibo'):SetRelPos(nWidth - 135, 55)
	
	hWnd:Lookup('WndScroll_Tabs'):SetSize(171, nHeight - 102)
	hWnd:Lookup('WndScroll_Tabs', ''):SetSize(171, nHeight - 102)
	hWnd:Lookup('WndScroll_Tabs', ''):FormatAllItemPos()
	hWnd:Lookup('WndScroll_Tabs/ScrollBar_Tabs'):SetSize(16, nHeight - 111)
	
	hWnd:Lookup('WndScroll_MainPanel'):SetSize(nWidth - 191, nHeight - 100)
	hWnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetSize(20, nHeight - 110)
	hWnd:Lookup('WndScroll_MainPanel/ScrollBar_MainPanel'):SetRelPos(nWidth - 23, 5)
	hWnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel'):SetSize(nWidth - 201, nHeight - 100)
	hWnd:Lookup('WndScroll_MainPanel/WndContainer_MainPanel', ''):SetSize(nWidth - 201, nHeight - 100)
	local hWndMainPanel = hFrame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	if hWndMainPanel.OnPanelResize then
		local res, err = pcall(hWndMainPanel.OnPanelResize, hWndMainPanel)
		if not res then
			MY.Debug({err}, 'MY#OnPanelResize', MY_DEBUG.ERROR)
		elseif MY.Sys.GetLang() ~= 'vivn' then
			hWndMainPanel:FormatAllContentPos()
		end
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
		elseif MY.Sys.GetLang() ~= 'vivn' then
			hWndMainPanel:FormatAllContentPos()
		end
	end
	hWndMainPanel:FormatAllContentPos()
	hWndMainPanel:Lookup('', ''):FormatAllItemPos()
	hTotal:FormatAllItemPos()
end

-- if panel visible
MY.IsPanelVisible = function()
	return MY.GetFrame() and MY.GetFrame():IsVisible()
end

-- if panel visible
MY.IsPanelOpened = function()
	return Station.Lookup("Normal/MY")
end

-- 获取主窗体句柄
-- (frame) MY.GetFrame()
MY.GetFrame = function()
	return Station.Lookup('Normal/MY')
end

-- (string, number) MY.GetVersion()     -- HM的 获取字符串版本号 修改方便拿过来了
MY.GetVersion = function()
	local v = _MY.dwVersion
	local szVersion = string.format("%X.%X.%02X", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- ##################################################################################################
--             #                 #         #                   #                                     
--   # # # # # # # # # # #       #   #     #         #           #             # # # #   # # # #     
--       #     #     #         #     #     #           #                       #     #   #     #     
--       # # # # # # #         #     # # # # # # #         # # # # # # #       #     #   #     #     
--             #             # #   #       #                     #             #     #   #     #     
--     # # # # # # # # #       #           #         #           #             #     #   #     #     
--             #       #       #           #           #         #           # # # # # # # # # # #   
--   # # # # # # # # # # #     #   # # # # # # # #         # # # # # # #       #     #   #     #     
--             #       #       #           #                     #             #     #   #     #     
--     # # # # # # # # #       #           #           #         #             #     #   #     #     
--             #               #           #         #           #             #     #   #     #     
--           # #               #           #             # # # # # # # # #   #     # # #     # #     
-- ##################################################################################################
-- 注册初始化函数
-- RegisterInit(string id, function fn) -- 注册
-- RegisterInit(function fn)            -- 注册
-- RegisterInit(string id)              -- 注销
MY.RegisterInit = function(arg1, arg2)
	local szKey, fnAction
	if type(arg1) == 'string' then
		szKey = arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	if fnAction then
		if szKey then
			_MY.tInitFun[szKey] = fnAction
		else
			table.insert(_MY.tInitFun, fnAction)
		end
	elseif szKey then
		_MY.tInitFun[szKey] = nil
	end
end

-- 注册游戏结束函数
-- RegisterExit(string id, function fn) -- 注册
-- RegisterExit(function fn)            -- 注册
-- RegisterExit(string id)              -- 注销
MY.RegisterExit = function(arg1, arg2)
	local szKey, fnAction = ''
	if type(arg1) == 'string' then
		szKey = '.' .. arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	MY.RegisterEvent('PLAYER_EXIT_GAME' .. szKey, fnAction)
	MY.RegisterEvent('GAME_EXIT' .. szKey, fnAction)
	MY.RegisterEvent('RELOAD_UI_ADDON_BEGIN' .. szKey, fnAction)
end

-- 注册插件重载函数
-- RegisterReload(string id, function fn) -- 注册
-- RegisterReload(function fn)            -- 注册
-- RegisterReload(string id)              -- 注销
MY.RegisterReload = function(arg1, arg2)
	local szKey, fnAction = ''
	if type(arg1) == 'string' then
		szKey = '.' .. arg1
		fnAction = arg2
	elseif type(arg1) == 'function' then
		fnAction = arg1
	end
	MY.RegisterEvent('RELOAD_UI_ADDON_END' .. szKey, fnAction)
end

-- 注册游戏事件监听
-- MY.RegisterEvent(szEvent, fnAction) -- 注册
-- MY.RegisterEvent(szEvent) -- 注销
-- (string)  szEvent  事件，可在后面加一个点并紧跟一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
-- (function)fnAction 事件处理函数，arg0 ~ arg9，传入 nil 相当于取消该事件
--特别注意：当 fnAction 为 nil 并且 szKey 也为 nil 时会取消所有通过本函数注册的事件处理器
MY.RegisterEvent = function(szEvent, fnAction)
	local szKey = nil
	local nPos = StringFindW(szEvent, ".")
	if nPos then
		szKey = string.sub(szEvent, nPos + 1)
		szEvent = string.sub(szEvent, 1, nPos - 1)
	end
	if fnAction then
		if not _MY.tEvent[szEvent] then
			_MY.tEvent[szEvent] = {}
			RegisterEvent(szEvent, _MY.EventHandler)
		end
		if szKey then
			_MY.tEvent[szEvent][szKey] = fnAction
		else
			table.insert(_MY.tEvent[szEvent], fnAction)
		end
	else
		if szKey then
			_MY.tEvent[szEvent][szKey] = nil
		else
			_MY.tEvent[szEvent] = {}
		end
	end
end
_MY.EventHandler = function(szEvent, ...)
	local tEvent = _MY.tEvent[szEvent]
	if tEvent then
		for k, v in pairs(tEvent) do
			local res, err = pcall(v, szEvent, ...)
			if not res then
				MY.Debug({err}, 'OnEvent#' .. szEvent .. "." .. k, MY_DEBUG.ERROR)
			end
		end
	end
end
-- ##########################################################################
--     #           #                 # # # # # # #           #               
--       #     #   #         # # #         #                 #               
--             # # # # #       #         #                   # # # # # #     
--           #     #           #     # # # # # # #           #               
--   # # #         #           #     #           #           #               
--       #   # # # # # # #     #     #     #     #   # # # # # # # # # # #   
--       #       #   #         #     #     #     #           #               
--       #       #   #         #     #     #     #           # # #           
--       #     #     #   #     # #   #     #     #           #     # #       
--       #   #         # #   #           #   #               #         #     
--     #   #                           #       #             #               
--   #       # # # # # # #         # #           #           #               
-- ##########################################################################
MY.RedrawCategory = function(szCategory)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	
	-- draw category
	local wndCategoryList = frame:Lookup('Wnd_Total/WndContainer_Category')
	wndCategoryList:Clear()
	for _, ctg in pairs(_MY.tTabs) do
		local nCount = 0
		for i, tab in ipairs(ctg) do
			if not (tab.bShielded and MY.IsShieldedVersion()) then
				nCount = nCount + 1
			end
		end
		if nCount > 0 then
			local chkCategory = wndCategoryList:AppendContentFromIni(_MY.szIniFile, "CheckBox_Category")
			chkCategory.szCategory = ctg.id
			chkCategory:Lookup('', 'Text_Category'):SetText(ctg.id)
			chkCategory.OnCheckBoxCheck = function()
				if chkCategory.bActived then
					return
				end
				
				PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
				local p = chkCategory:GetParent():GetFirstChild()
				while p do
					if p.szCategory ~= chkCategory.szCategory then
						p.bActived = false
						p:Check(false)
					end
					p = p:GetNext()
				end
				MY.RedrawTab(chkCategory.szCategory)
			end
			szCategory = szCategory or ctg.id
		end
	end
	wndCategoryList:FormatAllContentPos()
	
	MY.SwitchCategory(szCategory)
end

-- MY.SwitchCategory(szCategory)
MY.SwitchCategory = function(szCategory)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	
	local hList = frame:Lookup('Wnd_Total/WndContainer_Category')
	local chk = hList:GetFirstChild()
	while(chk and chk.szCategory ~= szCategory) do
		chk = chk:GetNext()
	end
	if not chk then
		chk = hList:GetFirstChild()
	end
	if chk then
		hList.szCategory = chk.szCategory
		chk:Check(true)
	end
end

MY.RedrawTab = function(szCategory)
	local frame = MY.GetFrame()
	if not (frame and szCategory) then
		return
	end
	
	-- draw tabs
	local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
	hTabs:Clear()
	
	for _, ctg in ipairs(_MY.tTabs) do
		if ctg.id == szCategory then
			for i, tab in ipairs(ctg) do
				if not (tab.bShielded and MY.IsShieldedVersion()) then
					local hTab = hTabs:AppendItemFromIni(_MY.szIniFile, "Handle_Tab")
					hTab.szID = tab.szID
					hTab:Lookup('Text_Tab'):SetText(tab.szTitle)
					if tab.dwIconFrame then
						hTab:Lookup('Image_TabIcon'):FromUITex(tab.szIconTex, tab.dwIconFrame)
					else
						hTab:Lookup('Image_TabIcon'):FromTextureFile(tab.szIconTex)
					end
					hTab:Lookup('Image_Bg'):FromUITex(_MY.szUITexCommon, 3)
					hTab:Lookup('Image_Bg_Active'):FromUITex(_MY.szUITexCommon, 1)
					hTab:Lookup('Image_Bg_Hover'):FromUITex(_MY.szUITexCommon, 2)
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

MY.SwitchTab = function(szID)
	local frame = MY.GetFrame()
	if not frame then
		return
	end
	
	if szID then
		-- check if category is right
		local szCategory = frame:Lookup('Wnd_Total/WndContainer_Category').szCategory
		for _, ctg in ipairs(_MY.tTabs) do
			for i, tab in ipairs(ctg) do
				if tab.szID == szID then
					if ctg.id ~= szCategory then
						MY.SwitchCategory(ctg.id)
					end
				end
			end
		end
		
		-- get tab window
		local hTab
		local hTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs', '')
		for i = 0, hTabs:GetItemCount() - 1 do
			if hTabs:Lookup(i).szID == szID then
				hTab = hTabs:Lookup(i)
			end
		end
		if (not hTab) or hTab.bActived then
			return
		end
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		
		-- deal with ui response
		local hTabs = hTab:GetParent()
		for i = 0, hTabs:GetItemCount() - 1 do
			hTabs:Lookup(i).bActived = false
			hTabs:Lookup(i):Lookup("Image_Bg_Active"):Hide()
		end
		hTab.bActived = true
		hTab:Lookup("Image_Bg_Active"):Show()
	end
	
	-- get main panel
	local wndMainPanel = frame:Lookup('Wnd_Total/WndScroll_MainPanel/WndContainer_MainPanel')
	if wndMainPanel.szID == szID then
		-- return
	end
	-- fire custom registered on switch event
	if wndMainPanel.OnPanelDeactive then
		local res, err = pcall(wndMainPanel.OnPanelDeactive, wndMainPanel)
		if not res then
			MY.Debug({err}, 'MY#OnPanelDeactive', MY_DEBUG.ERROR)
		end
	end
	wndMainPanel.OnPanelDeactive = nil
	wndMainPanel:Clear()
	wndMainPanel:Lookup('', ''):Clear()
	
	wndMainPanel.OnPanelResize   = nil
	wndMainPanel.OnPanelActive   = nil
	wndMainPanel.OnPanelDeactive = nil
	if not szID then
		-- 欢迎页
		local ui = MY.UI(wndMainPanel)
		local w, h = ui:size()
		ui:append("Image", "Image_Adv", { x = 0, y = 0, image = { MY.GetAddonInfo().szUITexPoster, 0 } })
		ui:append("Text", "Text_Adv", { x = 10, y = 300, w = 557, font = 200 })
		wndMainPanel.OnPanelResize = function(wnd)
			local w, h = MY.UI(wnd):size()
			if w / 557 > (h - 50) / 278 then
				ui:item('#Image_Adv'):size((h - 50) / 278 * 557, (h - 50))
				ui:item('#Text_Adv'):pos(10, h - 40)
			else
				ui:item('#Image_Adv'):size(w, w / 557 * 278)
				ui:item('#Text_Adv'):pos(10, w / 557 * 278 + 10)
			end
		end
		wndMainPanel.OnPanelResize(wndMainPanel)
		MY.BreatheCall(function()
			local player = GetClientPlayer()
			if player then
				ui:item('#Text_Adv'):text(_L('%s, welcome to use mingyi plugins!', player.szName) .. 'v' .. MY.GetVersion())
				return 0
			end
		end, 500)
		wndMainPanel:FormatAllContentPos()
	else
		for _, ctg in ipairs(_MY.tTabs) do
			for _, tab in ipairs(ctg) do
				if tab.szID == szID then
					if tab.fn.OnPanelActive then
						local res, err = pcall(tab.fn.OnPanelActive, wndMainPanel)
						if not res then
							MY.Debug({err}, 'MY#OnPanelActive', MY_DEBUG.ERROR)
						elseif MY.Sys.GetLang() ~= 'vivn' then
							wndMainPanel:FormatAllContentPos()
						end
					end
					wndMainPanel.OnPanelResize   = tab.fn.OnPanelResize
					wndMainPanel.OnPanelActive   = tab.fn.OnPanelActive
					wndMainPanel.OnPanelDeactive = tab.fn.OnPanelDeactive
					break
				end
			end
		end
	end
	wndMainPanel.szID = szID
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
-- Ex： MY.RegisterPanel( "Test", "测试标签", "测试", "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, { OnPanelActive = function(wnd) end } )
MY.RegisterPanel = function(szID, szTitle, szCategory, szIconTex, rgbaTitleColor, options)
	local category
	for _, ctg in ipairs(_MY.tTabs) do
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
		table.insert(_MY.tTabs, {
			id = szCategory,
		})
		category = _MY.tTabs[#_MY.tTabs]
	end
	-- format szIconTex
	if type(szIconTex)~="string" then szIconTex = 'UI/Image/Common/Logo.UITex|6' end
	local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
	if dwIconFrame then dwIconFrame = tonumber(dwIconFrame) end
	szIconTex = string.gsub(szIconTex, '%|.*', '')

	-- format other params
	if type(options)~="table" then options = {} end
	if type(rgbaTitleColor)~="table" then rgbaTitleColor = { 255, 255, 255, 255 } end
	if type(rgbaTitleColor[1])~="number" then rgbaTitleColor[1] = 255 end
	if type(rgbaTitleColor[2])~="number" then rgbaTitleColor[2] = 255 end
	if type(rgbaTitleColor[3])~="number" then rgbaTitleColor[3] = 255 end
	if type(rgbaTitleColor[4])~="number" then rgbaTitleColor[4] = 200 end
	if type(options)~="table" then options = {} end
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
			OnPanelResize  = options.OnPanelResize ,
			OnPanelActive  = options.OnPanelActive ,
			OnPanelDeative = options.OnPanelDeative,
		},
	})

	if _MY.bLoaded then
		MY.RedrawCategory()
	end
end

-- ##################################################################################################
--             #                                       # # # # # # # #             #       #         
--   # # # # # # # # # # #     # # # # # # # # #                   #           #   #   #   #         
--   #     #       #     #     #               #     #           #       #         #       #         
--       #     #     #         #               #     #   #     #     #   #   # # # # # #   # # # #   
--           #                 #               #     #     #   #   #     #       # #     #     #     
--     # # # # # # # # #       #               #     #         #         #     #   # #     #   #     
--     #     #         #       #               #     #     #   #   #     #   #     #   #   #   #     
--     #   # # # # #   #       #               #     #   #     #     #   #       #         #   #     
--     # # #     #     #       #               #     #         #         #   # # # # #     #   #     
--     #     # #       #       # # # # # # # # #     #       # #         #     #     #       #       
--     #   #     #     #       #               #     #                   #       # #       #   #     
--     # # # # # # # # #                             # # # # # # # # # # #   # #     #   #       #   
-- ##################################################################################################
MY.OnMouseWheel = function()
	return true
end
-- key down
MY.OnFrameKeyDown = function()
	if GetKeyName(Station.GetMessageKey()) == "Esc" then
		if IsPopupMenuOpened() then
			Wnd.CloseWindow("PopupMenuPanel")
		else
			MY.ClosePanel()
		end
		return 1
	end
	return 0
end

---------------------------------------------------
-- 事件、快捷键、菜单注册
---------------------------------------------------
if _MY.nDebugLevel < 3 then
	RegisterEvent("CALL_LUA_ERROR", function()
		print(arg0)
		OutputMessage("MSG_SYS", arg0)
	end)
	TraceButton_AppendAddonMenu({{
		szOption = "ReloadUIAddon",
		fnAction = function()
			ReloadUIAddon()
		end,
	}})
end

MY.RegisterEvent("LOADING_END", _MY.Init)
