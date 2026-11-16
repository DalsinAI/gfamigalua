#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c)
# for the part drawer the build made: C/lua to C:lua, Docs/Lua/ to
# SYS:Docs/Lua/.
#   write-part.sh <part drawer> <version>
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
P=$1; V=$2
{
    echo "part Lua $V"
    echo "; Lua: the scripting language (C:lua), require() looks in LIBS:lua/"
    echo "needs 68040"
    (cd "$P" && find C Docs -type f | LC_ALL=C sort) | while read -r f; do
        echo "copy \"$f\" \"SYS:$f\""
    done
} > "$P/Part"
