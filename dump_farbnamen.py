#!/usr/bin/python
# coding=utf-8
import os
import sys
import sqlite3
#import logging

SELF_PATH = os.path.dirname(os.path.abspath(__file__))

def insert_cache_db1(info_game2,info_game1s):

    allcnt = 0
    d = {}
    for info_game1 in info_game1s:
        d[info_game1] = os.path.getmtime(info_game1)
    #for k, v in sorted(d.items(), key=lambda x: x[1], reverse=True):
    #    print k
    for k in sorted(d, key=lambda x: d[x], reverse=True):
        info_game1 = k
        exists_tong = {}
        exists_info = {}

        con = sqlite3.connect(info_game2.decode('gbk'))
        con.text_factory=str
        cur = con.cursor()
        cur.execute("select * from TongCache;")
        for id,name in cur.fetchall():
            exists_tong[id] = name
        #logging.info("tong exists %d"%(len(exists_tong),))
        cur.close()
        cur = con.cursor()
        cur.execute("select * from InfoCache;")
        for id, name, force, role, level, title, camp, tong in cur.fetchall():
            exists_info[id] = name
        #logging.info("info exists %d"%(len(exists_info),))
        cur.close()

        cur = con.cursor()
        tst = sqlite3.connect(info_game1.decode('gbk'))
        tst.text_factory=str
        ttt = tst.cursor()
        ttt.execute("select * from TongCache;")
        #local DBI_W  = DB:Prepare("REPLACE INTO InfoCache (id, name, force, role, level, title, camp, tong) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
        #local DBT_W  = DB:Prepare("REPLACE INTO TongCache (id, name) VALUES (?, ?)")
        cnt = 0
        for id,name in ttt.fetchall():
            if exists_tong.has_key(id):
                pass
            else:
                cur.execute("insert INTO TongCache (id, name) VALUES (?, ?)",(id,name))
                cnt += cur.rowcount
        #logging.info("tong add %d" % (cnt,))
        ttt.close()
        ttt = tst.cursor()
        ttt.execute("select * from InfoCache;")
        cnt = 0
        for id, name, force, role, level, title, camp, tong in ttt.fetchall():
            if exists_info.has_key(id):
                pass
            else:
                cur.execute("insert INTO InfoCache (id, name, force, role, level, title, camp, tong) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",(id, name, force, role, level, title, camp, tong))
                cnt += cur.rowcount
        #logging.info("info add %d" % (cnt,))
        ttt.close()
        tst.close()

        cur.close()
        con.commit()
        con.close()
        allcnt += cnt
    return allcnt

