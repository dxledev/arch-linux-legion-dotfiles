#!/usr/bin/env bash
set -euo pipefail

collect_disk() {
    /usr/bin/df -Pk / | /usr/bin/awk 'NR == 2 { print $2, $3 }'
}

collect_metrics() {
    local disk_total disk_used
    read -r disk_total disk_used < <(collect_disk)
    /usr/bin/awk -v disk_total="$disk_total" -v disk_used="$disk_used" '
        FILENAME == "/proc/stat" && $1 == "cpu" {
            for (i = 2; i <= 9; i++) total += $i
            idle = $5 + $6
        }
        $1 == "MemTotal:" { memory_total = $2 }
        $1 == "MemAvailable:" { memory_available = $2 }
        FILENAME == "/proc/uptime" { uptime = $1 }
        END {
            printf "{\"total\":%.0f,\"idle\":%.0f,\"memoryTotal\":%.0f,\"memoryUsed\":%.0f,\"diskTotal\":%.0f,\"diskUsed\":%.0f,\"uptime\":%.0f}\n", total, idle, memory_total, memory_total - memory_available, disk_total, disk_used, uptime
        }
    ' /proc/stat /proc/meminfo /proc/uptime
}

collect_metrics
