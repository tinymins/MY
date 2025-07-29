# -*- coding: utf-8 -*-

"""
该脚本用于定位项目中的插件根目录及插件集目录，并提供相关路径的获取与设置工作目录等功能。
"""

import os
from typing import Optional


def is_interface_path(path: str) -> bool:
    """
    判断给定的路径是否为插件根目录。
    如果目录名为 "interface" 或 "interfacesource"（不区分大小写），返回 True，否则返回 False。

    参数:
        path (str): 待判断的路径。

    返回:
        bool: 如果为插件根目录则返回 True，否则返回 False。
    """
    name = os.path.basename(path).lower()
    return name == "interface" or name == "interfacesource"


def get_interface_path() -> Optional[str]:
    """
    从当前文件所在目录开始向上查找，直到找到插件根目录（目录名为 "interface" 或 "interfacesource"）。
    如果找到则返回该插件根目录的绝对路径，如果未找到则返回 None。

    返回:
        Optional[str]: 插件根目录的绝对路径，或者在未找到时返回 None。
    """
    parent: str = os.path.abspath(__file__)
    while parent:
        child: str = os.path.abspath(os.path.join(parent, os.pardir))
        # 如果到达文件系统根目录，则退出循环
        if child == parent:
            return None
        if is_interface_path(child):
            return child
        parent = child
    return None


def get_packet_path(name: Optional[str] = None) -> str:
    """
    获取插件集所在目录的路径。
    如果传入 name 参数，则将该名字拼接到插件根目录的路径下返回；
    否则，默认获取当前文件的上上上级目录。

    参数:
        name (Optional[str]): 如果提供，则返回接口路径下该名称子目录的绝对路径。

    返回:
        str: 插件集的绝对路径。
    """
    if name:
        interface_path: Optional[str] = get_interface_path()
        if interface_path is None:
            raise Exception("未找到插件根目录，无法确定插件集路径。")
        return os.path.abspath(os.path.join(interface_path, name))
    else:
        # 从当前文件路径向上三级目录，作为插件集根目录
        return os.path.abspath(os.path.join(__file__, os.pardir, os.pardir, os.pardir))


def get_packet_dist_path() -> str:
    """
    获取构建结果目标目录的路径。

    返回:
        str: 构建结果目标目录的绝对路径，即在插件集目录下 '!src-dist/dist' 子目录。
    """
    return os.path.join(get_packet_path(), "!src-dist", "dist")


def set_packet_as_cwd(name: Optional[str] = None) -> None:
    """
    将插件集目录设置为当前工作目录。
    如果找不到插件集目录，则抛出异常。

    参数:
        name (Optional[str]): 如果提供，则用于获取接口路径下对应的子目录路径作为插件集目录。

    异常:
        Exception: 当插件集路径未找到时抛出异常。
    """
    packet_path: str = get_packet_path(name)
    if not os.path.isdir(packet_path):
        raise Exception(f"未能找到有效的插件集目录: {packet_path}")
    os.chdir(packet_path)


def get_current_packet_id() -> str:
    """
    获取当前插件集的标识，即插件集目录的名称。

    返回:
        str: 当前插件集目录的名称。
    """
    parent_dir = os.path.abspath(
        os.path.join(__file__, os.pardir, os.pardir, os.pardir)
    )
    for name in os.listdir(parent_dir):
        full_path = os.path.join(parent_dir, name)
        if os.path.isdir(full_path) and name.endswith("_!Base"):
            return name[:-6]
    raise Exception("获取当前插件集目录的名称失败")
