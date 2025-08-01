# -*- coding: utf-8 -*-
# pip3 install ntplib pypiwin32 semver

"""
版本标签自动创建脚本
本脚本根据 CHANGELOG.md、git tag 及 git log 中包含 "release:" 字样的 commit，自动生成版本 tag。
"""

import argparse
import codecs
import os
import re
import semver
import time
import subprocess
from typing import List, Dict, Optional

import plib.utils as utils
import plib.git as git
import plib.environment as env


def __get_release_commit_list() -> List[Dict[str, object]]:
    """
    获取带有 'release:' 标签的提交列表
    返回字典列表，每个字典包括：版本号 version (str)、提交哈希 hash (str) 及提交时间戳 timestamp (int)
    """
    commit_list: List[Dict[str, object]] = []
    # 执行 git log 命令，根据 'release:' 搜索包含版本信息的 commit
    output: str = utils.read_popen_output(
        'git log --grep release: --pretty=format:"%h|%at|%s"'
    )
    for commit in output.split("\n"):
        try:
            parts = commit.strip().split("|")
            if len(parts) < 3:
                continue
            commit_hash: str = parts[0].strip()
            timestamp: int = int(parts[1].strip())
            # 移除 "release:" 前缀，并提取版本号信息
            version: str = re.sub(r"(?is)^release:\s+", "", parts[2].strip())
            commit_list.append(
                {"version": version, "hash": commit_hash, "timestamp": timestamp}
            )
        except Exception:
            continue
    return commit_list


def __get_release_tag_list() -> List[Dict[str, str]]:
    """
    获取 git 标签列表（仅提取以 "v" 开头且 version 大于0的标签）
    返回字典列表，每个字典包括：版本号 version (str) 及完整标签名 name (str)
    """
    tag_list: List[Dict[str, str]] = []
    tag_output: str = utils.read_popen_output("git tag -l")
    for tag in tag_output.split("\n"):
        tag = tag.strip()
        try:
            if not tag.startswith("v"):
                continue
            version: str = tag[1:]
            # semver.compare 若 version 大于 "0.0.0" 即为有效版本
            if semver.compare(version, "0.0.0") > 0:
                tag_list.append({"version": version, "name": tag})
        except Exception:
            continue
    return tag_list


def __get_changelog_list() -> List[Dict[str, str]]:
    """
    解析 CHANGELOG.md 文件，提取版本号与对应的更新说明信息
    返回字典列表，每个字典包括：版本号 version (str) 及更新信息 message (str)
    解析规则：
      - 非 '*' 或 ' *' 开头的行视为版本声明行，从中提取 "v" 后面的版本号
      - 紧随版本声明后的 '*' 开头行均视为该版本的更新说明
    """
    changelog_list: List[Dict[str, str]] = []
    current_info: Optional[Dict[str, str]] = None
    try:
        with codecs.open("CHANGELOG.md", "r", encoding="utf8") as fp:
            for line in fp:
                line = line.rstrip("\n")
                if not line:
                    continue
                if not line.startswith("*") and not line.startswith(" *"):
                    m = re.search(r"v([\d\.]+)", line, re.IGNORECASE)
                    if m:
                        version = m.group(1).strip()
                        current_info = {"version": version, "message": ""}
                        # 插入到列表首部，使得最新版本排在前面
                        changelog_list.insert(0, current_info)
                elif current_info is not None:
                    current_info["message"] += line + "\n"
    except Exception:
        pass
    return changelog_list


def main() -> None:
    """
    主函数：解析命令行参数、检查 git 状态，按 CHANGELOG.md 与 git log 自动生成版本标签，
    并通过设置环境变量传入 tag 时间，使 tag 时间与对应提交时间保持一致。
    """
    parser = argparse.ArgumentParser(description="自动添加发行版 tag。")
    parser.add_argument("--overwrite", action="store_true", help="覆盖已存在的 tag。")
    parser.add_argument(
        "--dry-run", action="store_true", help="仅演示，不实际推送 tag。"
    )
    args = parser.parse_args()

    # 切换当前工作目录为包所在目录
    env.set_packet_as_cwd()

    # 检查当前分支是否有未提交修改
    utils.assert_exit(git.is_clean(), "错误：当前分支存在未提交的文件变更！")

    subprocess.run(["git", "checkout", "master"], check=True)
    utils.assert_exit(
        git.is_clean(), "错误：切换到 master 分支后存在未提交的文件变更！"
    )

    # 与 stable 分支 rebase，保证提交记录干净
    subprocess.run(["git", "rebase", "stable"], check=True)
    utils.assert_exit(git.is_clean(), "错误：请解决冲突并先清除未提交变更后再重试！")

    print("正在读取 CHANGELOG 和版本列表...")
    changelog_list = __get_changelog_list()
    tag_list = __get_release_tag_list()
    release_list = __get_release_commit_list()

    for changelog in changelog_list:
        version: str = changelog.get("version", "")
        # 若未指定覆盖，且该版本 tag 已存在，则跳过
        if not args.overwrite:
            if any(p.get("version", "") == version for p in tag_list):
                continue

        # 在 release 提交列表中查找匹配的版本提交
        release: Optional[Dict[str, object]] = next(
            (p for p in release_list if p.get("version", "") == version), None
        )
        if release is None:
            continue

        commit_hash: str = release.get("hash", "")

        # 如果启用模拟设置系统时间，则将系统时间修改为该 commit 时间
        commit_timestamp: int = release.get("timestamp", 0)

        # 构造 tag 提交信息
        print(f"在提交 {commit_hash} 上创建 tag v{version} ...")
        message: str = f"Release v{version}\n{changelog.get('message', '')}"

        if not args.dry_run:
            # 将提交信息写入临时文件
            with codecs.open("commit_msg.txt", "w", encoding="utf8") as f:
                f.write(message)

            # 使用 commit 提交时间构造 tag 时间字符串，格式形如 "Fri Apr 23 15:02:36 2021 +0800"
            commit_date: str = time.strftime(
                "%a %b %d %H:%M:%S %Y %z", time.localtime(commit_timestamp)
            )
            # 复制当前环境变量，并添加 GIT_AUTHOR_DATE、GIT_COMMITTER_DATE 用于设置 tag 创建时间
            env_tag = os.environ.copy()
            env_tag["GIT_AUTHOR_DATE"] = commit_date
            env_tag["GIT_COMMITTER_DATE"] = commit_date

            # 使用 subprocess.run 调用 git tag 命令，传入环境变量使 tag 时间与提交时间一致
            subprocess.run(
                [
                    "git",
                    "tag",
                    "-a",
                    f"v{version}",
                    commit_hash,
                    "-f",
                    "-F",
                    "commit_msg.txt",
                ],
                env=env_tag,
                check=True,
            )
            os.remove("commit_msg.txt")

            # 推送代码与 tag 至远程仓库
            subprocess.run(["git", "push"], check=True)
            subprocess.run(["git", "push", "--tags"], check=True)

    print("任务完成。")


if __name__ == "__main__":
    main()
