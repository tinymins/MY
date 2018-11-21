# -*- coding: utf-8 -*-

'''
    File name: convert-lang.py
    Author: Emil Zhai
    Python Version: 3.7
'''

import sys, os, codecs, re, time, json, zlib
from l_convert import zhcn2zhtw

root = os.path.dirname(os.path.abspath(__file__))
excludes = ['.git', '@DATA']
extnames = ['.jx3dat', '.lang']
crc_file = os.path.join(root, '__pycache__/lang.crc.json')

def crc(fileName):
    prev = 0
    for eachLine in open(fileName,'rb'):
        prev = zlib.crc32(eachLine, prev)
    return '%X'%(prev & 0xFFFFFFFF)

crcs = {}

if os.path.isfile(crc_file):
    with open(crc_file, 'r') as f:
        crcs = json.load(f)
        print('crc cache loaded: ' + crc_file)

for cwd, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in excludes]

    #for dirname in  dirs:
    #    print("cwd is:" + cwd)
    #    print("dirname is" + dirname)

    for filename in files:
        basename, extname = os.path.splitext(filename)
        if basename == 'zhcn' and extname in extnames:
            filepath = os.path.join(cwd, filename)
            print('file loading: ' + filepath)

            crc_text = crc(filepath)
            if crc_text == crcs.get(filepath):
                print('file not changed.')
            else:
                # all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
                all_the_text = ""
                for count, line in enumerate(codecs.open(filepath,'r',encoding='gbk')):
                    if count == 0 and line.find('-- language data') == 0:
                        all_the_text = line.replace('zhcn', 'zhtw')
                    else:
                        all_the_text = all_the_text + line

                print('file converting...')
                # all_the_text = all_the_text.decode('gbk')
                all_the_text = zhcn2zhtw(all_the_text)

                print('file saving...')
                with codecs.open(os.path.join(cwd,"zhtw.jx3dat"),'w',encoding='utf8') as f:
                    f.write(all_the_text)
                    print('file saved: zhtw.jx3dat')

                crcs[filepath] = crc_text
            print('-----------------------')

with open(crc_file, 'w') as file:
    file.write(json.dumps(crcs))
    print('crc cache saved: ' + crc_file)
