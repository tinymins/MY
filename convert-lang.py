# -*- coding: GBK -*-
from lang_mapping import map_zhcn2zhtw
import sys, os, codecs, re, time

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

root = os.path.dirname(os.path.abspath(__file__))
excludes = [".git", "@DATA"]

for cwd, dirs, files in os.walk(root):
	dirs[:] = [d for d in dirs if d not in excludes]

	#for dirname in  dirs:
	#    print "cwd is:" + cwd
	#    print  "dirname is" + dirname

	for filename in files:
		if filename == "zhcn.jx3dat":
			print 'file loading: ' + os.path.join(cwd,filename)
			# all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
			all_the_text = ""
			for count, line in enumerate(codecs.open(os.path.join(cwd,filename),'r',encoding='gbk')):
				if count == 0 and line.find('-- language data') == 0:
					all_the_text = line.replace('zhcn', 'zhtw')
				else:
					all_the_text = all_the_text + line

			print 'file converting...'
			# all_the_text = all_the_text.decode('gbk')
			all_the_text = zhcn2zhtw(all_the_text)

			print 'file saving...'
			with codecs.open(os.path.join(cwd,"zhtw.jx3dat"),'w',encoding='utf8') as f:
				f.write(all_the_text)
				print 'file saved: zhtw.jx3dat'
			print '-----------------------'
