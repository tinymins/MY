# -*- coding: utf-8 -*-
"""
版本更新与更新日志管理脚本

说明：
    本脚本负责更新 Base.lua 中的版本号和打包时间，以及更新 CHANGELOG.md 文件。
    支持两种使用方式：
    1. 交互式模式：默认模式，供本地终端使用
    2. 命令行参数模式：供 CI/CD 流水线使用

用法：
    # 交互式模式（默认）
    python changelog.py

    # CI/CD 模式（命令行参数）
    python changelog.py --version-type patch --changelog "插件A：修复问题|插件B：新增功能"

    # 仅获取新版本号（不修改文件）
    python changelog.py --version-type patch --dry-run
"""

import argparse
import os
import re
import sys
from datetime import datetime
from typing import Optional, Tuple, List

# 添加 plib 路径以便导入本地模块
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import semver  # noqa: E402
from plib.environment import get_packet_path, get_current_packet_id  # noqa: E402


def get_base_lua_path() -> str:
    """获取 Base.lua 文件路径"""
    packet_id = get_current_packet_id()
    packet_path = get_packet_path()
    return os.path.join(packet_path, f"{packet_id}_!Base", "src", "lib", "Base.lua")


def get_changelog_path() -> str:
    """获取 CHANGELOG.md 文件路径"""
    packet_path = get_packet_path()
    return os.path.join(packet_path, "CHANGELOG.md")


def read_current_version() -> str:
    """
    从 Base.lua 中读取当前版本号

    返回：
        当前版本号字符串（如 "1.2.3"）
    """
    base_lua_path = get_base_lua_path()

    try:
        with open(base_lua_path, "r", encoding="gbk") as f:
            content = f.read()
    except UnicodeDecodeError:
        with open(base_lua_path, "r", encoding="utf-8") as f:
            content = f.read()

    # 匹配 _VERSION_ = 'x.y.z' 格式
    match = re.search(r"_VERSION_\s*=\s*'([^']*)'", content)
    if not match:
        raise ValueError("无法从 Base.lua 中读取版本号")

    version = match.group(1)

    # 验证版本号格式
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        raise ValueError(f"版本号格式无效: {version}，期望格式: X.Y.Z")

    return version


def calculate_new_version(current_version: str, version_type: str) -> str:
    """
    根据版本类型计算新版本号

    参数：
        current_version: 当前版本号
        version_type: 版本类型（major/minor/patch）

    返回：
        新版本号字符串
    """
    version_type = version_type.lower()

    if version_type == "patch":
        return semver.bump_patch(current_version)
    elif version_type == "minor":
        return semver.bump_minor(current_version)
    elif version_type == "major":
        return semver.bump_major(current_version)
    else:
        raise ValueError(f"无效的版本类型: {version_type}，有效值: major/minor/patch")


def update_base_lua(new_version: str, build_date: Optional[str] = None) -> None:
    """
    更新 Base.lua 中的版本号和打包时间

    参数：
        new_version: 新版本号
        build_date: 打包日期（格式 YYYYMMDD），默认为当前日期
    """
    if build_date is None:
        build_date = datetime.now().strftime("%Y%m%d")

    base_lua_path = get_base_lua_path()

    try:
        with open(base_lua_path, "r", encoding="gbk") as f:
            content = f.read()
        encoding = "gbk"
    except UnicodeDecodeError:
        with open(base_lua_path, "r", encoding="utf-8") as f:
            content = f.read()
        encoding = "utf-8"

    # 更新 _BUILD_
    content = re.sub(
        r"(local _BUILD_\s*=\s*)'[^']*'",
        rf"\1'{build_date}'",
        content,
    )

    # 更新 _VERSION_
    content = re.sub(
        r"(local _VERSION_\s*=\s*)'[^']*'",
        rf"\1'{new_version}'",
        content,
    )

    with open(base_lua_path, "w", encoding=encoding) as f:
        f.write(content)

    print(f"✅ Base.lua 已更新: 版本={new_version}, 构建日期={build_date}")


