#!/usr/bin/env bash

set -ue

__caploy_setup() {
  shared_path="$deploy_to/shared"
  current_path="$deploy_to/current"
  releases_path="$deploy_to/releases"
  repo_path="$deploy_to/repo"
}

__caploy_display_usage() {
  cat <<TXT >&2
Usage: $(basename $0) [env] [command]

caploy version $(__caploy_get_version)
TXT
}

__caploy_get_version() {
  if [ "$(type -t __caploy_version)" = "function" ];then
    ver=`__caploy_version`
  else
    ver="(development)"
  fi
  echo $ver
}

__caploy_usage_exit() {
  exit 64
}

internal:run:check() {
  local env="${1:-""}"
  local command="${2:-""}"
  if [ -z "$env" -o -z "$command" ];then
    __caploy_display_usage
    __caploy_usage_exit
  fi

  if [ ! -f "$env" -a ! -L "$env" ];then
    echo "'$env' does not exist or not a file" >&2
    __caploy_usage_exit
  fi

  if [ "$(type -t $command)" != "function" ];then
    echo "'$command' is not valid command" >&2
    __caploy_usage_exit
  fi
}

internal:build() {
  local lib="${BASH_SOURCE[0]}"
  local env="$1"
  local command="$2"
  tmp=`mktemp`
  cat "$lib" | grep -F -v 'internal:run "$@"' >> "$tmp"
  cat "$env" >> "$tmp"
  echo "__caploy_setup; $command" >> "$tmp"
  echo "$tmp"
}

internal:run() {
  internal:run:check "$@"
  local script="$(internal:build "$@")"
  internal:upload_then_run "$script"
}

internal:run:dev() {
  internal:run:check "$@"
  local env="$1"
  local command="$2"
  if [ -z "$env" -o -z "$command" ];then
    __caploy_usage_exit
  fi
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

