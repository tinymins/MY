# -*- coding: utf-8 -*-

import zlib


def get_file_crc(file_name):
    prev = 0
    for eachLine in open(file_name, "rb"):
        prev = zlib.crc32(eachLine, prev)
    return "%X" % (prev & 0xFFFFFFFF)


def exit_with_message(msg):
    print(msg)
    exit()


def assert_exit(condition, msg):
    if not condition:
        exit_with_message(msg)