def process_changelog_input(changelog_input: str) -> List[str]:
    """
    处理更新日志输入，将其转换为标准格式

    支持的输入格式：
    1. "插件A：内容|插件B：内容" （冒号分隔）
    2. "* [插件A] 内容|* [插件B] 内容" （标准格式）
    3. 混合格式

    参数：
        changelog_input: 原始更新日志输入

    返回：
        格式化后的更新日志行列表
    """
    # 首先处理原始格式 * [插件] 内容，在 * 前面添加分隔符
    processed = re.sub(r"([^|])(\*\s*\[)", r"\1|\2", changelog_input)

    # 按 | 分割每一行
    lines = processed.split("|")
    result = []

    for line in lines:
        # 去掉首尾空格和引号
        line = line.strip().strip('"').strip('"').strip('"')

        # 跳过空行
        if not line:
            continue

        # 检查是否已经是 * [插件] 格式
        if re.match(r"^\*\s*\[", line):
            # 已经是正确格式，只需要格式化空格
            match = re.match(r"^\*\s*\[([^\]]*)\]\s*(.*)", line)
            if match:
                plugin = match.group(1).strip()
                content = match.group(2).strip()
                result.append(f"* [{plugin}] {content}")
            else:
                result.append(line)
        else:
            # 转换 插件:内容 或 插件：内容 格式为 * [插件] 内容
            if re.search(r"[：:]", line):
                parts = re.split(r"[：:]", line, maxsplit=1)
                plugin = parts[0].strip().strip('"').strip('"').strip('"')
                content = (
                    parts[1].strip().strip('"').strip('"').strip('"')
                    if len(parts) > 1
                    else ""
                )
                result.append(f"* [{plugin}] {content}")
            else:
                # 如果没有冒号，假设整行都是内容
                result.append(f"* {line}")

    return result


