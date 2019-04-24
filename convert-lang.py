# -*- coding: utf-8 -*-

'''
    File name: convert-lang.py
    Author: Emil Zhai
    Python Version: 3.7
'''

import sys, os, codecs, re, time, json, zlib
from l_convert import zhcn2zhtw

FILE_MAPPING = {
    'zhcn.lang': { 'out': 'zhtw.lang', 'type': 'lang' },
    'zhcn.jx3dat': { 'out': 'zhtw.jx3dat', 'type': 'lang' },
    'info.ini': { 'out': 'info.ini.zh_TW', 'type': 'info' },
    'package.ini': { 'out': 'package.ini.zh_TW', 'type': 'package' },
}
IGNORE_FOLDER = ['.git', '@DATA']

# get interface root path and crc file path
pkg_name = ''
root_path = os.path.dirname(os.path.abspath(__file__))
if os.path.basename(root_path).lower() != 'interface' and os.path.basename(os.path.dirname(root_path)) == 'interface':
    pkg_name = os.path.basename(root_path)
    root_path = os.path.dirname(root_path)
crc_file = os.path.join(root_path, '__pycache__' + os.path.sep + 'file.crc.json')

def crc(fileName):
    prev = 0
    for eachLine in open(fileName,'rb'):
        prev = zlib.crc32(eachLine, prev)
    return '%X'%(prev & 0xFFFFFFFF)

def is_path_include(cwd, d):
    if os.path.basename(cwd).lower() == 'interface' and os.path.isfile(os.path.join(cwd, d)):
        return False
    if d in IGNORE_FOLDER:
        return False
    if os.path.basename(os.path.dirname(cwd)).lower() == 'interface' and pkg_name != '':
        if os.path.basename(cwd) == pkg_name:
            return True
        elif os.path.exists(os.path.join(cwd, 'package.ini')):
            return 'dependence=' + pkg_name in open(os.path.join(cwd, 'package.ini')).read()
        elif os.path.exists(os.path.join(cwd, 'info.ini')):
            return 'dependence=' + pkg_name in open(os.path.join(cwd, 'info.ini')).read()
        return False
    return True

crcs = {}

if os.path.isfile(crc_file):
    with open(crc_file, 'r') as f:
        crcs = json.load(f)
        print('crc cache loaded: ' + crc_file)

cpkg = ''
cpkg_path = '?'

for cwd, dirs, files in os.walk(root_path):
    dirs[:] = [d for d in dirs if is_path_include(cwd, d)]
    files[:] = [d for d in files if is_path_include(cwd, d)]

    #for dirname in dirs:
    #    print("cwd is:" + cwd)
    #    print("dirname is" + dirname)

    # for filename in files:
    #     print(cwd, filename)

    for filename in files:
        basename, extname = os.path.splitext(filename)
        is_info_file = filename in ['info.ini', 'package.ini']
        if filename in FILE_MAPPING:
            info = FILE_MAPPING[filename]
            filepath = os.path.join(cwd, filename)
            relpath = filepath.replace(root_path, '')

            if filename == 'package.ini':
                cpkg = cwd[cwd.rfind('\\') + 1:]
                cpkg_path = cwd
            print('-----------------------')
            print('file loading: ' + filepath)

            crc_text = crc(filepath)
            if crc_text == crcs.get(relpath):
                print('file not changed.')
            else:
                try:
                    # all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
                    all_the_text = ""
                    for count, line in enumerate(codecs.open(filepath,'r',encoding='gbk')):
                        if info['type'] == 'lang' and count == 0 and line.find('-- language data') == 0:
                            all_the_text = line.replace('zhcn', 'zhtw')
                        else:
                            all_the_text = all_the_text + line
                    print('file converting...')

                    # fill missing package
                    if filename == 'info.ini' and cwd.find(cpkg_path) == 0 and all_the_text.find('package=') == -1:
                        all_the_text = all_the_text.rstrip() + '\npackage=' + cpkg + '\n'
                        with codecs.open(filepath,'w',encoding='gbk') as f:
                            f.write(all_the_text)
                            print('file saved: ' + filepath)
                        crc_text = crc(filepath)

                    # all_the_text = all_the_text.decode('gbk')
                    all_the_text = zhcn2zhtw(all_the_text)

                    print('file saving...')
                    destfile = info['out']
                    with codecs.open(os.path.join(cwd, destfile),'w',encoding='utf8') as f:
                        f.write(all_the_text)
                        print('file saved: ' + destfile)
                except:
                    pass
                crcs[relpath] = crc_text

with open(crc_file, 'w') as file:
    print('-----------------------')
    file.write(json.dumps(crcs))
    print('crc cache saved: ' + crc_file)

print('-----------------------')
