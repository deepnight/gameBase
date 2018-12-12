@echo off

set redist=redist
set game=CatsAreAssholes

echo Cleaning...
rmdir /Q/S "%redist%" >nul
mkdir "%redist%\" >nul
mkdir "%redist%\%game%\" >nul

echo Copying hl.exe files...
copy %haxepath%\hl.exe "%redist%\%game%"
copy %haxepath%\libhl.dll "%redist%\%game%"
copy %haxepath%\msvcr120.dll "%redist%\%game%"
copy %haxepath%\OpenAL32.dll "%redist%\%game%"
copy %haxepath%\SDL2.dll "%redist%\%game%"
REM copy %haxepath%\depends.dll "%redist%\%game%"
REM copy %haxepath%\gc.dll "%redist%\%game%"
REM copy %haxepath%\msvcr100.dll "%redist%\%game%"
REM copy %haxepath%\msvcp120.dll "%redist%\%game%"
REM copy %haxepath%\neko.dll "%redist%\%game%"

copy %haxepath%\fmt.hdll "%redist%\%game%"
copy %haxepath%\openal.hdll "%redist%\%game%"
copy %haxepath%\ui.hdll "%redist%\%game%"
copy %haxepath%\uv.hdll "%redist%\%game%"
copy %haxepath%\sdl.hdll "%redist%\%game%"
REM copy %haxepath%\ssl.ndll "%redist%\%game%"
REM copy %haxepath%\std.ndll "%redist%\%game%"
REM copy %haxepath%\zlib.ndll "%redist%\%game%"
REM copy %haxepath%\regexp.ndll "%redist%\%game%"
REM copy %haxepath%\mysql5.ndll "%redist%\%game%"
REM copy %haxepath%\mod_tora2.ndll "%redist%\%game%"


ren "%redist%\%game%"\*.exe "%game%.exe"

echo HL...
haxe hl.hxml

echo Flash...
haxe flash.hxml

echo JS...
haxe js.hxml

echo Copying binaries...
copy bin\client.hl "%redist%\%game%\hlboot.dat" >nul
copy bin\client.swf "%redist%" >nul
copy bin\client.js "%redist%" >nul
echo Done!