def generate_db0(info_game0s):
        datakey = ['i', 'n', 'f', 'r', 'l', 't', 'c', 'g']
        # sql id, name, force, role, level, title, camp, tong
        #                   id    名字  门派 体型 等级 称号 阵营 帮会
        dataval = {}
        tongval = {}
        n2idval = {}
        datadup = 0
        tongdup = 0
        n2iddup = 0
        for srvdir in info_game0s:
            tongdir = os.path.join(srvdir, 'TONG')
            if os.path.exists(tongdir):
                for one in os.listdir(tongdir):
                    tongfile = os.path.join(tongdir, one)
                    filetime = os.path.getmtime(tongfile)
                    tong = eval(open(tongfile, "rb").read().replace("[", "").replace("]", "").replace("=", ":")[5:].decode("gbk").encode("utf8"))
                    for k, v in tong.items():
                        if not tongval.has_key(k):
                            tongval[k] = (filetime, v)
                        else:
                            _filetime, _v = tongval[k]
                            if _v != v:
                                tongdup += 1
                                if _filetime < filetime:
                                    tongval[k] = (filetime, v)
        for k, v in tongval.copy().items():
            tongval[k] = v[1]
        for srvdir in info_game0s:
            datadir = os.path.join(srvdir, 'DATA')
            if os.path.exists(datadir):
                for one in os.listdir(datadir):
                    datafile = os.path.join(datadir, one)
                    filetime = os.path.getmtime(datafile)
                    data = eval(open(datafile, "rb").read().replace("[", "").replace("]", "").replace("=", ":")[5:].decode("gbk").encode("utf8"))
                    # data1 = json.loads(open(os.path.join(datadir,one),"rb").read().replace("[","").replace("]","").replace("=",":")[5:].decode("gbk").encode("utf8"))
                    # .replace("{","[").replace("}","]")
                    for _, xv in data.items():
                        # u.update(xv.keys())
                        v = []
                        srv = ""
                        ver = ""
                        v.append(srv.decode("gbk").encode("utf8"))
                        v.append(ver)
                        v.append(str(xv.get("_")))
                        for xk in datakey:
                            x = xv.get(xk, None)
                            if xk == "g":
                                if type(x) is int:
                                    v.append(str(x))
                                    if x == 0:
                                        v.append(str(""))
                                    else:
                                        y = tongval.get(x, None)
                                        v.append(str(y))
                                else:
                                    v.append(str(-1))
                                    v.append(str(x))
                                continue
                            v.append(str(x))
                        # print "\t".join([(x if str(x).isdigit() else (x + ("  " *  (10 - len(x))))) for x in v])
                        # print "\t".join([(x if str(x).isdigit() else (x + ("  " *  (10 - len(x))))) for x in v])
                        # print k, xv.get("i")
                        k = xv.get("i")
                        if not dataval.has_key(k):
                            dataval[k] = (filetime, v)
                        else:
                            _filetime, _v = dataval[k]
                            if str(_v[3:]) != str(v[3:]):
                                if _v[7] != v[7]:
                                    pass
                                elif _v[10] != v[10] and (_v[10] == "-1" or v[10] == "-1"):
                                    pass
                                else:
                                    datadup += 1
                                    # print srv.decode("gbk").encode("utf8"),(_filetime - filetime)/86400,int(_v[2]) - int(v[2])
                                    # print _filetime, "\t".join(_v[2:])
                                    # print filetime, "\t".join(v[2:])
                                if _filetime < filetime:
                                    dataval[k] = (filetime, v)
                                elif int(_v[2]) < int(v[2]):
                                    dataval[k] = (filetime, v)
        for srvdir in info_game0s:
            dat2dir = os.path.join(srvdir, 'DAT2')
            if os.path.exists(dat2dir):
                for one in os.listdir(dat2dir):
                    dat2file = os.path.join(dat2dir, one)
                    filetime = os.path.getmtime(dat2file)
                    dat2 = eval("{" + open(dat2file, "rb").read().replace("[", "").replace("]", "").replace("{","[").replace("}", "]").replace("=", ":")[6:-1].decode("gbk").encode("utf8") + "}")
                    # print dat2
                    for _, xv in dat2.items():
                        v = []
                        srv = ""
                        ver = ""
                        v.append(srv.decode("gbk").encode("utf8"))
                        v.append(ver)
                        v.append(str(int(filetime)))
                        for oneone in xv:
                            v.append(str(oneone))
                        v.append(str(tongval.get(xv[7], None)))
                        # print "\t".join([(x if str(x).isdigit() else (x + ("  " *  (10 - len(x))))) for x in v])
                        # print "\t".join([(x if str(x).isdigit() else (x + ("  " *  (10 - len(x))))) for x in v])
                        # print k, xv.get("i")
                        k = xv[0]
                        if not dataval.has_key(k):
                            dataval[k] = (filetime, v)
                        else:
                            _filetime, _v = dataval[k]
                            if str(_v[3:]) != str(v[3:]):
                                if _v[7] != v[7]:
                                    pass
                                elif _v[10] != v[10] and (_v[10] == "-1" or v[10] == "-1"):
                                    pass
                                else:
                                    datadup += 1
                                    # print v[7] , v[10]
                                    # print _v[7] , _v[10]
                                    # print srv.decode("gbk").encode("utf8"), (_filetime - filetime) / 86400, int(_v[2]) - int(v[2])
                                    # print _filetime, "\t".join(_v[2:])
                                    # print filetime, "\t".join(v[2:])
                                if _filetime < filetime:
                                    dataval[k] = (filetime, v)
                                elif int(_v[2]) < int(v[2]):
                                    dataval[k] = (filetime, v)
        for k, v in dataval.copy().items():
            dataval[k] = v[1]
        for srvdir in info_game0s:
            n2iddir = os.path.join(srvdir, 'N2ID')
            if os.path.exists(n2iddir):
                for one in os.listdir(n2iddir):
                    n2idfile = os.path.join(n2iddir, one)
                    filetime = os.path.getmtime(n2idfile)
                    n2id = {}
                    with open(n2idfile, "rb") as f:
                        s = f.read()
                        if s and s.startswith("DATA"):
                            n2id = eval(s.replace("[", "").replace("]", "").replace("=", ":")[5:].decode("gbk").encode("utf8"))
                    # print dat2
                    for v, k in n2id.items():
                        if dataval.has_key(k):
                            if dataval[k][4] == v:
                                pass
                            else:
                                n2iddup += 1
                                # print dataval[k][4] , v
                        else:
                            # print k,v
                            if not n2idval.has_key(k):
                                n2idval[k] = (filetime, v)
                            else:
                                _filetime, _v = n2idval[k]
                                if _v != v:
                                    srv = ""
                                    print srv.decode("gbk").encode("utf8"), (_filetime - filetime) / 86400, v, _v
                                    if _filetime < filetime:
                                        n2idval[k] = (filetime, v)

        #logging.info("%d,%d\t\t\t\t\t%d,%d,%d,%d"%( len(tongval), len(dataval), tongdup, datadup, n2iddup, len(n2idval),))
        return tongval,dataval

