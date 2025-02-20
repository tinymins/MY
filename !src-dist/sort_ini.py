# -*- coding: utf-8 -*-
"""
INI 文件排序脚本
本脚本对指定的 .ini 文件或目录下所有以大写字母开头的 .ini 文件进行排序。
排序规则：
    1. 在每个节内，将以 "._WndType=" 或 "._Parent=" 开头的行固定放在最前面；
    2. 其余非空行根据去除首尾空格后的内容进行区分大小写排序；
    3. 原有空行保留在排序后的末尾。
"""

import sys
import os
import time
from typing import List


def sort_lines(lines: List[str]) -> List[str]:
    """
    对单个节内的行进行排序。

    参数:
        lines: 当前节的所有行列表。

    返回:
        排序后的行列表。
    """
    # 固定顺序的行：仅包含以 "._WndType=" 或 "._Parent=" 开头的行
    fixed_order: List[str] = [
        line
        for line in lines
        if line.startswith("._WndType=") or line.startswith("._Parent=")
    ]

    # 需要排序的其他非空行（排除已在固定顺序中的行）
    other_lines: List[str] = [
        line for line in lines if line not in fixed_order and line.strip()
    ]

    # 根据去除首尾空白后的内容排序（区分大小写）
    other_lines.sort(key=lambda s: s.strip())

    # 保留所有原有的空行（仅含空白字符的行）
    empty_lines: List[str] = [line for line in lines if not line.strip()]

    # 综合固定顺序行、排序后的行和空行
    return fixed_order + other_lines + empty_lines


def sort_ini_file(file_path: str) -> None:
    """
    对单个 INI 文件进行处理，按照指定规则对各个节的内容进行排序，
    并将排序后的结果写回原文件。

    参数:
        file_path: INI 文件的完整路径。
    """
    try:
        with open(file_path, "r", encoding="gbk") as f:
            lines: List[str] = f.readlines()
    except Exception as e:
        print(f"读取文件失败: {file_path}, 错误: {e}")
        return

    sorted_lines: List[str] = []  # 存放最终排序后的所有行
    current_section_lines: List[str] = []  # 存放当前节内部的行
    section_header: str = ""  # 当前节的标题行，如 "[Section]"
    inter_section_newlines: List[str] = []  # 存放节与节之间的空行

    for line in lines:
        stripped_line: str = line.strip()
        # 判断是否为节标题（以 [ 开始，以 ] 结束）
        if stripped_line.startswith("[") and stripped_line.endswith("]"):
            # 当前已有节，先对前一节进行排序并保存
            if section_header:
                sorted_section_lines: List[str] = sort_lines(current_section_lines)
                sorted_lines.append(section_header)
                sorted_lines.extend(sorted_section_lines)
            # 在节之间添加之前收集的空行
            sorted_lines.extend(inter_section_newlines)
            inter_section_newlines = []
            # 更新当前节：设置新节标题并重置当前节的行列表
            section_header = line
            current_section_lines = []
        elif section_header:
            # 如果已经进入某个节，将行加入当前节内容中
            current_section_lines.append(line)
        else:
            # 如果还未遇到任何节标题，则视为节之间的空行
            inter_section_newlines.append(line)

    # 对最后一个节进行处理
    if section_header:
        sorted_section_lines = sort_lines(current_section_lines)
        sorted_lines.append(section_header)
        sorted_lines.extend(sorted_section_lines)

    # 写入排序后的内容回原文件
    try:
        with open(file_path, "w", encoding="gbk") as f:
            f.writelines(sorted_lines)
    except Exception as e:
        print(f"写入文件失败: {file_path}, 错误: {e}")


def process_directory(directory: str) -> None:
    """
    遍历指定目录，查找所有符合条件（扩展名为 .ini 且文件名首字母为大写）的 INI 文件，并逐个排序处理。

    参数:
        directory: 需要处理的目标目录路径。
    """
    for root, _, files in os.walk(directory):
        for file in files:
            # 判断文件扩展名是否为 .ini 且文件名首字母为大写
            if file.lower().endswith(".ini") and file[0].isupper():
                file_path: str = os.path.join(root, file)
                sort_ini_file(file_path)
                print(f"已排序: {file_path}")


def main() -> None:
    """
    主函数：根据命令行参数或用户输入获取文件或目录路径，然后执行排序任务。
    """
    if len(sys.argv) == 2:
        path: str = sys.argv[1]
    else:
        from plib.environment import get_packet_path

        path = get_packet_path()

    if os.path.isfile(path):
        # 检查是否为以大写字母开头的 .ini 文件
        if path.lower().endswith(".ini") and os.path.basename(path)[0].isupper():
            sort_ini_file(path)
            print(f"已排序: {path}")
        else:
            print("该文件不是以大写字母开头的 .ini 文件。")
    elif os.path.isdir(path):
        process_directory(path)
    else:
        print("无效的路径。")

    print("处理完成，程序将在3秒后退出。")
    time.sleep(3)


if __name__ == "__main__":
    main()
