#!/bin/bash

# --- INI ---
PID_FILE="${XDG_RUNTIME_DIR}/dwl_status.pid"

# PID 管理：检查实例是否存在，如果存在则静默退出
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    exit 0
fi
printf "%s\n" "$$" > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT INT TERM

# --- 配置 (Configuration) ---
ICON_ARCH="󰣇"
ICON_MUSIC="♫"
ICON_TEMP=""
ICON_CPU=""
ICON_MEM="󰍛"
ICON_VOL=""
ICON_NET_DOWN=""
ICON_NET_UP=""
ICON_TIME="󰃰"
# --- 颜色定义 (Color Definitions for Bar Patch) ---
C_NORM="^fg(00ff00)"   # 绿色 (正常)
C_WARN="^fg(ffff00)"   # 黄色 (警告)
C_CRIT="^fg(ff0000)"   # 红色 (严重)
C_RESET="^fg()"       # 重置颜色
# --- 初始化 (Initialization) ---
ARCH=$(uname -r | cut -d'-' -f1)
INTERFACE=$(ip route | awk '/default/ {print $5; exit}')

if [[ -n "$INTERFACE" ]]; then
    NET_RX_FILE="/sys/class/net/$INTERFACE/statistics/rx_bytes"
    NET_TX_FILE="/sys/class/net/$INTERFACE/statistics/tx_bytes"
    if [[ -r "$NET_RX_FILE" && -r "$NET_TX_FILE" ]]; then
        RX1=$(<"$NET_RX_FILE")
        TX1=$(<"$NET_TX_FILE")
    fi
else
    NET_STATUS_STR="No Interface"
fi
read -r prev_cpu prev_idle <<< "$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5; exit}' /proc/stat)"

# --- 全局状态变量 ---
CPU_STATUS="" MEM_STATUS="" TEMP_STATUS="" VOL_STATUS=""
MUSIC_STATUS="" IME_STATUS="" TIME_STATUS=""
NET_STATUS_STR=${NET_STATUS_STR:-""}

# --- 函数定义 (Functions) ---
update_cpu() {
    read -r curr_cpu curr_idle <<< "$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5; exit}' /proc/stat)"
    total_diff=$((curr_cpu - prev_cpu)); idle_diff=$((curr_idle - prev_idle))
    if [ "$total_diff" -gt 0 ]; then
        usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))
    else
        usage=0
    fi
    prev_cpu=$curr_cpu; prev_idle=$curr_idle
    CPU_STATUS=$(printf "%02d%%" "$usage")
}
update_mem() {
    MEM_STATUS=$(awk '/^MemTotal:/ {t=$2/1024} /^MemAvailable:/ {a=$2/1024} END {printf "%d/%dMB", (t-a), t}' /proc/meminfo)
}
update_temp() {
    # 仅提取温度的纯数字，用于后续比较
    local temp_val
    temp_val=$(sensors 2>/dev/null | awk '/Core 0|Package id 0|CPU/ {for(i=1;i<=NF;i++) if($i~/\+[0-9]+\.[0-9]+°C/) {gsub(/\+|°C/,"",$i); print $i; exit}}')

    # 如果没有读到温度，显示 N/A
    if [[ -z "$temp_val" ]]; then
        TEMP_STATUS="N/A"
        return
    fi

    # 将温度值转为整数（去掉小数点后的部分）
    local temp_int=${temp_val%.*}

    # 根据阈值判断并用颜色代码包裹输出
    if (( temp_int >= 80 )); then
        # 严重阈值 (>= 80°C)，使用红色
        TEMP_STATUS="${ICON_TEMP} ${C_CRIT}${temp_int}°C${C_RESET}"
    elif (( temp_int >= 65 )); then
        # 警告阈值 (>= 65°C)，使用黄色
        TEMP_STATUS="${ICON_TEMP} ${C_WARN}${temp_int}°C${C_RESET}"
    else
        # 正常范围，使用绿色
        TEMP_STATUS="${ICON_TEMP} ${C_NORM}${temp_int}°C${C_RESET}"
    fi
}
update_volume() {
    local vol
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F'/' '/Volume:/ {gsub(/%| /,""); print $2; exit}')
    VOL_STATUS=$(printf "%02d%%" "${vol:-50}")
}
update_music() {
    # 检查 mpd (Music Player Daemon) 服务是否正在运行
    if pgrep -x "mpd" >/dev/null; then
        local music
        music=$(mpc current 2>/dev/null | cut -d'-' -f2 | sed 's/^ *//')
        # 如果服务在运行，则获取状态
        MUSIC_STATUS="[${music:-Off}]"
    else
        # 如果服务未运行，则状态为空
        MUSIC_STATUS=""
    fi
}
update_ime() {
    case $(fcitx5-remote 2>/dev/null) in
        2) IME_STATUS="CN" ;; 1) IME_STATUS="EN" ;; *) IME_STATUS="??" ;;
    esac
}
update_time() {
    TIME_STATUS=$(date "+%a %b %d %H:%M")
}
update_net() {
    if [[ -z "$RX1" ]]; then NET_STATUS_STR=${NET_STATUS_STR:-"N/A"}; return; fi
    local RX2 TX2 RX_DIFF TX_DIFF RX_SPEED TX_SPEED
    RX2=$(<"$NET_RX_FILE"); TX2=$(<"$NET_TX_FILE")
    RX_DIFF=$((RX2 - RX1)); TX_DIFF=$((TX2 - TX1))
    RX_SPEED=$(( (RX_DIFF * 8) / 1000000 )); TX_SPEED=$(( (TX_DIFF * 8) / 1000000 ))
    RX1=$RX2; TX1=$TX2
    NET_STATUS_STR=$(printf "%s %dMbps %s %dMbps" "$ICON_NET_DOWN" "$RX_SPEED" "$ICON_NET_UP" "$TX_SPEED")
}

