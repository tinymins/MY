# -*- coding: utf-8 -*-

import codecs
import os
import re
import requests
import luadata

# https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt

TONG_MAP = {
    "ā": "a",
    "á": "a",
    "ǎ": "a",
    "à": "a",
    "ō": "o",
    "ó": "o",
    "ǒ": "o",
    "ò": "o",
    "ê": "e",
    "ē": "e",
    "ē": "e",
    "é": "e",
    "ě": "e",
    "ě": "e",
    "è": "e",
    "ế": "e",
    "ê̌": "e",
    "ề": "e",
    "ê̄": "e",
    "ī": "i",
    "í": "i",
    "ǐ": "i",
    "ì": "i",
    "ū": "u",
    "ú": "u",
    "ǔ": "u",
    "ù": "u",
    "ǖ": "v",
    "ǘ": "v",
    "ǚ": "v",
    "ǜ": "v",
    "ü": "v",
    "m̄": "m",
    "ḿ": "m",
    "m̀": "m",
    "ń": "n",
    "ň": "n",
    "ǹ": "n",
}


def __remove_pinyin_tone(s):
    for k in TONG_MAP:
        s = s.replace(k, TONG_MAP[k])
    return s


def __update_pinyin(file):
    url = "https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt"
    r = requests.get(url, allow_redirects=True)
    open(file, "wb").write(r.content)


def __load_pinyin(src_file):
    pinyin = {}
    for _, line in enumerate(codecs.open(src_file, "r", encoding="utf8")):
        z = re.match(r"^U\+([0-9A-F]+)\:\s([^\s]*?)\s\s\#\s(.*?)$", line)
        if z:
            g = z.groups()
            try:
                g[2].encode(encoding="gbk", errors="strict")
                ss = []
                for s in __remove_pinyin_tone(g[1]).split(","):
                    if not re.match("^[a-z]+$", s):
                        print("ERROR: " + s)
                    if s not in ss:
                        ss.append(s)
                pinyin[g[2]] = ss
            except:
                pass
    return pinyin


def __save_pinyin(dst_file, pinyin):
    luadata.write(dst_file, pinyin, encoding="gbk")


if __name__ == "__main__":
    packet_name = os.path.basename(
        os.path.abspath(os.path.join(__file__, "..", "..", "..", ".."))
    )
    src_file = os.path.abspath(os.path.join(__file__, "..", "pinyin.txt"))
    __update_pinyin(src_file)
    pinyin = __load_pinyin(src_file)
    dst_file = os.path.abspath(
        os.path.join(
            __file__,
            "..",
            "..",
            "..",
            "..",
            packet_name + "_!Base/data/pinyin/zhcn.jx3dat",
        )
    )
    __save_pinyin(dst_file, pinyin)
