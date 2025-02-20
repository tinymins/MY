if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.cmd import run_as_admin

    # 示例：以管理员身份运行命令 "calc.exe"
    run_as_admin("calc.exe")

if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.environment import (
        get_interface_path,
        get_packet_path,
        set_packet_as_cwd,
        get_current_packet_id,
        get_packet_dist_path,
    )
    import os

    print("当前插件根目录路径:", get_interface_path())
    print("默认插件集路径:", get_packet_path())
    try:
        set_packet_as_cwd()
        print("当前工作目录已设置为插件集目录:", os.getcwd())
    except Exception as e:
        print("设置工作目录失败:", e)
    print("插件集标识:", get_current_packet_id())
    print("插件集构建结果目标目录:", get_packet_dist_path())

if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.git import is_clean, get_current_branch, get_head_time_tag

    print("Git 工作区是否干净：", is_clean())
    print("当前分支：", get_current_branch())
    print("提交时间标签：", get_head_time_tag())

if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.publish import run

    # 示例：执行打包
    run("build", None)


if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.require import require

    # 示例：尝试导入 requests 模块并打印其版本号
    module_requests = require("requests")
    try:
        version = getattr(module_requests, "__version__", "未知版本")
    except Exception:
        version = "未知版本"
    print(f"requests 模块版本：{version}")

if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.time import sync_ntp_time

    # 示例：执行时间同步操作
    sync_ntp_time()

if __name__ == "__main__":
    # 测试各个函数的功能
    from plib.utils import get_file_crc

    # 示例：通过命令行参数调用 CRC32 计算函数
    file = "__test__.py"
    crc_result: str = get_file_crc(file)
    print(f"文件 {file} 的 CRC32 校验值为: {crc_result}")
