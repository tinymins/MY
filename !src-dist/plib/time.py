# -*- coding: utf-8 -*-
"""
本脚本用于通过 NTP 服务器同步系统时间，
需要安装第三方库 ntplib 和 pypiwin32：
    pip install ntplib
    pip install pypiwin32

说明：
    1. 使用强类型标注（type annotations）。
    2. 使用中文注释便于理解。
"""

import time
from typing import Tuple

# 引用外部依赖模块，假设 require 与 run_as_admin 已经在项目中定义
from .require import require  # 用于动态加载模块
from .cmd import run_as_admin  # 用于以管理员权限执行命令

# 动态加载 ntplib 模块
ntplib = require("ntplib")


def get_ntp_time(ntp_server_url: str) -> Tuple[str, str, str, str, str, str]:
    """
    从指定的 NTP 服务器获取当前时间

    参数:
        ntp_server_url (str): NTP 服务器地址

    返回:
        Tuple[str, str, str, str, str, str]:
            包括年份、月份、日期、小时、分钟和秒钟（均为字符串格式）
    """
    # 创建 NTP 客户端实例
    ntp_client = ntplib.NTPClient()
    # 发起请求获取 NTP 时间信息
    ntp_stats = ntp_client.request(ntp_server_url)
    # 将 NTP 时间戳转换为本地时间结构
    local_time = time.localtime(ntp_stats.tx_time)
    # 分别格式化输出年、月、日、时、分、秒
    year = time.strftime("%Y", local_time)
    month = time.strftime("%m", local_time)
    day = time.strftime("%d", local_time)
    hour = time.strftime("%H", local_time)
    minute = time.strftime("%M", local_time)
    second = time.strftime("%S", local_time)

    return year, month, day, hour, minute, second


def set_system_time(
    year: str, month: str, day: str, hour: str, minute: str, second: str
) -> None:
    """
    通过命令行设置系统时间

    参数:
        year (str): 年份，如 "2023"
        month (str): 月份，如 "10"
        day (str): 日，如 "31"
        hour (str): 小时，如 "14"
        minute (str): 分，如 "30"
        second (str): 秒，如 "05"
    """
    # 设置日期，命令格式为 "date MM-DD-YYYY"
    date_cmd = "date {}-{}-{}".format(month, day, year)
    # 设置时间，命令格式为 "time HH:MM:SS"
    time_cmd = "time {}:{}:{}".format(hour, minute, second)

    # 以管理员权限执行命令
    run_as_admin(date_cmd)
    run_as_admin(time_cmd)


def sync_ntp_time(ntp_server_url: str = "ntp5.aliyun.com") -> None:
    """
    同步系统时间到指定的 NTP 服务器

    参数:
        ntp_server_url (str): NTP 服务器地址，默认为 "ntp5.aliyun.com"
    """
    # 获取 NTP 服务器当前时间
    year, month, day, hour, minute, second = get_ntp_time(ntp_server_url)
    # 设置系统时间
    set_system_time(year, month, day, hour, minute, second)
    # 打印成功同步信息
    print(
        '系统时间已根据 NTP 服务器 "{}" 的数据同步为 "{}/{}/{} {}:{}:{}"'.format(
            ntp_server_url, year, month, day, hour, minute, second
        )
    )
