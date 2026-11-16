#!/bin/sh
# PC test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/C" "$T/Docs/Lua"
: > "$T/C/lua"; : > "$T/Docs/Lua/ReadMe"; : > "$T/Docs/Lua/LICENSE"
sh "$HERE/../scripts/write-part.sh" "$T" 5.5.1
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part Lua 5.5.1'
expect 'needs 68040'
expect 'copy "C/lua" "SYS:C/lua"'
expect 'copy "Docs/Lua/ReadMe" "SYS:Docs/Lua/ReadMe"'
expect 'copy "Docs/Lua/LICENSE" "SYS:Docs/Lua/LICENSE"'
[ "$(head -1 "$T/Part")" = 'part Lua 5.5.1' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: file count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 5.5.1   # a second run: the same file
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
