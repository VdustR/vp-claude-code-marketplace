#!/usr/bin/env bash
set -euo pipefail

# vp-localsend: LocalSend CLI wrapper for Claude Code
# Uses localsend-cli (Go) from https://github.com/0w0mewo/localsend-cli

LOCALSEND_VERSION="v0.0.6"
CACHE_DIR="${HOME}/.cache/vp-localsend"
BIN="${CACHE_DIR}/localsend-cli"
PID_FILE="${CACHE_DIR}/receive.pid"
START_TIME_FILE="${CACHE_DIR}/receive.start"
RECEIVE_DIR="${CACHE_DIR}/received"
LOG_FILE="${CACHE_DIR}/receive.log"
LOCK_DIR="${CACHE_DIR}/.receive.lock"

# ─── Helpers ──────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }

detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    darwin) os="darwin" ;;
    linux)  os="linux" ;;
    *)      die "Unsupported OS: $os (only macOS and Linux are supported)" ;;
  esac

  case "$arch" in
    x86_64|amd64)  arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)             die "Unsupported architecture: $arch" ;;
  esac

  echo "${os}-${arch}"
}

# Escape a string for safe embedding in JSON (#2)
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s" | tr -d '\000-\037'
}

# Validate IPv4 address format (#14)
validate_ip() {
  local ip="$1"
  if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    die "Invalid IP address format: $ip (only IPv4 supported)"
  fi
  local IFS='.'
  read -ra octets <<< "$ip"
  for octet in "${octets[@]}"; do
    # Reject leading zeros to prevent octal interpretation by curl
    if [[ "$octet" =~ ^0[0-9] ]]; then
      die "Invalid IP address: $ip (leading zeros not allowed)"
    fi
    if (( 10#$octet > 255 )); then
      die "Invalid IP address: $ip (octet $octet > 255)"
    fi
  done
}

# URL-encode a string (#6)
url_encode() {
  local string="$1" length=${#1} encoded="" i c
  for (( i = 0; i < length; i++ )); do
    c="${string:i:1}"
    case "$c" in
      [A-Za-z0-9._~-]) encoded+="$c" ;;
      *) encoded+="$(printf '%%%02X' "'$c")" ;;
    esac
  done
  printf '%s' "$encoded"
}

# Portable SHA256 checksum (#11)
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo ""
  fi
}

# Known SHA256 checksums for localsend-cli releases (#11)
expected_checksum() {
  local platform="$1"
  case "$platform" in
    darwin-amd64) echo "7e37b55e5d9e68af664f49d56162c39f3bd8b92afe00cd28f9639a2c0f8fdc9f" ;;
    darwin-arm64) echo "bce5dc36481d922a6fb1ca7a028ca44a8cf5988928d201dac0166bacec0f62bc" ;;
    linux-amd64)  echo "dfcd8339dd960b274108e1b06af78906dc48d9da66dad2d9f9e573d23684c14c" ;;
    linux-arm64)  echo "5813e86e650ece74a36bb41c78bbda25272f895b10814ec8598a74167e243219" ;;
    *) echo "" ;;
  esac
}

# Format byte count to human-readable size
format_size() {
  local size="$1"
  if ! [[ "$size" =~ ^[0-9]+$ ]]; then
    echo "?"
    return
  fi
  if (( size >= 1073741824 )); then
    echo "$(( size / 1073741824 ))G"
  elif (( size >= 1048576 )); then
    echo "$(( size / 1048576 ))M"
  elif (( size >= 1024 )); then
    echo "$(( size / 1024 ))K"
  else
    echo "${size}B"
  fi
}

