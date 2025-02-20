# -*- coding: utf-8 -*-

import os
import time


def is_interface_path(path):
    name = os.path.basename(path).lower()
    return name == "interface" or name == "interfacesource"


def get_interface_path():
    parent = __file__
    while parent:
        child = os.path.abspath(os.path.join(parent, os.pardir))
        if child == parent:
            return None
        if is_interface_path(child):
            return child
        parent = child
    return None


def get_packet_path(name=None):
    if name:
        interface_path = get_interface_path()
        if interface_path is None:
            return None
        return os.path.abspath(os.path.join(interface_path, name))
    else:
        return os.path.abspath(os.path.join(__file__, os.pardir, os.pardir, os.pardir))


def get_packet_dist_path() -> str:
    """返回构建结果目标目录"""
    return os.path.join(get_packet_path(), "!src-dist", "dist")


def set_packet_as_cwd(name=None):
    packet_path = get_packet_path(name)
    if packet_path is None:
        raise Exception("Can not find packet path!")
    os.chdir(packet_path)


def get_current_packet_id():
    packet_path = os.path.abspath(
        os.path.join(__file__, os.pardir, os.pardir, os.pardir)
    )
    return os.path.basename(packet_path)


def get_git_time_tag():
    """获取Git提交哈希和提交时间作为时间标签"""
    try:
        commit_hash = os.popen("git rev-parse --short HEAD").read().strip()
        commit_date = (
            os.popen("git log -1 --format=%cd --date=format:%Y%m%d%H%M%S")
            .read()
            .strip()
        )
        return f"{commit_date}-{commit_hash}"
    except:
        return time.strftime("%Y%m%d%H%M%S", time.localtime())
