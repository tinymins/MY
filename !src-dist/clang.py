# -*- coding: utf-8 -*-
# pip install pyinstaller
# pyinstaller --onefile convert-lang.py

'''
    File name: convert-lang.py
    Author: Emil Zhai
    Python Version: 3.7
'''

import codecs
import json
import os
import re
import sys
import time
import plib.utils as utils
import plib.environment as env
from plib.environment import get_current_packet_id
from plib.language.converter import Converter

FILE_MAPPING = {
    'zhcn.lang': {'out': 'zhtw.lang', 'type': 'lang'},
    'zhcn.jx3dat': {'out': 'zhtw.jx3dat', 'type': 'lang'},
    'info.ini': {'out': 'info.ini.zh_TW', 'type': 'info'},
    'package.ini': {'out': 'package.ini.zh_TW', 'type': 'package'},
}
FILE_MAPPING_RE = [
    {'pattern': r'(.*)\.zhcn\.jx3dat', 'out': r'\1.zhtw.jx3dat', 'type': 'lang'},
]
FOLDER_MAPPING = {
    # 'zhcn': { 'out': 'zhtw', 'type': 'lang' },
}
IGNORE_FOLDER = ['.git', '@DATA']


def __load_crc_cache(root_path):
    crcs = {}
    crc_file = os.path.join(root_path, '__pycache__' + os.path.sep + 'file.crc.json')
    if os.path.isfile(crc_file):
        with open(crc_file, 'r') as f:
            print('Crc cache loaded: ' + crc_file)
            crcs = json.load(f)
    return crcs


def __save_crc_cache(root_path, crcs):
    if not os.path.exists(os.path.join(root_path, '__pycache__')):
        os.mkdir(os.path.join(root_path, '__pycache__'))
    crc_file = os.path.join(root_path, '__pycache__' + os.path.sep + 'file.crc.json')
    with open(crc_file, 'w') as file:
        print('--------------------------------')
        file.write(json.dumps(crcs))
        print('Crc cache saved: ' + crc_file)


def __is_path_include(pkg_name, cwd, d):
    if env.is_interface_path(cwd) and os.path.isfile(os.path.join(cwd, d)):
        return False
    if d in IGNORE_FOLDER:
        return False
    if not env.is_interface_path(cwd) and env.is_interface_path(os.path.dirname(cwd)) and pkg_name != '':
        if os.path.basename(cwd) == pkg_name:
            return True
        elif os.path.exists(os.path.join(cwd, 'package.ini')):
            return 'dependence=' + pkg_name in open(os.path.join(cwd, 'package.ini'), encoding='GBK').read()
        elif os.path.exists(os.path.join(cwd, 'info.ini')):
            return 'dependence=' + pkg_name in open(os.path.join(cwd, 'info.ini'), encoding='GBK').read()
        return False
    return True


