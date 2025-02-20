# -*- coding: utf-8 -*-
# pip3 install semver

"""
新版本打包自动化
"""

import argparse

from plib.publish import run
import plib.environment as env

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="One-key release packet product helper."
    )
    parser.add_argument("--diff", type=str, help="Package diff version.")
    parser.add_argument("--no-build", action="store_true", help="Package source code.")
    args = parser.parse_args()

    env.set_packet_as_cwd()

    run(args.diff, args.no_build)
