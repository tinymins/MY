# -*- coding: utf-8 -*-
"""
AssertVersion 版本更新工具模块

提供更新 Lua 文件中 AssertVersion 调用版本号的功能
"""

import os
import re
from typing import List, Tuple

import plib.git as git
from plib.semver import Semver, satisfies as semver_satisfies


def should_update_version_constraint(
    constraint: str, new_version: str, force_update: bool = False
) -> Tuple[bool, str]:
    """
    判断版本约束是否需要更新

    参数：
        constraint: 当前版本约束
        new_version: 新版本号
        force_update: 是否强制更新（忽略约束检查）

    返回：
        tuple: (是否需要更新, 新的约束字符串)
    """
    constraint = constraint.strip().strip("'\"")

    # 不更新通配符版本要求，即使在强制更新模式下
    if constraint == "*":
        return False, constraint

    if force_update:
        # 强制更新模式，一律更新为 ^ 格式
        new_constraint = f"^{new_version}"
        return True, new_constraint

    try:
        # 使用我们的 semver 模块检查新版本是否满足约束
        satisfies = semver_satisfies(new_version, constraint)

        if not satisfies:
            # 需要更新约束，统一使用 ^ 格式
            new_constraint = f"^{new_version}"
            return True, new_constraint

        return False, constraint

    except Exception as e:
        print(f"Warning: Cannot process version constraint '{constraint}': {e}")
        return False, constraint


def find_lua_files(directory: str) -> List[str]:
    """
    递归查找所有Lua文件

    参数：
        directory: 要搜索的目录

    返回：
        Lua文件路径列表
    """
    lua_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".lua"):
                lua_files.append(os.path.join(root, file))
    return lua_files


def update_assert_version_in_file(
    file_path: str, new_version: str, force_update: bool = False
) -> Tuple[bool, int]:
    """
    更新单个文件中的AssertVersion调用

    参数：
        file_path: 要更新的文件路径
        new_version: 新版本号
        force_update: 是否强制更新（忽略约束检查）

    返回：
        tuple: (是否有更新, 更新的数量)
    """
    # 检测文件编码
    encoding_used = "gbk"  # 默认使用 gbk
    try:
        with open(file_path, "r", encoding="gbk", newline="") as f:
            content = f.read()
    except UnicodeDecodeError:
        encoding_used = "utf-8"
        try:
            with open(file_path, "r", encoding="utf-8", newline="") as f:
                content = f.read()
        except Exception as e:
            print(f"Warning: Cannot read file {file_path}: {e}")
            return False, 0
    except Exception as e:
        print(f"Warning: Cannot read file {file_path}: {e}")
        return False, 0

    # 匹配 AssertVersion 调用的正则表达式
    # 匹配类似：X.AssertVersion(MODULE_NAME, _L[MODULE_NAME], '^27.0.0')
    pattern = r'(\w+\.AssertVersion\s*\([^,]+,\s*[^,]+,\s*["\'])([^"\']+)(["\'])'

    updated_content = content
    update_count = 0

    def replace_version(match):
        nonlocal update_count
        prefix = match.group(1)
        version_constraint = match.group(2)
        suffix = match.group(3)

        should_update, new_constraint = should_update_version_constraint(
            version_constraint, new_version, force_update
        )

        if should_update:
            update_count += 1
            print(f"  {file_path}: {version_constraint} -> {new_constraint}")
            return f"{prefix}{new_constraint}{suffix}"

        return match.group(0)

    updated_content = re.sub(pattern, replace_version, updated_content)

    if update_count > 0:
        try:
            # 使用相同的编码和 newline="" 参数写回文件，保持原始行尾符
            with open(file_path, "w", encoding=encoding_used, newline="") as f:
                f.write(updated_content)
            return True, update_count
        except Exception as e:
            print(f"Error writing file {file_path}: {e}")
            return False, 0

    return False, 0