def insert_cache_file_tong(info_game2, xtong):

    exists_tong = {}
    
    con = sqlite3.connect(info_game2.decode('gbk'))
    con.text_factory=str
    cur = con.cursor()
    cur.execute("select * from TongCache;")
    for id,name in cur.fetchall():
        exists_tong[id] = name
    #logging.info("tong exists %d"%(len(exists_tong),))
    cur.close()
    cur = con.cursor()
    
    cnt = 0
    for id,_name in xtong.items():
        if exists_tong.has_key(id):
            pass
        else:
            name = _name.decode("utf8").encode("gbk")
            cur.execute("insert INTO TongCache (id, name) VALUES (?, ?)",(id,name))
            cnt += cur.rowcount
    #logging.info("tong add %d" % (cnt,))
    cur.close()
    con.commit()
    con.close()
    return cnt
    
def insert_cache_file_info(info_game2, xdata):

    exists_info = {}
    rev_tong = {}
    
    con = sqlite3.connect(info_game2.decode('gbk'))
    con.text_factory=str
    cur = con.cursor()
    cur.execute("select * from TongCache;")
    for id,name in cur.fetchall():
        rev_tong[name] = id
    #print "tong rev",len(rev_tong)
    cur.close()
    cur = con.cursor()
    cur.execute("select * from InfoCache;")
    for id, name, force, role, level, title, camp, tong in cur.fetchall():
        exists_info[id] = name
    #logging.info("info exists %d"%(len(exists_info),))
    cur.close()
    cur = con.cursor()
    
    cnt = 0
    for id,values in xdata.items():
        if exists_info.has_key(id):
            pass
        else:
            _,_,_,_id, _name, _force, _role, _level, _title, _camp, _tong1, _tong2 = values
            force = int(_force)
            role = int(_role)
            level = int(_level)
            camp = int(_camp)
            tong1 = int(_tong1)
            name = _name.decode("utf8").encode("gbk")
            title = _title.decode("utf8").encode("gbk")
            tong2 = _tong2.decode("utf8").encode("gbk")
            if tong1 >= 0:
                tong = tong1
            elif tong2:
                tong = rev_tong.get(tong2,0)
                #print tong
            else:
                tong = 0
                #print tong
            cur.execute("insert INTO InfoCache (id, name, force, role, level, title, camp, tong) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",(id, name, force, role, level, title, camp, tong))
            cnt += cur.rowcount
    #logging.info("info add %d" % (cnt,))
    cur.close()
    con.commit()
    con.close()
    return cnt

