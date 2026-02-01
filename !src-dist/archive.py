# -*- coding: utf-8 -*-
# pip3 install semver

"""
构建打包自动化脚本

功能:
    执行构建并生成压缩包，自动切换到打包目录，并触发构建和打包操作。

使用方法:
    python archive.py
"""

import plib.environment as env
from plib.publish import run


def main() -> None:
    """
    主入口函数，设置工作目录并执行构建打包任务。
    """
    # 切换当前工作目录为打包目录
    env.set_packet_as_cwd()

    # 调用构建命令，执行构建和打包操作
    run("archive")


if __name__ == "__main__":
    main()
