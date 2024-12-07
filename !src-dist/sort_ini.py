import sys
import os


def sort_lines(lines):
    # 根据特定顺序处理 lines，确保 _WndType 和 _Parent 的行在开头
    fixed_order = [
        line
        for line in lines
        if line.startswith("._WndType=") or line.startswith("._Parent=")
    ]
    # 过滤出其他行并排序
    other_lines = [line for line in lines if line not in fixed_order and line.strip()]
    other_lines.sort(key=lambda s: s.strip().lower())
    # 合并结果，留下空行在末尾
    return fixed_order + other_lines + [line for line in lines if not line.strip()]


def sort_ini_file(file_path):
    # 读取整个文件内容
    with open(file_path, "r", encoding="gbk") as f:
        lines = f.readlines()

    sorted_lines = []
    current_section_lines = []
    section_header = None
    inter_section_newlines = []  # 用于存储节之间的空行

    for line in lines:
        # 移除首尾空白字符以处理
        stripped_line = line.strip()

        # 检查是否为节标题
        if stripped_line.startswith("[") and stripped_line.endswith("]"):
            # 处理先前的节（如果有）
            if section_header:
                # 对当前节的行进行排序并保存
                sorted_section_lines = sort_lines(current_section_lines)
                sorted_lines.append(section_header)
                sorted_lines.extend(sorted_section_lines)

            # 添加节间空行
            sorted_lines.extend(inter_section_newlines)
            inter_section_newlines = []

            # 更新当前节
            section_header = line
            current_section_lines = []

        elif section_header:
            # 在一个节内部，直接加入行
            current_section_lines.append(line)

        else:
            # 节之间的空行
            inter_section_newlines.append(line)

    # 对最后一个节进行排序
    if section_header:
        sorted_section_lines = sort_lines(current_section_lines)
        sorted_lines.append(section_header)
        sorted_lines.extend(sorted_section_lines)

    # 将排序后的内容写回文件
    with open(file_path, "w", encoding="gbk") as f:
        f.writelines(sorted_lines)


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
