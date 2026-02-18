#!/usr/bin/env bash
#
# somafm.sh
# Control SomaFM internet radio playback
#
# Usage: somafm.sh <command> [options]
#
# Commands:
#   play [channel] [--volume=N]  Start playback (default: groovesalad, volume: 50)
#   stop                         Stop playback
#   status                       Show current channel and track
#   list                         List available channels
#   volume <0-100>               Change volume (seamless, no interruption)
#
# Exit codes:
#   0 - Success
#   1 - Missing dependency (mpv, curl, jq)
#   2 - Network error / invalid channel / playback failure
#

set -euo pipefail

# State directory (per-user, in tmp)
STATE_DIR="${TMPDIR:-/tmp}/somafm-$(id -u)"
PID_FILE="${STATE_DIR}/somafm.pid"
CHANNEL_FILE="${STATE_DIR}/somafm.channel"
SOCK_FILE="${STATE_DIR}/somafm.sock"

SOMAFM_API="https://api.somafm.com/channels.json"

# --- Dependency check ---

check_deps() {
    local missing=()
    for cmd in mpv curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing dependencies: ${missing[*]}" >&2
        echo "" >&2
        echo "Install with:" >&2
        echo "  macOS:  brew install ${missing[*]}" >&2
        echo "  Ubuntu: sudo apt install ${missing[*]}" >&2
        exit 1
    fi
}

# --- State helpers ---

init_state_dir() {
    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"
}

is_playing() {
    if [ ! -f "$PID_FILE" ]; then
        return 1
    fi
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null) || { cleanup_state; return 1; }
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        cleanup_state
        return 1
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
        cleanup_state
        return 1
    fi
    local proc_name
    proc_name=$(ps -p "$pid" -o comm= 2>/dev/null || true)
    if [ "$proc_name" != "mpv" ]; then
        cleanup_state
        return 1
    fi
    return 0
}

cleanup_state() {
    rm -f "$PID_FILE" "$CHANNEL_FILE" "$SOCK_FILE" "${STATE_DIR}/mpv.log"
}

# --- Commands ---

