#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

supervisor_pid_file="/tmp/cec-listener-supervisor.pid"

if [[ -f "$supervisor_pid_file" ]]; then
  spid="$(cat "$supervisor_pid_file" 2>/dev/null || true)"
  if [[ -n "${spid}" ]] && kill -0 "$spid" 2>/dev/null; then
    kill -USR1 "$spid"
    echo "cec-listener restart signal sent (supervisor pid $spid)"
    exit 0
  fi
fi

./start.sh