ensure_binary() {
  if [[ -x "$BIN" ]]; then
    return 0
  fi

  echo "localsend-cli not found. Downloading ${LOCALSEND_VERSION}..."
  mkdir -p "$CACHE_DIR"

  local platform tarball url
  platform="$(detect_platform)"
  tarball="localsend-${LOCALSEND_VERSION}-${platform}.tar.gz"
  url="https://github.com/0w0mewo/localsend-cli/releases/download/${LOCALSEND_VERSION}/${tarball}"

  echo "Downloading from: ${url}"
  curl -fsSL -o "${CACHE_DIR}/${tarball}" "$url" || die "Failed to download localsend-cli"

  # Verify checksum if available (#11)
  local expected
  expected="$(expected_checksum "$platform")"
  if [[ -n "$expected" ]]; then
    local actual
    actual="$(sha256 "${CACHE_DIR}/${tarball}")"
    if [[ -z "$actual" ]]; then
      echo "WARNING: No sha256 tool available, skipping checksum verification"
    elif [[ "$actual" != "$expected" ]]; then
      rm -f "${CACHE_DIR}/${tarball}"
      die "Checksum mismatch! Expected: ${expected}, Got: ${actual}"
    else
      echo "Checksum verified."
    fi
  fi

  # Validate tarball contents for path traversal (#12)
  local tar_contents
  if ! tar_contents="$(tar -tzf "${CACHE_DIR}/${tarball}" 2>&1)"; then
    rm -f "${CACHE_DIR}/${tarball}"
    die "Failed to read tarball contents (file may be corrupted)"
  fi
  if echo "$tar_contents" | grep -q '\.\.'; then
    rm -f "${CACHE_DIR}/${tarball}"
    die "Tarball contains suspicious path traversal entries"
  fi

  echo "Extracting..."
  tar -xzf "${CACHE_DIR}/${tarball}" -C "$CACHE_DIR" || die "Failed to extract archive"

  # The binary name inside the archive may vary; find it (#1, #16)
  local extracted
  extracted="$(find "$CACHE_DIR" -maxdepth 2 -name 'localsend*' -type f -perm /111 ! -name '*.tar.gz' ! -name '*.sh' | head -1)"
  if [[ -z "$extracted" ]]; then
    # Try without exec permission check (some archives don't preserve it)
    extracted="$(find "$CACHE_DIR" -maxdepth 2 -name 'localsend*' -type f ! -name '*.tar.gz' ! -name '*.sh' ! -name '*.pid' ! -name '*.start' ! -name '*.log' | head -1)"
    [[ -n "$extracted" ]] && chmod +x "$extracted"
  fi

  if [[ -z "$extracted" ]]; then
    die "Could not find localsend binary in extracted archive. Contents: $(ls -la "$CACHE_DIR")"
  fi

  if [[ "$extracted" != "$BIN" ]]; then
    mv "$extracted" "$BIN"
  fi
  chmod +x "$BIN"

  # Clean up tarball
  rm -f "${CACHE_DIR}/${tarball}"
  echo "localsend-cli ${LOCALSEND_VERSION} installed successfully."
}

# ─── Commands ─────────────────────────────────────

cmd_setup() {
  ensure_binary
  echo ""
  "$BIN" --help 2>&1 || true
}

cmd_scan() {
  ensure_binary
  local timeout="${1:-4}"
  echo "Scanning local network for LocalSend devices (${timeout}s)..."
  "$BIN" scan -t "$timeout"
}

