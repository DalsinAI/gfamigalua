# What build-amiga.sh (the stove) and tests/host-lua.sh (the PC) share:
# Lua's sources and fetching them. Sourced; needs HERE (the repo) and
# lua.lock's settings.
# MIT, Copyright (c) 2026 AmiCradle Team.

# lua.c and the library, as upstream's makefile (CORE_O, LIB_O, LUA_O);
# not ltests.c (the internal test library) or onelua.c
LUA_SRCS="lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c
 lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c
 lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c
 lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c lua.c"

# a repository at one commit, fetched once: fetch_at DIR URL COMMIT
fetch_at() {
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${1:?}"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
        [ "$(git -C "$1" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# Lua's licence, as lua.h carries it (the release's only copy of it)
lua_licence() {
    sed -n '/^\* Copyright (C)/,/^\*\*\*\*\*/p' "$1/lua.h" | sed -e 's/^\* \{0,1\}//' -e '/^\*\*\*\*/d'
}
