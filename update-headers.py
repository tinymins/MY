# -*- coding: utf-8 -*-

'''
    File name: update-headers.py
    Author: Emil Zhai
    Python Version: 3.7
'''

import sys, os, codecs, re, time, json, zlib

root = os.path.dirname(os.path.abspath(__file__))
header_file = os.path.join(root, 'header.tpl.lua')

exclude_folders = ['.git', '@DATA']
include_exts = ['.lua']
exclude_files = ['MY.lua', 'Compatible.lua', 'header.tpl.lua']

header = ''
for _, line in enumerate(codecs.open(header_file,'r',encoding='gbk')):
    header = header + line
print('header loaded: ' + header_file)

for cwd, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in exclude_folders]

    #for dirname in  dirs:
    #    print("cwd is:" + cwd)
    #    print("dirname is" + dirname)

    for filename in files:
        basename, extname = os.path.splitext(filename)
        if extname in include_exts and not filename in exclude_files:
            filepath = os.path.join(cwd, filename)
            print('file loading: ' + filepath)
            all_the_text = ''
            for count, line in enumerate(codecs.open(filepath,'r',encoding='gbk')):
                all_the_text = all_the_text + line
            ret_text = re.sub(r'(?s)([-]+)\n-- these global functions are accessed all the time by the event handler\n-- so caching them is worth the effort\n\1.*?\n\1\n', header, all_the_text)

            if all_the_text != ret_text:
                print('file saving...')
                with codecs.open(filepath,'w',encoding='gbk') as f:
                    f.write(ret_text)
                    print('file saved...')

            print('-----------------------')