def update_assert_version(
    new_version: str,
    diff_ver: str = None,
    force_changed: bool = False,
    scan_all_if_no_changes: bool = True,
) -> Tuple[int, int]:
    """
    更新 Lua 文件中的 AssertVersion 调用到指定版本

    参数：
        new_version: 新版本号
        diff_ver: 指定对比版本（可选）
        force_changed: 是否强制更新（忽略约束检查）
        scan_all_if_no_changes: 当没有变更时是否扫描所有文件

    返回：
        tuple: (总更新文件数, 总更新次数)
    """
    # 验证新版本格式
    try:
        new_semver = Semver(new_version)
    except Exception:
        print(f"Error: Invalid version format: {new_version}")
        return 0, 0

    # 获取当前目录
    current_dir = os.getcwd()
    print(f"Scanning Lua files in: {current_dir}")
    print(f"Target version: {new_version}")

    # 检测是否为大版本升级
    is_major_upgrade = False
    previous_version = ""

    # 如果指定了 diff 参数或 force_changed，使用 git.get_version_info 获取版本信息
    if diff_ver is not None or force_changed:
        print("Getting version information...")

        # 使用 git.get_version_info 获取版本信息
        version_info = git.get_version_info(diff_ver=diff_ver)

        base_hash = version_info.get("previous_hash", "")
        changed_folders = version_info.get("changed_addon_folders", [])
        previous_version = version_info.get("previous", "")

        if base_hash:
            print(f"Base version: {previous_version} ({base_hash})")

        # 检测大版本升级
        if previous_version:
            try:
                prev_semver = Semver(previous_version)
                is_major_upgrade = new_semver.major > prev_semver.major
                if is_major_upgrade:
                    print(
                        f"⚠️ Major version upgrade detected ({previous_version} -> {new_version})"
                    )
                    print(
                        "Scanning ALL Lua files to update incompatible version constraints..."
                    )
            except Exception:
                pass

        # 大版本升级时，扫描所有文件（让 satisfies 逻辑判断是否需要更新）
        if is_major_upgrade:
            lua_files = find_lua_files(current_dir)
            # 大版本升级时不强制更新，让 semver_satisfies 自然判断
            # ^28.x.x 不满足 29.0.0，会自动更新
            force_update = False
        elif changed_folders:
            print(f"Changed addon folders: {', '.join(changed_folders)}")
            # 只处理变更的子插件文件夹中的 Lua 文件
            lua_files = []
            for folder in changed_folders:
                folder_lua_files = find_lua_files(folder)
                lua_files.extend(folder_lua_files)

            # 使用传入的 force_changed 参数
            force_update = force_changed
        else:
            print("No changed addon folders found")
            if scan_all_if_no_changes:
                # 没有变更时，扫描所有 Lua 文件
                lua_files = find_lua_files(current_dir)
                force_update = False
            else:
                # 没有变更时，不处理任何文件
                lua_files = []
                force_update = False
    else:
        # 没有指定 diff 参数，扫描所有 Lua 文件
        lua_files = find_lua_files(current_dir)
        force_update = False

    if not lua_files:
        print("No Lua files to process")
        return 0, 0

    print(f"Found {len(lua_files)} Lua files")
    print()

    total_files_updated = 0
    total_updates = 0

    # 处理每个文件
    for file_path in lua_files:
        file_updated, update_count = update_assert_version_in_file(
            file_path, new_version, force_update
        )
        if file_updated:
            total_files_updated += 1
            total_updates += update_count

    print()
    print("AssertVersion Update Summary:")
    print(f"  Files updated: {total_files_updated}")
    print(f"  Total updates: {total_updates}")

    if total_updates > 0:
        print(
            f"Successfully updated {total_updates} AssertVersion calls in {total_files_updated} files"
        )
    else:
        print("No AssertVersion calls needed to be updated")

    return total_files_updated, total_updates


def update_assert_version_for_changed_addons(
    new_version: str, diff_ver: str = None, force_changed: bool = True
) -> Tuple[int, int]:
    """
    更新变更子插件中的 AssertVersion 调用到指定版本

    参数：
        new_version: 新版本号
        diff_ver: 指定对比版本（可选）
        force_changed: 是否强制更新变更的子插件（默认为 True）

    返回：
        tuple: (总更新文件数, 总更新次数)
    """
    return update_assert_version(
        new_version,
        diff_ver=diff_ver,
        force_changed=force_changed,
        scan_all_if_no_changes=False,
    )
