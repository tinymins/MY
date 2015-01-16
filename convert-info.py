# -*- coding: UTF-8 -*-
from lang_mapping import map_zhcn2zhtw, map_zhtw2zhcn
import os
import os.path # 遍历文件所需库
import codecs  # 保存UTF-8编码所需库
import re      # 正则匹配
import time    # 获取时间

def zhcn2zhtw(source):
    dest = ""
    pattern = re.compile(".", re.S) #u"([\u4e00-\u9fa5])"
    results = pattern.findall(source)
    for result in results :
        if map_zhcn2zhtw.has_key(result):
            dest = dest + map_zhcn2zhtw[result]
        else:
            dest = dest + result
    return dest

def zhtw2zhcn(source):
    dest = ""
    pattern = re.compile(".", re.S) #u"([\u4e00-\u9fa5])"
    results =  pattern.findall(source)
    for result in results :
        if map_zhtw2zhcn.has_key(result):
            dest = dest + map_zhtw2zhcn[result]
        else:
            dest = dest + result
    return dest

if __name__ == '__main__':
    from sys import argv
    print 'Select dest lang'
    print '----------------'
    print '1.zhcn'
    print '2.zhtw'
    print '----------------'
    if not argv[1:]:
        sel = raw_input("Select 1 or 2:")
    else:
        sel = argv[1]

    if sel == '2' or sel == 'zhtw':
        dest_cod = 'utf8'
        conv_fun = zhcn2zhtw
        print 'converting to zhtw...'
    else:
        dest_cod = 'gbk'
        conv_fun = zhtw2zhcn
        print 'converting to zhcn...'
    print '----------------'

    rootdir = os.getcwd()                                   # 指明被遍历的文件夹
    for parent, dirnames, filenames in os.walk(rootdir):    # 三个参数：分别返回1.父目录 2.所有文件夹名字（不含路径） 3.所有文件名字
        for filename in filenames:                      #输出文件信息
            if filename.lower() == "info.ini" or filename.lower() == "package.ini":
                print 'file loading: ' + os.path.join(parent,filename)
                # all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
                with codecs.open(os.path.join(parent,filename), 'r') as f:
                    all_the_text = f.read()
                print 'file converting...'
                try:
                    all_the_text = codecs.lookup('utf-8').decode(all_the_text)[0]
                except:
                    all_the_text = codecs.lookup('gbk').decode(all_the_text)[0]
                all_the_text = conv_fun(all_the_text)
                # print ''
                # print all_the_text
                # print ''
                print 'file saving...'
                with codecs.open(os.path.join(parent,filename), 'w', encoding = dest_cod) as f:
                    f.write(all_the_text)
                    print 'file saved...'
                print '-----------------------'