cmd_play() {
    local channel="groovesalad"
    local volume=50

    for arg in "$@"; do
        case "$arg" in
            --volume=*)
                volume="${arg#--volume=}"
                if ! [[ "$volume" =~ ^[0-9]+$ ]] || [ "$volume" -lt 0 ] || [ "$volume" -gt 100 ]; then
                    echo "Error: Volume must be 0-100" >&2
                    exit 2
                fi
                ;;
            -*)
                echo "Error: Unknown option: $arg" >&2
                exit 2
                ;;
            *)
                if ! [[ "$arg" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    echo "Error: Invalid channel name (use letters, numbers, hyphens, underscores)" >&2
                    exit 2
                fi
                channel="$arg"
                ;;
        esac
    done

    # Stop existing playback
    if is_playing; then
        cmd_stop
    fi

    init_state_dir

    local url="https://somafm.com/${channel}.pls"

    # Remove stale socket
    rm -f "$SOCK_FILE"

    # Start mpv in background (log kept for diagnostics)
    local mpv_log="${STATE_DIR}/mpv.log"
    nohup mpv --no-video --no-terminal --volume="$volume" --network-timeout=30 \
        --input-ipc-server="$SOCK_FILE" "$url" >"$mpv_log" 2>&1 & disown
    local mpv_pid=$!

    # Atomic PID write
    echo "$mpv_pid" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "$PID_FILE"
    echo "$channel" > "${CHANNEL_FILE}.tmp" && mv "${CHANNEL_FILE}.tmp" "$CHANNEL_FILE"

    # Wait briefly and verify mpv started
    sleep 1
    if ! kill -0 "$mpv_pid" 2>/dev/null; then
        echo "Error: Failed to start playback for channel '${channel}'" >&2
        echo "Run 'somafm.sh list' to see available channels" >&2
        if [ -s "$mpv_log" ]; then
            echo "" >&2
            echo "mpv output:" >&2
            tail -5 "$mpv_log" >&2
        fi
        cleanup_state
        exit 2
    fi

    echo "Playing: ${channel} (volume: ${volume})"
    echo "Stream:  ${url}"
}

cmd_stop() {
    if ! is_playing; then
        echo "No playback running"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null || true
    # Wait for graceful exit
    local i=0
    while kill -0 "$pid" 2>/dev/null && [ $i -lt 10 ]; do
        sleep 0.1
        ((i++))
    done
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
        sleep 0.2
    fi
    cleanup_state
    echo "Playback stopped"
}

cmd_status() {
    if ! is_playing; then
        echo "Status: stopped"
        return 0
    fi

    local channel
    channel=$(cat "$CHANNEL_FILE" 2>/dev/null || echo "unknown")
    echo "Status:  playing"
    echo "Channel: ${channel}"

    # Fetch now-playing from SomaFM API
    local now_playing
    now_playing=$(curl -f -sS --connect-timeout 5 --max-time 10 "$SOMAFM_API" 2>/dev/null \
        | jq -r --arg ch "$channel" '.channels[] | select(.id == $ch) | .lastPlaying // "unknown"' 2>/dev/null \
        || echo "unavailable")
    echo "Now:     ${now_playing}"
}

cmd_list() {
    echo "Fetching channels..." >&2
    local data
    data=$(curl -f -sS --connect-timeout 5 --max-time 10 "$SOMAFM_API" 2>/dev/null) || {
        echo "Error: Failed to fetch channel list" >&2
        exit 2
    }

    printf "%-20s %8s  %-20s  %s\n" "CHANNEL" "LISTENERS" "GENRE" "TITLE"
    printf "%-20s %8s  %-20s  %s\n" "-------" "---------" "-----" "-----"
    echo "$data" | jq -r '
        .channels
        | sort_by(-(.listeners | tonumber))
        | .[]
        | [.id, .listeners, .genre, .title]
        | @tsv
    ' | while IFS=$'\t' read -r id listeners genre title; do
        printf "%-20s %8s  %-20s  %s\n" "$id" "$listeners" "$genre" "$title"
    done
}

cmd_volume() {
    if [ $# -eq 0 ]; then
        echo "Usage: somafm.sh volume <0-100>" >&2
        exit 2
    fi

    local vol="$1"
    if ! [[ "$vol" =~ ^[0-9]+$ ]] || [ "$vol" -lt 0 ] || [ "$vol" -gt 100 ]; then
        echo "Error: Volume must be 0-100" >&2
        exit 2
    fi

    if ! is_playing; then
        echo "Error: No playback running" >&2
        exit 2
    fi

    # Wait for IPC socket to be ready (mpv may still be connecting)
    local j=0
    while [ ! -S "$SOCK_FILE" ] && [ $j -lt 25 ]; do
        sleep 0.2
        ((j++))
    done
    if [ ! -S "$SOCK_FILE" ]; then
        echo "Error: IPC socket not found (mpv may still be starting)" >&2
        exit 2
    fi

    echo "{\"command\":[\"set_property\",\"volume\",${vol}]}" | nc -U "$SOCK_FILE" >/dev/null 2>&1 || {
        echo "Error: Failed to change volume" >&2
        exit 2
    }

    echo "Volume: ${vol}"
}

# --- Usage ---

usage() {
    echo "Usage: somafm.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  play [channel] [--volume=N]  Start playback (default: groovesalad, volume: 50)"
    echo "  stop                         Stop playback"
    echo "  status                       Show current channel and track"
    echo "  list                         List available channels"
    echo "  volume <0-100>               Change volume (seamless, no interruption)"
}

# --- Main ---

check_deps

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

command="$1"
shift

case "$command" in
    play)   cmd_play "$@" ;;
    stop)   cmd_stop ;;
    status) cmd_status ;;
    list)   cmd_list ;;
    volume) cmd_volume "$@" ;;
    *)
        echo "Error: Unknown command: ${command}" >&2
        echo "" >&2
        usage
        exit 1
        ;;
esac
