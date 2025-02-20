# -*- coding: utf-8 -*-

"""
本脚本提供一个强类型的辅助函数 `require`，用于导入指定模块，
如果模块未安装则退出程序并提示用户通过 pip 安装。
"""

import sys
import importlib
from types import ModuleType
from typing import Optional


def require(name: str, installer: Optional[str] = None) -> ModuleType:
    """
    强类型导入模块，如果导入失败则退出程序。

    参数：
        name (str): 要导入的模块名称。
        installer (Optional[str]): 提示安装的包名称，默认为 None，此时使用 name 的值。

    返回：
        ModuleType: 导入成功的模块对象。

    示例：
        requests = require("requests")
    """
    installer = installer if installer is not None else name
    try:
        return importlib.import_module(name)
    except ImportError:
        sys.exit(
            f"导入模块 '{name}' 失败，请执行命令：python -m pip install {installer} 来安装它。"
        )
