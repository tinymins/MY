# -*- coding: utf-8 -*-

import os, re

def __split(rootpath):
	mapid=None
	file=None
	for line in open(rootpath + 'zhcn.jx3dat'):
		res = re.search(r'dwMapID=(\d+)', line)
		if res != None:
			if res.group(1) != mapid:
				if file != None:
					file.write('}')
				mapid = res.group(1)
				file = open(rootpath + mapid + '.zhcn.jx3dat', 'w')
				file.write('return {\n')
			file.write(line)
	if file != None:
		file.write('}')

if __name__ == '__main__':
	__split(os.path.abspath('!src-dist/dat/MY_Resource/data/focus/'))
	os.remove(os.path.abspath('!src-dist/dat/MY_Resource/data/focus/zhcn.jx3dat'))
