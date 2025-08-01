# -*- coding: utf-8 -*-
"""
本脚本用于计算文件的 CRC32 校验值，并提供辅助退出函数。
"""

import zlib
import sys
from typing import NoReturn
import subprocess


def read_popen_output(command: str) -> str:
    """
    执行命令并读取输出。

    参数：
        command: 要执行的命令字符串
    返回：
        命令输出的字符串
    """
    try:
        with subprocess.Popen(
            command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        ) as process:
            output, error = process.communicate()
            if error:
                raise RuntimeError(f"命令执行错误: {error.decode('utf-8')}")
            return output.decode("utf-8")
    except Exception as e:
        exit_with_message(f"执行命令失败: {e}")


def read_file(
    file_path: str, primary_encoding: str = "gbk", fallback_encoding: str = "utf-8"
) -> str:
    """
    尝试使用主要编码读取文件，如果失败则尝试使用备用编码。

    参数：
        file_path: 文件路径
        primary_encoding: 首选编码（默认GBK）
        fallback_encoding: 备用编码（默认UTF-8）
    返回：
        文件内容字符串
    """
    try:
        with open(file_path, "r", encoding=primary_encoding) as f:
            return f.read()
    except UnicodeDecodeError:
        with open(file_path, "r", encoding=fallback_encoding) as f:
            return f.read()


def get_file_crc(file_name: str) -> str:
    """
    计算指定文件的 CRC32 校验值，并以大写 16 进制字符串形式返回。

    参数:
        file_name (str): 文件路径

    返回:
        str: 文件的 CRC32 校验值（大写 16 进制）
    """
    crc_value: int = 0
    try:
        # 使用 with 自动管理文件关闭
        with open(file_name, "rb") as f:
            for line in f:
                crc_value = zlib.crc32(line, crc_value)
    except IOError as error:
        exit_with_message(f"打开文件失败: {error}")
    # 将 crc_value 限制在 32 位内，并转换为大写 16 进制字符串输出
    return f"{crc_value & 0xFFFFFFFF:X}"


def exit_with_message(msg: str) -> NoReturn:
    """
    输出错误信息后退出程序。

    参数:
        msg (str): 要输出的错误信息
    """
    print(msg)
    sys.exit(1)


def assert_exit(condition: bool, msg: str) -> None:
    """
    当条件不满足时输出提示信息并退出程序。

    参数:
        condition (bool): 判断条件
        msg (str): 条件不满足时的提示信息
    """
    if not condition:
        exit_with_message(msg)
