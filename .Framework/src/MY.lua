---------------------------------
-- 茗伊插件
-- by：茗伊@双梦镇@追风蹑影
-- ref: 借鉴大量海鳗源码 @haimanchajian.com
---------------------------------
--[[
######################################################################################################################################################
######################################################################################################################################################
  # # # # #   # # # # #                                       #                         #           #                 # # # # # #     
    #     #     #     #                           # # # #   # # # # #                   #     # # # # # # #   # # # #           #     
      #   #       #   #                           #     #   #       #                 #       #           #       #     #       #     
    #     #     #     #                           #     #   #   #   #                 #   #   # # # # # # #       #     #       #     
        #     #                                   #     #   #     # #                 # #     #                 #       #       #     
      # # # # # # # # #                           #     #   #                           #     # # # # # # #     # # #   # # # # # #   
    # #       #           # # # # # # # # # # #   #     #   # # # # # #               #       #   #   #   #   # #   #             #   
  #   # # # # # # # #                             #     #             #               # #   # #   #   #   #     #   #             #   
      #       #                                   # # # #             #                       # # # # # # #     #   # # # # # #   #   
      # # # # # # # #                             #     # # # # # #   #                   #   #   #   #   #     # # #             #   
      #       #                                                       #               # #     #   #   #   #     #   #             #   
      # # # # # # # # #                                           # #                         #         # #                   # #     
: :,,,,,,.,.,.,.,.,......   ;jXFPqq5kFUL2r:.: . ..,.,..... :;iiii:ii7;..........,...,,,,,,:,:,,,:::,:::,:::::::::,:::::::::,:::,:,:::::::::::::::::::.
,                         ,uXSSS1S2U2Uuuuu7i,::.           ........:::                         . . . . . . . . . . . . . . . . . . . . . . . . . . .. 
: :.,.,.,.,.,.....,...  :q@M0Pq555F5515u2u2UuYj7:         :,,,:,::::i:: ........,...,.,.,.,,,,,.,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:.
, ,,.,.,.............  7OMEPF515u2u2UULJJujJYY7v7r.  . ....,,,.,,:,:,,.................,.,.,.,.,.,,:,,.,,,,:,:,:,:,:.,,,,,,,.,.,.,.,,,.,,,,:,,,,,,,:,.
, ,.,...............  uBEkSU2U1u2uUJuvjuuLL7v77r;ri,.,,..   . ..,,,,..,.................,.,.,.,.,.,.,.,.,.,.,.,.,,,.,.,..           ....,,,.,,,,,.,,, 
, ,,.,...............v5XXF21U1uFU2JUUuJjvvr7rriii:::.            ..:.. . ..................,...,.,.,.,.,,,.,.,.,.,....   :,;i7YLv7:.    ...,.,.,.,,,, 
, ,................ :Uk1q2Pk5u11uJ55uvuYYv7rrii::,,.              ...    ...................,.,.,.,.,.,.,,,.,.,.,..: ..iO@@BMB@B@B@MMqui  ..,.,.,.,.: 
. .,..............  iPFuUXXX2jJuLJJJvL7v7v7rii::,.                 ...    .................,...,.,.,.,.,.,.,.,.,. 2;iPFNXNE08kYGUSO@B@@@k:  ...,.,.,,.
, ,.,.............. rS1jU1FF1U12jvL7vv7r777ii::...                  ...   . ....................,.,.,.,.,...:,...:5EZL7uE1r   j@P   :7NB@Bq, .,.,.,,: 
. ...,............  iSLYuuU11qXX5122jY7rii::.::,..                   ,,    ........................,.,.,.. ,L,. rEJUi:5S,   :BBJ::.    .S@BM: .,.,.,,.
, ,.,.,............ ;UYvuYjUF555FkSuY7i::.....:.,.                   .:.    . ..................,.,.,.....i7,:..OJr:.Lk  7SB@u. .L@BF    r@Br ..,.,., 
. ...,............. :SYLY5U1uuLv77ri:,.,.. . .....                   .,,    ................ .......... ,Y,  :.,vi,. rLr,1B2E@BX...O@r:   2@O  ..,.,. 
, ,................  71LUFFSJ7r:,.,......         .                   ,,:.  . ......... ....i:. ... . i;Zr  . ruL. ,.::,7:.:@BB::ri,:X@q. ,B@  ....., 
. ..................  JkFX1jiii:,,.......  ....    .                 ..:::::, .......  :.. .7,1  r7:.,ii@v rrL5.k .70;ri:71@0: .iMB@8r.,, .MB: ...... 
, ,..................  u817:,.:::.....,,::i::,,.   .                ..,:iiiir  ..... ,NJ . ::iLvu rL7JFiv::..E7 S8: :jL :5PUr,rjS1::PB@Bu ;PBi ,F7v , 
. .................... :X0,..755J7ri:::::::i....   .               ..,::i7777i ..... vOr  ivurvPr SUrjL:,20ii;r,uJr:rGPv : :r..:u@X   i,  8PX. .FL:.,.
, ,...................  :E7 :vLriirr7i..:i7r:..   .               ..,:r,  ,ivL, ......:.  .Ui7ULY:r ;2jvu1B2JiL;v571vuikr7 i:rq7ii7i,    7B1, .,r..., 
. .,..................   r5.:irvvu::iL   .::..       .           ..,::      .ii....... .,ii750i.i12,1iLv:v1O@8B8LJU:i, iNSiqJkviiru@@Br 1Ev. ......,. 
, ,.....................  rr.:;i;:..iv.     ...   . .,.       ..,.:::i.   .   ..........,::i: .::i::,,.,:...,.....,,,:5UNur:,.:::..  :0BO:. ..,...,., 
. .,.,.................... :..::...:7:..   .,,.......:,......:::::,,:i:  . . ...........       ..  ..  .. ..   ..  . .::.. . .  .i7j0@Pi. .,.,.,.,.,,.
, ,.,......................  .i:...ir.:. :, .,,.... ,ri::::.:::,:,::i,. ..........................,.,.,...,.,.,.,,,.....:i7rUX55qGP7:   ....,.,.,.,.: 
. .,......................   .,ri:,LvjU;,,.  ..,.... rri::::::,:::::i, ..........................,.....,.....,.,.,.,...... . ..      ....,.,.,.,.,.,,.
, ,.....,.................  78:.rii;7;r::.:,::,.. :i ,viiii:i:i:i:iir  .........................,.,.....,.,.,...,.,...,.,....... .,.....,.,.,.,.,.,., 
. ...,.....................UMMOr.:ir7vvvri:::,.. :5:  77iri;iiiiiii7i  ............................,.,.,.,.,...,.,...,.,.,.,....i F,::.,.,.,.,.,.,.,, 
, ,.,...,.,.,.,...........i75ZMBkiii7LLii:i,. . :52   :jLrr;ri;;r7LJ: . ........................,.,.,.,.,.,.,.,.,.,.,.,.,.,.,..,N 5 Lv .....,.,.,.,., 
, .,.,...,.,........       ,7BOMMGuriiii::.. ..:Yq: .  .i7LuYL7vrrii. ...........................,...,...,.,.,.,...,...,.,...,.,0.山Uv ..,.,.,.,.,.., 
, ,.....,.,......   ..,,.rLL77OM8N0Fu7ri::::::irPu. .,,   .:,,uq:    ...........................,.,.....,.,.....,.,...,.,.......:::,i...,.,.,.....,., 
. .,.,.,...... ..:iu2v7juEFurrrMO0SSSkuUJJ77iirkq: .,,......  .Y:  . ..........................,...,.,...,.,...,.,.,.,.,.,.,....:,,,::...,.,.,.....,..
, ,.,.......::;71FkU7jZZM5r;rP:rBOEXXSS2j7;ii71U: ,,:...,.:::,...   . ............................,.,...,.,.,.,.,.,.,.,.,.,....,7;Y71r .,.,.,......., 
. ...,....,:i7LY7rirL5SE5::;kj;iiSPFuuuL77i:iv;,.,,:.,,:,:,,,::::::,   ........................,.,.,.,...,.,.,.,.,.,...,.,.,....rJ河vi ....,.,.,.,.,,.
, ,.,....,::7ri:ir7Jv7u1r;iiSrv2kv7:.rr  :v7Lr .:,:,,,,,:,::::::::::::,  .........................,.,.,.,.,...,.,...,.,.,...,...5.::S:....,.,.....,., 
. .,.,...:::ir;7777YirLJrvr:iiuE;i:  v:. ,iru. ,,,,:,:::,:::,:::::,::::: ..............................,.,.,.,.,.,.........,.,..   ........,.,.,...,. 
, ,.,...:rvr:r7ir;J7iivr;r7i:ivX  i  :. ...vJ.,,:::::,,::::,:i:,:,::::::: ........................,.,.,...,.,...... .   ....,...:FL:..............,., 
. .... .rvLS:ir;iru7:riiirri:7q@.....,:. ..Br .::::,.::::,,ii:,::ii::::i:. ....................,.,.,.........,.....rFrYu:........0:k: .............,, 
, ,... iuvL07:;iir57iir;rrrii78i .:i.:r:...v,..::,,,::::::ii:,::iir,::i:i, .............................,.......,..vq華0: ..... rU九r7........,....., 
. ... .LYuL05riii7Lurrrr;7;riYS .;rv::::..   ..::,,:::,:,ii:i::;:ri,::i::: ......................,.............,...JjN1Si..... ,r  ,r; ..,.........,. 
, ,.. 7uLjuS0ri:r7Lvr;rir;rii1Z :rri7:::,......::,:::,:,ii:ir,iiir:::ii:i:  ......................,.......,.,.,....,.i:.:...,.. ,. ,. ............,., 
. .. :LYjjJPM7:ir7vv;rr7rrrirZMJ::iirr,:.......::::::::ii::7i:;ii;:::i::ii ..................,.,.,...,.......,.....  ,   ..... :GS7EGr ..,.....,.,.,, 
, .. vv7jj11@u:i7rv7rr7rri7iL088v:iiiri,,.....::::::::ii:::Yi:r:r:::i:::;:. ......................,.,...,.,...,.,..v U:,7 .... :Ok轉0v .,.,...,...,., 
. . .227vjSFO0,irr77irrri;r7r20OO7:;;r;:,.....:i:::::ii:::i2:ii7i::iri:iii ..............,...,.......,.,.,...,.,...0 山iu .,.,..uv:v5r ....,.,.,...,. 
, . i7XJvJPFEMr:rrrr7r;iiirir7S0MMU:iirr:.,.. :7i:r:::iii:YL::r7::rriii:i:  ................,...,...,...,.....,....Si57JJ ..,..     . ..........,.,., 
. ..;rjXvjkqX@O;r7rrii:iiri;i77YJ8BZ7,:ii,....:Y,iriiiii:i27:ivLr7ri:i::i: ................,.........,...,........  .. , .......v7777 ...,.,...,..... 
. . 7rvkuuPqkO@YvLL77vuu7i;irvr;iYG8Bj,:rr:,..:.,:irriii:rSi:rLrvriii:i:i: .....................,.,.....,......... i::7ir ..,...FL風1 ..,...,.,.,..., 
. ..7r7FFUkZ58BkrFU1UUFkriirrur7rrFNN@2,:Lr,,::::::irrii:uu:ivv7;i:::::ii: ..............................,.....,...GJ絕Nv .... :FLk1Si ....,...,.,.,. 
. .,Li72kUkqXN@B7LUJujkur:irv7ivYiFjFE@87i,,:::::::,irr:ik7:7v7i:,,,::::i.  ........................,.,.....,.... ,FukL72 .....::.,.7L .......,...,., 
. .:LrrUk55EPqM@Pvuuu1FJriivv7:vu;uL7FSG7irr::::::::::7755:7SL;rrrrrri:ii. ..............................,...,.,..,i.r::r....,....  . ...,.....,..... 
. .:L;rYk2FPEqMBE71U1USvr:rL7;rr1v1L7Uui7ri7vi:::::::::2ZriYvir77rr;rriii ....................,.,.......,.....,.,.... ........ :MqUuk: .......,....., 
. .;LrrL5F2PZOB7.Uj5J12rrirYr7rrj2Fj1EEGYv7r7jri::::::.vU71krii::i:iirri:......................,.,.,.,.,.....,.,...U77k27 .... ,uL飄P: ..,.,.,....... 
. iiJrr7151SOM8 rNu1jS1i7:7vrr7i7F05FPZ8@1YJvvjvri;i:::,,:SEi,i,::iiiiri: ..........................,.,.....,...,. i:頂uF ..,..,5LYrFu .,.,.,.,...,., 
  riv7irYFFk8@U FOYUF0vr7i;v77r7i2Zu1kk0M@kYYLLF7rri::::,:.U0u7i,,:iiii;: ...........................,.........,...U:uvuu .,.....    ,.....,.,...,... 
 .riLvii7YkXMB: GZ5j05;rLiii777rruMLLJjuFB@XjuLuUi;i::i:::::7USFUr:::::r: ................,.......,.,.........,.,.,: .  :...,.. L7iiri..,.,.,...,..., 
:LLr7LiLLJ2qOq  ZOS5Pj;LYrirrL77iuMLrYLu75O@01LvYJr2vi;i::::,:iFUU7::iir. .................,.......,.,.,.,...,.,.. ..:.: ..,.,..uP絮7i ,.,...,.,...,. 
rrL;rLr7Y1EO@r  XBONFr7L1;iir7Yri7@j777uJ;Y0@ZFuL7vqSrvrr:iii::UOLi:iiri. ..............................,.,.,.,.,..2u坐ki...... 7GSY5...,...,.....,., 
::;;;7ir7vJZ;   vME5777J1J:ri7J7iiMXiLL2UJrv0@G1LivE7iYvr;irr::,7M5i,iir ..............,.....,...,...,.,...,.,.,...7i01;:.......7rL:vi.....,.,.,...,. 
,.::1SL:rv1X.   jkXvLLYJUFvr;iYvi:SOirLj11uvL0@Mui2E;.Yv7riiL:i:.iPFr:ii .........................,...,.,.......,..iivrii.......  .  ...,.....,.,..., 
v:iFXZOFi,,     kFUujUJuYU12virLii7Mii;vJ15uYjX@@1v82.;7i7rLji:iii7rUv:: ............,.....,.............,.,.,.....  . ....,.............,.,.,.,.,,,,.
Yi7JLuNOEJ:,:  .XNkY1uuYjvJLuri7riiZr:7rLUXuuYu18BGUN17iirvjYLri7:777qL ..................,...,...,...,...,.,.,.,..u7rrii.,.,...,.,.,.,.,.,...,...,., 
7i;JY7ivuFXPGO.70ZZ2YUu2UuJYvY;rrr:PLi7v7YuFUUJJj5GMqPku;iLuLSvrrr;7LU1 ...............,.,...,.,.,...,.,.,...,.,.. 7L忘r,..,.,...,...,.,.,...,.....,..
::7;7rirYj2UNOuMMXE5juuuuu12Yr7r7rij5::r7rvLUu221uJuEZk5ur77uS177;rruLr ..............,.,.,.,.,.....,.,.,.,.,.....:LY;7Lv...,.....,...,.,...,.,....., 
 :1Liiirir7L7PXO@OSujuJuYYLJJ7rvrrirOi:ii77vvju55k51YU5X5U7rJk5LLrivJ7  .................,.,.....,...,...,.,.,..... ,::. ..,.,.,.,.....,.,.....,...,..
. LL7;ririrr71FYGBBNFuuJuJjLuv;r7rr:O1.:iirrvvJjU5XqNS2uFSFvLU1LY;rYv. ...............,.,.,.....,.,.,...,.,...,.,. :.,:ii...,...,...,...,.,...,...,., 
. iJ777ri;rvLU1,v2EBOZSSUujuuurrir;iL@i::ii;irrvLuu5XE0q221X1Ujv7Li.  .................,.,.,...,.,.,.,.,.....,.,...0L經17 .,...,.,.,...,...,.,.,.,.,..
, .7LLYr;r7;rrX::ivY5FXSP52UUuLr;i;iiqG.::iiiii;77LLjukPqS12NEFL0Bi  .............,.....,.,...,.,.............,....S57Ju; ..,...,.,.,.,.,...,...,.,., 
, .:vY7i;ririiMGr:::irrvL2U1uuJY7rii:iMr:iii:i:::i;77LLu1Pkkk1.M@@B@E: ............,.,...........,.,...,...,...,..:vr;Yj:......,.,.,.....,.,...,...,. 
: . irii7iri:i@B@Yi:,,,,::i;v7LLjLL77i55irrrriiii:i:iir7YUP2F: B@B@2  ........................,.,.,...,...,.,.,.,..  ...,...,.,.,.,...,.,.,.,.,.,.,., 
, ...Y7v77rr:i1@BB5NFYvv777rirvLLYLjJu5krv7YJjLjJUjJvj1k1Yr7i  @B@Br ..................,.........,.,.,.,.,.,.,.,.,.,.............,.,.,.,.,.,.,.,.,.,,.
: ,..:vLLvL7riiu@BZO@B@BBOMOMOOGEE8GMB@PJ2SU1kq2Lv2qPuv:,...   B@B@J .........................,.,.,.,.,.,.,.,.,.,.,....     :::,.  ...,.,,,.,,,.,.,., 
, ,,..rX2uvr;r:,jGLvvuSGM@MBGZ0NSS112ZMk7Lu2v;vSqXvi:      .   kB@M  ..............,.........,.,.,.,.,,,,,.,,,.,.,... .ir7U5uJJuUu7: ..,.,.,.,.,.,.,,.
: ,.. ,FquLLvii::77::,:,:irvFXqXkUUYYLFSL77LSS;::i.    .. .... 7@BE  .......................,.,.,,,,,,,,,,,.,,,,,.. ,vuF:M@.     .7k1, ...,.,.,.,.,.: 
, .,.. :uYvv77ii::i::i...i   .:rLU5YJLiY::.       ,  . .. .... 7B@O  ..........................,.,.,.,.,.,.,,,.,.. v1LFZS@  .,2XUL  rEF. ..,.,,,.,.:,.
: :.,.. 7ujvv7rir:ii:,:.r7..:.. ....vLLi77LYLJ   .......,....  ;@BB  .........................,.,.,.,.,.,.,.,.,.. 5Ui05LMS . E@1@B@L..PM,...,.,.,,,., 
, ,,.,...LYv77rri;:i:.  ,:.,:....:.18kii7J7.rMU  ,.:..,,   ... iB@B  ......................,.,.,.,.,.,.,.,.,.,., 7P:Mv7JMM ..:jUi .q7:.PO....,.,.,.,,.
, ,,,.,. :Y7L7riiiiiUZF7:  :ii:::::207.,.   .58.......   ...   :@B@  .....................,.,.,.,.,.,.,.,.,.,....E,kki.5LBS.........;i;:@v..,.,.,.,,, 
,.,,.,....rLvv7L77:,.i7Lu7   . ,.::JGkri:::.i8Y..  .   ...     :B@B  ..........,.........,...,.,.,.,.,.,.,.,.,..:q.@L: :NYO@8L:,ii::irr:q0:..,.,.,.,,.
: :,,.,., .LXPq0u7rii::,,,i.        iYF1vi:;7,  ...        ..   @B@  .........,.,.........,.,.,.,.,.,.,.,.,.,.. rP.BL,. .7uv2M@0i:rii;7:1Zi...,.,.,., 
,.::,,,,.. ::..2k1L7rLLvri,:.          .        .,....   ..,..  @@@. ..................,.....,.,.,.,.,.,.,.,.,..:Z PS.  ivuMOY;B@ui77r: 5Gi,.,.,.,.,,.
:.:,,,,,,..     uX1L77JuXkL::.  . .            .. ....,,:,.     8@@. ...,.....,...,...,.,.,.,.,.,.,.,.,.,.,.,... 8;.@: LGrUviMO uBJrJv, @ui...,.,.,,, 
:.,:,:,,.,.....  i,.    .72urri        .       ....,,,..     .. v@B, ....,.,.....,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.. iB,rM.vPrO@P.q, B@rL7:OO7:..,,,.,.,,.
:.:,,,,,,,,.,.,  .:....   :SPYv:      ..    . ..,,,.... .    .. rB@: .,.,.,.,.,.,.,.,.,.,.,.,.,.,.,.,,,,,,,.,,,.. rBjvZjkk5OM:iri0@i7jB8L:,.,.,.,.,,: 
:.::,:,:,,.,.,.....:::,.   .r5jv,  ...,. . ..,.... ..      ...  i@B: ,.,.,,,.,,,.,,,,,,,,,.,,,,,,,,,.,,,,,.,,,,,,. :OM11u2257vLvL@UJG@Xvi,.,.,,,,,,:,.
:.:::::,,,:,,.,....,:,,,.     ::......: ... . .   ... .   ... . :@@i .,.,.,.,,,.,,,,,,,,:,:,:,:,:,:,,,,,:,:,:,:,:,...rZMOX1u1FkE@B8MZJ7:..,,:,,,:,,,:.
:.::,:,,,:,,,,,,....::,,,,...  ..... ,,  ... . ..... ... ..     r@Br ,.,,,.,.,.,,,,,,,,:,:,:,:,:,:,:,,,:,,,:,:,:,,,,...iJPEO8OZ011uvi:.,.,,:,:,:,:,::.
:.:::,:,,,,,:,,,.,..:::::,..  . ......,...... ..,.      .   .   rB@7 .,.,.,,,.,,,,,,,,:,:,:::,:,:,:,:,:,:,,,,,,,:,:,,.....::iii::,:.....,,:,:,:,:,:,:.
:.::::,:,,,:,,,,.:,ri:::::::.........,.... .....   . ...   .    :@@7  .,.,,,,,,,,:,,,,,:,:,:,:,,,:,,,,,,,:,:,:,,,:,::,,,...........,.,,:,:,:,:,:,:,:,.
:.:::,:,:,:,:,,,.:i:77;:,,:,,...,,:,:::...,..     . . . ... .   rB@7 i: ,,:,,,,,,,:,,,,,:,:,:,:,:,:,:,:,:,:,:,,,:,:,:,:,:,:,,.,,,,:,,::,:,:,,,:,:,,,:.
:.::::,:,:,:,,,,,,ii:irL77r7rri:,,,i7LJZL:.                  .. v@BMu@u .,,:,,,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,.
:.:::::::::::,:::.:ii:iirrr;7rr7rirr7ii7Err::,:,:::,,,:::,..,.. UBM@@B@. .:,:,:::,:,:,:,:,:,:,:::::::::::::::::::::::::::::::::::::::::::::,:::::::::.
: ............ ... ,,,.,..         .:;i:rir7rr;rii::..          k@BF :O@J. . ........................................................................ 
]]

