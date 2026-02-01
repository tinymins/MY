# -*- coding: utf-8 -*-

"""
本脚本提供 Git 相关的工具函数，包括状态检查、版本信息获取等。

注意：
    - 本模块函数在 Git 不可用时可能抛出异常或返回空值
    - 上层调用者应先通过 is_available() 检测 Git 可用性
    - 根据业务需求决定是否退出或降级处理
"""

import os
import re
import time
import subprocess
from typing import List, Dict, Optional

import plib.utils as utils
from plib.semver import Semver
from plib.environment import get_current_packet_id


def is_available() -> bool:
    """
    检测当前目录是否是有效的 Git 仓库。

    检测条件：
        1. git 命令可用
        2. 当前目录处于 git 工作区内（存在 .git 目录或父目录中有）

    返回:
        bool: 是有效的 Git 仓库返回 True，否则返回 False
    """
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return result.stdout.strip().lower() == "true"
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return False


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
        result = subprocess.run(
            ["git", "branch"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        branch_lines: List[str] = result.stdout.strip().splitlines()
        for line in branch_lines:
            if line.startswith("*"):
                return line[2:].strip()
        return ""
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return ""


def get_head_time_tag() -> str:
    """
    获取当前 Git 提交的时间标签，该标签由提交日期和短哈希组成。

    返回:
        str: 格式为 "YYYYMMDDHHMMSS-commit_hash" 的字符串，
             如果获取失败则返回当前本地时间的字符串标签（不含 hash）。
    """
    try:
        result_hash = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        commit_hash: str = result_hash.stdout.strip()

        result_date = subprocess.run(
            ["git", "log", "-1", "--format=%cd", "--date=format:%Y%m%d%H%M%S"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        commit_date: str = result_date.stdout.strip()

        return f"{commit_date}-{commit_hash}"
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        # Git 不可用时，仅返回本地时间（不含 hash）
        return time.strftime("%Y%m%d%H%M%S", time.localtime())


def __get_current_version(packet: Optional[str] = None) -> str:
    """
    从 Base.lua 文件中获取当前版本号

    参数:
        packet: 包标识，如果为 None 则自动获取

    返回:
        str: 当前版本号，如果获取失败则返回空字符串
    """
    if packet is None:
        packet = get_current_packet_id()

    base_file: str = f"{packet}_!Base/src/lib/Base.lua"
    try:
        content = utils.read_file(base_file)
        for line in content.splitlines():
            if line.startswith("local _VERSION_ "):
                # 去掉前缀并移除引号
                current_version = re.sub(
                    r"(?is)^local _VERSION_\s+=", "", line
                ).strip()[1:-1]
                return current_version
    except Exception as e:
        print(f"Warning: Cannot read version from {base_file}: {e}")
        return ""
    return ""


def __extract_addon_folder(file_path: str) -> Optional[str]:
    """
    从文件路径中提取子插件文件夹名称

    参数:
        file_path: 文件路径

    返回:
        Optional[str]: 子插件文件夹名称，如果不是子插件文件则返回 None
    """
    file_path = (
        file_path.strip('"')
        if file_path.startswith('"') and file_path.endswith('"')
        else file_path
    )

    # 跳过 !src-dist 目录下的文件
    if file_path.startswith("!src-dist/"):
        return None

    # 提取第一层目录名称
    parts = file_path.split("/")
    if len(parts) > 0 and parts[0]:
        return parts[0]

    return None


def __get_changed_addon_folders(base_hash: str) -> List[str]:
    """
    获取从指定 commit 到当前 HEAD 之间变更的子插件文件夹

    参数:
        base_hash: 基础提交的 hash

    返回:
        List[str]: 变更的子插件文件夹列表
    """
    if not base_hash:
        print("Warning: No base hash provided, scanning all addon folders")
        # 如果没有基础 hash，返回所有包含 info.ini 的文件夹
        addon_folders = []
        for item in os.listdir("."):
            addon_path = os.path.join(".", item)
            if os.path.isdir(addon_path) and os.path.exists(
                os.path.join(addon_path, "info.ini")
            ):
                addon_folders.append(item)
        return addon_folders

    try:
        # 获取文件变更列表
        filelist: List[str] = (
            utils.read_popen_output(f"git diff {base_hash} HEAD --name-status")
            .strip()
            .split("\n")
        )

        changed_folders = set()

        for file in filelist:
            lst: List[str] = file.split("\t")
            if not lst:
                continue

            # 处理添加、修改、删除的文件
            if lst[0] in ["A", "M", "D"]:
                folder = __extract_addon_folder(lst[1])
                if folder:
                    changed_folders.add(folder)
            # 处理重命名的文件
            elif lst[0].startswith("R"):
                folder = __extract_addon_folder(lst[1])
                if folder:
                    changed_folders.add(folder)
                if len(lst) >= 3:
                    folder = __extract_addon_folder(lst[2])
                    if folder:
                        changed_folders.add(folder)

        # 只返回确实存在且包含 info.ini 的文件夹
        result = []
        for folder in changed_folders:
            addon_path = os.path.join(".", folder)
            if os.path.isdir(addon_path) and os.path.exists(
                os.path.join(addon_path, "info.ini")
            ):
                result.append(folder)

        return result

    except Exception as e:
        print(f"Warning: Cannot get changed files: {e}")
        return []


def get_version_info(
    packet: Optional[str] = None, diff_ver: Optional[str] = None
) -> Dict[str, str]:
    """
    获取版本信息，包括当前版本、最新提交hash及历史版本记录，并从git提交信息中提取release记录。

    参数:
        packet: 包标识（用于确定Base.lua路径），如果为 None 则自动获取
        diff_ver: 指定对比版本（可选）

    返回:
        包含以下字段的字典：
            "current"               : 当前版本号（从 Base.lua 中获取）
            "current_hash"          : 当前最新提交的短 hash
            "max"                   : 历史中最大的版本号
            "previous"              : 上一版本号
            "previous_message"      : 上一版本的提交信息
            "previous_hash"         : 上一版本对应的提交 hash
            "changed_addon_folders" : 变更的子插件文件夹列表
    """
    if packet is None:
        packet = get_current_packet_id()

    current_version: str = __get_current_version(packet)
    if not current_version:
        utils.exit_with_message("读取Base.lua文件出错：无法获取当前版本信息")

    # 获取当前最新提交短hash
    current_hash: str = utils.read_popen_output(
        'git log -n 1 --pretty=format:"%h"'
    ).strip()

    # 获取所有包含 release 信息的提交记录（以 SUCCESS|<hash>|release: <version> 格式保存）
    commit_list: List[str] = utils.read_popen_output(
        'git log --grep release: --pretty=format:"SUCCESS|%h|%s"'
    ).split("\n")

    if diff_ver:
        extra_commit: str = utils.read_popen_output(
            f'git log {diff_ver} -n 1 --pretty=format:"SUCCESS|%h|%s"'
        )
        commit_list += extra_commit.split("\n")

    commit_list = list(filter(lambda x: x and x.startswith("SUCCESS|"), commit_list))

    current_semver = Semver(current_version)
    max_version: str = ""
    max_semver: Optional[Semver] = None
    prev_version: str = ""
    prev_version_message: str = ""
    prev_version_hash: str = ""
    prev_semver: Optional[Semver] = None

    # 遍历所有提交记录，提取版本号信息，使用 semver 进行版本比较
    for commit in commit_list:
        try:
            parts: List[str] = commit.split("|")
            if len(parts) < 3:
                continue
            version: str = re.sub(r"(?is)^release:\s+", "", parts[2]).strip()
            version_message: str = parts[2].strip()
            version_hash: str = parts[1].strip()

            try:
                version_semver = Semver(version)
            except:
                continue

            # 忽略与当前版本相同的记录
            if version_semver == current_semver:
                continue

            if diff_ver:
                # 若指定对比版本，且两个版本相同则赋值
                if diff_ver == version and version_semver > Semver("0.0.0"):
                    max_version = version
                    prev_version = version
                    prev_version_message = version_message
                    prev_version_hash = version_hash
                    continue
                if diff_ver.startswith(version_hash):
                    max_version = "0.0.0"
                    prev_version = "0.0.0"
                    prev_version_message = version_message
                    prev_version_hash = version_hash
                    continue
            else:
                # 若无 diff_ver 指定，则取版本大于"0.0.0"且最大版本号更新的记录
                if max_version == "" and version_semver > Semver("0.0.0"):
                    max_version = version
                    max_semver = version_semver
                    prev_version = version
                    prev_version_message = version_message
                    prev_version_hash = version_hash
                    prev_semver = version_semver
                    continue

                if version_semver < current_semver and version_semver > Semver("0.0.0"):
                    if prev_semver is None or version_semver > prev_semver:
                        prev_version = version
                        prev_version_message = version_message
                        prev_version_hash = version_hash
                        prev_semver = version_semver

                if max_semver is None or version_semver > max_semver:
                    max_version = version
                    max_semver = version_semver
        except Exception:
            # 忽略解析错误的记录
            continue

    # 获取变更的子插件文件夹
    changed_addon_folders = __get_changed_addon_folders(prev_version_hash)

    return {
        "current": current_version,
        "current_hash": current_hash,
        "max": max_version,
        "previous": prev_version,
        "previous_message": prev_version_message,
        "previous_hash": prev_version_hash,
        "changed_addon_folders": changed_addon_folders,
    }