cmd_send() {
  if [[ $# -lt 2 ]]; then
    die "Usage: localsend.sh send <ip> <file-or-dir> [--pin=PIN]"
  fi

  local ip="$1" target="$2" pin=""
  shift 2

  # Validate IP format (#14)
  validate_ip "$ip"

  # Parse optional flags
  for arg in "$@"; do
    case "$arg" in
      --pin=*) pin="${arg#--pin=}" ;;
    esac
  done

  if [[ ! -e "$target" ]]; then
    die "File or directory not found: $target"
  fi

  # Collect files to send
  local -a files=()
  if [[ -d "$target" ]]; then
    # Prevent find from interpreting target as an option
    local safe_target="$target"
    [[ "$safe_target" == -* ]] && safe_target="./$safe_target"
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$safe_target" -type f -print0)
    [[ ${#files[@]} -eq 0 ]] && die "Directory is empty: $target"
  else
    files=("$target")
  fi

  echo "Sending ${#files[@]} file(s) to ${ip}..."

  # Build files JSON for prepare-upload (#2, #3)
  local files_json="{"
  local i=0
  for f in "${files[@]}"; do
    local fname fsize ftype fid
    fname="$(json_escape "$(basename "$f")")"
    fsize="$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || true)"
    [[ "$fsize" =~ ^[0-9]+$ ]] || die "Failed to get valid file size: $f"
    ftype="application/octet-stream"
    fid="file-${i}"

    [[ $i -gt 0 ]] && files_json+=","
    files_json+="\"${fid}\":{\"id\":\"${fid}\",\"fileName\":\"${fname}\",\"size\":${fsize},\"fileType\":\"${ftype}\"}"
    i=$(( i + 1 ))
  done
  files_json+="}"

  # Generate a simple fingerprint
  local fingerprint
  fingerprint="claude-code-$(date +%s)"

  # Build PIN parameter with URL encoding (#6)
  local pin_param=""
  if [[ -n "$pin" ]]; then
    pin_param="?pin=$(url_encode "$pin")"
  fi

  # Step 1: prepare-upload (#5 - separate stderr)
  echo "Requesting transfer..."
  local prepare_url="https://${ip}:53317/api/localsend/v2/prepare-upload${pin_param}"
  local response http_code body curl_exit=0
  response=$(curl -sk -w "\n%{http_code}" -X POST "$prepare_url" \
    -H "Content-Type: application/json" \
    -d "{
      \"info\": {
        \"alias\": \"Claude Code\",
        \"version\": \"2.0\",
        \"deviceModel\": \"CLI\",
        \"deviceType\": \"headless\",
        \"fingerprint\": \"${fingerprint}\",
        \"download\": false
      },
      \"files\": ${files_json}
    }" 2>/dev/null) || curl_exit=$?

  if [[ $curl_exit -ne 0 ]]; then
    die "Network error connecting to ${ip}:53317 (curl exit code ${curl_exit}). Is the device online and running LocalSend?"
  fi

  http_code="$(echo "$response" | tail -1)"
  body="$(echo "$response" | sed '$d')"

  # Validate http_code is numeric (#5)
  if ! [[ "$http_code" =~ ^[0-9]{3}$ ]]; then
    die "Failed to connect to ${ip}:53317 (is the device online and running LocalSend?)"
  fi

  case "$http_code" in
    200) ;;
    204) echo "Receiver finished (no files needed)."; return 0 ;;
    403) die "Transfer rejected by receiver." ;;
    401) die "PIN required. Use --pin=PIN" ;;
    409) die "Receiver is busy with another transfer." ;;
    *)   die "prepare-upload failed (HTTP ${http_code}): ${body}" ;;
  esac

  # Flatten JSON to single line for reliable sed parsing (#4)
  body="$(echo "$body" | tr -d '\n\r')"

  local session_id
  session_id="$(echo "$body" | sed -n 's/.*"sessionId":"\([^"]*\)".*/\1/p')"
  [[ -z "$session_id" ]] && die "Failed to parse sessionId from response: ${body}"

  echo "Receiver accepted. Uploading..."

  # Step 2: upload each file
  local success=0 fail=0
  i=0
  for f in "${files[@]}"; do
    local fid="file-${i}"
    local token
    token="$(echo "$body" | sed -n "s/.*\"${fid}\":\"\\([^\"]*\\)\".*/\\1/p")"

    if [[ -z "$token" ]]; then
      echo "  SKIP $(basename "$f") (not requested by receiver)"
      i=$(( i + 1 ))
      continue
    fi

    local upload_url="https://${ip}:53317/api/localsend/v2/upload?sessionId=$(url_encode "$session_id")&fileId=$(url_encode "$fid")&token=$(url_encode "$token")"
    local upload_code upload_curl_exit=0
    upload_code=$(curl -sk -o /dev/null -w "%{http_code}" \
      -X POST "$upload_url" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$f" 2>/dev/null) || upload_curl_exit=$?

    if [[ $upload_curl_exit -ne 0 ]]; then
      echo "  FAIL $(basename "$f") (network error, curl exit code ${upload_curl_exit})"
      fail=$(( fail + 1 ))
      i=$(( i + 1 ))
      continue
    fi

    if [[ "$upload_code" == "200" ]]; then
      echo "  OK $(basename "$f")"
      success=$(( success + 1 ))
    else
      echo "  FAIL $(basename "$f") (HTTP ${upload_code:-connection failed})"
      fail=$(( fail + 1 ))
    fi
    i=$(( i + 1 ))
  done

  echo ""
  if [[ $fail -eq 0 ]]; then
    echo "Done. ${success} file(s) sent successfully."
  else
    echo "Done. ${success} succeeded, ${fail} failed."
    return 1
  fi
}

cmd_receive() {
  ensure_binary
  local action="${1:-start}"

  case "$action" in
    start) receive_start "${@:2}" ;;
    stop)  receive_stop ;;
    status) receive_status ;;
    *) die "Usage: localsend.sh receive [start|stop|status]" ;;
  esac
}

