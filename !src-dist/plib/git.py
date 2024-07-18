# -*- coding: utf-8 -*-

import os


def is_clean():
    status = os.popen("git status").read().strip().split("\n")
    return status[len(status) - 1] == "nothing to commit, working tree clean"


def get_current_branch():
    name_list = os.popen("git branch").read().strip().split("\n")
    for name in name_list:
        if name[0:1] == "*":
            return name[2:]
    return ""
