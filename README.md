# Lua for GFOS

Lua 5.5.1, the scripting language, for GFOS (AmigaOS 3.2.3 with GFOpenUp),
as a GFOpenUp part:

    GFOpenUpTool INSTALL Parts/Lua

gives `C:lua` and `SYS:Docs/Lua/` (this ReadMe and Lua's licence).

    lua                       interactive
    lua script.lua args       run a script
    lua -e "print(_VERSION)"

## What it is

- Lua 5.5.1 from lua/lua at tag v5.5.1 (lua.lock), fetched at build time;
  nothing third-party is kept here.
- 68040, soft float with fpuauto (the FPU when there is one, so an LC040
  runs it too); 64-bit integers and doubles as on every Lua 5.5.
- 512 KB stack, set in the program (the Shell's 4 KB is far too small).
- `require()` looks in `LIBS:lua/?.lua`, `LIBS:lua/?/init.lua`, then the
  current directory (`amiga/lua-gfos.h`); `LUA_PATH` overrides it as usual.
- No C modules (Lua's loader needs `dlopen()`), no `io.popen` (no `popen()`
  in the C library): both give Lua's own "not supported" error.
- No `luac`: Lua's git tree doesn't carry it (only the lua.org tarball,
  which this build can't fetch). `string.dump` writes the same bytecode.

## Build

    STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

The PC tests run first. `OUT/Parts/Lua` is the part; `OUT/tests/testes`
is upstream's test suite for a lab run:

    CD tests/testes
    lua -e "_port=true" all.lua

## Tests

    make -C tests test

- `test-part.sh`: the Part file.
- `host-lua.sh`: Lua built for the PC from the same sources and settings
  (`amiga/lua-gfos.h`, no `LUA_USE_POSIX`), then upstream's test suite
  (`testes/all.lua` in portable mode) and the GFOS `package.path`.

MIT (this repository); Lua is MIT, Copyright (C) 1994-2026 Lua.org,
PUC-Rio.

Team 3
