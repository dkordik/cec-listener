#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/cec-listener.pid"
supervisor_pid_file="/tmp/cec-listener-supervisor.pid"

stop_pid() {
  local pid="$1"
  if ! kill -0 "$pid" 2>/dev/null; then
    return 0
  fi

  kill -TERM "$pid" 2>/dev/null || true
  for _ in {1..30}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.1
  done

  kill -KILL "$pid" 2>/dev/null || true
}

if [[ -f "$pid_file" ]]; then
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "${pid}" ]]; then
    stop_pid "$pid"
  fi
  rm -f "$pid_file"
fi

if [[ -f "$supervisor_pid_file" ]]; then
  spid="$(cat "$supervisor_pid_file" 2>/dev/null || true)"
  if [[ -n "${spid}" ]]; then
    stop_pid "$spid"
  fi
  rm -f "$supervisor_pid_file"
fi

# Fallback cleanup in case old/manual runs exist.
pkill -f "node index.js" 2>/dev/null || true
pkill -f "cec-client -m -d 8 -b r -o cec-listener" 2>/dev/null || true

echo "cec-listener stopped"
