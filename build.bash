#!/usr/bin/env bash

set -ue

if [ -x "${1:-""}" ];then
  cat <<USAGE >&2
$0 [version]
USAGE
  exit 1
fi

version="$1"
dist=`mktemp`

cat internal.bash >> "$dist"
for file in tasks/*.bash; do
  cat "$file" >> "$dist"
done

cat <<SH >> "$dist"
__caploy_version() {
  echo "$version"
}
SH

echo 'internal:run "$@"' >> "$dist"
chmod +x "$dist"

mv "$dist" ./caploy
