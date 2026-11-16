#!/bin/sh
# Lua built for the PC the way build-amiga.sh builds it for GFOS (the same
# sources and amiga/lua-gfos.h, and no LUA_USE_POSIX: GFOS's C library has
# no popen, mkstemp or dlopen), then upstream's own test suite (testes/,
# all.lua, portable mode: _port=true leaves out what assumes a Unix shell)
# and the GFOS settings: package.path and package.cpath.
#   sh tests/host-lua.sh
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/lua.lock"
. "$HERE/scripts/lua-common.sh"
WORK=${WORK:-"$HERE/build-host"}; CC=${HOST_CC:-cc}
mkdir -p "$WORK"
SRC="$WORK/lua"
fetch_at "$SRC" "$LUA_GIT" "$LUA_COMMIT"
O="$WORK/obj"; rm -rf "$O"; mkdir -p "$O"
objs=""
for f in $LUA_SRCS; do
    # shellcheck disable=SC2086
    $CC -std=gnu99 -O2 -Wall -Wno-deprecated-declarations -include "$HERE/amiga/lua-gfos.h" \
        -c "$SRC/$f" -o "$O/${f%.c}.o" &
    objs="$objs $O/${f%.c}.o"
done
wait
# shellcheck disable=SC2086
$CC -o "$WORK/lua-host" $objs -lm
echo "built: $("$WORK/lua-host" -v)"

fail=0
if (cd "$SRC/testes" && "$WORK/lua-host" -e "_port=true" all.lua > "$WORK/testes.log" 2>&1) && grep -q "final OK" "$WORK/testes.log"; then
    echo "testes: final OK ($(grep -c '^testing' "$WORK/testes.log") test files, $(grep 'total time' "$WORK/testes.log"))"
else
    echo "FAIL testes:"; tail -20 "$WORK/testes.log"; fail=1
fi
got=$(env -u LUA_PATH -u LUA_PATH_5_5 -u LUA_CPATH -u LUA_CPATH_5_5 "$WORK/lua-host" -e 'io.write(package.path, "|", package.cpath)')
want='LIBS:lua/?.lua;LIBS:lua/?/init.lua;?.lua;?/init.lua|'
if [ "$got" = "$want" ]; then echo "paths: all checks passed"; else echo "FAIL paths: $got"; fail=1; fi
exit $fail
