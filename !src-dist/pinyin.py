# -*- coding: utf-8 -*-
# https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt

"""
该脚本用于从指定的在线资源下载汉字拼音数据，
并将其加工后保存为 Lua 数据文件。
支持有声调与无声调两种格式，并且对简体（zh-CN）与繁体（zh-TW）均可转换。

主要步骤：
1. 下载最新的拼音数据文件。
2. 利用正则表达式提取每行的Unicode编码、拼音和汉字。
3. 根据需求进行无声调或加全角字母的处理。
4. 按指定编码将汉字和拼音转换为十六进制数据并写入Lua脚本。

使用类型注解帮助保证数据类型正确，便于维护和阅读。
"""

import codecs
import os
import re
import requests
from typing import Dict, List
from plib.language.converter import Converter  # 假定该模块存在，负责简繁体转换

# 定义声调字符到无声调字符的映射
TONE_TO_TONELESS: Dict[str, str] = {
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

# 定义无声调字母到全角字符的映射（全角字符）
TONELESS_TO_TONE: Dict[str, str] = {
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


def __remove_pinyin_tone(s: str) -> str:
    """
    将拼音中的带声调字符转换为无声调字符。

    参数：
        s: 包含声调的拼音字符串。
    返回：
        转换后的无声调拼音字符串。
    """
    for k, v in TONE_TO_TONELESS.items():
        s = s.replace(k, v)
    return s


def __add_pinyin_tone(s: str) -> str:
    """
    将拼音中的无声调字母转换为全角字符（用于标识原始带声调数据）。

    参数：
        s: 不含声调的拼音字符串。
    返回：
        全角字符处理后的拼音字符串。
    """
    for k, v in TONELESS_TO_TONE.items():
        s = s.replace(k, v)
    return s


def __update_pinyin(file_path: str) -> None:
    """
    从GitHub上下载最新拼音数据文件并保存到指定路径。

    参数：
        file_path: 本地保存数据的文件路径。
    """
    url: str = (
        "https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt"
    )
    response = requests.get(url, allow_redirects=True)
    response.raise_for_status()  # 若请求失败则引发异常
    with open(file_path, "wb") as f:
        f.write(response.content)


def __load_pinyin(
    src_file: str, remove_tone: bool = False, dest_lang: str = "zh-CN"
) -> Dict[str, List[str]]:
    """
    载入拼音数据文件，并根据需要进行转换处理。

    参数：
        src_file: 源拼音数据文件的路径。
        remove_tone: 如果为True，则移除拼音中的声调。
        dest_lang: 目标语言代码，用于简繁转换，如'zh-CN'或'zh-TW'。
    返回：
        一个字典，键为汉字，值为对应的拼音列表。
    """
    pinyin: Dict[str, List[str]] = {}
    converter = Converter(dest_lang) if dest_lang else None

    # 按行读取文件内容（utf8编码）
    with codecs.open(src_file, "r", encoding="utf8") as f:
        for line in f:
            # 如果需要进行简繁体转换
            if converter:
                line = converter.convert(line)
            # 使用正则表达式匹配行格式：U+XXXX: 拼音  # 汉字
            m = re.match(r"^U\+([0-9A-F]+)\:\s([^\s]*?)\s\s\#\s(.*?)$", line)
            if m:
                code_val, py_raw, char = m.groups()
                try:
                    # 根据需求选择是否移除声调或做全角处理
                    py: str = (
                        __remove_pinyin_tone(py_raw)
                        if remove_tone
                        else __add_pinyin_tone(py_raw)
                    )
                    # 检查汉字是否能被编码为gbk，若不能则跳过
                    char.encode(encoding="gbk", errors="strict")
                    py_list: List[str] = []
                    for s in py.split(","):
                        if remove_tone and not re.match("^[a-z]+$", s):
                            print("ERROR: " + s)
                        if s not in py_list:
                            py_list.append(s)
                    pinyin[char] = py_list
                except Exception as e:
                    # 出现异常时忽略该行，并打印日志信息
                    print(f"加载拼音时发生异常：{e}, 行内容：{line.strip()}")
                    continue
    return pinyin


def __save_pinyin(
    dst_file: str, pinyin: Dict[str, List[str]], encoding: str = "gbk"
) -> None:
    """
    将处理好的拼音数据转换为Lua可用格式文件。

    参数：
        dst_file: 保存Lua文件的目标路径。
        pinyin: 处理好的汉字->拼音列表字典。
        encoding: 保存文件时使用的编码，如"gbk"或"utf8"。
    """
    with codecs.open(dst_file, "w", encoding=encoding) as f:
        f.write("return function(string)\n")
        f.write("\tlocal char = string.char\n")
        f.write("\treturn {\n")

        # 遍历字典，对每个汉字及其对应的拼音进行处理
        for char, py_list in pinyin.items():
            try:
                # 尝试将汉字编码为指定编码
                encoded_char: bytes = char.encode(encoding)
                encoded_py_list: List[bytes] = []
                failed_py_list: List[str] = []
                for s in py_list:
                    try:
                        encoded_py_list.append(s.encode(encoding))
                    except UnicodeEncodeError:
                        encoded_py_list.append(b"")
                        failed_py_list.append(s)
                        continue
            except UnicodeEncodeError:
                py_joined = ",".join(py_list)
                print(
                    f"WARNING: 汉字 {char} 的拼音 {py_joined} 无法用 {encoding} 编码，跳过。"
                )
                continue

            if failed_py_list:
                py_joined = ",".join(py_list)
                failed_joined = ",".join(failed_py_list)
                print(
                    f"WARNING: 汉字 {char} 的拼音中以下项无法编码 {encoding}: {failed_joined}。（全拼：{py_joined}）"
                )

            # 将编码结果转换为Lua所需的十六进制字符串格式
            hex_char = ", ".join(f"0x{byte:02x}" for byte in encoded_char)
            f.write(f"\t\t[char({hex_char})] = {{ -- {char}\n")

            for idx, encoded_py in enumerate(encoded_py_list):
                if not encoded_py:
                    continue
                hex_py = ", ".join(f"0x{byte:02x}" for byte in encoded_py)
                f.write(f"\t\t\tchar({hex_py}), -- {py_list[idx]}\n")

            f.write("\t\t},\n")

        f.write("\t}\n")
        f.write("end\n")


def main() -> None:
    """
    程序入口，依次更新拼音数据并生成对应的Lua数据文件。
    """
    # 当前脚本所在路径的上两级目录名称作为包名称
    packet_name: str = os.path.basename(
        os.path.abspath(os.path.join(__file__, "..", ".."))
    )
    # 源拼音数据文件路径（data子目录下）
    src_file: str = os.path.abspath(os.path.join(__file__, "..", "data", "pinyin.txt"))

    # 下载最新拼音数据到src_file
    __update_pinyin(src_file)

    # 保存gbk编码下：无声调与带声调两种格式（简体中文）
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                f"{packet_name}_Resource/data/pinyin/toneless.zhcn.jx3dat",
            )
        ),
        __load_pinyin(src_file, remove_tone=True),
        encoding="gbk",
    )
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                f"{packet_name}_Resource/data/pinyin/tone.zhcn.jx3dat",
            )
        ),
        __load_pinyin(src_file, remove_tone=False),
        encoding="gbk",
    )

    # 保存utf8编码下：无声调与带声调两种格式（繁体中文）
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                f"{packet_name}_Resource/data/pinyin/toneless.zhtw.jx3dat",
            )
        ),
        __load_pinyin(src_file, remove_tone=True, dest_lang="zh-TW"),
        encoding="utf8",
    )
    __save_pinyin(
        os.path.abspath(
            os.path.join(
                __file__,
                "..",
                "..",
                f"{packet_name}_Resource/data/pinyin/tone.zhtw.jx3dat",
            )
        ),
        __load_pinyin(src_file, remove_tone=False, dest_lang="zh-TW"),
        encoding="utf8",
    )


if __name__ == "__main__":
    main()
