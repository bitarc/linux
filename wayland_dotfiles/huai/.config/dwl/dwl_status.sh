#!/bin/bash

# --- 配置 (Configuration) ---
# 将图标定义为变量，方便统一修改和管理
ICON_ARCH="󰣇"
ICON_MUSIC="♫"
ICON_TEMP=""
ICON_CPU=""
ICON_MEM=""
ICON_VOL=""
ICON_NET_DOWN=""
ICON_NET_UP=""
ICON_TIME="󰃰"

# --- 初始化 (Initialization) ---
# 只执行一次的系统信息获取
ARCH=$(uname -r | cut -d'-' -f1)
INTERFACE=$(ip route | awk '/default/ {print $5; exit}')

# 网络文件路径
NET_RX_FILE="/sys/class/net/$INTERFACE/statistics/rx_bytes"
NET_TX_FILE="/sys/class/net/$INTERFACE/statistics/tx_bytes"

# 初始化网络速度计算变量 (如果接口存在且文件可读)
if [[ -n "$INTERFACE" && -r "$NET_RX_FILE" && -r "$NET_TX_FILE" ]]; then
    RX1=$(<"$NET_RX_FILE")
    TX1=$(<"$NET_TX_FILE")
fi

# 初始化CPU使用率计算变量
read -r CPU_PREV_TOTAL CPU_PREV_IDLE < <(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat)


# --- 函数定义 (Functions) ---
# 将每个信息块封装成独立的函数，提高可读性和可维护性

update_cpu() {
    local cpu_total cpu_idle total_diff idle_diff usage
    # 读取当前CPU时间
    read -r cpu_total cpu_idle < <(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat)

    # 计算差值
    total_diff=$((cpu_total - CPU_PREV_TOTAL))
    idle_diff=$((cpu_idle - CPU_PREV_IDLE))

    # 计算使用率
    if (( total_diff > 0 )); then
        usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))
    else
        usage=0
    fi
    
    # 更新上一次的值
    CPU_PREV_TOTAL=$cpu_total
    CPU_PREV_IDLE=$cpu_idle

    printf "%02d%%" "$usage"
}

update_mem() {
    # 使用单个 awk 进程处理 /proc/meminfo，更高效
    awk '/^MemTotal:/ {total=$2/1024} /^MemAvailable:/ {avail=$2/1024} END {printf "%d/%dMB", (total-avail), total}' /proc/meminfo
}

update_temp() {
    local temp
    # 增加对命令失败的健壮性处理
    temp=$(sensors 2>/dev/null | awk '/Core 0|Package id 0|CPU/ {for(i=1;i<=NF;i++) if($i~/\+[0-9]+\.[0-9]+°C/) {gsub(/\+|°C/,"",$i); printf "%.0f°C",$i; exit}}')
    echo "${temp:-N/A}" # 如果 temp 为空，则输出 N/A
}

update_volume() {
    local vol
    # pactl 可能会失败，提供默认值
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F'/' '/Volume:/ {gsub(/%| /,""); print $2; exit}')
    printf "%02d%%" "${vol:-0}"
}

update_music() {
    local music
    music=$(mpc current 2>/dev/null | cut -d'-' -f2 | sed 's/^ *//') # 使用 cut 和 sed 更清晰
    echo "[${music:-Stopped}]" # 如果为空，显示 Stopped
}

update_ime() {
    case $(fcitx5-remote 2>/dev/null) in
        2) echo "CN" ;;
        1) echo "EN" ;;
        *) echo "??" ;; # 未知状态
    esac
}

update_net() {
    # 检查网络是否初始化成功
    if [[ -z "$RX1" ]]; then
        echo "N/A"
        return
    fi

    # 定义局部变量
    local RX2 TX2 RX_DIFF TX_SPEED RX_SPEED
    
    # 读取当前的网络字节数
    RX2=$(<"$NET_RX_FILE")
    TX2=$(<"$NET_TX_FILE")

    # 计算自上次检查以来的字节差值 (Bytes/Second)
    RX_DIFF=$((RX2 - RX1))
    TX_DIFF=$((TX2 - TX1))

    # --- 核心修改在这里 ---
    # 将 Bytes/sec 转换为整数 Mbps
    # 公式: (Bytes * 8 bits/Byte) / 1,000,000 bits/Megabit
    # Shell 的整数除法会自动去掉浮点数部分
    RX_SPEED=$(( (RX_DIFF * 8) / 1000000 ))
    TX_SPEED=$(( (TX_DIFF * 8) / 1000000 ))

    # 更新旧值，为下一次计算做准备
    RX1=$RX2
    TX1=$TX2

    # 输出最终格式化的字符串，单位为 Mbps
    # 使用 %d 来格式化整数
    printf "%s %dMbps %s %dMbps" "$ICON_NET_DOWN" "$RX_SPEED" "$ICON_NET_UP" "$TX_SPEED"
}

# --- 主循环 (Main Loop) ---
# 移除了 exec 1> >(stdbuf -oL cat)，它通常不是必需的
while true; do
    # 调用函数获取所有状态
    cpu_status=$(update_cpu)
    mem_status=$(update_mem)
    temp_status=$(update_temp)
    vol_status=$(update_volume)
    music_status=$(update_music)
    ime_status=$(update_ime)
    net_status=$(update_net)
    time_status=$(date "+%a %b %d %H:%M")

    # 组合最终的输出字符串
    # 使用 printf 格式化字符串，比一长串变量拼接更清晰
    printf "%s %s|%s %s|%s %s|%s %s|%s %s|%s %s|%s|%s %s|%s\n" \
        "$ICON_ARCH" "$ARCH" \
        "$ICON_MUSIC" "$music_status" \
        "$ICON_TEMP" "$temp_status" \
        "$ICON_CPU" "$cpu_status" \
        "$ICON_MEM" "$mem_status" \
        "$ICON_VOL" "$vol_status" \
        "$net_status" \
        "$ICON_TIME" "$time_status" \
        "$ime_status"

    sleep 1
done