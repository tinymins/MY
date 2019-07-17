local base_char,keywords=128,{"and","break","do","else","elseif","end","false","for","function","if","in","local","nil","not","or","repeat","return","then","true","until","while","unpack","write","name","tostring","pack","out_fn","require","base_path","\"Can't open output file for writing: \"","\"TK_OP\"","\"Can't open input file for reading: \"","\"TK_STRING\"","string","locallist","close","ipairs","format","gsub","\"TK_KEYWORD\"","match","package","\"TK_NAME\"","\"TK_COMMENT\"","open","\"TK_LSTRING\"","\"TK_EOL\"","\"<name>\"","path","\"VGLOBAL\"","print","type","\"<string>\"","\"function\"","\"TK_LCOMMENT\"","\"\\n\"","minify_level","\"whitespace\"","require_resource","\"([\\r\\n])([\\r\\n]?)\"","error","endianness","\"string\"","sub","\"TK_EOS\"","\"comments\"","xcount","\"^(#.-\\n)(.+)$\"","\"TK_SPACE\"","\"\"","\"=\"","exit","\"opt-comments\"","sizeof_size_t","read","is_vararg","xref","sizeof_Number","preload","value","\"*a\"","very_verbose","\"...\"","\"^%-%-%[=*%[\"","\"VVOID\"","prev","optimize","\"emptylines\"","\"[\"","\"locals\"","\"VLOCAL\"","executable","seminfo","\".uglified\"","char","skip","\"TK_NUMBER\"","sizeof_int","\"end\"","very_quiet","newname","table","\"unfinished string\"","\"<number>\"","\"package.preload['\"","io","rename","module","gmatch","tonumber","\",\"","\"]\"","\"numbers\"","\"\\\\\"","\"OK!\"","resolve_module","\"opt-whitespace\"","compile_string","\"opt-emptylines\"","os","'cannot open \"'","find","\"VUPVAL\"","\"number\"","minify_string","\".\"","decl",}; function prettify(code) return code:gsub("["..string.char(base_char).."-"..string.char(base_char+#keywords).."]", 
	function (c) return keywords[c:byte()-base_char]; end) end return assert(loadstring(prettify[===[™.œ['optlex']=(â(...)å i=_G
å u=úøÏ"optlex"å t=u.©
å e=u.¿
å d=u.˙
å f=u.rep
å s
Ω=i.Ω
warn={}å a,o,r
å w={TK_KEYWORD=ì,TK_NAME=ì,TK_NUMBER=ì,TK_STRING=ì,TK_LSTRING=ì,TK_OP=ì,TK_EOS=ì,}å x={TK_COMMENT=ì,TK_LCOMMENT=ì,TK_EOL=ì,TK_SPACE=ì,}å c
å â v(e)å n=a[e-1]ä e<=1 è n==Øí
ë ì
Ö n==∆í
ë v(e-1)Ü
ë á
Ü
å â y(n)å e=a[n+1]ä n>=#a è e==Øè e==¡í
ë ì
Ö e==∆í
ë y(n+1)Ü
ë á
Ü
å â O(n)å l=#t(n,‘)å l=e(n,l+1,-(l-1))å e,n=1,0
ï ì É
å l,a,t,o=d(l,º,e)ä é l í Ç Ü
e=l+1
n=n+1
ä#o>0 Å t~=o í
e=e+1
Ü
Ü
ë n
Ü
å â g(c,i)å l=t
å n,e=a[c],a[i]ä n==°è n==Æè
e==°è e==Æí
ë∆Ö n==üè e==üí
ä(n==üÅ(e==®è e==´))è(e==üÅ(n==®è n==´))í
ë∆Ü
ä n==üÅ e==üí
å n,e=o[c],o[i]ä(l(n,"^%.%.?$")Å l(e,"^%."))è(l(n,"^[~=<>]$")Å e==«)è(n==ŸÅ(e==Ÿè e==«))í
ë" "Ü
ë∆Ü
å n=o[c]ä e==üí n=o[i]Ü
ä l(n,"^%.%.?%.?$")í
ë" "Ü
ë∆Ñ
ë" "Ü
Ü
å â k()å l,t,i={},{},{}å e=1
à n=1,#a É
å a=a[n]ä a~=∆í
l[e],t[e],i[e]=a,o[n],r[n]e=e+1
Ü
Ü
a,o,r=l,t,i
Ü
å â E(d)å n=o[d]å n=n
å a
ä t(n,"^0[xX]")í
å e=i.ô(i.Ó(n))ä#e<=#n í
n=e
Ñ
ë
Ü
Ü
ä t(n,"^%d+%.?0*$")í
n=t(n,"^(%d+)%.?0*$")ä n+0>0 í
n=t(n,"^0*([1-9]%d*)$")å l=#t(n,"0*$")å o=i.ô(l)ä l>#o+1 í
n=e(n,1,#n-l).."e"..o
Ü
a=n
Ñ
a="0"Ü
Ö é t(n,"[eE]")í
å l,n=t(n,"^(%d*)%.(%d+)$")ä l==∆í l=0 Ü
ä n+0==0 Å l==0 í
a="0"Ñ
å o=#t(n,"0*$")ä o>0 í
n=e(n,1,#n-o)Ü
ä l+0>0 í
a=l..˛..n
Ñ
a=˛..n
å l=#t(n,"^0*")å l=#n-l
å o=i.ô(#n)ä l+2+#o<1+#n í
a=e(n,-l).."e-"..o
Ü
Ü
Ü
Ñ
å n,l=t(n,"^([^eE]+)[eE]([%+%-]?%d+)$")l=i.Ó(l)å c,o=t(n,"^(%d*)%.(%d*)$")ä c í
l=l-#o
n=c..o
Ü
ä n+0==0 í
a="0"Ñ
å o=#t(n,"^0*")n=e(n,o+1)o=#t(n,"0*$")ä o>0 í
n=e(n,1,#n-o)l=l+o
Ü
å t=i.ô(l)ä l==0 í
a=n
Ö l>0 Å(l<=1+#t)í
a=n..f("0",l)Ö l<0 Å(l>=-#n)í
o=#n+l
a=e(n,1,o)..˛..e(n,o+1)Ö l<0 Å(#t>=-l-#n)í
o=-l-#n
a=˛..f("0",o)..n
Ñ
a=n.."e"..l
Ü
Ü
Ü
ä a Å a~=o[d]í
ä c í
s("<number> (line "..r[d]..") "..o[d].." -> "..a)c=c+1
Ü
o[d]=a
Ü
Ü
å â T(h)å n=o[h]å a=e(n,1,1)å p=(a=="'")Å'"'è"'"å n=e(n,2,-2)å l=1
å f,i=0,0
ï l<=#n É
å h=e(n,l,l)ä h==Úí
å o=l+1
å r=e(n,o,o)å c=d("abfnrtv\\\n\r\"'0123456789",r,1,ì)ä é c í
n=e(n,1,l-1)..e(n,o)l=l+1
Ö c<=8 í
l=l+2
Ö c<=10 í
å t=e(n,o,o+1)ä t=="\r\n"è t=="\n\r"í
n=e(n,1,l)..∏..e(n,o+2)Ö c==10 í
n=e(n,1,l)..∏..e(n,o+1)Ü
l=l+2
Ö c<=12 í
ä r==a í
f=f+1
l=l+2
Ñ
i=i+1
n=e(n,1,l-1)..e(n,o)l=l+1
Ü
Ñ
å t=t(n,"^(%d%d?%d?)",o)o=l+1+#t
å s=t+0
å c=u.ﬂ(s)å r=d("\a\b\f\n\r\t\v",c,1,ì)ä r í
t=Ú..e("abfnrtv",r,r)Ö s<32 í
t=Ú..s
Ö c==a í
t=Ú..c
f=f+1
Ö c==Úí
t="\\\\"Ñ
t=c
ä c==p í
i=i+1
Ü
Ü
n=e(n,1,l-1)..t..e(n,o)l=l+#t
Ü
Ñ
l=l+1
ä h==p í
i=i+1
Ü
Ü
Ü
ä f>i í
l=1
ï l<=#n É
å o,i,t=d(n,"(['\"])",l)ä é o í Ç Ü
ä t==a í
n=e(n,1,o-2)..e(n,o)l=o
Ñ
n=e(n,1,o-1)..Ú..e(n,o)l=o+2
Ü
Ü
a=p
Ü
n=a..n..a
ä n~=o[h]í
ä c í
s("<string> (line "..r[h]..") "..o[h].." -> "..n)c=c+1
Ü
o[h]=n
Ü
Ü
å â K(u)å n=o[u]å c=t(n,"^%[=*%[")å l=#c
å s=e(n,-l,-1)å i=e(n,l+1,-(l+1))å a=∆å n=1
ï ì É
å l,o,d,c=d(i,º,n)å o
ä é l í
o=e(i,n)Ö l>=n í
o=e(i,n,l-1)Ü
ä o~=∆í
ä t(o,"%s+$")í
warn.lstring="trailing whitespace in long string near line "..r[u]Ü
a=a..o
Ü
ä é l í
Ç
Ü
n=l+1
ä l í
ä#c>0 Å d~=c í
n=n+1
Ü
ä é(n==1 Å n==l)í
a=a..∏Ü
Ü
Ü
ä l>=3 í
å e,n=l-1
ï e>=2 É
å l="%]"..f(«,e-2).."%]"ä é t(a,l)í n=e Ü
e=e-1
Ü
ä n í
l=f(«,n-2)c,s=Ÿ..l..Ÿ,..l..Ü
Ü
o[u]=c..a..s
Ü
å â m(r)å l=o[r]å i=t(l,‘)å n=#i
å u=e(l,-n,-1)å c=e(l,n+1,-(n-1))å a=∆å l=1
ï ì É
å o,n,r,i=d(c,º,l)å n
ä é o í
n=e(c,l)Ö o>=l í
n=e(c,l,o-1)Ü
ä n~=∆í
å l=t(n,"%s*$")ä#l>0 í n=e(n,1,-(l+1))Ü
a=a..n
Ü
ä é o í
Ç
Ü
l=o+1
ä o í
ä#i>0 Å r~=i í
l=l+1
Ü
a=a..∏Ü
Ü
n=n-2
ä n>=3 í
å e,l=n-1
ï e>=2 É
å n="%]"..f(«,e-2).."%]"ä é t(a,n)í l=e Ü
e=e-1
Ü
ä l í
n=f(«,l-2)i,u="--["..n..Ÿ,..n..Ü
Ü
o[r]=i..a..u
Ü
å â _(l)å n=o[l]å t=t(n,"%s*$")ä#t>0 í
n=e(n,1,-(t+1))Ü
o[l]=n
Ü
å â L(o,l)ä é o í ë á Ü
å n=t(l,‘)å n=#n
å t=e(l,-n,-1)å e=e(l,n+1,-(n-1))ä d(e,o,1,ì)í
ë ì
Ü
Ü
â ◊(n,l,t,d)å p=n[…]å u=n[ı]å h=n[˜]å b=n["opt-eols"]å S=n["opt-strings"]å q=n["opt-numbers"]å N=n.KEEP
c=n.DETAILS Å 0
s=s è i.≥
ä b í
p=ì
u=ì
h=ì
Ü
a,o,r=l,t,d
å n=1
å l,d
å i
å â t(t,l,e)e=e è n
a[e]=t è∆o[e]=l è∆Ü
ï ì É
l,d=a[n],o[n]å c=v(n)ä c í i=ç Ü
ä l==¡í
Ç
Ö l==®è
l==´è
l==üí
i=n
Ö l==·í
ä q í
E(n)Ü
i=n
Ö l==°è
l==Æí
ä S í
ä l==°í
T(n)Ñ
K(n)Ü
Ü
i=n
Ö l==¨í
ä p í
ä n==1 Å e(d,1,1)=="#"í
_(n)Ñ
t()Ü
Ö u í
_(n)Ü
Ö l==∑í
ä L(N,d)í
ä u í
m(n)Ü
i=n
Ö p í
å e=O(d)ä x[a[n+1]]í
t()l=∆Ñ
t(≈," ")Ü
ä é h Å e>0 í
t(Ø,f(∏,e))Ü
ä u Å l~=∆í
n=n-1
Ü
Ñ
ä u í
m(n)Ü
i=n
Ü
Ö l==Øí
ä c Å h í
t()Ö d=="\r\n"è d=="\n\r"í
t(Ø,∏)Ü
Ö l==≈í
ä u í
ä c è y(n)í
t()Ñ
å l=a[i]ä l==∑í
t()Ñ
å e=a[n+1]ä x[e]í
ä(e==¨è e==∑)Å
l==üÅ o[i]=="-"í
Ñ
t()Ü
Ñ
å e=g(i,n+1)ä e==∆í
t()Ñ
t(≈," ")Ü
Ü
Ü
Ü
Ü
Ñ
Ω("unidentified token encountered")Ü
n=n+1
Ü
k()ä b í
n=1
ä a[1]==¨í
n=3
Ü
ï ì É
l,d=a[n],o[n]ä l==¡í
Ç
Ö l==Øí
å l,e=a[n-1],a[n+1]ä w[l]Å w[e]í
å e=g(n-1,n+1)ä e==∆í
t()Ü
Ü
Ü
n=n+1
Ü
k()Ü
ä c Å c>0 í s()Ü
ë a,o,r
Ü
Ü)™.œ['optparser']=(â(...)å e=_G
å l=úøå u=ú"table"Ï"optparser"å t="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"å i="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"å m={}à e ã l.Ì([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")É
m[e]=ì
Ü
å d,f,s,o,h,b,r,c
å â p(e)å t={}à a=1,#e É
å n=e[a]å o=n.ò
ä é t[o]í
t[o]={ˇ=0,token=0,size=0,}Ü
å e=t[o]e.ˇ=e.ˇ+1
å t=n.Õ
å l=#t
e.token=e.token+l
e.size=e.size+l*#o
ä n.ˇ í
n.id=a
n.√=l
ä l>1 í
n.first=t[2]n.last=t[l]Ü
Ñ
e.id=a
Ü
Ü
ë t
Ü
å â k(e)å c=l.byte
å r=l.ﬂ
å l={TK_KEYWORD=ì,TK_NAME=ì,TK_NUMBER=ì,TK_STRING=ì,TK_LSTRING=ì,}ä é e[…]í
l.TK_COMMENT=ì
l.TK_LCOMMENT=ì
Ü
å n={}à e=1,#d É
n[e]=f[e]Ü
à e=1,#o É
å e=o[e]å l=e.Õ
à e=1,e.√ É
å e=l[e]n[e]=∆Ü
Ü
å e={}à n=0,255 É e[n]=0 Ü
à o=1,#d É
å o,n=d[o],n[o]ä l[o]í
à l=1,#n É
å n=c(n,l)e[n]=e[n]+1
Ü
Ü
Ü
å â a(l)å n={}à o=1,#l É
å l=c(l,o)n[o]={c=l,freq=e[l],}Ü
u.sort(n,â(n,e)ë n.freq>e.freq
Ü)å e={}à l=1,#n É
e[l]=r(n[l].c)Ü
ë u.concat(e)Ü
t=a(t)i=a(i)Ü
å â _()å n
å c,d=#t,#i
å e=r
ä e<c í
e=e+1
n=l.¿(t,e,e)Ñ
å o,a=c,1
ê
e=e-o
o=o*d
a=a+1
î o>e
å o=e%c
e=(e-o)/c
o=o+1
n=l.¿(t,o,o)ï a>1 É
å o=e%d
e=(e-o)/d
o=o+1
n=n..l.¿(i,o,o)a=a-1
Ü
Ü
r=r+1
ë n,h[n]~=ç
Ü
â ◊(e,n,l,a,t)d,f,s,o=n,l,a,t
r=0
c={}h=p(s)b=p(o)ä e["opt-entropy"]í
k(e)Ü
å e={}à n=1,#o É
e[n]=o[n]Ü
u.sort(e,â(n,e)ë n.√>e.√
Ü)å l,n,r={},1,á
à o=1,#e É
å e=e[o]ä é e.isself í
l[n]=e
n=n+1
Ñ
r=ì
Ü
Ü
e=l
å a=#e
ï a>0 É
å i,l
ê
i,l=_()î é m[i]c[#c+1]=i
å n=a
ä l í
å t=s[h[i].id].Õ
å i=#t
à l=1,a É
å l=e[l]å a,e=l.act,l.rem
ï e<0 É
e=o[-e].rem
Ü
å o
à n=1,i É
å n=t[n]ä n>=a Å n<=e í o=ì Ü
Ü
ä o í
l.‡=ì
n=n-1
Ü
Ü
Ü
ï n>0 É
å l=1
ï e[l].‡ É
l=l+1
Ü
n=n-1
å t=e[l]l=l+1
t.Â=i
t.‡=ì
t.done=ì
å i,r=t.first,t.last
å c=t.Õ
ä i Å n>0 í
å a=n
ï a>0 É
ï e[l].‡ É
l=l+1
Ü
a=a-1
å e=e[l]l=l+1
å a,l=e.act,e.rem
ï l<0 É
l=o[-l].rem
Ü
ä é(r<a è i>l)í
ä a>=t.act í
à o=1,t.√ É
å o=c[o]ä o>=a Å o<=l í
n=n-1
e.‡=ì
Ç
Ü
Ü
Ñ
ä e.last Å e.last>=t.act í
n=n-1
e.‡=ì
Ü
Ü
Ü
ä n==0 í Ç Ü
Ü
Ü
Ü
å l,n={},1
à o=1,a É
å e=e[o]ä é e.done í
e.‡=á
l[n]=e
n=n+1
Ü
Ü
e=l
a=#e
Ü
à e=1,#o É
å e=o[e]å l=e.Õ
ä e.Â í
à n=1,e.√ É
å n=l[n]f[n]=e.Â
Ü
e.ò,e.oldname=e.Â,e.ò
Ñ
e.oldname=e.ò
Ü
Ü
ä r í
c[#c+1]="self"Ü
å e=p(o)Ü
Ü)™.œ['llex']=(â(...)å m=_G
å i=úøÏ"llex"å d=i.˙
å u=i.©
å t=i.¿
å p={}à e ã i.Ì([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")É
p[e]=ì
Ü
å e,r,l,a,c
å â o(n,l)å e=#tok+1
tok[e]=n
›[e]=l
tokln[e]=c
Ü
å â f(n,i)å a=t
å t=a(e,n,n)n=n+1
å e=a(e,n,n)ä(e==∏è e=="\r")Å(e~=t)í
n=n+1
t=t..e
Ü
ä i í o(Ø,t)Ü
c=c+1
l=n
ë n
Ü
â init(n,t)e=n
r=t
l=1
c=1
tok={}›={}tokln={}å t,a,e,n=d(e,"^(#[^\r\n]*)(\r?\n?)")ä t í
l=l+#e
o(¨,e)ä#n>0 í f(l,ì)Ü
Ü
Ü
â chunkid()ä r Å u(r,"^[=@]")í
ë t(r,2)Ü
ë"[string]"Ü
â errorline(n,l)å e=Ω è m.Ω
e(i.¶("%s:%d: %s",chunkid(),l è c,n))Ü
å r=errorline
å â s(n)å t=t
å a=t(e,n,n)n=n+1
å o=#u(e,"=*",n)n=n+o
l=n
ë(t(e,n,n)==a)Å o è(-o)-1
Ü
å â h(i,c)å n=l+1
å t=t
å o=t(e,n,n)ä o=="\r"è o==∏í
n=f(n)Ü
å o=n
ï ì É
å o,u,d=d(e,"([\r\n%]])",n)ä é o í
r(i Å"unfinished long string"è"unfinished long comment")Ü
n=o
ä d==í
ä s(n)==c í
a=t(e,a,l)l=l+1
ë a
Ü
n=l
Ñ
a=a..∏n=f(n)Ü
Ü
Ü
å â _(u)å n=l
å i=d
å c=t
ï ì É
å t,d,o=i(e,"([\n\r\\\"'])",n)ä t í
ä o==∏è o=="\r"í
r(Á)Ü
n=t
ä o==Úí
n=n+1
o=c(e,n,n)ä o==∆í Ç Ü
t=i("abfnrtv\n\r",o,1,ì)ä t í
ä t>7 í
n=f(n)Ñ
n=n+1
Ü
Ö i(o,"%D")í
n=n+1
Ñ
å o,e,l=i(e,"^(%d%d?%d?)",n)n=e+1
ä l+1>256 í
r("escape sequence too large")Ü
Ü
Ñ
n=n+1
ä o==u í
l=n
ë c(e,a,n-1)Ü
Ü
Ñ
Ç
Ü
Ü
r(Á)Ü
â llex()å c=d
å d=u
ï ì É
å n=l
ï ì É
å u,b,i=c(e,"^([_%a][_%w]*)",n)ä u í
l=n+#i
ä p[i]í
o(®,i)Ñ
o(´,i)Ü
Ç
Ü
å i,p,u=c(e,"^(%.?)%d",n)ä i í
ä u==˛í n=n+1 Ü
å u,f,a=c(e,"^%d*[%.%d]*([eE]?)",n)n=f+1
ä#a==1 í
ä d(e,"^[%+%-]",n)í
n=n+1
Ü
Ü
å a,n=c(e,"^[_%w]*",n)l=n+1
å e=t(e,i,n)ä é m.Ó(e)í
r("malformed number")Ü
o(·,e)Ç
Ü
å m,p,u,i=c(e,"^((%s)[ \t\v\f]*)",n)ä m í
ä i==∏è i=="\r"í
f(n,ì)Ñ
l=p+1
o(≈,u)Ü
Ç
Ü
å i=d(e,"^%p",n)ä i í
a=n
å f=c("-[\"'.=<>~",i,1,ì)ä f í
ä f<=2 í
ä f==1 í
å r=d(e,"^%-%-(%[?)",n)ä r í
n=n+2
å i=-1
ä r==Ÿí
i=s(n)Ü
ä i>=0 í
o(∑,h(á,i))Ñ
l=c(e,"[\n\r]",n)è(#e+1)o(¨,t(e,a,l-1))Ü
Ç
Ü
Ñ
å e=s(n)ä e>=0 í
o(Æ,h(ì,e))Ö e==-1 í
o(ü,Ÿ)Ñ
r("invalid long string delimiter")Ü
Ç
Ü
Ö f<=5 í
ä f<5 í
l=n+1
o(°,_(i))Ç
Ü
i=d(e,"^%.%.?%.?",n)Ñ
i=d(e,"^%p=?",n)Ü
Ü
l=n+#i
o(ü,i)Ç
Ü
å e=t(e,n,n)ä e~=∆í
l=n+1
o(ü,e)Ç
Ü
o(¡,∆)ë
Ü
Ü
Ü
ë _M
Ü)™.œ['lparser']=(â(...)å S=_G
å b=úøÏ"lparser"å K,y,O,M,d,f,D,n,v,c,p,_,l,P,w,C,r,k,E
å g,u,m,L,N,x
å e=b.Ì
å I={}à e ã e("else elseif end until <eof>","%S+")É
I[e]=ì
Ü
å F={}à e ã e("if while do for repeat function local return break","%S+")É
F[e]=e.."_stat"Ü
å z={}å U={}à e,n,l ã e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")É
z[e]=n+0
U[e]=l+0
Ü
å Z={["not"]=ì,["-"]=ì,["#"]=ì,}å J=8
å â o(l,n)å e=Ω è S.Ω
e(b.¶("(source):%d: %s",n è c,l))Ü
å â e()D=O[d]n,v,c,p=K[d],y[d],O[d],M[d]d=d+1
Ü
å â Q()ë K[d]Ü
å â i(l)å e=n
ä e~=ËÅ e~=µí
ä e==∞í e=v Ü
e="'"..e.."'"Ü
o(l.." near "..e)Ü
å â s(e)i("'"..e.."' expected")Ü
å â o(l)ä n==l í e();ë ì Ü
Ü
å â A(e)ä n~=e í s(e)Ü
Ü
å â t(n)A(n);e()Ü
å â G(e,n)ä é e í i(n)Ü
Ü
å â a(e,l,n)ä é o(e)í
ä n==c í
s(e)Ñ
i("'"..e.."' expected (to close '"..l.."' at line "..n..")")Ü
Ü
Ü
å â h()A(∞)å n=v
_=p
e()ë n
Ü
å â V(e,n)e.k="VK"Ü
å â R(e)V(e,h())Ü
å â s(o,t)å e=l.bl
å n
ä e í
n=e.£
Ñ
n=l.£
Ü
å e=#r+1
r[e]={ò=o,Õ={_},ˇ=_,}ä t í
r[e].isself=ì
Ü
å l=#k+1
k[l]=e
E[l]=n
Ü
å â T(e)å n=#k
ï e>0 É
e=e-1
å n=n-e
å l=k[n]å e=r[l]å t=e.ò
e.act=p
k[n]=ç
å o=E[n]E[n]=ç
å n=o[t]ä n í
e=r[n]e.rem=-l
Ü
o[t]=l
Ü
Ü
å â q()å n=l.bl
å e
ä n í
e=n.£
Ñ
e=l.£
Ü
à n,e ã S.pairs(e)É
å e=r[e]e.rem=p
Ü
Ü
å â p(e,n)ä b.¿(e,1,1)=="("í
ë
Ü
s(e,n)Ü
å â S(o,l)å n=o.bl
å e
ä n í
e=n.£
ï e É
ä e[l]í ë e[l]Ü
n=n.÷
e=n Å n.£
Ü
Ü
e=o.£
ë e[l]è-1
Ü
å â b(n,o,e)ä n==ç í
e.k=≤ë≤Ñ
å l=S(n,o)ä l>=0 í
e.k=€e.id=l
ë€Ñ
ä b(n.÷,o,e)==≤í
ë≤Ü
e.k=˚ë˚Ü
Ü
Ü
å â X(o)å n=h()b(l,n,o)ä o.k==≤í
å e=C[n]ä é e í
e=#w+1
w[e]={ò=n,Õ={_},}C[n]=e
Ñ
å e=w[e].Õ
e[#e+1]=_
Ü
Ñ
å e=o.id
å e=r[e].Õ
e[#e+1]=_
Ü
Ü
å â b(n)å e={}e.isbreakable=n
e.÷=l.bl
e.£={}l.bl=e
Ü
å â _()å e=l.bl
q()l.bl=e.÷
Ü
å â j()å e
ä é l í
e=P
Ñ
e={}Ü
e.÷=l
e.bl=ç
e.£={}l=e
Ü
å â H()q()l=l.÷
Ü
å â S(n)å l={}e()R(l)n.k="VINDEXED"Ü
å â Y(n)e()u(n)t()Ü
å â B(e)å e,l={},{}ä n==∞í
R(e)Ñ
Y(e)Ü
t(«)u(l)Ü
å â q(e)ä e.v.k==’í ë Ü
e.v.k=’Ü
å â q(e)u(e.v)Ü
å â W(l)å i=c
å e={}e.v={}e.t=l
l.k="VRELOCABLE"e.v.k=’t("{")ê
ä n=="}"í Ç Ü
å n=n
ä n==∞í
ä Q()~=«í
q(e)Ñ
B(e)Ü
Ö n==Ÿí
B(e)Ñ
q(e)Ü
î é o(Ô)Å é o(";")a("}","{",i)Ü
å â Q()å t=0
ä n~=")"í
ê
å n=n
ä n==∞í
s(h())t=t+1
Ö n==”í
e()l.Ã=ì
Ñ
i("<name> or '...' expected")Ü
î l.Ã è é o(Ô)Ü
T(t)Ü
å â B(r)å l={}å t=c
å o=n
ä o=="("í
ä t~=D í
i("ambiguous syntax (function call x new statement)")Ü
e()ä n==")"í
l.k=’Ñ
g(l)Ü
a(")","(",t)Ö o=="{"í
W(l)Ö o==µí
V(l,v)e()Ñ
i("function arguments expected")ë
Ü
r.k="VCALL"Ü
å â D(l)å n=n
ä n=="("í
å n=c
e()u(l)a(")","(",n)Ö n==∞í
X(l)Ñ
i("unexpected symbol")Ü
Ü
å â q(l)D(l)ï ì É
å n=n
ä n==˛í
S(l)Ö n==Ÿí
å e={}Y(e)Ö n==":"í
å n={}e()R(n)B(l)Ö n=="("è n==µè n=="{"í
B(l)Ñ
ë
Ü
Ü
Ü
å â R(o)å n=n
ä n==Ëí
o.k="VKNUM"Ö n==µí
V(o,v)Ö n=="nil"í
o.k="VNIL"Ö n=="true"í
o.k="VTRUE"Ö n=="false"í
o.k="VFALSE"Ö n==”í
G(l.Ã==ì,"cannot use '...' outside a vararg function");o.k="VVARARG"Ö n=="{"í
W(o)ë
Ö n==∂í
e()N(o,á,c)ë
Ñ
q(o)ë
Ü
e()Ü
å â v(o,a)å l=n
å t=Z[l]ä t í
e()v(o,J)Ñ
R(o)Ü
l=n
å n=z[l]ï n Å n>a É
å o={}e()å e=v(o,U[l])l=e
n=z[l]Ü
ë l
Ü
â u(e)v(e,0)Ü
å â z(e)å n={}å e=e.v.k
G(e==€è e==˚è e==≤è e=="VINDEXED","syntax error")ä o(Ô)í
å e={}e.v={}q(e.v)z(e)Ñ
t(«)g(n)ë
Ü
n.k="VNONRELOC"Ü
å â v(e,n)t("do")b(á)T(e)m()_()Ü
å â V(e)å n=f
p("(for index)")p("(for limit)")p("(for step)")s(e)t(«)L()t(Ô)L()ä o(Ô)í
L()Ñ
Ü
v(1,ì)Ü
å â R(e)å n={}p("(for generator)")p("(for state)")p("(for control)")s(e)å e=1
ï o(Ô)É
s(h())e=e+1
Ü
t("in")å l=f
g(n)v(e,á)Ü
å â B(e)å l=á
X(e)ï n==˛É
S(e)Ü
ä n==":"í
l=ì
S(e)Ü
ë l
Ü
â L()å e={}u(e)Ü
å â v()å e={}u(e)Ü
å â L()e()v()t("then")m()Ü
å â G()å n,e={}s(h())n.k=€T(1)N(e,á,c)Ü
å â S()å e=0
å n={}ê
s(h())e=e+1
î é o(Ô)ä o(«)í
g(n)Ñ
n.k=’Ü
T(e)Ü
â g(e)u(e)ï o(Ô)É
u(e)Ü
Ü
â N(l,n,e)j()t("(")ä n í
p("self",ì)T(1)Ü
Q()t(")")x()a(„,∂,e)H()Ü
â m()b(á)x()_()Ü
â for_stat()å o=f
b(ì)e()å l=h()å e=n
ä e==«í
V(l)Ö e==Ôè e=="in"í
R(l)Ñ
i("'=' or 'in' expected")Ü
a(„,"for",o)_()Ü
â while_stat()å n=f
e()v()b(ì)t("do")m()a(„,"while",n)_()Ü
â repeat_stat()å n=f
b(ì)b(á)e()x()a("until","repeat",n)v()_()_()Ü
â if_stat()å l=f
å o={}L()ï n=="elseif"É
L()Ü
ä n=="else"í
e()m()Ü
a(„,"if",l)Ü
â return_stat()å l={}e()å e=n
ä I[e]è e==";"í
Ñ
g(l)Ü
Ü
â break_stat()å n=l.bl
e()ï n Å é n.isbreakable É
n=n.÷
Ü
ä é n í
i("no loop to break")Ü
Ü
â expr_stat()å e={}e.v={}q(e.v)ä e.v.k=="VCALL"í
Ñ
e.÷=ç
z(e)Ü
Ü
â function_stat()å o=f
å n,l={},{}e()å e=B(n)N(l,e,o)Ü
â do_stat()å n=f
e()m()a(„,"do",n)Ü
â local_stat()e()ä o(∂)í
G()Ñ
S()Ü
Ü
å â t()f=c
å e=n
å n=F[e]ä n í
_M[n]()ä e=="return"è e=="break"í ë ì Ü
Ñ
expr_stat()Ü
ë á
Ü
â x()å e=á
ï é e Å é I[n]É
e=t()o(";")Ü
Ü
â parser()j()l.Ã=ì
e()x()A("<eof>")H()ë w,r
Ü
â init(e,t,a)d=1
P={}å n=1
K,y,O,M={},{},{},{}à l=1,#e É
å e=e[l]å o=ì
ä e==®è e==üí
e=t[l]Ö e==´í
e=∞y[n]=t[l]Ö e==·í
e=Ëy[n]=0
Ö e==°è e==Æí
e=µy[n]=∆Ö e==¡í
e="<eof>"Ñ
o=á
Ü
ä o í
K[n]=e
O[n]=a[l]M[n]=l
n=n+1
Ü
Ü
w,C,r={},{},{}k,E={},{}Ü
ë _M
Ü)™.œ['minichunkspy']=(â(...)å h,n,u=¢,Ê,math
å l,b,a,e=•,setmetatable,¥,assert
å l=__END_OF_GLOBALS__
å f,t,s=h.ﬂ,h.byte,h.¿
å v,d,y=u.frexp,u.ldexp,u.abs
å _=n.concat
å l=u.huge
å m=l-l
å o=á
å i=4
å r=4
å c=8
å n={}å â k()n[#n+1]={o,i,r,c}Ü
å â g()o,i,r,c=ñ(n[#n])n[#n]=ç
Ü
å â n(e,n)ë e.new(e,n)Ü
å p={}å n=n{new=â(e,l)å l=l è{}å n=p[e]è{__index=e,__call=n}p[e]=n
ë b(l,n)Ü,}å x=n{ñ=â(n,n,e)ë ç,e Ü,ö=â(e,e)ë∆Ü}å p={}å â b(e)å n=p[e]è n{ñ=â(o,l,n)ë s(l,n,n+e-1),n+e
Ü,ö=â(l,n)ë s(n,1,e)Ü}p[e]=n
ë n
Ü
å T=n{ñ=â(l,n,e)ë t(n,e,e),e+1
Ü,ö=â(n,e)ë f(e)Ü}å t=n{ñ=â(l,e,n)å e,l,a,t=t(e,n,n+3)ä o í e,l,a,t=t,a,l,e Ü
ë e+l*256+a*256^2+t*256^3,n+4
Ü,ö=â(n,i)e(a(i)==¸,"unexpected value type to pack as an uint32")å n,l,t,e
e=i%2^32
n=e%256;e=(e-n)/256
l=e%256;e=(e-l)/256
t=e%256;e=(e-t)/256
ä o í n,l,t,e=e,t,l,n Ü
ë f(n,l,t,e)Ü}å w=n{ñ=â(n,e,l)å n=t:ñ(e,l)å e=t:ñ(e,l+4)ä o í n,e=e,n Ü
ë n+e*2^32,l+8
Ü,ö=â(l,n)e(a(n)==¸,"unexpected value type to pack as an uint64")å e=n%2^32
å n=(n-e)/2^32
ä o í e,n=n,e Ü
ë t:ö(e)..t:ö(n)Ü}å â E(e,l)å n=t:ñ(e,l)å e=t:ñ(e,l+4)ä o í n,e=e,n Ü
å l=e%2^20
å n=n
å o=n+l*2^32
e=(e-l)/2^20
å n=e%2^11
å e=e<=n Å 1 è-1
ë e,n,o
Ü
å â f(l,i,n)å e=n%2^32
å a=(n-e)/2^32
å n=e
å e=((l<0 Å 2^11 è 0)+i)*2^20+a
ä o í n,e=e,n Ü
ë t.ö(ç,n)..t.ö(ç,e)Ü
å â K(e)ä e~=e í ë e Ü
ä e==0 í e=1/e Ü
ë e>0 Å 1 è-1
Ü
å s=d(1,-1022-52)å p=s*2^52
å O=d(2^52-1,-1022-52)å p=d(2^53-1,1023-52)e(s~=0 Å s/2==0)e(p~=l)e(p*2==l)å f=n{ñ=â(n,e,t)å a,n,o=E(e,t)å e
ä n==0 í
e=d(o,-1022-52)Ö n==2047 í
e=o==0 Å l è m
Ñ
e=d(2^52+o,n-1023-52)Ü
e=a*e
ë e,t+8
Ü,ö=â(n,e)ä e~=e í
ë f(1,2047,2^52-1)Ü
å o=K(e)e=y(e)ä e==l í ë f(o,2047,0)Ü
ä e==0 í ë f(o,0,0)Ü
å n,l
ä e<=O í
n=0
l=e/s
Ñ
å e,o=v(e)l=(2*e-1)*2^52
n=o+1022
Ü
ë f(o,n,l)Ü}å l=T
å d={[4]=t,[8]=w}å p={[4]=float,[8]=f}å s=n{ñ=â(l,e,n)ë d[i]:ñ(e,n)Ü,ö=â(n,e)ë d[i]:ö(e)Ü,}å t=n{ñ=â(l,n,e)ë d[r]:ñ(n,e)Ü,ö=â(n,e)ë d[r]:ö(e)Ü,}å y=n{ñ=â(l,e,n)ë p[c]:ñ(e,n)Ü,ö=â(n,e)ë p[c]:ö(e)Ü,}å v=b(4)å m=n{ñ=â(l,i,n)å t={}å e,o=1,1
ï l[e]É
å a=l[e]å l=a.ò
ä é l í l,o=o,o+1 Ü
t[l],n=a:ñ(i,n)e=e+1
Ü
ë t,n
Ü,ö=â(n,a)å o={}å e,l=1,1
ï n[e]É
å t=n[e]å n=t.ò
ä é n í n,l=l,l+1 Ü
o[e]=t:ö(a[n])e=e+1
Ü
ë _(o)Ü}å f=n{ñ=â(o,l,e)å a,e=t:ñ(l,e)å n={}å t=o.¥
à o=1,a É
n[o],e=t:ñ(l,e)Ü
ë n,e
Ü,ö=â(o,l)å n=#l
å e={t:ö(n)}å o=o.¥
à n=1,n É
e[#e+1]=o:ö(l[n])Ü
ë _(e)Ü}å w=n{ñ=â(o,l,n)å n,l=t:ñ(l,n)e(n==0 è n==1,"unpacked an unexpected value "..n.." for a Boolean")ë n==1,l
Ü,ö=â(l,n)e(a(n)=="boolean","unexpected value type to pack as a Boolean")ë t:ö(n Å 1 è 0)Ü}å s=n{ñ=â(n,l,e)å n,e=s:ñ(l,e)å o=ç
ä n>0 í
å n=n-1
o=l:¿(e,e+n-1)Ü
ë o,e+n
Ü,ö=â(l,n)e(a(n)=="nil"è a(n)==ø,"unexpected value type to pack as a String")ä n==ç í
ë s:ö(0)Ü
ë s:ö(#n+1)..n.."\0"Ü}å _=m{b(4){ò="signature"},l{ò="version"},l{ò="format"},l{ò="endianness"},l{ò="sizeof_int"},l{ò="sizeof_size_t"},l{ò="sizeof_insn"},l{ò="sizeof_Number"},l{ò="integral_flag"},}å b={[0]=x,[1]=w,[3]=y,[4]=s,}å y=n{ñ=â(t,o,n)å n,t=l:ñ(o,n)å l=b[n]e(l,"unknown constant type "..n.." to unpack")å l,o=l:ñ(o,t)ä n==3 í
e(a(l)==¸)Ü
ë{¥=n,–=l},o
Ü,ö=â(n,e)å e,n=e.¥,e.–
ë l:ö(e)..b[e]:ö(n)Ü}å b=m{s{ò="name"},t{ò="startpc"},t{ò="endpc"}}å l=m{s{ò="name"},t{ò="line"},t{ò="last_line"},l{ò="num_upvalues"},l{ò="num_parameters"},l{ò="is_vararg"},l{ò="max_stack_size"},f{ò="insns",¥=v},f{ò="constants",¥=y},f{ò="prototypes",¥=ç},f{ò="source_lines",¥=t},f{ò=⁄,¥=b},f{ò="upvalues",¥=s},}e(l[10].ò=="prototypes","missed the function prototype list")l[10].¥=l
å l=n{ñ=â(t,f,n)å a={}å n,t=_:ñ(f,n)e(n.signature=="\27Lua","signature check failed")e(n.version==81,"version mismatch")e(n.¶==0,"format mismatch")e(n.æ==0 è
n.æ==1,"endianness mismatch")e(d[n.‚],"int size unsupported")e(d[n. ],"size_t size unsupported")e(n.sizeof_insn==4,"insn size unsupported")e(p[n.Œ],"number size unsupported")e(n.integral_flag==0,"integral flag mismatch; only floats supported")k()o=n.æ==0
i=n. 
r=n.‚
c=n.Œ
a.header=n
a.body,t=l:ñ(f,t)g()ë a,t
Ü,ö=â(e,n)å t
k()å e=n.header
o=e.æ==0
i=e. 
r=e.‚
c=e.Œ
t=_:ö(n.header)..l:ö(n.body)g()ë t
Ü}å â o(e)ä a(e)==∂í
ë o(h.dump(e))Ü
å n=l:ñ(e,1)å l=l:ö(n)ä e==l í ë ì Ü
å n
å n=u.min(#e,#l)à n=1,n É
å l=e:¿(n,n)å e=e:¿(n,n)ä l~=e í
ë á,("chunk roundtripping failed: ".."first byte difference at index %d"):¶(n)Ü
Ü
ë á,("chunk round tripping failed: ".."original length %d vs. %d"):¶(#e,#l)Ü
ë{disassemble=â(e)ë l:ñ(e,1)Ü,assemble=â(e)ë l:ö(e)Ü,validate=o}Ü)É å e={};e["vio"]='local vio = {};\
vio.__index = vio; \
	\
function vio.open(string)\
	return setmetatable({ pos = 1, data = string }, vio);\
end\
\
function vio:read(format, ...)\
	if self.pos >= #self.data then return; end\
	if format == "*a" then\
		local oldpos = self.pos;\
		self.pos = #self.data;\
		return self.data:sub(oldpos, self.pos);\
	elseif format == "*l" then\
		local data;\
		data, self.pos = self.data:match("([^\\r\\n]*)\\r?\\n?()", self.pos)\
		return data;\
	elseif format == "*n" then\
		local data;\
		data, self.pos = self.data:match("(%d+)()", self.pos)\
		return tonumber(data);	\
	elseif type(format) == "number" then\
		local oldpos = self.pos;\
		self.pos = self.pos + format;\
		return self.data:sub(oldpos, self.pos-1);\
	end\
end\
\
function vio:seek(whence, offset)\
	if type(whence) == "number" then\
		whence, offset = "cur", whence;\
	end\
	offset = offset or 0;\
	\
	if whence == "cur" then\
		self.pos = self.pos + offset;\
	elseif whence == "set" then\
		self.pos = offset + 1;\
	elseif whence == "end" then\
		self.pos = #self.data - offset;\
	end\
	\
	return self.pos;\
end\
\
local function _readline(f) return f:read("*l"); end\
function vio:lines()\
	return _readline, self;\
end\
\
function vio:write(...)\
	for i=1,select(\'#\', ...) do\
		local dat = tostring(select(i, ...));\
		self.data = self.data:sub(1, self.pos-1)..dat..self.data:sub(self.pos+#dat, -1);\
	end\
end\
\
function vio:close()\
	self.pos, self.data = nil, nil;\
end\
\
'e["gunzip.lua"]="local i,h,b,m,l,d,e,y,r,w,u,v,l,l=assert,error,ipairs,pairs,tostring,type,setmetatable,io,math,table.sort,math.max,string.char,io.open,_G;local function p(n)local l={};local e=e({},l)function l:__index(l)local n=n(l);e[l]=n\
return n\
end\
return e\
end\
local function l(n,l)l=l or 1\
h({n},l+1)end\
local function _(n)local l={}l.outbs=n\
l.wnd={}l.wnd_pos=1\
return l\
end\
local function t(l,e)local n=l.wnd_pos\
l.outbs(e)l.wnd[n]=e\
l.wnd_pos=n%32768+1\
end\
local function n(l)return i(l,'unexpected end of file')end\
local function o(n,l)return n%(l+l)>=l\
end\
local a=p(function(l)return 2^l end)local c=e({},{__mode='k'})local function g(o)local l=1\
local e={}function e:read()local n\
if l<=#o then\
n=o:byte(l)l=l+1\
end\
return n\
end\
return e\
end\
local l\
local function s(d)local n,l,o=0,0,{};function o:nbits_left_in_byte()return l\
end\
function o:read(e)e=e or 1\
while l<e do\
local e=d:read()if not e then return end\
n=n+a[l]*e\
l=l+8\
end\
local o=a[e]local a=n%o\
n=(n-a)/o\
l=l-e\
return a\
end\
c[o]=true\
return o\
end\
local function f(l)return c[l]and l or s(g(l))end\
local function s(l)local n\
if y.type(l)=='file'then\
n=function(n)l:write(v(n))end\
elseif d(l)=='function'then\
n=l\
end\
return n\
end\
local function d(e,o)local l={}if o then\
for e,n in m(e)do\
if n~=0 then\
l[#l+1]={val=e,nbits=n}end\
end\
else\
for n=1,#e-2,2 do\
local o,n,e=e[n],e[n+1],e[n+2]if n~=0 then\
for e=o,e-1 do\
l[#l+1]={val=e,nbits=n}end\
end\
end\
end\
w(l,function(n,l)return n.nbits==l.nbits and n.val<l.val or n.nbits<l.nbits\
end)local e=1\
local o=0\
for n,l in b(l)do\
if l.nbits~=o then\
e=e*a[l.nbits-o]o=l.nbits\
end\
l.code=e\
e=e+1\
end\
local e=r.huge\
local c={}for n,l in b(l)do\
e=r.min(e,l.nbits)c[l.code]=l.val\
end\
local function o(n,e)local l=0\
for e=1,e do\
local e=n%2\
n=(n-e)/2\
l=l*2+e\
end\
return l\
end\
local d=p(function(l)return a[e]+o(l,e)end)function l:read(a)local o,l=1,0\
while 1 do\
if l==0 then\
o=d[n(a:read(e))]l=l+e\
else\
local n=n(a:read())l=l+1\
o=o*2+n\
end\
local l=c[o]if l then\
return l\
end\
end\
end\
return l\
end\
local function b(l)local a=2^1\
local e=2^2\
local c=2^3\
local d=2^4\
local n=l:read(8)local n=l:read(8)local n=l:read(8)local n=l:read(8)local t=l:read(32)local t=l:read(8)local t=l:read(8)if o(n,e)then\
local n=l:read(16)local e=0\
for n=1,n do\
e=l:read(8)end\
end\
if o(n,c)then\
while l:read(8)~=0 do end\
end\
if o(n,d)then\
while l:read(8)~=0 do end\
end\
if o(n,a)then\
l:read(16)end\
end\
local function p(l)local f=l:read(5)local i=l:read(5)local e=n(l:read(4))local a=e+4\
local e={}local o={16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15}for n=1,a do\
local l=l:read(3)local n=o[n]e[n]=l\
end\
local e=d(e,true)local function r(o)local t={}local a\
local c=0\
while c<o do\
local o=e:read(l)local e\
if o<=15 then\
e=1\
a=o\
elseif o==16 then\
e=3+n(l:read(2))elseif o==17 then\
e=3+n(l:read(3))a=0\
elseif o==18 then\
e=11+n(l:read(7))a=0\
else\
h'ASSERT'end\
for l=1,e do\
t[c]=a\
c=c+1\
end\
end\
local l=d(t,true)return l\
end\
local n=f+257\
local l=i+1\
local n=r(n)local l=r(l)return n,l\
end\
local a\
local o\
local c\
local r\
local function h(e,n,l,d)local l=l:read(e)if l<256 then\
t(n,l)elseif l==256 then\
return true\
else\
if not a then\
local l={[257]=3}local e=1\
for n=258,285,4 do\
for n=n,n+3 do l[n]=l[n-1]+e end\
if n~=258 then e=e*2 end\
end\
l[285]=258\
a=l\
end\
if not o then\
local l={}for e=257,285 do\
local n=u(e-261,0)l[e]=(n-(n%4))/4\
end\
l[285]=0\
o=l\
end\
local a=a[l]local l=o[l]local l=e:read(l)local o=a+l\
if not c then\
local e={[0]=1}local l=1\
for n=1,29,2 do\
for n=n,n+1 do e[n]=e[n-1]+l end\
if n~=1 then l=l*2 end\
end\
c=e\
end\
if not r then\
local n={}for e=0,29 do\
local l=u(e-2,0)n[e]=(l-(l%2))/2\
end\
r=n\
end\
local l=d:read(e)local a=c[l]local l=r[l]local l=e:read(l)local l=a+l\
for e=1,o do\
local l=(n.wnd_pos-1-l)%32768+1\
t(n,i(n.wnd[l],'invalid distance'))end\
end\
return false\
end\
local function u(l,a)local i=l:read(1)local e=l:read(2)local r=0\
local o=1\
local c=2\
local f=3\
if e==r then\
l:read(l:nbits_left_in_byte())local e=l:read(16)local o=n(l:read(16))for e=1,e do\
local l=n(l:read(8))t(a,l)end\
elseif e==o or e==c then\
local n,o\
if e==c then\
n,o=p(l)else\
n=d{0,8,144,9,256,7,280,8,288,nil}o=d{0,5,32,nil}end\
repeat until h(l,a,n,o);end\
return i~=0\
end\
local function e(l)local n,l=f(l.input),_(s(l.output))repeat until u(n,l)end\
return function(n)local l=f(n.input)local n=s(n.output)b(l)e{input=l,output=n}l:read(l:nbits_left_in_byte())l:read()end\
"e["squish.debug"]='package.preload[\'minichunkspy\']=(function(...)local string,table,math=string,table,math\
local ipairs,setmetatable,type,assert=ipairs,setmetatable,type,assert\
local _=__END_OF_GLOBALS__\
local string_char,string_byte,string_sub=string.char,string.byte,string.sub\
local table_concat=table.concat\
local math_abs,math_ldexp,math_frexp=math.abs,math.ldexp,math.frexp\
local Inf=math.huge\
local Nan=Inf-Inf\
local BIG_ENDIAN=false\
local function construct(class,...)return class.new(class,...)end\
local mt_memo={}local Field=construct{new=function(class,self)local self=self or{}local mt=mt_memo[class]or{__index=class,__call=construct}mt_memo[class]=mt\
return setmetatable(self,mt)end,}local None=Field{unpack=function(self,bytes,ix)return nil,ix end,pack=function(self,val)return""end}local char_memo={}local function char(n)local field=char_memo[n]or Field{unpack=function(self,bytes,ix)return string_sub(bytes,ix,ix+n-1),ix+n\
end,pack=function(self,val)return string_sub(val,1,n)end}char_memo[n]=field\
return field\
end\
local uint8=Field{unpack=function(self,bytes,ix)return string_byte(bytes,ix,ix),ix+1\
end,pack=function(self,val)return string_char(val)end}local uint32=Field{unpack=function(self,bytes,ix)local a,b,c,d=string_byte(bytes,ix,ix+3)if BIG_ENDIAN then a,b,c,d=d,c,b,a end\
return a+b*256+c*256^2+d*256^3,ix+4\
end,pack=function(self,val)assert(type(val)=="number","unexpected value type to pack as an uint32")local a,b,c,d\
d=val%2^32\
a=d%256;d=(d-a)/256\
b=d%256;d=(d-b)/256\
c=d%256;d=(d-c)/256\
if BIG_ENDIAN then a,b,c,d=d,c,b,a end\
return string_char(a,b,c,d)end}local int32=uint32{unpack=function(self,bytes,ix)local val,ix=uint32:unpack(bytes,ix)return val<2^32 and val or(val-2^31),ix\
end}local Byte=uint8\
local Size_t=uint32\
local Integer=int32\
local Number=char(8)local Insn=char(4)local Struct=Field{unpack=function(self,bytes,ix)local val={}local i,j=1,1\
while self[i]do\
local field=self[i]local key=field.name\
if not key then key,j=j,j+1 end\
val[key],ix=field:unpack(bytes,ix)i=i+1\
end\
return val,ix\
end,pack=function(self,val)local data={}local i,j=1,1\
while self[i]do\
local field=self[i]local key=field.name\
if not key then key,j=j,j+1 end\
data[i]=field:pack(val[key])i=i+1\
end\
return table_concat(data)end}local List=Field{unpack=function(self,bytes,ix)local len,ix=Integer:unpack(bytes,ix)local vals={}local field=self.type\
for i=1,len do\
vals[i],ix=field:unpack(bytes,ix)end\
return vals,ix\
end,pack=function(self,vals)local len=#vals\
local data={Integer:pack(len)}local field=self.type\
for i=1,len do\
data[#data+1]=field:pack(vals[i])end\
return table_concat(data)end}local Boolean=Field{unpack=function(self,bytes,ix)local val,ix=Integer:unpack(bytes,ix)assert(val==0 or val==1,"unpacked an unexpected value "..val.." for a Boolean")return val==1,ix\
end,pack=function(self,val)assert(type(val)=="boolean","unexpected value type to pack as a Boolean")return Integer:pack(val and 1 or 0)end}local String=Field{unpack=function(self,bytes,ix)local len,ix=Integer:unpack(bytes,ix)local val=nil\
if len>0 then\
local string_len=len-1\
val=bytes:sub(ix,ix+string_len-1)end\
return val,ix+len\
end,pack=function(self,val)assert(type(val)=="nil"or type(val)=="string","unexpected value type to pack as a String")if val==nil then\
return Integer:pack(0)end\
return Integer:pack(#val+1)..val.."\\0"end}local ChunkHeader=Struct{char(4){name="signature"},Byte{name="version"},Byte{name="format"},Byte{name="endianness"},Byte{name="sizeof_int"},Byte{name="sizeof_size_t"},Byte{name="sizeof_insn"},Byte{name="sizeof_Number"},Byte{name="integral_flag"},}local ConstantTypes={[0]=None,[1]=Boolean,[3]=Number,[4]=String,}local Constant=Field{unpack=function(self,bytes,ix)local t,ix=Byte:unpack(bytes,ix)local field=ConstantTypes[t]assert(field,"unknown constant type "..t.." to unpack")local v,ix=field:unpack(bytes,ix)return{type=t,value=v},ix\
end,pack=function(self,val)local t,v=val.type,val.value\
return Byte:pack(t)..ConstantTypes[t]:pack(v)end}local Local=Struct{String{name="name"},Integer{name="startpc"},Integer{name="endpc"}}local Function=Struct{String{name="name"},Integer{name="line"},Integer{name="last_line"},Byte{name="num_upvalues"},Byte{name="num_parameters"},Byte{name="is_vararg"},Byte{name="max_stack_size"},List{name="insns",type=Insn},List{name="constants",type=Constant},List{name="prototypes",type=nil},List{name="source_lines",type=Integer},List{name="locals",type=Local},List{name="upvalues",type=String},}assert(Function[10].name=="prototypes","missed the function prototype list")Function[10].type=Function\
local Chunk=Struct{ChunkHeader{name="header"},Function{name="body"}}local function validate(chunk)if type(chunk)=="function"then\
return validate(string.dump(chunk))end\
local f=Chunk:unpack(chunk,1)local chunk2=Chunk:pack(f)if chunk==chunk2 then return true end\
local i\
local len=math.min(#chunk,#chunk2)for i=1,len do\
local a=chunk:sub(i,i)local b=chunk:sub(i,i)if a~=b then\
return false,("chunk roundtripping failed: ".."first byte difference at index %d"):format(i)end\
end\
return false,("chunk round tripping failed: ".."original length %d vs. %d"):format(#chunk,#chunk2)end\
return{disassemble=function(chunk)return Chunk:unpack(chunk,1)end,assemble=function(disassembled)return Chunk:pack(disassembled)end,validate=validate}end)local cs=require"minichunkspy"local function ___adjust_chunk(chunk,newname,lineshift)local c=cs.disassemble(string.dump(chunk));c.body.name=newname;lineshift=-c.body.line;local function shiftlines(c)c.line=c.line+lineshift;c.last_line=c.last_line+lineshift;for i,line in ipairs(c.source_lines)do\
c.source_lines[i]=line+lineshift;end\
for i,f in ipairs(c.prototypes)do\
shiftlines(f);end\
end\
shiftlines(c.body);return assert(loadstring(cs.assemble(c),newname))();end\
'â ª(n)ë e[n]è Ω("resource '"..ô(n).."' not found");Ü Ü
pcall(ú,"luarocks.require");å o={v="verbose",vv="very_verbose",o="output",q="quiet",qq="very_quiet",g="debug"}å e={use_http=á};à n,l ã •(arg)É
ä l:©("^%-")í
å n=l:©("^%-%-?([^%s=]+)()")n=(o[n]è n):ß("%-+","_");ä n:©("^no_")í
n=n:¿(4,-1);e[n]=á;Ñ
e[n]=l:©("=(.*)$")è ì;Ü
Ñ
ù=l;Ü
Ü
ä e.“ í e.verbose=ì;Ü
ä e.‰ í e.quiet=ì;Ü
å n=â()Ü
å n,o,i,a=n,n,n,n;ä é e.‰ í n=≥;Ü
ä é e.quiet í o=≥;Ü
ä e.verbose è e.“ í i=≥;Ü
ä e.“ í a=≥;Ü
≥=i;å t,f,c={},{},{};â Module(e)ä t[e]í
i("Ignoring duplicate module definition for "..e);ë â()Ü
Ü
å n=#t+1;t[n]={ò=e,url=___fetch_url};t[e]=t[n];ë â(e)t[n].±=e;Ü
Ü
â Resource(n,l)å e=#c+1;c[e]={ò=n,±=l è n};ë â(n)c[e].±=n;Ü
Ü
â AutoFetchURL(e)___fetch_url=e;Ü
â Main(e)Ê.insert(f,e);Ü
â Output(n)ä e.output==ç í
õ=n;Ü
Ü
â Option(n)n=n:ß("%-","_");ä e[n]==ç í
e[n]=ì;ë â(l)e[n]=l;Ü
Ñ
ë â()Ü;Ü
Ü
â GetOption(n)ë e[n:ß('%-','_')];Ü
â Message(n)ä é e.quiet í
o(n);Ü
Ü
â Error(l)ä é e.‰ í
n(l);Ü
Ü
â Exit()¯.»(1);Ü
ù=(ù è˛):ß("/$",∆).."/"squishy_file=ù.."squishy";õ=e.output;å l,r=pcall(dofile,squishy_file);ä é l í
n("Couldn't read squishy file: "..r);¯.»(1);Ü
ä é õ í
n("No output file specified by user or squishy file");¯.»(1);Ö#f==0 Å#t==0 Å#c==0 í
n("No files, modules or resources. Not going to generate an empty file.");¯.»(1);Ü
å r={};â r.filesystem(e)å e,n=Í.≠(e);ä é e í ë á,n;Ü
å n=e:À(—);e:§();ë n;Ü
ä e.use_http í
â r.http(e)å n=ú"socket.http";å n,e=n.request(e);ä e==200 í
ë n;Ü
ë á,"HTTP status code: "..ô(e);Ü
Ñ
â r.http(e)ë á,"Module not found. Re-squish with --use-http option to fetch it from "..e;Ü
Ü
o("Writing "..õ..”);å l,d=Í.≠(õ,"w+");ä é l í
n("Couldn't open output file: "..ô(d));¯.»(1);Ü
ä e.‹ í
ä e.‹==ì í
l:ó("#!/usr/bin/env lua\n");Ñ
l:ó(e.‹,∏);Ü
Ü
i("Resolving modules...");É
å e=™.config:¿(1,1);å i=™.config:¿(5,5);å o=™.±:ß("[^;]+",â(n)ä é n:©("^%"..e)í
ë ù..n;Ü
Ü):ß("/%./","/");å l=™.cpath:ß("[^;]+",â(n)ä é n:©("^%"..e)í
ë ù..n;Ü
Ü):ß("/%./","/");â Ù(n,l)n=n:ß("%.",e);à e ã l:Ì("[^;]+")É
e=e:ß("%"..i,n);a("Looking for "..e)å n=Í.≠(e);ä n í
a("Found!");n:§();ë e;Ü
Ü
ë ç;Ü
à l,e ã •(t)É
ä é e.± í
e.±=Ù(e.ò,o);ä é e.± í
n("Couldn't resolve module: "..e.ò);Ñ
e.±=e.±:ß("^"..ù:ß("%p","%%%1"),∆);Ü
Ü
Ü
Ü
i("Packing modules...");à o,t ã •(t)É
å i,d=t.ò,t.±;ä t.±:¿(1,1)~="/"í
d=ù..t.±;Ü
a("Packing "..i.." ("..d..")...");å o,c=r.filesystem(d);ä(é o)Å t.url í
å e=t.url:ß("%?",t.±);a("Fetching: "..e)ä e:©("^https?://")í
o,c=r.http(e);Ö e:©("^file://")è e:©("^[/%.]")í
å e,n=Í.≠((e:ß("^file://",∆)));ä e í
o,c=e:À(—);e:§();Ñ
o,c=ç,n;Ü
Ü
Ü
ä o í
ä é e.debug í
l:ó(È,i,"'] = (function (...)\n");l:ó(o);l:ó(" end)\n");Ñ
l:ó(È,i,"'] = assert(loadstring(\n");l:ó(("%q\n"):¶(o));l:ó(", ",("%q"):¶("@"..d),"))\n");Ü
Ñ
n("Couldn't pack module '"..i.."': "..(c è"unknown error... path to module file correct?"));¯.»(1);Ü
Ü
ä#c>0 í
i("Packing resources...")l:ó("do local resources = {};\n");à o,e ã •(c)É
å o,e=e.ò,e.±;å e,t=Í.≠(ù..e,"rb");ä é e í
n("Couldn't load resource: "..ô(t));¯.»(1);Ü
å n=e:À(—);å e=0;n:ß("(=+)",â(n)e=math.max(e,#n);Ü);l:ó(("resources[%q] = %q"):¶(o,n));Ü
ä e.virtual_io í
å e=ª("vio");ä é e í
n("Virtual IO requested but is not enabled in this build of squish");Ñ
l:ó(e,∏)l:ó[[local io_open, io_lines = io.open, io.lines; function io.open(fn, mode)
					if not resources[fn] then
						return io_open(fn, mode);
					else
						return vio.open(resources[fn]);
				end end
				function io.lines(fn)
					if not resources[fn] then
						return io_lines(fn);
					else
						return vio.open(resources[fn]):lines()
				end end
				local _dofile = dofile;
				function dofile(fn)
					if not resources[fn] then
						return _dofile(fn);
					else
						return assert(loadstring(resources[fn]))();
				end end
				local _loadfile = loadfile;
				function loadfile(fn)
					if not resources[fn] then
						return _loadfile(fn);
					else
						return loadstring(resources[fn], "@"..fn);
				end end ]]Ü
Ü
l:ó[[function require_resource(name) return resources[name] or error("resource '"..tostring(name).."' not found"); end end ]]Ü
a("Finalising...")à e,o ã pairs(f)É
å e,t=Í.≠(ù..o);ä é e í
n("Failed to open "..o..": "..t);¯.»(1);Ñ
l:ó((e:À(—):ß("^#.-\n",∆)));e:§();Ü
Ü
l:§();o(Û);å c=ú"optlex"å r=ú"optparser"å l=ú"llex"å d=ú"lparser"å t={none={};debug={∫,⁄,"entropy",¬,Ò};default={¬,∫,ÿ,Ò,⁄};basic={¬,∫,ÿ};full={¬,∫,ÿ,"eols","strings",Ò,⁄,"entropy"};}ä e.π Å é t[e.π]í
n("Unknown minify level: "..e.π);n("Available minify levels: none, basic, default, full, debug");Ü
à l,n ã •(t[e.π è"default"]è{})É
ä e["minify_"..n]==ç í
e["minify_"..n]=ì;Ü
Ü
å a={["opt-locals"]=e.minify_locals;[…]=e.minify_comments;["opt-entropy"]=e.minify_entropy;[ı]=e.minify_whitespace;[˜]=e.minify_emptylines;["opt-eols"]=e.minify_eols;["opt-strings"]=e.minify_strings;["opt-numbers"]=e.minify_numbers;}å â t(e)n("minify: "..e);¯.»(1);Ü
å â f(e)å n=Í.≠(e,"rb")ä é n í t(˘..e..'" for reading')Ü
å l=n:À(—)ä é l í t('cannot read from "'..e..'"')Ü
n:§()ë l
Ü
å â u(e,l)å n=Í.≠(e,"wb")ä é n í t(˘..e..'" for writing')Ü
å l=n:ó(l)ä é l í t('cannot write to "'..e..'"')Ü
n:§()Ü
â ˝(e)l.init(e)l.llex()å n,e,l=l.tok,l.›,l.tokln
ä a["opt-locals"]í
r.≥=≥
d.init(n,e,l)å o,l=d.parser()r.◊(a,n,e,o,l)Ü
c.≥=≥
n,e,l=c.◊(a,n,e,l)å e=Ê.concat(e)ä ¢.˙(e,"\r\n",1,1)è
¢.˙(e,"\n\r",1,1)í
c.warn.mixedeol=ì
Ü
ë e;Ü
â minify_file(e,n)å e=f(e);e=˝(e);u(n,e);Ü
ä e.minify~=á í
o("Minifying "..õ..”);minify_file(õ,õ);o(Û);Ü
å c=ú"llex"å t=128;å a={"and","break","do","else","elseif",„,"false","for",∂,"if","in","local","nil","not","or","repeat","return","then","true","until","while"}â uglify_file(f,o)å i,l=Í.≠(f);ä é i í
n(†..ô(l));ë;Ü
å l,r=Í.≠(o..ﬁ,"wb+");ä é l í
n(û..ô(r));ë;Ü
å n=i:À(—);i:§();å r,i=n:©(ƒ);å i=i è n;ä r í
l:ó(r)Ü
ï t+#a<=255 Å i:˙(Ÿ..¢.ﬂ(t).."-"..¢.ﬂ(t+#a-1)..)É
t=t+1;Ü
ä t+#a>255 í
l:ó(i);l:§();¯.Î(o..ﬁ,o);ë;Ü
å d={}à n,e ã •(a)É
d[e]=¢.ﬂ(t+n);Ü
å r=0;n:ß("(=+)",â(e)r=math.max(r,#e);Ü);c.init(i,"@"..f);c.llex()å i=c.›;ä e.uglify_level=="full"Å t+#a<255 í
å e={};à o,l ã •(c.tok)É
ä l==´è l==°í
å n=¢.¶("%q,%q",l,i[o]);ä é e[n]í
e[n]={¥=l,–=i[o],count=0};e[#e+1]=e[n];Ü
e[n].count=e[n].count+1;Ü
Ü
à n=1,#e É
å e=e[n];e.score=(e.count)*(#e.–-1)-#¢.¶("%q",e.–)-1;Ü
Ê.sort(e,â(n,e)ë n.score>e.score;Ü);å n=255-(t+#a);à n=n+1,#e É
e[n]=ç;Ü
å n=#a;à l,e ã •(e)É
ä e.score>0 í
Ê.insert(a,e.–);d[e.–]=¢.ﬂ(t+n+l);Ü
Ü
Ü
l:ó("local base_char,keywords=",ô(t),",{");à n,e ã •(a)É
l:ó(¢.¶("%q",e),',');Ü
l:ó[[}; function prettify(code) return code:gsub("["..string.char(base_char).."-"..string.char(base_char+#keywords).."]", 
	function (c) return keywords[c:byte()-base_char]; end) end ]]l:ó[[return assert(loadstring(prettify]]l:ó(Ÿ,¢.rep(«,r+1),Ÿ);à e,n ã •(c.tok)É
ä n==®è n==´è n==°í
å n=d[i[e]];ä n í
l:ó(n);Ñ
l:ó(i[e]);Ü
Ñ
l:ó(i[e]);Ü
Ü
l:ó(,¢.rep(«,r+1),);l:ó(", '@",o,"'))()");l:§();¯.Î(o..ﬁ,o);Ü
ä e.uglify í
o("Uglifying "..õ..”);uglify_file(õ,õ);o(Û);Ü
å l=ú"minichunkspy"â ˆ(n,o)å n=¢.dump(loadstring(n,o));ä((é e.debug)è e.compile_strip)Å e.compile_strip~=á í
å n=l.disassemble(n);å â o(e)e.source_lines,e.locals,e.upvalues={},{},{};à n,e ã •(e.prototypes)É
o(e);Ü
Ü
i("Stripping debug info...");o(n.body);ë l.assemble(n);Ü
ë n;Ü
â compile_file(l,e)å o,l=Í.≠(l);ä é o í
n(†..ô(l));ë;Ü
å l,t=Í.≠(e..".compiled","w+");ä é l í
n(û..ô(t));ë;Ü
å n=o:À(—);o:§();å o,t=n:©(ƒ);å n=t è n;ä o í
l:ó(o)Ü
l:ó(ˆ(n,e));¯.Î(e..".compiled",e);Ü
ä e.compile í
o("Compiling "..õ..”);compile_file(õ,õ);o(Û);Ü
â gzip_file(e,l)å o,e=Í.≠(e);ä é o í
n(†..ô(e));ë;Ü
å e,t=Í.≠(l..".gzipped","wb+");ä é e í
n(û..ô(t));ë;Ü
å a=o:À(—);o:§();å t,o=a:©(ƒ);å o=o è a;ä t í
e:ó(t)Ü
å t,a=Í.≠(l..".pregzip","wb+");ä é t í
n("Can't open temp file for writing: "..ô(a));ë;Ü
t:ó(o);t:§();å n=Í.popen("gzip -c '"..l..".pregzip'");o=n:À(—);n:§();¯.remove(l..".pregzip");å n=0;o:ß("(=+)",â(e)n=math.max(n,#e);Ü);e:ó("local ungz = (function ()",ª"gunzip.lua"," end)()\n");e:ó[[return assert(loadstring((function (i)local o={} ungz{input=i,output=function(b)table.insert(o,string.char(b))end}return table.concat(o)end) ]];e:ó((¢.¶("%q",o):ß("\26","\\026")));e:ó(", '@",l,"'))()");e:§();¯.Î(l..".gzipped",l);Ü
ä e.gzip í
o("Gzipping "..õ..”);gzip_file(õ,õ);o(Û);Ü
]===], '@s'))()