#!/usr/bin/env bash

set -ue

__caploy_setup() {
  shared_path="$deploy_to/shared"
  current_path="$deploy_to/current"
  releases_path="$deploy_to/releases"
  repo_path="$deploy_to/repo"
}

internal:build() {
  local lib="${BASH_SOURCE[0]}"
  local env="$1"
  local command="$2"
  if [ ! -f "$env" ]; then
    error
  fi
  tmp=`mktemp`
  cat "$lib" | grep -F -v 'internal:run "$@"' >> "$tmp"
  cat "$env" >> "$tmp"
  echo "__caploy_setup; $command" >> "$tmp"
  echo "$tmp"
}

internal:run() {
  local script="$(internal:build "$@")"
  internal:upload_then_run "$script"
}

internal:run:dev() {
  local env="$1"
  local command="$2"
  local script="$(mktemp)"

  for file in $BASH_SOURCE tasks/*.bash; do
    cat "$file" >> "$script"
  done
  cat "$env" >> "$script"
  echo "__caploy_setup; $command" >> "$script"
  internal:upload_then_run "$script"
}

internal:upload_then_run() {
  local script="$1"

  if [ -n "${CAPLOY_LOCAL:-""}" ];then
    dst="/tmp/caploy-run-script-local.bash"
    cp "$script" "$dst"
    bash -c "chmod +x $dst && $dst"
  else
    : ${remote_host:=localhost}
    : ${remote_port:=22}
    : ${remote_script_path:=/tmp/caploy-run-script.bash}
    scp -q -P $remote_port "$script" $remote_host:$remote_script_path
    rm -f "$script"
    ssh $remote_host -- "chmod +x $remote_script_path && $remote_script_path"
  fi
}

