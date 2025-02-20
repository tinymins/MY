# -*- coding: utf-8 -*-

"""
本脚本提供三个用于处理 Git 状态的工具函数，并添加了类型注解以实现强类型检查。
"""

import time
import subprocess
from typing import List


def is_clean() -> bool:
    """
    判断当前 Git 工作区是否干净，即是否存在未提交的修改。

    返回:
        bool: 如果工作区干净，返回 True；否则返回 False。
    """
    try:
        # 运行 "git status" 命令获取状态信息
        result = subprocess.run(
            ["git", "status"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        # 将输出按行拆分
        status_lines: List[str] = result.stdout.strip().splitlines()
        if not status_lines:
            return False
        # 判断最后一行是否包含“nothing to commit, working tree clean”
        return status_lines[-1] == "nothing to commit, working tree clean"
    except subprocess.CalledProcessError:
        # 若执行命令失败，默认返回 False
        return False


def get_current_branch() -> str:
    """
    获取当前 Git 仓库的分支名称。

    返回:
        str: 当前分支的名称，如果找不到则返回空字符串。
    """
    try:
        # 运行 "git branch" 命令，获取分支列表
        result = subprocess.run(
            ["git", "branch"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        branch_lines: List[str] = result.stdout.strip().splitlines()
        for line in branch_lines:
            # 当前分支的行以 "*" 开头，后面跟着一个空格及分支名称
            if line.startswith("*"):
                return line[2:].strip()
        return ""
    except subprocess.CalledProcessError:
        # 若执行命令失败，则返回空字符串
        return ""


def get_head_time_tag() -> str:
    """
    获取当前 Git 提交的时间标签，该标签由提交日期和短哈希组成。

    返回:
        str: 格式为 "YYYYMMDDHHMMSS-commit_hash" 的字符串，
             如果获取失败则返回当前本地时间的字符串标签。
    """
    try:
        # 获取当前提交的短哈希
        result_hash = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        commit_hash: str = result_hash.stdout.strip()

        # 获取当前提交的日期，格式为 YYYYMMDDHHMMSS
        result_date = subprocess.run(
            ["git", "log", "-1", "--format=%cd", "--date=format:%Y%m%d%H%M%S"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        commit_date: str = result_date.stdout.strip()

        return f"{commit_date}-{commit_hash}"
    except subprocess.CalledProcessError:
        # 如果获取 Git 信息失败，则使用当前本地时间作为标签
        return time.strftime("%Y%m%d%H%M%S", time.localtime())
