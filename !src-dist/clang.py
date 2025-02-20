# -*- coding: utf-8 -*-
"""
文件名称: convert-lang.py
作者    : Emil Zhai
适用Python版本: 3.7及以上

说明:
    本脚本用于将语言文件转换为繁体中文，同时更新部分Lua脚本文件中的头部信息。

使用方法:
    pip install pyinstaller
    pyinstaller --onefile convert-lang.py
"""

import codecs
import json
import os
import re
import sys
import time
from typing import Dict, List, Any

import plib.utils as utils
import plib.environment as env
from plib.environment import get_current_packet_id
from plib.language.converter import Converter

# 文件映射字典：指定输入文件、转换后输出文件名称以及文件类型
FILE_MAPPING: Dict[str, Dict[str, str]] = {
    "zhcn.lang": {"out": "zhtw.lang", "type": "lang"},
    "zhcn.jx3dat": {"out": "zhtw.jx3dat", "type": "lang"},
    "info.ini": {"out": "info.ini.zh_TW", "type": "info"},
    "package.ini": {"out": "package.ini.zh_TW", "type": "package"},
}

# 可用正则匹配的文件映射
FILE_MAPPING_RE: List[Dict[str, str]] = [
    # {"pattern": r"(.*)\.zhcn\.jx3dat", "out": r"\1.zhtw.jx3dat", "type": "lang"},
]

# 文件夹映射
FOLDER_MAPPING: Dict[str, Dict[str, str]] = {
    # 'zhcn': { 'out': 'zhtw', 'type': 'lang' },
}

# 忽略的文件夹列表
IGNORE_FOLDER: List[str] = [".git", "@DATA"]


def __load_crc_cache(root_path: str) -> Dict[str, Any]:
    """
    加载文件CRC缓存（文件校验码）

    参数:
        root_path: 根目录路径

    返回:
        包含已保存CRC信息的字典
    """
    crcs: Dict[str, Any] = {}
    crc_dir = os.path.join(root_path, "__pycache__")
    crc_file = os.path.join(crc_dir, "file.crc.json")
    if os.path.isfile(crc_file):
        with open(crc_file, "r") as f:
            print("加载CRC缓存: " + crc_file)
            crcs = json.load(f)
    return crcs


def __save_crc_cache(root_path: str, crcs: Dict[str, Any]) -> None:
    """
    保存文件CRC缓存

    参数:
        root_path: 根目录路径
        crcs: 包含CRC信息的字典
    """
    crc_dir = os.path.join(root_path, "__pycache__")
    # 使用os.makedirs确保文件夹存在
    os.makedirs(crc_dir, exist_ok=True)
    crc_file = os.path.join(crc_dir, "file.crc.json")
    with open(crc_file, "w") as file:
        print("--------------------------------")
        file.write(json.dumps(crcs))
        print("保存CRC缓存: " + crc_file)


def __is_path_include(pkg_name: str, cwd: str, d: str) -> bool:
    """
    判断当前路径或文件夹是否需要处理。
    排除特殊文件夹或不相关的文件夹，确保只处理目标包的相关文件。

    参数:
        pkg_name: 包名称（如果有）
        cwd: 当前工作目录
        d: 待判断的目录或文件名称

    返回:
        True 表示包含并需要处理，否则返回 False
    """
    # 如果当前路径为接口路径且d为文件，则不处理
    if env.is_interface_path(cwd) and os.path.isfile(os.path.join(cwd, d)):
        return False
    # 忽略指定的文件夹
    if d in IGNORE_FOLDER:
        return False
    # 如果当前路径不为接口路径，但上级为接口路径，且指定了包名称，则仅处理对应包内的文件
    if (
        (not env.is_interface_path(cwd))
        and env.is_interface_path(os.path.dirname(cwd))
        and pkg_name != ""
    ):
        if os.path.basename(cwd) == pkg_name:
            return True
        elif os.path.exists(os.path.join(cwd, "package.ini")):
            with codecs.open(
                os.path.join(cwd, "package.ini"), "r", encoding="GBK"
            ) as f:
                content = f.read()
            return ("dependence=" + pkg_name) in content
        elif os.path.exists(os.path.join(cwd, "info.ini")):
            with codecs.open(os.path.join(cwd, "info.ini"), "r", encoding="GBK") as f:
                content = f.read()
            return ("dependence=" + pkg_name) in content
        return False
    return True