def dump_table(info_game2,info_dump):
    cnt = 0
    f = open(info_dump,"wb")
    exists_tong = {}
    exists_info = {}
    
    con = sqlite3.connect(info_game2.decode('gbk'))
    con.text_factory=str
    cur = con.cursor()
    cur.execute("select * from TongCache;")
    for id,name in cur.fetchall():
        exists_tong[id] = name
        # print id,name.decode("gbk")
    #logging.info("tong exists %d"%(len(exists_tong),))
    cur.close()
    cur = con.cursor()
    cur.execute("select * from InfoCache;")
    for id, name, force, role, level, title, camp, tong in cur.fetchall():
        exists_info[id] = name
        line = [
            "%8d"%id,
            "%2d"%level,
            {
                1:"成男",
                2:"成女",
                3:"壮汉",
                4:"御姐",
                5:"正太",
                6:"萝莉",
            }.get(role,"unknown"+str(role)),
            {
                0: "中立",
                1: "浩气",
                2: "恶人",
            }.get(camp,"unknown"+str(camp)),
            {
                0: "江湖",
                1: "少林",
                2: "万花",
                3: "天策",
                4: "纯阳",
                5: "七秀",
                6: "五毒",
                7: "唐门",
                8: "藏剑",
                9: "丐帮",
                10: "明教",
                11: "苍云",
                12: "长歌",
                13: "霸刀",
                21: "苍云",
                22: "长歌",
                23: "霸刀",
            }.get(force,"unknown"+str(force)),
            (name.decode("gbk").encode("utf8")+"  "*(10-len(name.decode("gbk"))) + (" " if name.count("@") else "" )),
            (title.decode("gbk").encode("utf8")+"  "*(10-len(title.decode("gbk")))),
            "" if tong == 0 else exists_tong.get(tong,"unknown"+str(tong)).decode("gbk").encode("utf8")
            ]
        #print " ".join(line)
        f.write("\t".join([x.strip() for x in line])+"\t\r\n")
        cnt +=1
    f.close()
    #logging.info("info exists %d"%(len(exists_info),))
    cur.close()
    con.close()
    return cnt

def os_copyfile(s,d):
    if os.path.exists(s):
        with open(s, "rb") as ss:
            with open(d, "wb") as dd:
                dd.write(ss.read())