def convert_progress(argv):
    params = {}
    cwd = os.getcwd()
    start_time = time.time() * 1000
    converter = Converter('zh-TW')
    packet = get_current_packet_id()

    param_accept_arg = {
        "--path": True,
    }

    for idx, param in enumerate(argv):
        if (param in param_accept_arg) and idx < len(argv):
            params[param] = argv[idx + 1]
        else:
            params[param] = ""

    if '--path' not in params:
        params['--path'] = os.path.abspath(os.getcwd())

    # get interface root path
    pkg_name = ''
    root_path = params['--path']
    if (not env.is_interface_path(root_path)) and env.is_interface_path(os.path.dirname(root_path)):
        pkg_name = os.path.basename(root_path)
        root_path = os.path.dirname(root_path)

    print('--------------------------------')
    print('Working DIR: ' + root_path)
    print('Working PKG: ' + (pkg_name or 'ALL'))
    crcs = __load_crc_cache(root_path) if '--no-cache' not in params else {}

    cpkg = ''
    cpkg_path = '?'
    header = 'local X = %s' % packet

    for cwd, dirs, files in os.walk(root_path):
        dirs[:] = [d for d in dirs if __is_path_include(pkg_name, cwd, d)]
        files[:] = [d for d in files if __is_path_include(pkg_name, cwd, d)]

        # for dirname in dirs:
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

            if extname == '.lua' and basename != 'Base' and basename != 'LuaWatcher' \
                and relpath.find(os.path.sep + '!src-dist' + os.path.sep) == -1 \
                and relpath.find(os.path.sep + 'dist' + os.path.sep) == -1 \
                    and not (filename.startswith('src.') and filename.endswith('.lua')):  # src.xxxxxxx.lua
                print('--------------------------------')
                print('Update header: ' + filepath)
                crc_text = utils.get_file_crc(filepath)
                if not crc_changed:
                    crc_changed = crc_text != crcs.get(relpath)
                if crc_changed:
                    original_text = ''
                    finalize_text = ''
                    has_header = False
                    for count, line in enumerate(codecs.open(filepath, 'r', encoding='gbk')):
                        if line.startswith('local X = '):
                            has_header = True
                            finalize_text += 'local X = %s\n' % packet
                        elif line.strip() == header:
                            has_header = True
                        original_text += line
                    if not has_header:
                        finalize_text = header + '\n' + original_text
                    else:
                        finalize_text = original_text

                    if original_text != finalize_text:
                        print('File saving...')
                        with codecs.open(filepath, 'w', encoding='gbk') as f:
                            f.write(finalize_text)
                            print('File saved...')
                        crc_text = utils.get_file_crc(filepath)
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
                fileOut = converter.convert(filename)
            elif filename in FILE_MAPPING:
                info = FILE_MAPPING[filename]
                fileType = info['type']
                folderOut = cwd
                fileOut = info['out']
            else:
                for p in FILE_MAPPING_RE:
                    out = re.sub(p['pattern'], p['out'], filename)
                    if out != filename:
                        info = p
                        fileType = info['type']
                        folderOut = cwd
                        fileOut = out
            if fileType and folderOut and fileOut:
                print('--------------------------------')
                print('Convert language: ' + filepath)
                crc_text = utils.get_file_crc(filepath)
                if not crc_changed:
                    crc_changed = crc_text != crcs.get(relpath)
                if fileType == 'package':
                    cpkg = cwd[cwd.rfind('\\') + 1:]
                    cpkg_path = cwd
                if crc_changed:
                    try:
                        original_text = ""
                        for count, line in enumerate(codecs.open(filepath, 'r', encoding='gbk')):
                            if fileType == 'lang' and count == 0 and line.find('-- language data') == 0:
                                original_text = line.replace('zhcn', 'zhtw')
                            else:
                                original_text = original_text + line
                        print('File converting...')

                        # fill missing package
                        if fileType == 'info' and cwd.find(cpkg_path) == 0 and original_text.find('package=') == -1:
                            original_text = original_text.rstrip() + '\npackage=' + cpkg + '\n'
                            with codecs.open(filepath, 'w', encoding='gbk') as f:
                                f.write(original_text)
                                print('File saved: ' + filepath)
                            crc_text = utils.get_file_crc(filepath)

                        # all_the_text = all_the_text.decode('gbk')
                        original_text = converter.convert(original_text)

                        print('File saving...')
                        if not os.path.exists(folderOut):
                            os.mkdir(folderOut)
                        with codecs.open(os.path.join(folderOut, fileOut), 'w', encoding='utf8') as f:
                            f.write(original_text)
                            print('File saved: ' + fileOut)
                        crcs[relpath] = crc_text
                    except Exception as e:
                        crcs[relpath] = str(e)
                else:
                    print('Already up to date.')

    if '--no-cache' not in params:
        __save_crc_cache(root_path, crcs)

    print('--------------------------------')
    print('Process finished in %dms...' % (time.time() * 1000 - start_time))
    print('--------------------------------')

    if '--no-pause' not in params:
        time.sleep(10)


if __name__ == "__main__":
    env.set_packet_as_cwd()
    try:
        argv
    except NameError:
        argv = sys.argv[1:]
    else:
        pass
    convert_progress(argv)
