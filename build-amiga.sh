#!/bin/sh
# Builds Lua, the scripting language, for GFOS (AmigaOS 3.2.3 with GFOpenUp)
# with a stove: 68040, soft float with the FPU taken when there is one
# (fpuauto), 64-bit integers and doubles as on every other Lua 5.5.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# Lua and fpuauto are fetched at the commits lua.lock gives; nothing
# third-party is kept here. The PC tests (tests/host-lua.sh: upstream's own
# test suite on the same sources and settings) run first when there is a
# PC compiler; HOST_TESTS=0 skips them.
# OUT gets Parts/Lua: a GFOpenUp part (its Part file, C:lua, the ReadMe and
# licence in SYS:Docs/Lua), installed with
#   GFOpenUpTool INSTALL Parts/Lua
# and tests/testes/: upstream's test suite, for lua -e "_port=true" all.lua
# in a lab.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/lua.lock"
. "$HERE/scripts/lua-common.sh"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigalua/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-8}
# the PC tests run on the PC's own PATH, not the stove's
HOST_PATH=$PATH
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- the PC tests first: the same sources and settings, upstream's testes ------
if [ "${HOST_TESTS:-1}" != 0 ] && (PATH=$HOST_PATH; command -v "${HOST_CC:-cc}") > /dev/null 2>&1; then
    PATH=$HOST_PATH WORK="$WORK/host" sh "$HERE/tests/host-lua.sh" > "$WORK/host-tests.log" 2>&1 || { tail -30 "$WORK/host-tests.log"; exit 1; }
    grep -E "^testes:|checks passed" "$WORK/host-tests.log"
fi

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
FPD="$WORK/deps/fpuauto"
if [ "$(git -C "$FPD" rev-parse HEAD 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FPD"; mkdir -p "$FPD"; git -C "$FPD" init -q
    git -C "$FPD" config core.sparseCheckout true
    echo "/common/fpuauto/" > "$FPD/.git/info/sparse-checkout"
    git -C "$FPD" fetch -q --depth 1 --filter=blob:none "$FPA_REPO" "$FPA_COMMIT"
    git -C "$FPD" checkout -q FETCH_HEAD
fi
FA="$FPD/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi

# --- Lua at its pinned commit ---------------------------------------------------
SRC="$WORK/lua"
fetch_at "$SRC" "$LUA_GIT" "$LUA_COMMIT"

# --- compile -------------------------------------------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
# no loops turned into memset/memcpy calls (GCC 16), address 0 is memory
CF="-noixemul -m68040 -O2 -fno-tree-loop-distribute-patterns -fno-delete-null-pointer-checks $LATE \
 -std=gnu99 -Werror=implicit-function-declaration -Werror=int-conversion \
 -include $HERE/amiga/lua-gfos.h -I$SRC \
 -DLUA_AMIGA_VERSION=\\\"$LUA_VERSION\\\" -DLUA_AMIGA_DATE=\\\"$(date -u +%d.%m.%Y)\\\""
O="$WORK/obj"
[ "$(cat "$O/.src" 2>/dev/null)" = "$LUA_COMMIT" ] || { rm -rf "$O"; mkdir -p "$O"; echo "$LUA_COMMIT" > "$O/.src"; }
M="$O/Makefile"
{
    echo "CF = $CF"
    A=""
    for f in $LUA_SRCS; do
        o="${f%.c}.o"; A="$A $o"
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$o" "$SRC/$f"
    done
    A="$A amiga_start.o"
    printf 'amiga_start.o: %s\n\tm68k-amigaos-gcc $(CF) -c $< -o $@\n' "$HERE/amiga/amiga_start.c"
    echo "OBJS =$A"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
(cd "$O" && nice -n 19 make -k -j"$JOBS" all > make.log 2>&1) || { grep -E 'error' "$O/make.log" | head -40; tail -20 "$O/make.log"; exit 1; }
echo "compile: $(( $(date +%s) - t0 )) s"

# --- link: soft-float specs, then fpuauto's --------------------------------------
# shellcheck disable=SC2046
m68k-amigaos-gcc -noixemul -m68040 -specs="$HERE/scripts/m68k-soft-m68040.specs" -specs="$FA/fpuauto.specs" -L"$FAL" \
    -o "$O/lua.debug" $(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done) \
    -lm > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/Lua ------------------------------------------------
P="$OUT/Parts/Lua"; rm -rf "$P"; mkdir -p "$P/C" "$P/Docs/Lua"
m68k-amigaos-strip -o "$P/C/lua" "$O/lua.debug"
cp "$HERE/README.md" "$P/Docs/Lua/ReadMe"
lua_licence "$SRC" > "$P/Docs/Lua/LICENSE"
sh "$HERE/scripts/write-part.sh" "$P" "$LUA_VERSION"
# upstream's test suite, for a lab run (not in the part)
rm -rf "$OUT/tests"; mkdir -p "$OUT/tests"
mkdir -p "$OUT/tests/testes"; cp "$SRC"/testes/*.lua "$OUT/tests/testes/"   # not libs/: C modules, which _port leaves out
ls -l "$P/C/lua"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "fpuauto: $(m68k-amigaos-nm "$O/lua.debug" | grep -c ' T ___wrap_') wrapped routines"
echo "total: $(( $(date +%s) - t0 )) s"
