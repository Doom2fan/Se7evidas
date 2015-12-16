@ECHO OFF
SETLOCAL

SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"

%PROG_ZANDRONUM% -stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" %*