def convert_progress(argv: List[str]) -> None:
    """
    主转换流程函数。
    遍历指定目录下的文件，处理Lua脚本头部更新以及语言文件内容转换。

    参数:
        argv: 命令行参数列表（不包含脚本名称）
    """
    params: Dict[str, str] = {}
    start_time: float = time.time() * 1000  # 毫秒计时
    converter: Converter = Converter("zh-TW")
    packet: str = get_current_packet_id()

    # 接受的命令行参数及是否需要值的标记
    param_accept_arg: Dict[str, bool] = {
        "--path": True,
    }

    # 解析命令行参数，存储到params字典
    idx: int
    for idx, param in enumerate(argv):
        if param in param_accept_arg and idx < len(argv) - 1:
            params[param] = argv[idx + 1]
        else:
            # 若参数无对应的值，则置空字符串
            params[param] = ""

    # 如果未提供--path参数，则使用当前工作目录
    if "--path" not in params:
        params["--path"] = os.path.abspath(os.getcwd())

    # 获取接口根目录和包名（若存在）
    pkg_name: str = ""
    root_path: str = params["--path"]
    if (not env.is_interface_path(root_path)) and env.is_interface_path(
        os.path.dirname(root_path)
    ):
        pkg_name = os.path.basename(root_path)
        root_path = os.path.dirname(root_path)

    print("--------------------------------")
    print("工作目录: " + root_path)
    print("工作包: " + (pkg_name if pkg_name else "ALL"))
    crcs: Dict[str, Any] = (
        __load_crc_cache(root_path) if "--no-cache" not in params else {}
    )

    cpkg: str = ""
    cpkg_path: str = "?"
    header: str = f"local X = {packet}"

    # 遍历根目录下所有子目录和文件
    for cwd, dirs, files in os.walk(root_path):
        # 筛选需要处理的目录和文件
        dirs[:] = [d for d in dirs if __is_path_include(pkg_name, cwd, d)]
        files[:] = [d for d in files if __is_path_include(pkg_name, cwd, d)]

        for filename in files:
            foldername: str = os.path.basename(cwd)
            basename, extname = os.path.splitext(filename)
            filepath: str = os.path.join(cwd, filename)
            relpath: str = filepath.replace(root_path, "")
            crc_changed: bool = False

            # 处理Lua脚本文件：更新头部信息
            if (
                extname == ".lua"
                and basename not in ["Base", "LuaWatcher"]
                and (os.path.sep + "!src-dist" + os.path.sep) not in relpath
                and (os.path.sep + "dist" + os.path.sep) not in relpath
                and not (filename.startswith("src.") and filename.endswith(".lua"))
            ):

                print("--------------------------------")
                print("更新Lua脚本头部: " + filepath)
                crc_text: str = utils.get_file_crc(filepath)
                crc_changed = crc_text != crcs.get(relpath)
                if crc_changed:
                    original_text: str = ""
                    finalize_text: str = ""
                    has_header: bool = False
                    # 逐行读取并检查是否已存在头部标识
                    with codecs.open(filepath, "r", encoding="gbk") as f:
                        for count, line in enumerate(f):
                            if line.startswith("local X = "):
                                has_header = True
                                finalize_text += f"local X = {packet}\n"
                            elif line.strip() == header:
                                has_header = True
                                original_text += line
                            else:
                                original_text += line
                    # 若未发现头部，则添加 header
                    if not has_header:
                        finalize_text = header + "\n" + original_text
                    else:
                        finalize_text = original_text

                    # 如内容有变化则写入文件
                    if original_text != finalize_text:
                        print("保存文件更新...")
                        with codecs.open(filepath, "w", encoding="gbk") as f:
                            f.write(finalize_text)
                        print("文件已更新: " + filepath)
                        crc_text = utils.get_file_crc(filepath)
                    else:
                        print("文件已是最新状态。")
                    crcs[relpath] = crc_text
                else:
                    print("文件已是最新状态。")

            # 根据文件名称或所在文件夹判断是否需要进行语言转换
            fileType: Any = None
            fileOut: Any = None
            folderOut: str = ""
            if foldername in FOLDER_MAPPING:
                info: Dict[str, str] = FOLDER_MAPPING[foldername]
                fileType = info["type"]
                folderOut = os.path.abspath(os.path.join(cwd, "..", info["out"]))
                # 对文件名进行转换（此处调用转换器的convert方法）
                fileOut = converter.convert(filename)
            elif filename in FILE_MAPPING:
                info = FILE_MAPPING[filename]
                fileType = info["type"]
                folderOut = cwd
                fileOut = info["out"]
            else:
                for p in FILE_MAPPING_RE:
                    out = re.sub(p["pattern"], p["out"], filename)
                    if out != filename:
                        fileType = p["type"]
                        folderOut = cwd
                        fileOut = out
                        break

            # 如果匹配到需要进行转换的文件，则进行处理
            if fileType and folderOut and fileOut:
                print("--------------------------------")
                print("转换语言文件: " + filepath)
                crc_text: str = utils.get_file_crc(filepath)
                if not crc_changed:
                    crc_changed = crc_text != crcs.get(relpath)
                # 若文件类型为 package，则记录包名称及路径
                if fileType == "package":
                    cpkg = cwd[cwd.rfind("\\") + 1 :]
                    cpkg_path = cwd
                if crc_changed:
                    try:
                        original_text = ""
                        # 针对语言文件，调整文件中第一行的注释（如果存在）
                        with codecs.open(filepath, "r", encoding="gbk") as f:
                            for count, line in enumerate(f):
                                if (
                                    fileType == "lang"
                                    and count == 0
                                    and line.startswith("-- language data")
                                ):
                                    original_text += line.replace("zhcn", "zhtw")
                                else:
                                    original_text += line
                        print("开始转换文件内容...")
                        # 若info类型文件缺少 package 字段，则自动添加
                        if (
                            fileType == "info"
                            and cwd.startswith(cpkg_path)
                            and "package=" not in original_text
                        ):
                            original_text = (
                                original_text.rstrip() + "\npackage=" + cpkg + "\n"
                            )
                            with codecs.open(filepath, "w", encoding="gbk") as f:
                                f.write(original_text)
                            print("已添加package字段到文件: " + filepath)
                            crc_text = utils.get_file_crc(filepath)
                        # 使用转换器转换文件内容
                        converted_text: str = converter.convert(original_text)
                        print("保存转换后的文件...")
                        # 确保输出文件夹存在
                        os.makedirs(folderOut, exist_ok=True)
                        output_file: str = os.path.join(folderOut, fileOut)
                        with codecs.open(output_file, "w", encoding="utf8") as f:
                            f.write(converted_text)
                        print("文件已保存: " + output_file)
                        crcs[relpath] = crc_text
                    except Exception as e:
                        # 若出现异常，则将异常信息存入校验缓存，避免重复尝试转换
                        crcs[relpath] = str(e)
                        print("转换文件时出现错误: " + str(e))
                else:
                    print("文件已是最新状态。")

    # 最后保存CRC缓存（除非设置了 --no-cache 参数）
    if "--no-cache" not in params:
        __save_crc_cache(root_path, crcs)

    print("--------------------------------")
    elapsed: float = time.time() * 1000 - start_time
    print(f"处理完成，共耗时 {int(elapsed)} ms.")
    print("--------------------------------")

    # 若未设置 --no-pause 参数，则暂停10秒以便查看信息
    if "--no-pause" not in params:
        time.sleep(10)


if __name__ == "__main__":
    # 根据环境设置接口包目录
    env.set_packet_as_cwd()
    # 尝试获取命令行参数（若未定义则从 sys.argv 获取）
    try:
        argv: List[str] = sys.argv[1:]
    except NameError:
        argv = []
    convert_progress(argv)
