# -*- coding: utf-8 -*-
# pip3 install semver

"""
新版本打包自动化脚本

此脚本用于一键自动化发布打包工作，可根据命令行参数控制打包的具体行为。
"""

import argparse

# 引入自定义的打包发布模块和环境设置模块
from plib.publish import run
import plib.environment as env


def main() -> None:
    """
    主函数：
    1. 解析命令行参数；
    2. 设置打包工作目录；
    3. 执行打包操作。
    """
    # 创建命令行参数解析器，并设置描述信息
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="一键发布打包助手"
    )
    # 添加参数 --diff，用于指定差异版本号，类型为可选字符串
    parser.add_argument("--diff", type=str, help="打包差异版本（可选）")
    # 添加参数 --no-build，指示是否跳过构建，直接进行源码打包操作；若设置则为 True
    parser.add_argument("--no-build", action="store_true", help="不构建，直接打包源码")
    # 解析命令行参数，得到命名空间对象 args
    args: argparse.Namespace = parser.parse_args()

    # 设置当前工作目录为打包目录
    env.set_packet_as_cwd()

    # 调用打包函数，传入解析到的 diff 版本号和 no_build 标识
    run("publish", args.diff, args.no_build)


if __name__ == "__main__":
    main()