MY = { }
--[[
#######################################################################################################
            #                 #         #           # # # # # # # #             #       #                   #               # # # # # # # # #     
            #                 #         #                       #           #   #   #   #         # # # # # # # # # # #     #       #       #     
  # # # # # # # # # # #       #     #   #   # #   #           #       #         #       #               #       #           #         #     #     
            #                 #     #   # #   #   #   #     #     #   #   # # # # # #   # # # #     #   #       #   #     # # # # # # # # # # #   
          # # #           # # # #   # # #     #   #     #   #   #     #       # #     #     #     #     #       #     #     #       #       #     
        #   #   #             #   # #   #     #   #         #         #     #   # #     #   #                               # # # # # # # # #     
        #   #   #             #     #   #     #   #     #   #   #     #   #     #   #   #   #       # # # # # # # #         #       #       #     
      #     #     #           #     #   #   # #   #   #     #     #   #       #         #   #         #           #         # # # # # # # # #     
    #       #       #         #     #   #         #         #         #   # # # # #     #   #           #       #                   #             
  #   # # # # # # #   #       # #   #         #   #       # #         #     #     #       #               # # #             # # # # # # # # #     
            #             # #       #         #   #                   #       # #       #   #         # #       # #                 #             
            #                         # # # # #   # # # # # # # # # # #   # #     #   #       #   # #               # #   # # # # # # # # # # #   
#######################################################################################################
]]
local _DEBUG_ = 4
local _BUILD_ = "20141119"
local _VERSION_ = 0x2001400
local _ADDON_ROOT_ = '\\Interface\\MY\\'
local _FRAMEWORK_ROOT_ = '\\Interface\\MY\\.Framework\\'