# Atomic lock using mkdir (portable across macOS and Linux) (#13)
acquire_lock() {
  mkdir -p "$CACHE_DIR"
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Check if the lock is stale (older than 30 seconds)
    local mtime
    mtime="$(stat -f%m "$LOCK_DIR" 2>/dev/null || stat -c%Y "$LOCK_DIR" 2>/dev/null || true)"
    if [[ -z "$mtime" ]]; then
      # Cannot determine lock age; conservatively refuse
      die "Another receive operation is in progress (unable to check lock age)."
    fi
    local lock_age
    lock_age=$(( $(date +%s) - mtime ))
    if (( lock_age > 30 )); then
      rm -rf "$LOCK_DIR"
      mkdir "$LOCK_DIR" 2>/dev/null || die "Another receive operation is in progress."
    else
      die "Another receive operation is in progress."
    fi
  fi
}

release_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

receive_start() {
  acquire_lock
  trap 'release_lock; exit 1' INT TERM ERR

  # Re-check inside lock (#13)
  if receive_is_running; then
    local pid
    pid="$(cat "$PID_FILE")"
    echo "Receive server is already running (PID: ${pid})."
    receive_status
    release_lock
    trap - INT TERM ERR
    return 0
  fi

  mkdir -p "$RECEIVE_DIR"
  local output_dir="${1:-$RECEIVE_DIR}"
  mkdir -p "$output_dir"

  echo "Starting receive server..."
  echo "Files will be saved to: ${output_dir}"

  # Start localsend-cli recv in background (append log to preserve history)
  nohup "$BIN" recv -d "$output_dir" >> "$LOG_FILE" 2>&1 &
  local pid=$!

  echo "$pid" > "$PID_FILE"
  date +%s > "$START_TIME_FILE"

  # Brief wait to check if process started successfully
  sleep 1
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE" "$START_TIME_FILE"
    echo "Failed to start receive server. Log:"
    cat "$LOG_FILE" 2>/dev/null
    release_lock
    trap - INT TERM ERR
    return 1
  fi

  echo "Receive server started (PID: ${pid})."
  echo "Other LocalSend devices can now send files to this machine."
  echo ""
  echo "REMINDER: Run 'localsend.sh receive stop' when done to stop the server."

  release_lock
  trap - INT TERM
}

receive_stop() {
  acquire_lock
  trap 'release_lock; exit 1' INT TERM ERR

  if ! receive_is_running; then
    echo "No receive server is running."
    rm -f "$PID_FILE" "$START_TIME_FILE"
    release_lock
    trap - INT TERM ERR
    return 0
  fi

  local pid
  pid="$(cat "$PID_FILE")"
  echo "Stopping receive server (PID: ${pid})..."
  kill "$pid" 2>/dev/null || true

  # Wait briefly for clean exit
  local i=0
  while kill -0 "$pid" 2>/dev/null && [[ $i -lt 5 ]]; do
    sleep 1
    i=$(( i + 1 ))
  done

  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
  fi

  rm -f "$PID_FILE" "$START_TIME_FILE"
  echo "Receive server stopped."
  list_received_files "$RECEIVE_DIR"

  release_lock
  trap - INT TERM
}

