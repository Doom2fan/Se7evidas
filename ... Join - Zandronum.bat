@ECHO OFF
SETLOCAL

SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"

CALL %PROG_ZANDRONUM% -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" %S7_ZANDROARGS% -connect %*