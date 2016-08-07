#!/usr/bin/env bash

set -ue

deploy() {
  deploy:check:directories
  local release_path="$(git:release "$git_branch")"
  cd "$release_path"
  deploy:symlink:shared "$release_path"
  deploy:set_current_revision "$release_path"
  deploy:restart
  deploy:cleanup "${keep_release:-3}"
}

deploy:check:directories() {
  mkdir -p "$shared_path"
  mkdir -p "$releases_path"
}

deploy:set_current_revision() {
  local release_path="$1"
  tmp_current_path="$release_path/../tmp_current"
  ln -s "$release_path" "$tmp_current_path"
  mv "$tmp_current_path" "$current_path"
}

deploy:symlink:shared() {
  local shared="$shared_path"
  local release_path="$1"

  if [ -n "${linked_files[@]:-""}" ];then
    for file in ${linked_files[@]}; do
      ln -sf "$shared/$file" "$release_path"
    done
  fi

  if [ -n "${linked_dirs[@]:-""}" ];then
    for dir in ${linked_dirs[@]}; do
      ln -sf "$shared/$dir" "$release_path"
    done
  fi
}

deploy:cleanup() {
  local keep_release="$1"
  local releases="$(ls -xt $releases_path)"
  local counter=0
  for rel in $releases; do
    counter=$(($counter + 1))
    if [ $counter -gt $keep_release ];then
      rm -r "$releases_path/$rel"
    fi
  done
}

deploy:restart() {
  : deploy:restart called
}
