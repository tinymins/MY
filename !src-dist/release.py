# -*- coding: utf-8 -*-
# pip3 install ntplib pypiwin32 semver

"""
版本标签创建自动化
"""

import argparse
import codecs
import datetime
import os
import re
import semver
import time

import plib.utils as utils
import plib.git as git
import plib.environment as env
from plib.time import set_system_time, sync_ntp_time


def __get_release_commit_list():
    commit_list = []
    for commit in (
        os.popen('git log --grep release: --pretty=format:"%h|%at|%s"')
        .read()
        .split("\n")
    ):
        try:
            hash = re.sub(r"(?is)\|.+$", "", commit).strip()
            timestamp = int(
                re.sub(r"(?is)\|.+$", "", re.sub(r"(?is)^\w+\|", "", commit)).strip()
            )
            version = re.sub(r"(?is)^\w+\|\w+\|release:\s+", "", commit).strip()
            commit_list.append(
                {"version": version, "hash": hash, "timestamp": timestamp}
            )
        except:
            pass
    return commit_list


def __get_release_tag_list():
    tag_list = []
    for tag in os.popen("git tag -l").read().split("\n"):
        try:
            if tag[0:1] == "v":
                version = tag[1:]
                if semver.compare(version, "0.0.0") == 1:
                    tag_list.append({"version": version, "name": tag})
        except:
            pass
    return tag_list


def __get_changelog_list():
    info = None
    changelog_list = []
    for _, line in enumerate(codecs.open("CHANGELOG.md", "r", encoding="utf8")):
        try:
            if len(line) == 0:
                continue
            if line[0:1] != "*" and line[0:2] != " *":
                version = re.sub(r"(?is)^.+?v", "", line).strip()
                info = {"version": version, "message": ""}
                changelog_list.insert(0, info)
            elif info is not None:
                info.update({"message": info.get("message") + line})
        except:
            pass
    return changelog_list


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Automatic release branch tags.")
    parser.add_argument(
        "--mock-time", action="store_true", help="Tagger at commit time."
    )
    parser.add_argument("--overwrite", action="store_true", help="Overwrite exist tag.")
    parser.add_argument("--dry-run", action="store_true", help="Dry run.")
    args = parser.parse_args()

    env.set_packet_as_cwd()

    utils.assert_exit(git.is_clean(), "Error: branch has uncommitted file change(s)!")

    os.system("git checkout master")
    utils.assert_exit(git.is_clean(), "Error: branch has uncommitted file change(s)!")

    os.system("git rebase stable")
    utils.assert_exit(
        git.is_clean(), "Error: resolve conflict and remove uncommitted changes first!"
    )

    print("Reading changelog and version list...")
    changelog_list = __get_changelog_list()
    tag_list = __get_release_tag_list()
    release_list = __get_release_commit_list()

    for changelog in changelog_list:
        if not args.overwrite:
            tag = None
            for p in tag_list:
                if p.get("version") == changelog.get("version"):
                    tag = p
                    break
            if tag is not None:
                continue

        release = None
        for p in release_list:
            if p.get("version") == changelog.get("version"):
                release = p
                break
        if release is None:
            continue

        if args.mock_time:
            t = datetime.datetime.fromtimestamp(release.get("timestamp"))
            print(
                "Changing time to %d-%d-%d %d:%d:%d"
                % (t.year, t.month, t.day, t.hour, t.minute, t.second)
            )

            if not args.dry_run:
                set_system_time(t.year, t.month, t.day, t.hour, t.minute, t.second)

        print(
            "Creating tag v%s on %s..."
            % (changelog.get("version"), release.get("hash"))
        )

        if not args.dry_run:
            message = "Release v%s\n%s" % (
                changelog.get("version"),
                changelog.get("message"),
            )
            with codecs.open("commit_msg.txt", "w", encoding="utf8") as f:
                f.write(message)
            os.system(
                "git tag -a v%s %s -f -F commit_msg.txt"
                % (changelog.get("version"), release.get("hash"))
            )
            os.remove("commit_msg.txt")
            os.system("git push")
            os.system("git push --tags")

        if args.mock_time:
            if not args.dry_run:
                sync_ntp_time()
            print("Idle for 5 seconds.")
            time.sleep(5)

    print("Jobs Accomplished.")
