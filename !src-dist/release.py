# -*- coding: utf-8 -*-
# pip install pypiwin32
'''
版本标签创建自动化
'''

import time, os, re, codecs, win32api, datetime, argparse
import plib.utils as utils
import plib.git as git
import plib.environment as env

def __get_release_commit_list():
	commit_list = []
	for commit in os.popen('git log --grep Release --pretty=format:"%s|%h|%at"').read().split('\n'):
		try:
			info = commit.split('|')
			version = int(info[0][9:])
			timestamp = int(info[2])
			commit_list.append({ 'version': version, 'hash': info[1], 'timestamp': timestamp })
		except:
			pass
	return commit_list

def __get_release_tag_list():
	tag_list = []
	for tag in os.popen('git tag -l').read().split('\n'):
		try:
			version = int(tag[1:])
			tag_list.append({ 'version': version, 'name': tag })
		except:
			pass
	return tag_list

def __get_changelog_list():
	info = None
	changelog_list = []
	for _, line in enumerate(codecs.open('%s_CHANGELOG.txt' % env.get_current_packet_id(),'r',encoding='gbk')):
		try:
			if len(line) == 0:
				continue
			if line[0:1] != '*' and line[0:2] != ' *':
				version = int(line.split('v')[1])
				info = { 'version': version, 'message': '' }
				changelog_list.insert(0, info)
			elif info != None:
				info.update({'message': info.get('message') + line})
		except:
			pass
	return changelog_list

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Automatic release branch tags.')
	parser.add_argument('--mock-time', action='store_true', help='Tagger at commit time.')
	parser.add_argument('--overwrite', action='store_true', help='Overwrite exist tag.')
	args = parser.parse_args()

	env.set_packet_as_cwd()

	utils.assert_exit(git.is_clean(), 'Error: branch has uncommited file change(s)!')

	os.system('git checkout master')
	utils.assert_exit(git.is_clean(), 'Error: branch has uncommited file change(s)!')

	os.system('git rebase prelease')
	utils.assert_exit(git.is_clean(), 'Error: resolve conflict and remove uncommited changes first!')

	print('Reading changelog and version list...')
	changelog_list = __get_changelog_list()
	tag_list = __get_release_tag_list()
	release_list = __get_release_commit_list()

	for changlog in changelog_list:
		if not args.overwrite:
			tag = None
			for p in tag_list:
				if p.get('version') == changlog.get('version'):
					tag = p
					break
			if tag != None:
				continue

		release = None
		for p in release_list:
			if p.get('version') == changlog.get('version'):
				release = p
				break
		if release == None:
			continue

		if args.mock_time:
			t = datetime.datetime.fromtimestamp(release.get('timestamp'))
			print('Changing time to %d-%d-%d %d:%d:%d' % (t.year, t.month, t.day, t.hour, t.minute, t.second))
			tt = datetime.datetime.utcfromtimestamp(release.get('timestamp'))
			win32api.SetSystemTime(tt.year, tt.month, 0, tt.day, tt.hour, tt.minute, tt.second, 0)

		print('Creating tag V%d on %s...' % (changlog.get('version'), release.get('hash')))
		message = 'Release V%d\n%s' % (changlog.get('version'), changlog.get('message'))
		with codecs.open('commit_msg.txt','w',encoding='utf8') as f:
			f.write(message)
		os.system('git tag -a V%d %s -f -F commit_msg.txt' % (changlog.get('version'), release.get('hash')))
		os.remove('commit_msg.txt')

	print('Jobs Acomplished.')
