#!/usr/bin/env bash

here="$(cd $(dirname $0); pwd)"

. $here/../build-dist.bash
. $here/../assert.sh/assert.sh

deploy_to=/tmp/cap4

cat <<EOF > /tmp/env
deploy_to="$deploy_to"
git_branch=master
git_repo_url=${here}/../
keep_release=1
linked_files=(foo)
linked_dirs=(bar)

deploy:restart() {
  echo hi > log.txt
}
EOF

export CAPLOY_LOCAL=1
export CAPLOY_TESTING=1

clear_deploy_to() {
  rm -rf "$deploy_to"
}

set +u

clear_deploy_to
./caploy /tmp/env git:update
assert_raises "[ -d "$deploy_to" ]"
assert_raises "[ -d "$deploy_to/repo" ]"
assert "git --git-dir=/tmp/cap4/repo rev-parse HEAD" "$(git rev-parse master)"
assert_end "git:update"

clear_deploy_to
./caploy /tmp/env deploy:check:directories
assert_raises "[ -d "$deploy_to" ]"
assert_raises "[ -d "$deploy_to/shared" ]"
assert_raises "[ -d "$deploy_to/releases" ]"
assert_end "deploy:check:directories"

clear_deploy_to
./caploy /tmp/env deploy
rev="$(git rev-parse master)"
assert_raises "[ -d "$deploy_to" ]"
assert_raises "[ -d "$deploy_to/shared" ]"
assert_raises "[ -d "$deploy_to/releases/$rev" ]"
assert "readlink -f $deploy_to/current" "$deploy_to/releases/$rev"
assert "cat $deploy_to/current/log.txt" "hi"
assert "readlink -f $deploy_to/current/foo" "$deploy_to/shared/foo"
assert "readlink -f $deploy_to/current/bar" "$deploy_to/shared/bar"
assert_end "deploy"