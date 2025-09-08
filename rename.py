import os
import sys

def smart_rename_webm_files_auto(root_directory):
    """
    (全自动版 - 仅处理.webm文件)
    遍历目录及子目录，为每个目录内的 .webm 文件独立添加 "1_" 起始的数字前缀。
    - 如果文件已存在 "数字_" 格式的前缀，会先移除旧前缀再添加新前缀。
    - 自动跳过所有非 ".webm" 结尾的文件。
    """
    # 将 '.' 转换为绝对路径，以便打印更清晰的日志
    abs_root = os.path.abspath(root_directory)
    print(f"开始处理根目录： {abs_root}\n")

    for dirpath, dirnames, filenames in os.walk(root_directory):
        counter = 1
        
        print(f"--- 正在处理文件夹: {dirpath} ---")

        # 筛选出所有webm文件并排序，以便处理
        webm_files = sorted([f for f in filenames if f.lower().endswith(".webm")])

        if not webm_files:
            print("   此文件夹中没有 .webm 文件可处理。")
            # 打印出被跳过的非webm文件列表（可选，但对用户更友好）
            if filenames:
                print(f"   (跳过了 {len(filenames)} 个非webm文件)")
            continue

        # 打印出将被跳过的文件
        non_webm_files = [f for f in filenames if not f.lower().endswith(".webm")]
        for skipped_file in non_webm_files:
            print(f"   跳过非 webm 文件: '{skipped_file}'")

        # 仅处理筛选出来的webm文件
        for filename in webm_files:
            base_filename = filename
            
            try:
                prefix, rest_of_name = filename.split('_', 1)
                if prefix.isdigit():
                    print(f"   检测到旧前缀 '{prefix}_'，将从 '{filename}' 中移除。")
                    base_filename = rest_of_name
            except ValueError:
                pass

            old_file_path = os.path.join(dirpath, filename)
            new_filename = f"{counter}_{base_filename}"
            new_file_path = os.path.join(dirpath, new_filename)

            if old_file_path != new_file_path:
                try:
                    os.rename(old_file_path, new_file_path)
                    print(f"   已重命名: '{filename}' -> '{new_filename}'")
                except OSError as e:
                    print(f"   错误：重命名文件 '{filename}' 时出错: {e}")
            else:
                print(f"   文件名 '{filename}' 无需更改。")
            
            counter += 1

    print("\n处理完成！")


if __name__ == "__main__":
    # --- 全自动版使用说明 ---
    # 1. 将此脚本保存为任何 .py 文件 (例如 rename_webm.py)。
    # 2. 将此脚本文件【直接放入你想要整理的文件夹】中。
    # 3. 运行此脚本。
    # 4. 脚本将【立即、无提示地】开始重命名该文件夹内所有的 .webm 文件。

    # 设定要处理的目录为当前脚本所在的目录 ('.')
    directory_to_process = "."

    # 直接调用主函数
    smart_rename_webm_files_auto(directory_to_process)