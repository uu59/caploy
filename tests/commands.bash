#!/usr/bin/env bash

here="$(cd $(dirname $0); pwd)"

$here/../build.bash "0.0.0-test"
. $here/../assert.sh/assert.sh

deploy_to=/tmp/cap4

cat <<EOF > /tmp/env
deploy_to="$deploy_to"
: \${git_branch:="master"}
git_repo_url=${here}/../
keep_release=1
linked_files=(foo)
linked_dirs=(bar)

deploy:restart() {
  echo hi > deploy_restart.txt
}
EOF

export CAPLOY_LOCAL=1
export CAPLOY_TESTING=1

clear_deploy_to() {
  rm -rf "$deploy_to"
}

set +u

rm -rf "$here/tmpdir"
mkdir -p "$here/tmpdir"
mkdir -p "$here/tmpdir/dir"
echo 'deploy_to=/tmp' > "$here/tmpdir/file"
ln -s "$here/tmpdir/file" "$here/tmpdir/link"
assert_raises "./caploy" 64
assert_raises "./caploy /dev/null" 64
assert_raises "./caploy $here/tmpdir/file test" 0
assert_raises "./caploy $here/tmpdir/link test" 0
assert_raises "./caploy $here/tmpdir/dir test" 64
assert_raises "./caploy $here/tmpdir/file does_not_exist" 64
assert_end "invalid args then usage exit"
rm -rf "$here/tmpdir"

assert_raises "./caploy /tmp/env test" 0
assert "./caploy /tmp/env test:version" "0.0.0-test"
assert_end "test commands"

clear_deploy_to
./caploy /tmp/env git:update
assert_raises "[ -d '$deploy_to' ]"
assert_raises "[ -d '$deploy_to/repo' ]"
assert "git --git-dir=/tmp/cap4/repo rev-parse HEAD" "$(git rev-parse master)"
assert_end "git:update"

clear_deploy_to
./caploy /tmp/env deploy:check:directories
assert_raises "[ -d '$deploy_to' ]"
assert_raises "[ -d '$deploy_to/shared' ]"
assert_raises "[ -d '$deploy_to/releases' ]"
assert_end "deploy:check:directories"

clear_deploy_to
./caploy /tmp/env deploy
rev="$(git rev-parse master)"
assert_raises "[ -d '$deploy_to' ]"
assert_raises "[ -d '$deploy_to/shared' ]"
assert_raises "[ -d '$deploy_to/releases/$rev' ]"
assert "readlink -f $deploy_to/current" "$deploy_to/releases/$rev"
assert "cat $deploy_to/current/deploy_restart.txt" "hi"
assert "readlink -f $deploy_to/current/foo" "$deploy_to/shared/foo"
assert "readlink -f $deploy_to/current/bar" "$deploy_to/shared/bar"
assert_end "deploy"

clear_deploy_to
for commit in `git log -3 --reverse --pretty=%H`; do
  git_branch=$commit ./caploy /tmp/env deploy
  assert_raises "[ -d $deploy_to/releases/$commit ]"
done
assert "ls $deploy_to/releases | wc -l" "1" # keep_release
assert "[ -d $deploy_to/releases/$(git rev-parse master) ]"
assert_end "deploy:cleanup"

git checkout HEAD -- ./caploy
