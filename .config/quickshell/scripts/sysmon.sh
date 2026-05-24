#!/usr/bin/env bash
# System metrics daemon — outputs one JSON line every 2 seconds
# Fields: cpu, mem, mu (mem_used GB), mt (mem_total GB), bat, bs (bat_status), net

prev_idle=0
prev_total=0
gpu_counter=0
gpu_util=0; gpu_vram_used=0; gpu_vram_total=4096

while true; do
    # CPU delta
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    di=$((idle  - prev_idle))
    dt=$((total - prev_total))
    cpu=$(( dt > 0 ? (dt - di) * 100 / dt : 0 ))
    prev_idle=$idle; prev_total=$total

    # RAM
    mem_total=$(awk '/MemTotal:/{print $2}'     /proc/meminfo)
    mem_avail=$(awk '/MemAvailable:/{print $2}' /proc/meminfo)
    mem_used=$(( mem_total - mem_avail ))
    mem_pct=$(( mem_used * 100 / mem_total ))
    mu=$(awk "BEGIN{printf \"%.1f\", $mem_used  / 1048576}")
    mt=$(awk "BEGIN{printf \"%.0f\", $mem_total / 1048576}")

    # Battery
    bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)
    bs=$(cat  /sys/class/power_supply/BAT0/status   2>/dev/null || echo "AC")

    # GPU (NVIDIA) — sondé toutes les 10s (1 appel nvidia-smi sur 5 itérations)
    if [ $((gpu_counter % 5)) -eq 0 ]; then
        gpu_raw=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total \
            --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')
        if [ -n "$gpu_raw" ]; then
            IFS=',' read -r gpu_util gpu_vram_used gpu_vram_total <<< "$gpu_raw"
        else
            gpu_util=0; gpu_vram_used=0; gpu_vram_total=4096
        fi
    fi
    gpu_counter=$((gpu_counter + 1))

    # Network (wifi SSID or wired connection name)
    net=$(nmcli -t -f active,ssid dev wifi 2>/dev/null \
          | awk -F: '/^yes:/{sub(/^yes:/, ""); print; exit}')
    if [ -z "$net" ]; then
        net=$(nmcli -t -f device,state,connection dev 2>/dev/null \
              | awk -F: '$2=="connected" && $1!="lo" {print $3; exit}')
    fi
    [ -z "$net" ] && net="offline"

    # Volume via wpctl
    vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    vol_pct=$(echo "$vol_raw" | awk '{printf "%d", $2 * 100}')
    vol_muted=false
    echo "$vol_raw" | grep -q MUTED && vol_muted=true
    [ -z "$vol_pct" ] && vol_pct=0

    printf '{"cpu":%d,"mem":%d,"mu":"%s","mt":"%s","bat":"%s","bs":"%s","net":"%s","vol":%s,"vm":%s,"gpu":%d,"gv":%d,"gvt":%d}\n' \
        "$cpu" "$mem_pct" "$mu" "$mt" "$bat" "$bs" "$net" "$vol_pct" "$vol_muted" \
        "$gpu_util" "$gpu_vram_used" "$gpu_vram_total"

    sleep 2
done
