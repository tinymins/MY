import sys
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


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: drag an ini file onto this script")
    else:
        ini_file = sys.argv[1]
        sort_ini_file(ini_file)
