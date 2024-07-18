# -*- coding: utf-8 -*-

import os


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
