# -*- coding: utf-8 -*-
# pip install pypiwin32

from .require import require

shell = require("win32com.shell.shell", "pywin32")


def run_as_admin(cmd):
    """
    Run command as administrator.
    """
    shell.ShellExecuteEx(lpVerb="runas", lpFile="cmd.exe", lpParameters="/c " + cmd)
