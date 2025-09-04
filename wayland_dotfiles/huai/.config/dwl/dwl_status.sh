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

# 初始化网络速度计算的全局变量
if [[ -n "$INTERFACE" && -r "$NET_RX_FILE" && -r "$NET_TX_FILE" ]]; then
    RX1=$(<"$NET_RX_FILE")
    TX1=$(<"$NET_TX_FILE")
fi
# 全局变量，用于存储网络状态的最终字符串
NET_STATUS_STR=""
# 初始化CPU使用率计算的全局变量
read prev_cpu prev_idle <<< $(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5; exit}' /proc/stat)

# --- 【新增】为 CPU 状态创建一个全局变量 ---
CPU_STATUS=""

# --- 函数定义 (Functions) ---

# --- 【已修改】CPU 更新函数 ---
update_cpu() {
    # 读取当前的 CPU 时间
    read curr_cpu curr_idle <<< $(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5; exit}' /proc/stat)

    # 计算自上次检查以来的时间差
    total_diff=$((curr_cpu - prev_cpu))
    idle_diff=$((curr_idle - prev_idle))

    # 计算使用率
    if (( total_diff > 0 )); then
        usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))
    else
        usage=0
    fi

    # 【重要】更新全局的 prev 变量，为下一次计算做准备
    prev_cpu=$curr_cpu
    prev_idle=$curr_idle

    # 【重要】不再 printf 到标准输出，而是直接设置全局变量 CPU_STATUS
    CPU_STATUS=$(printf "%02d%%" "$usage")
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
        NET_STATUS_STR="N/A" # 直接设置全局变量
        return
    fi

    local RX2 TX2 RX_DIFF TX_SPEED RX_SPEED
    
    RX2=$(<"$NET_RX_FILE")
    TX2=$(<"$NET_TX_FILE")

    RX_DIFF=$((RX2 - RX1))
    TX_DIFF=$((TX2 - TX1))

    RX_SPEED=$(( (RX_DIFF * 8) / 1000000 ))
    TX_SPEED=$(( (TX_DIFF * 8) / 1000000 ))

    RX1=$RX2
    TX1=$TX2

    NET_STATUS_STR=$(printf "%s %dMbps %s %dMbps" "$ICON_NET_DOWN" "$RX_SPEED" "$ICON_NET_UP" "$TX_SPEED")
}


# --- 主循环 (Main Loop) ---
while true; do
    # 【已修改】直接调用 update_cpu 函数。它会更新全局的 prev_cpu, prev_idle 和 CPU_STATUS
    update_cpu
    
    # 其他函数依然可以这样调用，因为它们不依赖于在循环间保持状态
    mem_status=$(update_mem)
    temp_status=$(update_temp)
    vol_status=$(update_volume)
    music_status=$(update_music)
    ime_status=$(update_ime)
    time_status=$(date "+%a %b %d %H:%M")
    
    # 直接调用 update_net 函数。它会更新全局的 RX1, TX1 和 NET_STATUS_STR
    update_net

    # 组合最终的输出字符串，并打印到标准输出
    # dwl 会从这里读取状态信息
    printf "%s %s|%s %s|%s %s|%s %s|%s %s|%s %s|%s|%s %s|%s\n" \
        "$ICON_ARCH" "$ARCH" \
        "$ICON_MUSIC" "$music_status" \
        "$ICON_TEMP" "$temp_status" \
        "$ICON_CPU" "$CPU_STATUS" \
        "$ICON_MEM" "$mem_status" \
        "$ICON_VOL" "$vol_status" \
        "$NET_STATUS_STR" \
        "$ICON_TIME" "$time_status" \
        "$ime_status"

    sleep 1
done