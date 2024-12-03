import sys
import os
import configparser


def sort_ini_file(file_path):
    # 使用 ConfigParser 读取 ini 文件
    config = configparser.ConfigParser(
        allow_no_value=True, delimiters=("="), strict=False
    )

    # 用于维护读取项的顺序
    config.optionxform = str

    # 读取 ini 文件，指定编码为 GBK
    with open(file_path, "r", encoding="gbk") as f:
        config.read_file(f)

    # 对每个节进行排序
    sorted_sections = []
    for section in config.sections():
        items = config.items(section)

        # 特殊处理 _WndType 和 _Parent
        fixed_items = [item for item in items if item[0] in ("._WndType", "._Parent")]
        other_items = sorted(
            item for item in items if item[0] not in ("._WndType", "._Parent")
        )

        # 将固定项和排序过的其他项合并
        sorted_items = fixed_items + other_items
        sorted_sections.append((section, sorted_items))

    # 将排序结果写回文件
    with open(file_path, "w", encoding="gbk") as f:
        for section, items in sorted_sections:
            f.write(f"[{section}]\n")
            for key, value in items:
                if value is None:
                    f.write(f"{key}=\n")
                else:
                    f.write(f"{key}={value}\n")
            f.write("\n")


def process_directory(directory):
    # 遍历目录，寻找所有符合条件的 .ini 文件并进行排序
    for root, _, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(".ini") and file[0].isupper():
                file_path = os.path.join(root, file)
                sort_ini_file(file_path)
                print(f"Sorted: {file_path}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: drag a .ini file or a directory onto this script.")
    else:
        path = sys.argv[1]
        if os.path.isfile(path):
            if path.lower().endswith(".ini") and os.path.basename(path)[0].isupper():
                sort_ini_file(path)
                print(f"Sorted: {path}")
            else:
                print("The file is not an ini file with a capitalized filename.")
        elif os.path.isdir(path):
            process_directory(path)
        else:
            print("Invalid path.")
