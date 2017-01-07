@ECHO OFF
SETLOCAL

SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"
SET ZANFLAGSVALUE=""

IF DEFINED ZANFLAGS (
    SET ZANFLAGS_VALUE=%ZANFLAGS%
)

START /B "AAAA" %PROG_ZANDRONUM% -iwad doom2.wad -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" -host %ZANFLAGS_VALUE% %*
CALL %PROG_ZANDRONUM% -iwad doom2.wad -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" %S7_ZANDROARGS% -connect localhost %*