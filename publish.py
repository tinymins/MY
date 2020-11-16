# -*- coding: utf-8 -*-

import codecs, importlib, os, re, time

Converter = importlib.import_module('!src-dist.plib.language.converter').Converter

def __is_interface(path):
    name = os.path.basename(path).lower()
    return name == 'interface' or name == 'interfacesource'

# Get interface root path
pkg_name = ''
root_path = os.path.abspath(os.getcwd())
if not __is_interface(root_path) and __is_interface(os.path.dirname(root_path)):
    pkg_name = os.path.basename(root_path)
    root_path = os.path.dirname(root_path)

def __compress(addon):
    '''
    Compress and concat addon source into one file.

    Args:
        addon: Addon name
    '''
    print('--------------------------------')
    print('Compressing: %s' % addon)
    file_count = 0
    converter = Converter('zh-TW')
    # Remove debug codes in source
    for line in open('%s/info.ini' % addon):
        parts = line.strip().split('=')
        if parts[0].find('lua_') == 0:
            source_file = os.path.join(addon, parts[1])
            source_code = codecs.open(source_file,'r',encoding='gbk').read()
            source_code = re.sub(r'(?is)[^\n]*--\[\[#DEBUG LINE\]\][^\n]*\n?', '', source_code)
            source_code = re.sub(r'(?is)\n?--\[\[#DEBUG BEGIN\]\].*?--\[\[#DEBUG END\]\]\n?', '', source_code)
            codecs.open(source_file,'w',encoding='gbk').write(source_code)
    # Generate squishy file and execute squish
    with open('squishy', 'w') as squishy:
        squishy.write('Output "./%s/src.lua"\n' % addon)
        for line in open('%s/info.ini' % addon):
            parts = line.strip().split('=')
            if parts[0].find('lua_') == 0:
                if parts[1] == 'src.lua':
                    print('Already compressed...')
                    return
                file_path = os.path.join('.', addon, parts[1]).replace('\\', '/')
                file_count = file_count + 1
                squishy.write('Module "%d" "%s"\n' % (file_count, file_path))
    os.popen('lua "./!src-dist/tools/react/squish" --minify-level=full').read()
    os.remove('squishy')
    # Modify dist file for loading modules
    with open('./%s/src.lua' % addon, 'r+') as src:
        content = src.read()
        src.seek(0, 0)
        src.write('local package={preload={}}\n' + content)
    with open('./%s/src.lua' % addon, 'a') as src:
        src.write('\nfor _, k in ipairs({')
        for i in range(1, file_count + 1):
            src.write('\'%d\',' % i)
        src.write('}) do package.preload[k]() end')
    print('Compress done...')
    # Modify info.ini file
    info_content = ''
    for _, line in enumerate(codecs.open('%s/info.ini' % addon,'r',encoding='gbk')):
        parts = line.split('=')
        if parts[0].find('lua_') == 0:
            if parts[0] == 'lua_0':
                info_content = info_content + 'lua_0=src.lua\n'
        else:
            info_content = info_content + line
    with codecs.open('%s/info.ini' % addon,'w',encoding='gbk') as f:
        f.write(info_content)
    with codecs.open('%s/info.ini.zh_TW' % addon,'w',encoding='utf8') as f:
        f.write(converter.convert(info_content))
    print('Update info done...')

def __is_git_clean():
    status = os.popen('git status').read().strip().split('\n')
    return status[len(status) - 1] == 'nothing to commit, working tree clean'

def __get_current_branch():
    name_list = os.popen('git branch').read().strip().split('\n')
    for name in name_list:
        if name[0:1] == '*':
            return name[2:]
    return ''

def __get_version_info():
    '''Get version information'''
    # Read version from Base.lua
    current_version = 0
    for line in open('%s_!Base/src/Base.lua' % pkg_name):
        if line[6:15] == '_VERSION_':
            current_version = int(line[-6:-3])
    # Read max and previous release commit
    commit_list = os.popen('git log --grep Release --pretty=format:"%s|%p"').read().split('\n')
    max_version, prev_version, prev_version_message, prev_version_hash = 0, 0, '', ''
    for commit in commit_list:
        try:
            info = commit.split('|')
            version = int(info[0][9:])
            if version < current_version and version > prev_version:
                prev_version = version
                prev_version_message = info[0]
                prev_version_hash = info[1]
            if version > max_version:
                max_version = version
        except:
            pass
    return { 'current': current_version, 'max': max_version, 'previous': prev_version, 'previous_message': prev_version_message, 'previous_hash': prev_version_hash }

