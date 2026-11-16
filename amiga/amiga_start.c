/* Lua on AmigaOS: the Shell's 4 KB stack is far too small for Lua's parser
 * and its C calls (up to LUAI_MAXCCALLS deep), and the $VER string.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
unsigned long __stack = 512 * 1024;
static const char version[] __attribute__((used)) = "$VER: lua " LUA_AMIGA_VERSION " (" LUA_AMIGA_DATE ") GFOS";