# --- 状态栏打印函数 ---
print_status_bar() {
    # 使用一个数组来存储状态栏的各个模块
    local parts=()

    # 模块1: 内核版本 (始终显示)
    parts+=("${ICON_ARCH} ${ARCH}")

    # 模块2: 音乐 (仅当 MUSIC_STATUS 非空时显示)
    if [[ -n "$MUSIC_STATUS" ]]; then
        parts+=("${ICON_MUSIC} ${MUSIC_STATUS}")
    fi

    # 添加其余模块
    # parts+=("${ICON_TEMP} ${TEMP_STATUS}")
    parts+=("${ICON_CPU} ${CPU_STATUS}")
    parts+=("${ICON_MEM} ${MEM_STATUS}")
    parts+=("${ICON_VOL} ${VOL_STATUS}")
    parts+=("${NET_STATUS_STR}")
    parts+=("${ICON_TIME} ${TIME_STATUS}")
    parts+=("${IME_STATUS}")

    # 使用 "|" 作为分隔符，将数组中的所有模块连接成一个字符串并打印
    local IFS="|"
    printf "%s\n" "${parts[*]}"
}

# --- 信号陷阱 (Signal Trap) ---
trap 'update_volume; print_status_bar' SIGRTMIN+2
trap 'update_ime; print_status_bar' SIGRTMIN+3

# --- 首次运行 ---
# 立即执行所有更新，确保状态栏启动时不是空的
update_cpu; update_mem; update_temp; update_music; update_ime; update_time; update_net
# 首次获取音量，如果音频服务未就绪，将显示默认值 50%
update_volume


# --- 主循环 (Main Loop) ---
sec=0
while true; do
    # 高频更新
    update_cpu; update_temp; update_net
    # 中频更新
    if [ $((sec % 5)) -eq 0 ]; then
        update_mem; update_music
    fi
    # 低频更新
    if [ $((sec % 60)) -eq 0 ]; then
        update_time
    fi

    # 每秒打印一次最新状态
    print_status_bar

    sleep 1
    sec=$((sec + 1))
done
