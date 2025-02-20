# -*- coding: utf-8 -*-
# pip3 install semver

"""
新版本打包自动化
"""

import argparse
import plib.environment as env
from plib.publish import run


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="One-key release packet product helper."
    )
    args = parser.parse_args()

    env.set_packet_as_cwd()

    run("build")
