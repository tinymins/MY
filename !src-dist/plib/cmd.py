# -*- coding: utf-8 -*-
# pip install pypiwin32
"""
本模块提供以管理员身份运行命令的功能。

依赖模块：
    pywin32（安装命令：pip install pywin32）

说明：
    需要确保在管理员权限下运行此脚本才能生效。
"""

from typing import Any
from .require import require

# 加载 Windows COM Shell 模块，返回类型为 Any（类型未知）
shell: Any = require("win32com.shell.shell", "pywin32")


def run_as_admin(cmd: str) -> None:
    """
    以管理员权限运行命令提示符执行指定的命令。

    参数:
        cmd (str): 要执行的命令字符串，例如 "dir"、"echo Hello" 等。

    用法示例:
        run_as_admin("echo Hello, World!")
    """
    # 构造命令参数，使用 f-string 提高代码可读性
    cmd_parameters = f"/c {cmd}"
    shell.ShellExecuteEx(lpVerb="runas", lpFile="cmd.exe", lpParameters=cmd_parameters)
