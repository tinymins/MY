# -*- coding: utf-8 -*-
# https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt

import codecs
import os
import re
import requests
from plib.language.converter import Converter

TONE_TO_TONELESS = {
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
TONELESS_TO_TONE = {
    "a": "ａ",
    "b": "ｂ",
    "c": "ｃ",
    "d": "ｄ",
    "e": "ｅ",
    "f": "ｆ",
    "g": "ｇ",
    "h": "ｈ",
    "i": "ｉ",
    "j": "ｊ",
    "k": "ｋ",
    "l": "ｌ",
    "m": "ｍ",
    "n": "ｎ",
    "o": "ｏ",
    "p": "ｐ",
    "q": "ｑ",
    "r": "ｒ",
    "s": "ｓ",
    "t": "ｔ",
    "u": "ｕ",
    "v": "ｖ",
    "w": "ｗ",
    "x": "ｘ",
    "y": "ｙ",
    "z": "ｚ",
}


def __remove_pinyin_tone(s):
    for k in TONE_TO_TONELESS:
        s = s.replace(k, TONE_TO_TONELESS[k])
    return s


def __add_pinyin_tone(s):
    for k in TONELESS_TO_TONE:
        s = s.replace(k, TONELESS_TO_TONE[k])
    return s


def __update_pinyin(file):
    url = "https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt"
    r = requests.get(url, allow_redirects=True)
    open(file, "wb").write(r.content)


def __load_pinyin(src_file, remove_tone=False, dest_lang="zh-CN"):
    pinyin = {}
    converter = None
    if dest_lang:
        converter = Converter(dest_lang)
    for _, line in enumerate(codecs.open(src_file, "r", encoding="utf8")):
        if converter:
            line = converter.convert(line)
        z = re.match(r"^U\+([0-9A-F]+)\:\s([^\s]*?)\s\s\#\s(.*?)$", line)
        if z:
            g = z.groups()
            try:
                py = g[1]
                char = g[2]
                if remove_tone:
                    py = __remove_pinyin_tone(py)
                else:
                    py = __add_pinyin_tone(py)
                char.encode(encoding="gbk", errors="strict")
                py_list = []
                for s in py.split(","):
                    if remove_tone and not re.match("^[a-z]+$", s):
                        print("ERROR: " + s)
                    if s not in py_list:
                        py_list.append(s)
                pinyin[char] = py_list
            except:
                pass
    return pinyin


def __save_pinyin(dst_file, pinyin, encoding="gbk"):
    with codecs.open(dst_file, "w", encoding=encoding) as file:
        file.write("return function(string)\n")
        file.write("\tlocal char = string.char\n")
        file.write("\treturn {\n")

        # 遍历字典，转换每个汉字及其对应的拼音
        for char, py_list in pinyin.items():
            # 取第一个拼音作为代表（如果有多个拼音）
            try:
                # 将汉字编码为指定编码
                encoded_char = char.encode(encoding)
                encoded_py_list = []
                failed_py_list = []
                for s in py_list:
                    try:
                        encoded_py_list.append(s.encode(encoding))
                    except UnicodeEncodeError:
                        encoded_py_list.append(None)
                        failed_py_list.append(s)
                        continue
            except UnicodeEncodeError:
                py = ",".join(py_list)
                print(
                    f"WARNING: Character {char} of {char}:{py} cannot be encoded in {encoding}."
                )
                continue

            if len(failed_py_list) > 0:
                py = ",".join(py_list)
                failed_py = ",".join(failed_py_list)
                print(
                    f"WARNING: Character {failed_py} of {char}:{py} cannot be encoded in {encoding}."
                )

            # 转换指定编码为十六进制，并格式化为Lua所需的形式
            hex_char = ", ".join(f"0x{byte:02x}" for byte in encoded_char)
            file.write(f"\t\t[char({hex_char})] = {{ -- {char}\n")

            for index, encoded_py in enumerate(encoded_py_list):
                if encoded_py is None:
                    continue
                hex_py = ", ".join(f"0x{byte:02x}" for byte in encoded_py)
                file.write(f"\t\t\tchar({hex_py}), -- {py_list[index]}\n")

            file.write("\t\t},\n")

        file.write("\t}\n")
        file.write("end\n")


if __name__ == "__main__":
    packet_name = os.path.basename(os.path.abspath(os.path.join(__file__, "..", "..")))
    src_file = os.path.abspath(os.path.join(__file__, "..", "data", "pinyin.txt"))
    __update_pinyin(src_file)
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                packet_name + "_!Base/data/pinyin/zhcn.toneless.jx3dat",
            )
        ),
        __load_pinyin(src_file, True),
        "gbk",
    )
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                packet_name + "_!Base/data/pinyin/zhcn.tone.jx3dat",
            )
        ),
        __load_pinyin(src_file, False),
        "gbk",
    )
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                packet_name + "_!Base/data/pinyin/zhtw.toneless.jx3dat",
            )
        ),
        __load_pinyin(src_file, True, "zh-TW"),
        "utf8",
    )
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                packet_name + "_!Base/data/pinyin/zhtw.tone.jx3dat",
            )
        ),
        __load_pinyin(src_file, False, "zh-TW"),
        "utf8",
    )
