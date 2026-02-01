# -*- coding: utf-8 -*-
# pip3 install semver

"""
构建自动化脚本

功能:
    一键执行构建，自动切换到打包目录，并触发构建操作。
    仅构建不打压缩包，如需打包请使用 archive.py。

使用方法:
    python build.py
"""

import plib.environment as env
from plib.publish import run


def main() -> None:
    """
    主入口函数，设置工作目录并执行构建任务。
    """
    # 切换当前工作目录为打包目录
    env.set_packet_as_cwd()

    # 调用构建命令，仅执行构建操作
    run("build")


if __name__ == "__main__":
    main()