def info_union(games,mydir,others):

    db2 = {}
    dbdir = os.path.join(games,'bin','zhcn','interface','MY','@DATA')
    for dirname in os.listdir(dbdir):
        dbfile = os.path.join(dbdir,dirname,'cache','player_info.db')
        if os.path.exists(dbfile):
            server = dirname.split("@")[0].lstrip("#")
            db2[server] = dbfile
            #print server.decode('gbk'), dbfile.decode('gbk')
    db1 = {}
    db1dir = os.path.join(games,'bin','zhcn','interface','MY','@DATA','!all-users@zhcn','cache','player_info')
    for filename in os.listdir(db1dir):
        if filename.endswith(".db"):
            server = filename.split(".")[0]
            db1file = os.path.join(db1dir,filename)
            db1[server] = db1file
            #print server.decode('gbk'),db1file.decode('gbk')
    db0 = {}
    db0dir = os.path.join(games,'bin','zhcn','interface','MY','@DATA','cache','PLAYER_INFO')
    for dirname in os.listdir(db0dir):
        server = dirname
        db0file = os.path.join(db0dir,dirname)
        if os.path.isdir(db0file):
            db0files = os.listdir(db0file)
            if 'DATA' in db0files or 'DAT2' in db0files:
                #print server.decode('gbk'), db0file.decode('gbk') + '\\' + '|'.join(db0files)
                db0[server] = db0file
    dbext0 = {}
    dbext1 = {}
    for other in others:
        for a,b,c in os.walk(other):
            if 'DATA' in b or 'DAT2' in b:
                server = os.path.basename(a)
                if not dbext0.has_key(server):
                    dbext0[server] = []
                dbext0[server].append(a)
                #print server.decode('gbk'),a.decode('gbk') + '\\' + '|'.join(b)
            elif 'player_info.db' in c and os.path.basename(a) == 'cache':
                server = os.path.basename(os.path.dirname(a)).split("@")[0].lstrip("#")
                db2file = os.path.join(a, 'player_info.db')
                if not dbext1.has_key(server):
                    dbext1[server] = []
                dbext1[server].append(db2file)
                #print server.decode('gbk'), db2file.decode('gbk')
            elif 'player_info' == os.path.basename(a) and len([ x for x in c if x.endswith(".db")]) > 0:
                for filename in c:
                    if filename.endswith(".db"):
                        server = filename.split(".")[0]
                        db1file = os.path.join(a, filename)
                        if not dbext1.has_key(server):
                            dbext1[server] = []
                        dbext1[server].append(db1file)
                        #print server.decode('gbk'), db1file.decode('gbk')
            else:
                pass
    for server in sorted(set(db2.keys()+db1.keys()+db0.keys()+dbext1.keys()+dbext0.keys())):
        print "========",server.decode('gbk'),"========"
        info_game2 = os.path.join(mydir,server+".db")
        info_table = os.path.join(mydir,server+".txt")
        info_game2_orig = db2.get(server)
        if os.path.exists(info_game2):
            os.remove(info_game2)
        if info_game2_orig and os.path.exists(info_game2_orig):
            print "create",info_game2.decode('gbk'),"by",info_game2_orig.decode('gbk')
            os_copyfile(info_game2_orig, info_game2)
        else:
            print "create",info_game2.decode('gbk')
            con = sqlite3.connect(info_game2.decode('gbk'))
            cur = con.cursor()
            cur.execute('CREATE TABLE IF NOT EXISTS InfoCache (id INTEGER PRIMARY KEY, name VARCHAR(20) NOT NULL, force INTEGER, role INTEGER, level INTEGER, title VARCHAR(20), camp INTEGER, tong INTEGER)')
            cur.execute('CREATE INDEX IF NOT EXISTS info_cache_name_idx ON InfoCache(name)')
            cur.execute('CREATE TABLE IF NOT EXISTS TongCache (id INTEGER PRIMARY KEY, name VARCHAR(20))')
            cur.close()
            con.commit()
            con.close()

        info_game1 = db1.get(server)
        if info_game1 and os.path.exists(info_game1):
            print "union",info_game2.decode('gbk'),"from",info_game1.decode('gbk')
            cnt = insert_cache_db1(info_game2, [info_game1])
            print cnt

        info_game0 = db0.get(server)
        if info_game0 and os.path.exists(info_game0):
            print "union",info_game2.decode('gbk'),"from",info_game0.decode('gbk')
            xtong, xdata = generate_db0([info_game0])
            cnt1 = insert_cache_file_tong(info_game2,xtong)
            cnt2 = insert_cache_file_info(info_game2,xdata)
            print cnt2

        info_ext1 = dbext1.get(server)
        if info_ext1 and len(info_ext1):
            print "union", info_game2.decode('gbk'), "from", ",".join([x.decode('gbk') for x in info_ext1])
            cnt = insert_cache_db1(info_game2, info_ext1)
            print cnt

        info_ext0 = dbext0.get(server)
        if info_ext0 and len(info_ext0):
            print "union", info_game2.decode('gbk'), "from", ",".join([x.decode('gbk') for x in info_ext0])
            xtong, xdata = generate_db0(info_ext0)
            cnt1 = insert_cache_file_tong(info_game2, xtong)
            cnt2 = insert_cache_file_info(info_game2, xdata)
            print cnt2

        print "dump", info_table.decode('gbk')
        cnt = dump_table(info_game2, info_table)
        print cnt

if __name__ == '__main__':
    print u'聊天染色数据导出'
    if len(sys.argv) == 1:
        print u'[游戏目录] [输出目录] [从别人那里拷贝来的多个 @DATA-1 @DATA-2 ………… 随便放]'
        exit(0)
        sys.argv.append(r'C:\Users\xin\Game\JX3')
        sys.argv.append(r'C:\Users\xin\Desktop\peoples')
        sys.argv.append(r'C:\Users\xin\Desktop\test\data')
        sys.argv.append(r'C:\Users\xin\Desktop\test\data1')
        sys.argv.append(r'C:\Users\xin\Desktop\test\data2')
        sys.argv.append(r'C:\Users\xin\Desktop\test\data3')
    games = sys.argv[1]
    mydir = sys.argv[2] if len(sys.argv) >= 2 else os.path.join(SELF_PATH,"out")
    others = sys.argv[3:]
    if not os.path.exists(mydir): os.mkdir(mydir)
    info_union(games, mydir, others)
