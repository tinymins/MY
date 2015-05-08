@echo off && cls
if not exist ..\@data\config\MY_RECOUNT\ md ..\@data\config\MY_RECOUNT\
if not exist ..\@data\config\MY_RECOUNT\style.jx3dat copy .\data\style.jx3dat ..\@data\config\MY_RECOUNT\style.jx3dat
notepad ..\@data\config\MY_RECOUNT\style.jx3dat
