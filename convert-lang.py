# -*- coding: utf-8 -*-
# pip install pyinstaller
# pyinstaller --onefile convert-lang.py

'''
    File name: convert-lang.py
    Author: Emil Zhai
    Python Version: 3.7
'''

import sys, os, codecs, re, time, json, zlib

FILE_MAPPING = {
    'zhcn.lang': { 'out': 'zhtw.lang', 'type': 'lang' },
    'zhcn.jx3dat': { 'out': 'zhtw.jx3dat', 'type': 'lang' },
    'info.ini': { 'out': 'info.ini.zh_TW', 'type': 'info' },
    'package.ini': { 'out': 'package.ini.zh_TW', 'type': 'package' },
}
FOLDER_MAPPING = {
    # 'zhcn': { 'out': 'zhtw', 'type': 'lang' },
}
IGNORE_FOLDER = ['.git', '@DATA']

def zhcn2zhtw(sentence):
    from l_converter import Converter
    '''
    将sentence中的简体字转为繁体字
    :param sentence: 待转换的句子
    :return: 将句子中简体字转换为繁体字之后的句子
    '''
    return Converter('zh-TW').convert(sentence)

start_time = time.time() * 1000

# get interface root path
pkg_name = ''
root_path = os.path.abspath(os.getcwd())
header_file = os.path.join(root_path, 'header.tpl.lua')
if os.path.basename(root_path).lower() != 'interface' and os.path.basename(os.path.dirname(root_path).lower()) == 'interface':
    pkg_name = os.path.basename(root_path)
    root_path = os.path.dirname(root_path)
# get crc cache file path
if not os.path.exists(os.path.join(root_path, '__pycache__')):
    os.mkdir(os.path.join(root_path, '__pycache__'))
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

print('--------------------------------')
print('Working DIR: ' + root_path)
print('Working PKG: ' + (pkg_name or 'ALL'))
crcs = {}
if os.path.isfile(crc_file):
    with open(crc_file, 'r') as f:
        crcs = json.load(f)
        print('Crc cache loaded: ' + crc_file)

header = ''
header_changed = False
if os.path.exists(header_file):
    for _, line in enumerate(codecs.open(header_file,'r',encoding='gbk')):
        header = header + line
    print('Header loaded: ' + header_file)
    crc_header = crc(header_file)
    relpath = header_file.replace(root_path, '')
    if crc_header != crcs.get(relpath):
        header_changed = True
        crcs[relpath] = crc_header

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
        foldername = os.path.basename(cwd)
        basename, extname = os.path.splitext(filename)
        filepath = os.path.join(cwd, filename)
        relpath = filepath.replace(root_path, '')
        crc_changed = False

        if extname == '.lua' and header != '' and basename != pkg_name and filename != 'Compatible.lua':
            print('--------------------------------')
            print('Update header: ' + filepath)
            crc_text = crc(filepath)
            if not crc_changed:
                crc_changed = crc_text != crcs.get(relpath)
            if header_changed or crc_changed:
                all_the_text = ''
                for count, line in enumerate(codecs.open(filepath,'r',encoding='gbk')):
                    all_the_text = all_the_text + line
                ret_text = re.sub(r'(?s)([-]+)\n-- these global functions are accessed all the time by the event handler\n-- so caching them is worth the effort\n\1.*?\n\1\n', header, all_the_text)

                if all_the_text != ret_text:
                    print('File saving...')
                    with codecs.open(filepath,'w',encoding='gbk') as f:
                        f.write(ret_text)
                        print('File saved...')
                else:
                    print('Already up to date.')
                crcs[relpath] = crc_text
            else:
                print('Already up to date.')

        fileType = None
        fileOut = None
        if foldername in FOLDER_MAPPING:
            info = FOLDER_MAPPING[foldername]
            fileType = info['type']
            folderOut = os.path.abspath(os.path.join(cwd, '..', info['out']))
            fileOut = zhcn2zhtw(filename)
        elif filename in FILE_MAPPING:
            info = FILE_MAPPING[filename]
            fileType = info['type']
            folderOut = cwd
            fileOut = info['out']
        if fileType and folderOut and fileOut:
            print('--------------------------------')
            print('Convert language: ' + filepath)
            crc_text = crc(filepath)
            if not crc_changed:
                crc_changed = crc_text != crcs.get(relpath)
            if fileType == 'package':
                cpkg = cwd[cwd.rfind('\\') + 1:]
                cpkg_path = cwd
            if crc_changed:
                try:
                    # all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
                    all_the_text = ""
                    for count, line in enumerate(codecs.open(filepath,'r',encoding='gbk')):
                        if fileType == 'lang' and count == 0 and line.find('-- language data') == 0:
                            all_the_text = line.replace('zhcn', 'zhtw')
                        else:
                            all_the_text = all_the_text + line
                    print('File converting...')

                    # fill missing package
                    if fileType == 'info' and cwd.find(cpkg_path) == 0 and all_the_text.find('package=') == -1:
                        all_the_text = all_the_text.rstrip() + '\npackage=' + cpkg + '\n'
                        with codecs.open(filepath,'w',encoding='gbk') as f:
                            f.write(all_the_text)
                            print('File saved: ' + filepath)
                        crc_text = crc(filepath)

                    # all_the_text = all_the_text.decode('gbk')
                    all_the_text = zhcn2zhtw(all_the_text)

                    print('File saving...')
                    if not os.path.exists(folderOut):
                        os.mkdir(folderOut)
                    with codecs.open(os.path.join(folderOut, fileOut),'w',encoding='utf8') as f:
                        f.write(all_the_text)
                        print('File saved: ' + fileOut)
                    crcs[relpath] = crc_text
                except Exception as e:
                    crcs[relpath] = str(e)
            else:
                print('Already up to date.')

with open(crc_file, 'w') as file:
    print('--------------------------------')
    file.write(json.dumps(crcs))
    print('Crc cache saved: ' + crc_file)

print('--------------------------------')
print('Process finished in %dms...' % (time.time() * 1000 - start_time))
print('--------------------------------')
time.sleep(10)
