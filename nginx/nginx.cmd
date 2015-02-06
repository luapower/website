@echo off

set WEBB_DIR=C:/luapower/_luapower.com/www
set LUAPOWER_DIR=C:/luapower

set P=mingw32

set WEBBL=%WEBB_DIR%/?.lua
set LPB=%LUAPOWER_DIR%/bin/%P%
set LPBL=%LPB%/lua/?.lua
set LPBB=%LPB%/clib/?.dll
set LPL=%LUAPOWER_DIR%/?.lua

set LUA_PATH=%WEBBL%;%LPBL%;%LPL%
set LUA_CPATH=%LPBB%
set PATH=%LPB%;%PATH%

echo LUA_PATH=%LUA_PATH%
echo LUA_CPATH=%LUA_CPATH%
echo PATH=%PATH%

start /b bin/win32/nginx.exe -p . -c conf/nginx.dev.conf %*
