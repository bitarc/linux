import os
import sys

def smart_rename_files_auto(root_directory):
    """
    (全自动版 - 跳过所有.py文件)
    遍历目录及子目录，为每个目录内的文件独立添加 "0_" 起始的数字前缀。
    - 如果文件已存在 "数字_" 格式的前缀，会先移除旧前缀再添加新前缀。
    - 自动跳过所有以 ".py" 结尾的 Python 脚本文件。
    """
    # 将 '.' 转换为绝对路径，以便打印更清晰的日志
    abs_root = os.path.abspath(root_directory)
    print(f"开始处理根目录： {abs_root}\n")

    for dirpath, dirnames, filenames in os.walk(root_directory):
        counter = 1
        
        print(f"--- 正在处理文件夹: {dirpath} ---")

        if not filenames:
            print("  此文件夹中没有文件可处理。")
            continue

        filenames.sort()

        for filename in filenames:
            # --- 核心改动：检查文件名是否以 .py 结尾 ---
            if filename.endswith(".py"):
                print(f"  跳过 Python 脚本: '{filename}'")
                continue  # 跳过这个文件，继续处理下一个
            # -----------------------------------------

            base_filename = filename
            
            try:
                prefix, rest_of_name = filename.split('_', 1)
                if prefix.isdigit():
                    print(f"  检测到旧前缀 '{prefix}_'，将从 '{filename}' 中移除。")
                    base_filename = rest_of_name
            except ValueError:
                pass

            old_file_path = os.path.join(dirpath, filename)
            new_filename = f"{counter}_{base_filename}"
            new_file_path = os.path.join(dirpath, new_filename)

            if old_file_path != new_file_path:
                try:
                    os.rename(old_file_path, new_file_path)
                    print(f"  已重命名: '{filename}' -> '{new_filename}'")
                except OSError as e:
                    print(f"  错误：重命名文件 '{filename}' 时出错: {e}")
            else:
                print(f"  文件名 '{filename}' 无需更改。")
            
            counter += 1

    print("\n处理完成！")


if __name__ == "__main__":
    # --- 全自动版使用说明 ---
    # 1. 将此脚本保存为任何 .py 文件 (例如 rename_files.py)。
    # 2. 将此脚本文件【直接放入你想要整理的文件夹】中。
    # 3. 运行此脚本。
    # 4. 脚本将【立即、无提示地】开始重命名该文件夹内除 .py 文件外的所有文件。

    # 设定要处理的目录为当前脚本所在的目录 ('.')
    directory_to_process = "."

    # 直接调用主函数，不再需要传递脚本名，因为它会跳过所有 .py 文件
    smart_rename_files_auto(directory_to_process)