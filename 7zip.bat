@echo off
color 0A

:: ��ȡMY.lua�ļ��еĲ���汾��
set szVersion=0x0000000
for /f "tokens=2,4 delims= " %%i in (.Framework/src/MY.lua) do (
	if "%%i"=="_VERSION_" (
		set szVersion=%%j
	)
	if "%%i"=="_DEBUG_" (
		if "%%j" NEQ "4" (
			color 0C
			echo Warning: Addon is still in debug mode! Release progress abended!
			pause && exit
		)
	)
)

:: ��ȡ����ʽ����ǰʱ���ַ���
set szTime=%date:~0,10%%time:~0,8%
set szTime=%szTime:/=%
set szTime=%szTime::=%

:: ƴ���ַ�����ʼѹ���ļ�
set szFile=!src-dist\releases\MY.%szTime%v%szVersion:~5,2%.7z
echo zippping...
7z a -t7z %szFile% -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt
echo File(s) compressing acomplete!
echo Url: %szFile%
set /p _=press enter to exit...