def update_changelog(new_version: str, changelog_lines: List[str]) -> str:
    """
    更新 CHANGELOG.md 文件

    参数：
        new_version: 新版本号
        changelog_lines: 格式化后的更新日志行列表

    返回：
        生成的更新日志内容（用于输出）
    """
    changelog_path = get_changelog_path()
    packet_id = get_current_packet_id()

    # 读取现有内容
    with open(changelog_path, "r", encoding="utf-8") as f:
        existing_content = f.readlines()

    # 构建新的更新日志条目
    new_entry_lines = [
        f"## {packet_id}插件集 v{new_version}\n",
        "\n",
    ]
    for line in changelog_lines:
        new_entry_lines.append(f"{line}\n")
    new_entry_lines.append("\n")

    # 构建新的文件内容
    # 保留标题（前两行），插入新条目，然后是剩余内容
    new_content = []
    new_content.append("# 更新日志\n")
    new_content.append("\n")
    new_content.extend(new_entry_lines)

    # 跳过原文件的前两行（标题和空行），添加剩余内容
    if len(existing_content) > 2:
        new_content.extend(existing_content[2:])

    # 写入文件
    with open(changelog_path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    # 返回生成的更新日志内容（不含标题）
    generated_changelog = f"## {packet_id}插件集 v{new_version}\n\n"
    generated_changelog += "\n".join(changelog_lines)

    print("✅ CHANGELOG.md 已更新")

    return generated_changelog


def interactive_mode() -> Tuple[str, str]:
    """
    交互式模式，提示用户输入版本类型和更新日志

    返回：
        (version_type, changelog) 元组
    """
    print("\n" + "=" * 50)
    print("📦 版本更新与更新日志管理工具")
    print("=" * 50 + "\n")

    # 显示当前版本
    current_version = read_current_version()
    print(f"当前版本: {current_version}\n")

    # 计算三种版本类型的新版本号
    patch_version = calculate_new_version(current_version, "patch")
    minor_version = calculate_new_version(current_version, "minor")
    major_version = calculate_new_version(current_version, "major")

    # 选择版本类型
    print("请选择版本更新类型:")
    print(f"  1. Patch (修订版本) -> {patch_version}")
    print(f"  2. Minor (次版本)   -> {minor_version}")
    print(f"  3. Major (主版本)   -> {major_version}")
    print()

    while True:
        choice = input("请输入选项 (1/2/3): ").strip()
        if choice == "1":
            version_type = "patch"
            break
        elif choice == "2":
            version_type = "minor"
            break
        elif choice == "3":
            version_type = "major"
            break
        else:
            print("❌ 无效选项，请重新输入")

    new_version = calculate_new_version(current_version, version_type)
    print(f"\n新版本号将为: {new_version}\n")

    # 输入更新日志
    print("请输入更新日志内容:")
    print("  格式1: 插件名：更新内容|插件名：更新内容")
    print("  格式2: * [插件名] 更新内容|* [插件名] 更新内容")
    print("  提示: 使用 | 分隔多条更新记录")
    print()

    changelog = input("更新日志: ").strip()

    if not changelog:
        print("❌ 更新日志不能为空")
        sys.exit(1)

    return version_type, changelog


def run(
    version_type: Optional[str] = None,
    changelog: str = "",
    dry_run: bool = False,
    build_date: Optional[str] = None,
    new_version: Optional[str] = None,
) -> dict:
    """
    执行版本更新和更新日志更新

    参数：
        version_type: 版本类型（major/minor/patch），如果指定了 new_version 则可不传
        changelog: 更新日志内容
        dry_run: 是否只计算不修改文件
        build_date: 打包日期（可选）
        new_version: 直接指定目标版本号（供 CI 使用，跳过计算）

    返回：
        包含版本信息的字典
    """
    # 读取当前版本
    current_version = read_current_version()

    # 计算新版本（如果未直接指定）
    if new_version is None:
        if version_type is None:
            raise ValueError("必须指定 version_type 或 new_version")
        new_version = calculate_new_version(current_version, version_type)

    result = {
        "current_version": current_version,
        "new_version": new_version,
        "version_type": version_type or "direct",
    }

    if dry_run:
        print(f"当前版本: {current_version}")
        print(f"版本类型: {version_type}")
        print(f"新版本号: {new_version}")
        return result

    # 更新 Base.lua
    update_base_lua(new_version, build_date)

    # 处理并更新更新日志
    changelog_lines = process_changelog_input(changelog)
    generated_changelog = update_changelog(new_version, changelog_lines)

    result["changelog"] = generated_changelog

    print("\n" + "=" * 50)
    print("📝 更新日志内容预览:")
    print("=" * 50)
    print(generated_changelog)
    print("=" * 50 + "\n")

    return result


def main():
    """脚本入口函数"""
    parser = argparse.ArgumentParser(
        description="版本更新与更新日志管理工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 交互式模式（默认）
  python changelog.py

  # CI/CD 模式
  python changelog.py --version-type patch --changelog "插件A：修复问题|插件B：新增功能"

  # 仅计算新版本号（不修改文件）
  python changelog.py --version-type patch --dry-run

  # 指定打包日期
  python changelog.py --version-type patch --changelog "更新内容" --build-date 20260127
        """,
    )

    parser.add_argument(
        "--version-type",
        "-t",
        choices=["major", "minor", "patch", "Major", "Minor", "Patch"],
        help="版本更新类型: major/minor/patch",
    )
    parser.add_argument(
        "--changelog",
        "-c",
        help="更新日志内容，使用 | 分隔多条记录",
    )
    parser.add_argument(
        "--dry-run",
        "-n",
        action="store_true",
        help="仅计算新版本号，不修改任何文件",
    )
    parser.add_argument(
        "--build-date",
        "-d",
        help="打包日期（格式 YYYYMMDD），默认为当前日期",
    )
    parser.add_argument(
        "--output-version",
        "-o",
        action="store_true",
        help="仅输出新版本号（供脚本使用，不修改文件）",
    )
    parser.add_argument(
        "--new-version",
        "-v",
        help="直接指定目标版本号（跳过计算，供 CI 使用）",
    )

    args = parser.parse_args()

    # 切换到项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    os.chdir(project_root)

    # 仅输出新版本号模式
    if args.output_version and args.version_type:
        current_version = read_current_version()
        new_version = calculate_new_version(current_version, args.version_type)
        print(new_version)
        return

    # 命令行参数模式
    if args.version_type or args.new_version:
        if not args.changelog and not args.dry_run:
            parser.error("--changelog 参数是必需的（除非使用 --dry-run）")

        run(
            version_type=args.version_type,
            changelog=args.changelog or "",
            dry_run=args.dry_run,
            build_date=args.build_date,
            new_version=args.new_version,
        )

        if not args.dry_run:
            print("✅ 版本更新完成!")
        return

    # 如果没有提供任何参数，默认进入交互模式
    version_type, changelog = interactive_mode()
    run(version_type, changelog, dry_run=False, build_date=args.build_date)
    print("✅ 版本更新完成!")


if __name__ == "__main__":
    main()