receive_status() {
  if ! receive_is_running; then
    echo "STATUS: No receive server is running."
    rm -f "$PID_FILE" "$START_TIME_FILE"
    return 0
  fi

  local pid uptime_sec now start_time
  pid="$(cat "$PID_FILE")"
  now="$(date +%s)"
  start_time="$(cat "$START_TIME_FILE" 2>/dev/null || echo "$now")"
  uptime_sec=$((now - start_time))

  local minutes=$((uptime_sec / 60))
  local seconds=$((uptime_sec % 60))

  echo "STATUS: Receive server is running"
  echo "  PID: ${pid}"
  echo "  Uptime: ${minutes}m ${seconds}s"
  echo "  Save dir: ${RECEIVE_DIR}"

  # Idle warning
  if [[ $uptime_sec -gt 180 ]]; then
    echo ""
    echo "WARNING: Server has been running for over ${minutes} minutes."
    echo "If you are done receiving files, stop it with: localsend.sh receive stop"
  fi

  list_received_files "$RECEIVE_DIR"

  # Show recent log
  if [[ -f "$LOG_FILE" ]]; then
    local log_lines
    log_lines="$(tail -5 "$LOG_FILE" 2>/dev/null)"
    if [[ -n "$log_lines" ]]; then
      echo ""
      echo "Recent log:"
      echo "$log_lines"
    fi
  fi
}

# Check if receive server is running, with binary name validation (#10)
receive_is_running() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null)" || return 1
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  # Validate the process is actually localsend-cli, not a reused PID
  local proc_name
  proc_name="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
  [[ "$proc_name" == *localsend* ]]
}

# UUID pattern: 8-4-4-4-12 hex chars
is_uuid_filename() {
  [[ "$(basename "$1")" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\. ]]
}

list_received_files() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  # Use glob instead of ls to check for files (#9)
  local -a entries=("$dir"/*)
  [[ -e "${entries[0]}" ]] || return 0

  echo ""
  echo "Received:"
  for f in "${entries[@]}"; do
    [[ -f "$f" ]] || continue
    local name size_bytes size
    name="$(basename "$f")"
    # Use stat instead of ls for portable file size (#8)
    size_bytes="$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo "0")"
    size="$(format_size "$size_bytes")"

    if is_uuid_filename "$f" && [[ "$name" == *.txt ]]; then
      # Sanitize content to prevent terminal escape injection (#7)
      local content
      content="$(head -c 200 "$f" 2>/dev/null | LC_ALL=C tr -cd '[:print:]\n' | head -c 200)"
      echo "  [MSG] ${content} (${size})"
    else
      # Sanitize filename to prevent terminal escape injection
      local safe_name
      safe_name="$(printf '%s' "$name" | LC_ALL=C tr -cd '[:print:]\n')"
      echo "  [FILE] ${safe_name} (${size})"
    fi
  done
}

cmd_help() {
  cat <<'HELP'
vp-localsend: Send and receive files over local network

COMMANDS:
  setup                          Download and install localsend-cli
  scan [timeout]                 Scan for LocalSend devices (default: 4s)
  send <ip> <file|dir> [opts]    Send file or directory to a device
  receive start [dir]            Start receive server (background)
  receive stop                   Stop receive server
  receive status                 Check receive server status
  help                           Show this help

EXAMPLES:
  localsend.sh scan
  localsend.sh send 192.168.1.50 ./report.pdf
  localsend.sh send 192.168.1.50 ./dist --pin=1234
  localsend.sh receive start
  localsend.sh receive start ~/Downloads
  localsend.sh receive status
  localsend.sh receive stop
HELP
}

# ─── Main ─────────────────────────────────────────

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    setup)   cmd_setup "$@" ;;
    scan)    cmd_scan "$@" ;;
    send)    cmd_send "$@" ;;
    receive) cmd_receive "$@" ;;
    help)    cmd_help ;;
    *)       die "Unknown command: $cmd. Run 'localsend.sh help' for usage." ;;
  esac
}

main "$@"
