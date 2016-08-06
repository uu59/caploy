#!/usr/bin/env bash

set -ue

tmp=`mktemp`

cat internal.bash > "$tmp"
for file in tasks/*.bash; do
  cat "$file" >> "$tmp"
done
echo 'internal:run "$@"' >> "$tmp"
chmod +x "$tmp"

mv "$tmp" ./caploy
