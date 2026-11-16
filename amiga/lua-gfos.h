/* Lua's settings for GFOS, given to every file before luaconf.h (with
 * -include), and to the PC tests' build the same way.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#ifndef GFAMIGA_LUA_GFOS_H
#define GFAMIGA_LUA_GFOS_H

/* require() looks in LIBS:lua/ (a drawer for Lua libraries any program can
   share), then the current directory: AmigaDOS names, no "./" */
#define LUA_PATH_DEFAULT "LIBS:lua/?.lua;LIBS:lua/?/init.lua;?.lua;?/init.lua"
/* no C modules: Lua's loader needs dlopen(); on GFOS a binding would be
   an Amiga library, which this port doesn't load */
#define LUA_CPATH_DEFAULT ""

#endif