def __7zip(file_name, base_message, base_hash):
    cmd_suffix = ''
    if base_hash != '':
        # Generate file change list since previous release commit
        def pathToModule(path):
            return re.sub('(?:^\\!src-dist/data/|["/].*$)', '', path)
        paths = {
            'package.ini': True,
            'package.ini.*': True,
        }
        print('File change list:')
        filelist = os.popen('git diff ' + base_hash + ' HEAD --name-status').read().strip().split('\n')
        for file in filelist:
            lst = file.split('\t')
            if lst[0] == 'A' or lst[0] == 'M' or lst[0] == 'D':
                paths[pathToModule(lst[1])] = True
            elif lst[0][0] == 'R':
                paths[pathToModule(lst[1])] = True
                paths[pathToModule(lst[2])] = True
            print(file)
        print('')
        # Print addon change list
        print('Subpath change list:')
        for path in paths:
            print('/' + path)
            cmd_suffix = cmd_suffix + ' "' + path + '"'
        print('')

    # Prepare for 7z compressing
    print('zippping...')
    os.system('7z a -t7z ' + file_name + ' -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt' + cmd_suffix)
    print('File(s) compressing acomplished!')
    print('Url: ' + file_name)
    print('Based on git commit "%s(%s)".' % (base_message, base_hash) if base_hash != '' else 'Full package.')


def __exit(msg):
    print(msg)
    exit()

def __assert(condition, msg):
    if not condition:
        __exit(msg)

def run(mode):
    is_full = mode.find('full') >= 0
    is_release = mode.find('release') >= 0
    version_info = __get_version_info()

    if is_release:
        # Merge master into prelease
        if __get_current_branch() == 'master':
            __assert(__is_git_clean(), 'Error: master branch has uncommited file change(s)!')
            os.system('git checkout prelease || git checkout -b prelease')
            os.system('git rebase master')
            os.system('code "%s_!Base/src/Base.lua"' % pkg_name)
            os.system('code "%s_CHANGELOG.txt"' % pkg_name)
            __exit('Switched to prelease branch. Please commit release info and then run this script again!')

        # Merge prelease into stable
        if __get_current_branch() == 'prelease':
            os.system('git reset master')
            version_info = __get_version_info()
            __assert(version_info.get('current') > version_info.get('max'),
                'Error: current version(%s) must be larger than max history version(%d)!' % (version_info.get('current'), version_info.get('max')))
            os.system('git add * && git commit -m "Release V%s"' % version_info.get('current'))
            os.system('git checkout stable || git checkout -b stable')
            os.system('git reset origin/stable --hard')
            os.system('git rebase prelease')

        # Check if branch
        __assert(__is_git_clean(), 'Error: resolve conflict and remove uncommited changes first!')
        __assert(__get_current_branch() == 'stable', 'Error: current branch is not on stable!')

    # Compress and concat source file
    for addon in os.listdir('./'):
        if os.path.exists(os.path.join('./', addon, 'info.ini')):
            __compress(addon)

    # Package files
    file_name = '!src-dist/dist/%s_%s_v%s.7z' % (pkg_name, time.strftime('%Y%m%d%H%M%S', time.localtime()), version_info.get('current'))
    base_message = ''
    base_hash = ''
    if not is_full and version_info.get('current') != '' and version_info.get('previous_hash') != '':
        base_message = version_info.get('previous_message')
        base_hash = version_info.get('previous_hash')
    __7zip(file_name, base_message, base_hash)

    # Revert source code modify by compressing
    if is_release:
        os.system('git reset HEAD --hard')
        os.system('git checkout master')
    time.sleep(5)
    print('Exiting...')

if __name__ == '__main__':
    run('diff release')