--[[ 多语言处理
    (table) MY.LoadLangPack(void)
]]
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
    frame = nil,
    hBox = nil,
    hRequest = nil,
    bLoaded = false,
    dwVersion = _VERSION_,
    nDebugLevel = _DEBUG_,
    szBuildDate = _BUILD_,
    szName = _L["mingyi plugins"],
    szShortName = _L["mingyi plugin"],
    szIniFile = _FRAMEWORK_ROOT_.."ui\\MY.ini",
    szUITexPath = _FRAMEWORK_ROOT_.."image\\UIImage.UITex",
    szIniFileTabBox = _FRAMEWORK_ROOT_.."ui\\WndTabBox.ini",
    szIniFileMainPanel = _FRAMEWORK_ROOT_.."ui\\MainPanel.ini",
    
    tTabs = {   -- 标签页
        { id = _L["General"], }, 
        { id = _L["Target"] , }, 
        { id = _L["Battle"] , }, 
        { id = _L["Others"]  , }, 
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
MY.GetAddonInfo = function()
    local t = {}
    t.szName      = _MY.szName
    t.szShortName = _MY.szShortName
    t.szUITexPath = _MY.szUITexPath
    t.dwVersion   = _VERSION_
    t.szBuildDate = _BUILD_
    t.nDebugLevel = _DEBUG_
    t.szRoot      = _ADDON_ROOT_
    t.szFrameworkRoot = _FRAMEWORK_ROOT_
    t.szAuthor = _L['MingYi @ Double Dream Town']
    t.tAuthor = {
      [43567]   = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 体服
      [3582285] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 测试
      [3007396] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 枫泾古镇
      [1600498] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 追风蹑影
      [4664780] = string.char( 0xDC, 0xF8, 0xD2, 0xC1 ), -- 日月明尊
      -- [4662931] = string.char( 0xBE, 0xCD, 0xCA, 0xC7, 0xB8, 0xF6, 0xD5, 0xF3, 0xD1, 0xDB ), -- 日月明尊
      -- [3438030] = string.char( 0xB4, 0xE5, 0xBF, 0xDA, 0xB5, 0xC4, 0xCD, 0xF5, 0xCA, 0xA6, 0xB8, 0xB5 ), -- 枫泾古镇
    }
    return t
end
_MY.Init = function()
    if _MY.bLoaded then return end
    -- var
    _MY.bLoaded = true
    _MY.hBox = MY.GetFrame():Lookup("","Box_1")
    _MY.hRequest = MY.GetFrame():Lookup("Page_1")
    -- 窗口按钮
    MY.UI(MY.GetFrame()):children("#Btn_Close"):click(function() MY.ClosePanel() end)
    -- 重绘选项卡
    MY.RedrawCategory()
    -- init functions
    for i = 1, #_MY.tInitFun, 1 do
        local status, err = pcall(_MY.tInitFun[i].fn)
        if not status then MY.Debug(err.."\n", "_MY.tInitFun#"..i) end
    end

    -- 显示欢迎信息
    MY.Sysmsg({_L("%s, welcome to use mingyi plugins!", GetClientPlayer().szName) .. " v" .. MY.GetVersion() .. ' Build ' .. _MY.szBuildDate})
    if _MY.nDebugLevel >=3 then
        _MY.frame:Hide()
    else
        _MY.frame:Show()
    end
    
    -- 显示作者信息
    MY.UI(MY.GetFrame()):children("#Wnd_Total"):children("#Btn_Weibo")
      :text(_L['author\'s weibo'])
      :click(function()
        MY.UI.OpenInternetExplorer("http://weibo.com/zymah")
      end)
end

--[[
#######################################################################################################
    # # # # # # # # #                                                         #           #       
    #       #       #     # # # # # # # # # # #     # # # # # # # # #           #       #         
    # # # # # # # # #               #                   #       #                                 
    #       #       #             #                     #       #           # # # # # # # # #     
    # # # # # # # # #       # # # # # # # # # #         #       #                   #             
            #               #     #     #     #         #       #                   #             
        # #   # #           #     # # # #     #   # # # # # # # # # # #   # # # # # # # # # # #   
  # # #           # # #     #     #     #     #         #       #                   #             
        #       #           #     # # # #     #         #       #                 #   #           
        #       #           #     #     #     #       #         #               #       #         
      #         #           # # # # # # # # # #       #         #             #           #       
    #           #           #                 #     #           #         # #               # #   
#######################################################################################################
]]
-- close window
MY.ClosePanel = function(bRealClose)
    local frame = MY.GetFrame()
    if frame then
        if not bRealClose then
            frame:Hide()
        else
            Wnd.CloseWindow(frame)
            _MY.frame = nil
        end
        PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
    end
end
-- open window
MY.OpenPanel = function()
    local frame = MY.GetFrame()
    if frame then
        frame:Show()
        frame:BringToTop()
        Station.SetFocusWindow(frame)
    end
    PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end
-- toggle panel
MY.TogglePanel = function()
    local frame = MY.GetFrame()
    if not frame then
        return nil
    end
    if frame:IsVisible() then
        MY.ClosePanel()
    else
        MY.OpenPanel()
    end
end

--[[ 获取主窗体句柄
    (frame) MY.GetFrame()
]]
MY.GetFrame = function()
    if not _MY.frame then
        _MY.frame = Wnd.OpenWindow(_MY.szIniFile, "MY")
        -- local W, H = Station.GetClientSize()
        -- local w, h = _MY.frame:GetSize()
        -- _MY.frame:SetRelPos((W-w)/2, (H-h)/2)
        _MY.frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
        _MY.frame:CorrectPos()
        _MY.frame:Hide()
    end
    return _MY.frame
end

-- (string, number) MY.GetVersion()     -- HM的 获取字符串版本号 修改方便拿过来了
MY.GetVersion = function()
    local v = _MY.dwVersion
    local szVersion = string.format("%d.%d.%d", v/0x1000000,
        math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
    if  v%0x100 ~= 0 then
        szVersion = szVersion .. "b" .. tostring(v%0x100)
    end
    return szVersion, v
end
--[[
#######################################################################################################
            #                 #         #                   #                                     
  # # # # # # # # # # #       #   #     #         #           #             # # # #   # # # #     
      #     #     #         #     #     #           #                       #     #   #     #     
      # # # # # # #         #     # # # # # # #         # # # # # # #       #     #   #     #     
            #             # #   #       #                     #             #     #   #     #     
    # # # # # # # # #       #           #         #           #             #     #   #     #     
            #       #       #           #           #         #           # # # # # # # # # # #   
  # # # # # # # # # # #     #   # # # # # # # #         # # # # # # #       #     #   #     #     
            #       #       #           #                     #             #     #   #     #     
    # # # # # # # # #       #           #           #         #             #     #   #     #     
            #               #           #         #           #             #     #   #     #     
          # #               #           #             # # # # # # # # #   #     # # #     # #     
#######################################################################################################
]]
--[[ 注册初始化函数
    RegisterInit(string szFunName, function fn) -- 注册
    RegisterInit(function fn)                   -- 注册
    RegisterInit(string szFunName)              -- 注销
]]
MY.RegisterInit = function(arg1, arg2)
    local szFunName, fn
    if type(arg1)=='function' then fn = arg1 end
    if type(arg1)=='string'   then szFunName = arg1 end
    if type(arg2)=='function' then fn = arg1 end
    if type(arg2)=='string'   then szFunName = arg1 end
    if fn then
        if szFunName then
            for i = #_MY.tInitFun, 1, -1 do
                if _MY.tInitFun[i].szFunName == szFunName then
                    _MY.tInitFun[i] = { szFunName = szFunName, fn = fn }
                    return nil
                end
            end
        end
        table.insert(_MY.tInitFun, { szFunName = szFunName, fn = fn })
    elseif szFunName then
        for i = #_MY.tInitFun, 1, -1 do
            if _MY.tInitFun[i].szFunName == szFunName then
                table.remove(_MY.tInitFun, i)
            end
        end
    end
end
--[[ 注册游戏事件监听
    -- 注册
    MY.RegisterEvent( szEventName, szListenerId, fnListener )
    MY.RegisterEvent( szEventName, fnListener )
    -- 注销
    MY.RegisterEvent( szEventName, szListenerId )
    MY.RegisterEvent( szEventName )
 ]]
MY.RegisterEvent = function(szEventName, arg1, arg2)
    local szListenerId, fnListener
    -- param check
    if type(szEventName)~="string" then return end
    if type(arg1)=="function" then fnListener=arg1 elseif type(arg1)=="string" then szListenerId=arg1 end
    if type(arg2)=="function" then fnListener=arg2 elseif type(arg2)=="string" then szListenerId=arg2 end
    if fnListener then -- register event
        -- 第一次添加注册系统事件
        if type(_MY.tEvent[szEventName])~="table" then
            _MY.tEvent[szEventName] = {}
            RegisterEvent(szEventName, function(...)
                local param = {}
                for i = 0, 100, 1 do
                    if _G['arg'..i] then
                        table.insert(param, _G['arg'..i])
                    else
                        break
                    end
                end
                for i = #_MY.tEvent[szEventName], 1, -1 do
                    local hEvent = _MY.tEvent[szEventName][i]
                    if type(hEvent.fn)=="function" then
                        -- try to run event function
                        local status, err = pcall(hEvent.fn, unpack(param))
                        -- error report
                        if not status then MY.Debug(err..'\n', 'OnEvent#'..szEventName, 2) end
                    else
                        -- remove none function event
                        table.remove(_MY.tEvent[szEventName], i)
                        -- report error
                        MY.Debug((hEvent.szName or 'id:anonymous')..' is not a function.\n', 'OnEvent#'..szEventName, 2)
                    end
                end
            end)
        end
        -- 往事件数组中添加
        table.insert( _MY.tEvent[szEventName], { fn = fnListener, szName = szListenerId } )
    elseif szListenerId and _MY.tEvent[szEventName] then -- unregister event handle by id
        for i = #_MY.tEvent[szEventName], 1, -1 do
            if _MY.tEvent[szEventName][i].szName == szListenerId then
                table.remove(_MY.tEvent[szEventName], i)
            end
        end
    elseif szEventName and _MY.tEvent[szEventName] then -- unregister all event handle
        _MY.tEvent[szEventName] = {}
    end
end
--[[
#######################################################################################################
    #           #                 # # # # # # #           #               
      #     #   #         # # #         #                 #               
            # # # # #       #         #                   # # # # # #     
          #     #           #     # # # # # # #           #               
  # # #         #           #     #           #           #               
      #   # # # # # # #     #     #     #     #   # # # # # # # # # # #   
      #       #   #         #     #     #     #           #               
      #       #   #         #     #     #     #           # # #           
      #     #     #   #     # #   #     #     #           #     # #       
      #   #         # #   #           #   #               #         #     
    #   #                           #       #             #               
  #       # # # # # # #         # #           #           #               
#######################################################################################################
]]
--[[ 重绘Tab窗口 ]]
MY.RedrawTabPanel1 = function()
    local nTop = 3
    local frame = MY.GetFrame():Lookup("Window_Tabs"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    for i = 1, #_MY.aTabs, 1 do
        local tTab = _MY.aTabs[i]
        -- insert tab
        local fx = Wnd.OpenWindow(_MY.szIniFileTabBox, "aTabBox")
        if fx then
            local item = fx:Lookup("TabBox")
            if item then
                item:ChangeRelation(MY.GetFrame():Lookup("Window_Tabs"), true, true)
                item:SetName("TabBox_" .. tTab.szName)
                item:SetRelPos(0,nTop)
                item:Lookup("","Text_TabBox_Title"):SetText(tTab.szTitle)
                item:Lookup("","Text_TabBox_Title"):SetFontColor(unpack(tTab.rgbTitleColor))
                item:Lookup("","Text_TabBox_Title"):SetAlpha(tTab.alpha)
                if tTab.dwIconFrame then
                    item:Lookup("","Image_TabBox_Icon"):FromUITex(tTab.szIconTex, tTab.dwIconFrame)
                else
                    item:Lookup("","Image_TabBox_Icon"):FromTextureFile(tTab.szIconTex)
                end
                local w,h = item:GetSize()
                nTop = nTop + h
            end
            -- register tab mouse event
            item.OnMouseEnter = function()
                this:Lookup("","Image_TabBox_Background"):Hide()
                this:Lookup("","Image_TabBox_Background_Hover"):Show()
            end
            item.OnMouseLeave = function()
                this:Lookup("","Image_TabBox_Background"):Show()
                this:Lookup("","Image_TabBox_Background_Hover"):Hide()
            end
            item.OnLButtonDown = function()
                if this:Lookup("","Image_TabBox_Background_Sel"):IsVisible() then return end
                PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
                local p = this:GetParent():GetFirstChild()
                while p do
                    p:Lookup("","Image_TabBox_Background_Sel"):Hide()
                    p = p:GetNext()
                end
                this:Lookup("","Image_TabBox_Background_Sel"):Show()
                local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
                while frame do
                    if frame.fn.OnPanelDeactive then
                        local status, err = pcall(frame.fn.OnPanelDeactive, frame)
                        if not status then MY.Debug(err..'\n','MY#OnPanelDeactive',1) end
                    end
                    frame:Destroy()
                    frame = frame:GetNext()
                end
                -- insert main panel
                local fx = Wnd.OpenWindow(_MY.szIniFileMainPanel, "aMainPanel")
                local mainpanel
                if fx then
                    mainpanel = fx:Lookup("MainPanel")
                    if mainpanel then
                        mainpanel:ChangeRelation(MY.GetFrame():Lookup("Window_Main"), true, true)
                        mainpanel:SetRelPos(0,0)
                        mainpanel.fn = tTab.fn
                    end
                end
                Wnd.CloseWindow(fx)
                if tTab.fn.OnPanelActive then
                    local status, err = pcall(tTab.fn.OnPanelActive, mainpanel)
                    if not status then MY.Debug(err..'\n','MY#OnPanelActive',1) end
                end
            end
        end
        Wnd.CloseWindow(fx)
    end
end

MY.RedrawCategory = function(szCategory)
    local frame = MY.GetFrame()
    if not frame then
        return
    end
    
    -- draw category
    local wndCategoryList = frame:Lookup('Wnd_Total/WndContainer_Category')
    wndCategoryList:Clear()
    for _, ctg in pairs(_MY.tTabs) do
        if #ctg > 0 then
            local chkCategory = wndCategoryList:AppendContentFromIni(_MY.szIniFile, "CheckBox_Category")
            chkCategory:SetName('CheckBox_Category_' .. ctg.id)
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
    
    local chkCategory
    if szCategory then
        chkCategory = frame:Lookup('Wnd_Total/WndContainer_Category/CheckBox_Category_' .. szCategory)
    end
    if not chkCategory then
        chkCategory = frame:Lookup('Wnd_Total/WndContainer_Category'):GetFirstChild()
        if not chkCategory then
            return
        end
    end
    chkCategory:Check(true)
end

MY.RedrawTab = function(szCategory)
    local frame = MY.GetFrame()
    if not (frame and szCategory) then
        return
    end
    
    -- draw tabs
    local wndTabs = frame:Lookup('Wnd_Total/WndScroll_Tabs/WndContainer_Tabs')
    wndTabs:Clear()
    
    for _, ctg in ipairs(_MY.tTabs) do
        if ctg.id == szCategory then
            for i, tab in ipairs(ctg) do
                local wndTab = wndTabs:AppendContentFromIni(_MY.szIniFile, "Wnd_TabT")
                wndTab.szID = tab.szID
                wndTab:SetName('Wnd_Tab_' .. tab.szID)
                wndTab:Lookup('Btn_TabBg', ''):Lookup('Text_Tab'):SetText(tab.szTitle)
                if tab.dwIconFrame then
                    wndTab:Lookup('Btn_TabBg', ''):Lookup('Image_TabIcon'):FromUITex(tab.szIconTex, tab.dwIconFrame)
                else
                    wndTab:Lookup('Btn_TabBg', ''):Lookup('Image_TabIcon'):FromTextureFile(tab.szIconTex)
                end
                wndTab:Lookup('Btn_TabBg').OnLButtonClick = function()
                    MY.SwitchTab(this:GetParent().szID)
                end
            end
        end
    end
    wndTabs:FormatAllContentPos()
    
    MY.SwitchTab()
end

MY.SwitchTab = function(szID)
    local frame = MY.GetFrame()
    if not frame then
        return
    end
    
    if szID then
        -- get tab window
        local wndTab = frame:Lookup('Wnd_Total/WndScroll_Tabs/WndContainer_Tabs/Wnd_Tab_' .. szID)
        if (not wndTab) or wndTab.bActived then
            return
        end
        -- deal with ui response
        PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
        local p = wndTab:GetParent():GetFirstChild()
        while p do
            p.bActived = false
            p:Lookup("Btn_TabBg"):SetAnimateGroupNormal(11)
            p:Lookup("Btn_TabBg"):SetAnimateGroupMouseOver(9)
            p = p:GetNext()
        end
        wndTab.bActived = true
        wndTab:Lookup("Btn_TabBg"):SetAnimateGroupNormal(10)
        wndTab:Lookup("Btn_TabBg"):SetAnimateGroupMouseOver(10)
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
            MY.Debug(err..'\n', 'MY#OnPanelDeactive', 1)
        end
    end
    wndMainPanel.OnPanelDeactive = nil
    wndMainPanel:Clear()
    wndMainPanel:Lookup('', ''):Clear()
    
    if not szID then
        -- 欢迎页
        local ui = MY.UI(wndMainPanel)
        ui:append('Image_Adv', 'Image'):item('#Image_Adv'):pos(0, 0):size(557, 278)
          :image(MY.GetAddonInfo().szFrameworkRoot .. 'image/UIImage.UITex', 2)
        
        local txt = ui:append('Text_Adv', 'Text'):item('#Text_Adv'):pos(10, 300):width(250):font(200)
        MY.BreatheCall(function()
            local player = GetClientPlayer()
            if player then
                txt:text(_L('%s, welcome to use mingyi plugins!', player.szName))
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
                            MY.Debug(err..'\n', 'MY#OnPanelActive', 1)
                        else
                            wndMainPanel:FormatAllContentPos()
                        end
                    end
                    wndMainPanel.OnPanelDeactive = tab.fn.OnPanelDeactive
                    break
                end
            end
        end
    end
    wndMainPanel.szID = szID
end
--[[ 注册选项卡
    (void) MY.RegisterPanel( szID, szTitle, szCategory, szIconTex, rgbaTitleColor, fn )
    szID            选项卡唯一ID
    szTitle         选项卡按钮标题
    szCategory      选项卡所在分类
    szIconTex       选项卡图标文件|图标帧
    rgbaTitleColor  选项卡文字rgba
    fn              选项卡各种响应函数 {
        fn.OnPanelActive(wnd)      选项卡激活    wnd为当前MainPanel
        fn.OnPanelDeactive(wnd)    选项卡取消激活
    }
    Ex： MY.RegisterPanel( "Test", "测试标签", "测试", "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, { OnPanelActive = function(wnd) end } )
 ]]
MY.RegisterPanel = function( szID, szTitle, szCategory, szIconTex, rgbaTitleColor, fn )
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
    if type(fn)~="table" then fn = {} end
    if type(rgbaTitleColor)~="table" then rgbaTitleColor = { 255, 255, 255, 255 } end
    if type(rgbaTitleColor[1])~="number" then rgbaTitleColor[1] = 255 end
    if type(rgbaTitleColor[2])~="number" then rgbaTitleColor[2] = 255 end
    if type(rgbaTitleColor[3])~="number" then rgbaTitleColor[3] = 255 end
    if type(rgbaTitleColor[4])~="number" then rgbaTitleColor[4] = 200 end
    table.insert( category, {
        szID        = szID       ,
        szTitle     = szTitle    ,
        szCategory  = szCategory ,
        fn          = fn         ,
        szIconTex   = szIconTex  ,
        dwIconFrame = dwIconFrame,
        rgbTitle    = {rgbaTitleColor[1],rgbaTitleColor[2],rgbaTitleColor[3]},
        alpha       = rgbaTitleColor[4],
    })

    MY.RedrawCategory()
end

--[[
#######################################################################################################
            #                                       # # # # # # # #             #       #         
  # # # # # # # # # # #     # # # # # # # # #                   #           #   #   #   #         
  #     #       #     #     #               #     #           #       #         #       #         
      #     #     #         #               #     #   #     #     #   #   # # # # # #   # # # #   
          #                 #               #     #     #   #   #     #       # #     #     #     
    # # # # # # # # #       #               #     #         #         #     #   # #     #   #     
    #     #         #       #               #     #     #   #   #     #   #     #   #   #   #     
    #   # # # # #   #       #               #     #   #     #     #   #       #         #   #     
    # # #     #     #       #               #     #         #         #   # # # # #     #   #     
    #     # #       #       # # # # # # # # #     #       # #         #     #     #       #       
    #   #     #     #       #               #     #                   #       # #       #   #     
    # # # # # # # # #                             # # # # # # # # # # #   # #     #   #       #   
#######################################################################################################
]]
-- 绑定UI事件
MY.RegisterUIEvent = function(raw, szEvent, fnEvent)
    if not raw['tMy'..szEvent] then
        raw['tMy'..szEvent] = { raw[szEvent] }
        raw[szEvent] = function()
            for _, fn in ipairs(raw['tMy'..szEvent]) do pcall(fn) end
        end
    end
    if fnEvent then table.insert(raw['tMy'..szEvent], fnEvent) end
end
-- create frame
MY.OnFrameCreate = function()
end
MY.OnMouseWheel = function()
    MY.Debug(string.format('OnMouseWheel#%s.%s:%i\n',this:GetName(),this:GetType(),Station.GetMessageWheelDelta()),nil,0)
    return true
end
-- key down
MY.OnFrameKeyDown = function()
	if GetKeyName(Station.GetMessageKey()) == "Esc" then
		MY.ClosePanel()
		return 1
	end
	return 0
end
---------------------------------------------------
---------------------------------------------------
-- 事件、快捷键、菜单注册



if _MY.nDebugLevel <3 then RegisterEvent("CALL_LUA_ERROR", function() OutputMessage("MSG_SYS", arg0) end) end

-- MY.RegisterEvent("CUSTOM_DATA_LOADED", _MY.Init)
MY.RegisterEvent("LOADING_END", _MY.Init)

-- MY.RegisterEvent("PLAYER_ENTER_GAME", _MY.Init)
