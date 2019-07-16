# -*- coding: utf-8 -*-

import time, os, re, codecs

# get interface root path
pkg_name = ''
root_path = os.path.abspath(os.getcwd())
if os.path.basename(root_path).lower() != 'interface' and os.path.basename(os.path.dirname(root_path).lower()) == 'interface':
    pkg_name = os.path.basename(root_path)
    root_path = os.path.dirname(root_path)

def __zhcn2zhtw(sentence):
	from l_converter import Converter
	'''
	将sentence中的简体字转为繁体字
	:param sentence: 待转换的句子
	:return: 将句子中简体字转换为繁体字之后的句子
	'''
	return Converter('zh-TW').convert(sentence)

def __compress(addon):
	print('--------------------------------')
	print('Compressing: %s' % addon)
	file_count = 0
	# 分析包信息生成压缩描述
	with open('squishy', 'w') as squishy:
		squishy.write('Output "./%s/src.lua"\n' % addon)
		for line in open("%s/info.ini" % addon):
			parts = line.strip().split('=')
			if parts[0].find('lua_') == 0:
				if parts[1] == 'src.lua':
					print('Already compressed...')
					return
				file_path = os.path.join('.', addon, parts[1].replace('\\', '/'))
				file_count = file_count + 1
				squishy.write('Module "%d" "%s"\n' % (file_count, file_path))
	# 执行压缩
	os.popen('lua "./!src-dist/tools/react/squish.lua" --minify-level=full')
	# 添加加载脚本
	with open('./%s/src.lua' % addon, 'r+') as src:
		content = src.read()
		src.seek(0, 0)
		src.write('local package={preload={}}\n' + content)
	with open('./%s/src.lua' % addon, 'a') as src:
		for i in range(1, file_count + 1):
			src.write('\npackage.preload["%d"]()' % i)
	print('Compress done...')
	# 更新子插件描述文件
	info_content = ''
	for count, line in enumerate(codecs.open("%s/info.ini" % addon,'r',encoding='gbk')):
		parts = line.split('=')
		if parts[0].find('lua_') == 0:
			if parts[0] == 'lua_0':
				info_content = info_content + 'lua_0=src.lua\n'
		else:
			info_content = info_content + line
	with codecs.open("%s/info.ini" % addon,'w',encoding='gbk') as f:
		f.write(info_content)
	with codecs.open("%s/info.ini.zh_TW" % addon,'w',encoding='utf8') as f:
		f.write(__zhcn2zhtw(info_content))
	print('Update info done...')

def run(mode):
	# 读取Git分支
	name_list = os.popen('git branch').read().strip().split("\n")
	branch_name = ''
	for name in name_list:
		if name[0:1] == '*':
			branch_name = name[2:]

	# 判断是否忘记切换分支
	if branch_name != 'stable':
		print('Error: current branch(%s) is not on git stable!' % (branch_name))
		exit()

	# 判断未提交修改
	status = os.popen('git status').read().strip().split("\n")
	if (status[len(status) - 1] != 'nothing to commit, working tree clean'):
		print('Error: current branch has uncommited file change(s)!')
		exit()

	# 读取{NS}.lua文件中的插件版本号
	str_version = "0x0000000"
	for line in open("%s_!Base/src/Base.lua" % pkg_name):
		if line[6:15] == "_VERSION_":
			str_version = line[-6:-3]

	# 读取Git中最大的版本号
	version_list = os.popen('git tag').read().strip().split("\n")
	max_version, git_tag = 0, ''
	for version in version_list:
		try:
			if max_version < int(version[1:]):
				git_tag = version
				max_version = int(version[1:])
		except:
			pass

	# 判断是否忘记提升版本号
	if int(str_version) <= max_version:
		print('Error: current version(%s) is smaller than or equals with last git tagged version(%d)!' % (str_version, max_version))
		exit()

	# 优化合并源文件
	for addon in os.listdir('./'):
		if os.path.exists(os.path.join('./', addon, 'info.ini')):
			__compress(addon)

	if mode == 'diff':
		# 读取Git中最大的版本号 到最新版修改文件
		def pathToModule(path):
			return re.sub('(?:^\\!src-dist/dat/|["/].*$)', '', path)
		paths = {
			'package.ini': True,
			'package.ini.*': True,
		}
		print('File change list:')
		if git_tag != '':
			filelist = os.popen('git diff ' + git_tag + ' HEAD --name-status').read().strip().split("\n")
			for file in filelist:
				lst = file.split("\t")
				if lst[0] == "A" or lst[0] == "M" or lst[0] == "D":
					paths[pathToModule(lst[1])] = True
				elif lst[0][0] == "R":
					paths[pathToModule(lst[1])] = True
					paths[pathToModule(lst[2])] = True
				print(file)
		print('')

		# 输出修改的子目录列表
		print('Subpath change list:')
		for path in paths:
			print('/' + path)
		print('')

		# 拼接字符串开始压缩文件
		dst_file = "!src-dist/releases/%s_%s_v%s.7z" % (pkg_name, time.strftime("%Y%m%d%H%M%S", time.localtime()), str_version)
		print("zippping...")
		cmd = "7z a -t7z " + dst_file + " -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt"
		for path in paths:
			cmd = cmd + ' "' + path + '"'
		os.system(cmd)
		print("Based on git tag " + git_tag + ".")

	else:
		# 拼接字符串开始压缩文件
		dst_file = "!src-dist/releases/%s_%s_v%s.7z" % (pkg_name, time.strftime("%Y%m%d%H%M%S", time.localtime()), str_version)
		print("zippping...")
		os.system("7z a -t7z " + dst_file + " -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt")

	print("File(s) compressing acomplete!")
	print("Url: " + dst_file)

	os.popen('git reset HEAD --hard')
	time.sleep(5)
	print('Exiting...')

if __name__ == '__main__':
    run('diff')
