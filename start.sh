#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

cd "$(dirname "$0")"

# Prevent multiple instances from competing for the single CEC serial device.
pid_file="/tmp/cec-listener.pid"
supervisor_pid_file="/tmp/cec-listener-supervisor.pid"

if [[ -f "$supervisor_pid_file" ]]; then
  existing_pid="$(cat "$supervisor_pid_file" 2>/dev/null || true)"
  if [[ -n "${existing_pid}" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "cec-listener supervisor is already running (pid $existing_pid)." >&2
    exit 1
  fi
  rm -f "$supervisor_pid_file"
fi

child_pid=""
restart_requested=0
echo "$$" > "$supervisor_pid_file"

cleanup() {
  rm -f "$pid_file"
  rm -f "$supervisor_pid_file"
}

forward_and_wait() {
  local signal="$1"
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill "-$signal" "$child_pid" 2>/dev/null || true

    for _ in {1..20}; do
      if ! kill -0 "$child_pid" 2>/dev/null; then
        break
      fi
      sleep 0.1
    done

    if kill -0 "$child_pid" 2>/dev/null; then
      kill -KILL "$child_pid" 2>/dev/null || true
    fi
  fi
}

trap 'forward_and_wait TERM; cleanup; exit 0' TERM
trap 'forward_and_wait INT; cleanup; exit 0' INT
trap 'forward_and_wait HUP; cleanup; exit 0' HUP
trap 'restart_requested=1; forward_and_wait TERM' USR1
trap 'cleanup' EXIT

while true; do
  restart_requested=0
  node index.js &
  child_pid="$!"
  echo "$child_pid" > "$pid_file"

  exit_code=0
  if ! wait "$child_pid"; then
    exit_code=$?
  fi
  child_pid=""
  rm -f "$pid_file"

  if [[ "$restart_requested" -eq 1 ]]; then
    echo "Restarting cec-listener..."
    continue
  fi

  # 75 = self-restart requested by the running process (e.g. SIGUSR1).
  if [[ "$exit_code" -eq 75 ]]; then
    echo "Restarting cec-listener..."
    continue
  fi

  exit "$exit_code"
done
