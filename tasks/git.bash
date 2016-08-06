#!/usr/bin/env bash

set -ue

git:check() {
local repo_path_upstream="$(git --git-dir="$repo_path" ls-remote --get-url)"
  if [ "$repo_path_upstream" != "$git_repo_url" ]; then
    rm -rf "$repo_path"
  fi
}

git:clone() {
  if [ -d "$repo_path" ]; then
    # TODO: Update exists repo upstream url
    : git --git-dir="$repo_path" remote -v
  else
    git clone --bare --mirror "$git_repo_url" "$repo_path"
  fi
}

git:update() {
  git:check
  git:clone
  git --git-dir="$repo_path" fetch --prune
}

git:release() {
  git:update
  local revision="$(git:commit_hash "${1:-master}")"

  local release_path="$releases_path/$revision"
  if [ -d "$release_path" ];then
    echo "Already deployed" >&2
  else
    mkdir -p "$release_path"
    git --git-dir="$repo_path" archive "$revision" | tar xf - -C $release_path/
  fi
  echo "$release_path"
}

git:commit_hash() {
  local revision="${1:-master}"
  git --git-dir="$repo_path" rev-list --max-count=1 "$revision"
}
