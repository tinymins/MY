# -*- coding: GBK -*-
import time, os, re

# 读取Git分支
name_list = os.popen('git branch').read().strip().split("\n")
branch_name = ''
for name in name_list:
	if name[0:1] == '*':
		branch_name = name[2:]

# 判断是否忘记切换分支
if branch_name != 'publish':
	print 'Error: current branch(%s) is not on git publish!' % (branch_name)
	exit()

# 读取MY.lua文件中的插件版本号
str_version = "0x0000000"
for line in open("MY_!Base/src/MY.lua"):
	if line[6:15] == "_VERSION_":
		str_version = line[22:25]

# 读取Git中最大的版本号
version_list = os.popen('git tag').read().strip().split("\n")
max_version, git_tag = 0, ''
for version in version_list:
	if max_version < int(version[1:]):
		git_tag = version
		max_version = int(version[1:])

# 判断是否忘记提升版本号
if int(str_version) <= max_version:
	print 'Error: current version(%s) is smaller than or equals with last git published version(%d)!' % (str_version, max_version)
	exit()

# 读取Git中最大的版本号 到最新版修改文件
paths = {}
print 'File change list:'
if git_tag != '':
	filelist = os.popen('git diff ' + git_tag + ' --name-status').read().strip().split("\n")
	for file in filelist:
		print file
		paths[re.sub('["/].*$', '', re.sub('^[^\t]\t"*', '', file))] = True
print ''

# 输出修改的子目录列表
print 'Subpath change list:'
for path in paths:
	print '/' + path
print ''

# 拼接字符串开始压缩文件
dst_file = "!src-dist/releases/MY_" + time.strftime("%Y%m%d%H%M%S", time.localtime()) + "_v" + str_version + ".7z"
print "zippping..."
cmd = "7z a -t7z " + dst_file + " -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt"
for path in paths:
	cmd = cmd + ' "' + path + '"'
os.system(cmd)
print "Based on git tag " + git_tag + "."
print "File(s) compressing acomplete!"
print "Url: " + dst_file

time.sleep(5)
print('Exiting...')
