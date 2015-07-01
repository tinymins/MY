# -*- coding: UTF-8 -*-
from lang_mapping import map_zhcn2zhtw
import sys, os
import os.path # 遍历文件所需库
import codecs  # 保存UTF-8编码所需库
import re      # 正则匹配
import time    # 获取时间

def zhcn2zhtw(source):
	dest = ""
	pattern = re.compile(".", re.S) #u"([\u4e00-\u9fa5])"
	results =  pattern.findall(source)
	for result in results :
		if map_zhcn2zhtw.has_key(result):
			dest = dest + map_zhcn2zhtw[result]
		else:
			dest = dest + result
	return dest

rootdir = os.path.dirname(os.path.abspath(__file__))    # 指明被遍历的文件夹
for parent, dirnames, filenames in os.walk(rootdir):    # 三个参数：分别返回1.父目录 2.所有文件夹名字（不含路径） 3.所有文件名字
			#for dirname in  dirnames:                      #输出文件夹信息
			#    print "parent is:" + parent
			#    print  "dirname is" + dirname

			for filename in filenames:                      #输出文件信息
				if filename == "zhcn.jx3dat":
					#print "parent is:" + parent
					#print "filename is:" + filename
					#print "the full name of the file is:" + os.path.join(parent,filename) #输出文件路径信息
					print 'file loading: ' + os.path.join(parent,filename)
					# all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
					all_the_text = ""
					for count, line in enumerate(codecs.open(os.path.join(parent,filename),'r',encoding='gbk')):
						if count == 0 and line.find('-- language data') == 0:
							all_the_text = line.replace('zhcn', 'zhtw')
							# pass
						else:
							all_the_text = all_the_text + line

					print 'file converting...'
					# all_the_text = all_the_text.decode('gbk')
					all_the_text = zhcn2zhtw(all_the_text)

					print 'file saving...'
					with codecs.open(os.path.join(parent,"zhtw.jx3dat"),'w',encoding='utf8') as f:
						f.write(all_the_text)
						print 'file saved: zhtw.jx3dat'
					print '-----------------------'
