#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import argparse
import sys

# --- 配置区 ---

# 1. 定义要查找的视频文件扩展名 (可以根据需要添加或删除)
#    使用小写形式，脚本会自动忽略大小写
VIDEO_EXTENSIONS = ('.mp4', '.mkv', '.avi', 'mov', '.flv', '.wmv')

# 2. FFmpeg 参数配置
#    您可以在这里修改 CRF, cpu-used, 音频码率等参数
FFMPEG_PARAMS = [
    '-c:v', 'libvpx-vp9',
    '-crf', '31',
    '-b:v', '0',
    '-cpu-used', '4',
    '-c:a', 'libopus',
    '-b:a', '192k'
]
# --- 配置区结束 ---


def convert_videos(source_dir):
    """
    遍历源目录及其子目录，查找视频文件并将其在原地转换为 .webm 格式。
    """
    print(f"[*] 开始扫描目录及其所有子目录: {source_dir}")
    print("-" * 50)

    # os.walk 会遍历指定目录下的所有文件夹和文件
    for root, dirs, files in os.walk(source_dir):
        for filename in files:
            # 检查文件扩展名是否在我们的目标列表中
            if filename.lower().endswith(VIDEO_EXTENSIONS):
                input_path = os.path.join(root, filename)

                # --- 构建输出路径，与源文件在同一目录 ---
                base, ext = os.path.splitext(input_path)
                output_path = base + '.webm'
                
                # --- 检查输出文件是否已存在，如果存在则跳过 ---
                if os.path.exists(output_path):
                    print(f"[i] 跳过: 输出文件已存在 {output_path}")
                    print("-" * 50)
                    continue

                print(f"[+] 正在处理: {input_path}")
                print(f"    -> 输出到: {output_path}")

                # --- 构建并执行 ffmpeg 命令 ---
                # 将命令构建为一个列表，可以完美处理文件名中的空格和特殊字符
                command = [
                    'ffmpeg',
                    '-i', input_path,
                    *FFMPEG_PARAMS,
                    output_path
                ]

                try:
                    # 使用 subprocess.run 执行命令
                    result = subprocess.run(
                        command, 
                        check=True, 
                        capture_output=True, 
                        text=True, 
                        encoding='utf-8'
                    )
                    print(f"[✔] 成功: {filename}")

                except subprocess.CalledProcessError as e:
                    print(f"[!] 失败: {filename}", file=sys.stderr)
                    print(f"    错误信息: {e.stderr}", file=sys.stderr)
                except FileNotFoundError:
                    print("[!] 错误: ffmpeg 命令未找到。", file=sys.stderr)
                    print("    请确保 ffmpeg 已安装并已添加到系统的 PATH 环境变量中。", file=sys.stderr)
                    sys.exit(1)
                except Exception as e:
                    print(f"[!] 发生未知错误: {e}", file=sys.stderr)

                print("-" * 50)


def main():
    """
    主函数，用于解析命令行参数。
    """
    parser = argparse.ArgumentParser(
        description="批量将视频文件使用 ffmpeg 转换为 VP9/Opus 的 WebM 格式，并保存在源文件相同的目录中。",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "source_dir",
        help="包含源视频文件的根目录，脚本将遍历此目录及其所有子目录。"
    )
    
    args = parser.parse_args()

    # 确保源目录存在
    if not os.path.isdir(args.source_dir):
        print(f"错误: 目录 '{args.source_dir}' 不存在或不是一个目录。", file=sys.stderr)
        sys.exit(1)
        
    convert_videos(args.source_dir)
    print("[*] 所有任务处理完毕。")


if __name__ == '__main__':
    main()
