# Caploy

```console
$ cat test-sample
#!/usr/bin/env bash

set -ue

deploy_to="/path/to/app"
git_repo_url="git@github.com:uu59/caploy.git"
git_branch="master"

# These will be linked as `ln -sf shared/config.yml current/`
# linked_files=(config.yml .env)
# linked_dirs=(log)

REMOTE_HOST=127.0.0.1

deploy:restart() {
  echo "Deploy finished."
  kill -HUP `cat foo.pid`
}

# You can see debug log by bash way
# set -x
$ ./caploy test-sample deploy
Deploy finished.
$ tree -L 1 /path/to/app
/path/to/app
├── current -> /path/to/app/releases/3c82b568e40959de9c8e822c907f7658bc73bbe2
├── releases
├── repo
└── shared
```
