@ECHO OFF
SETLOCAL

SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"

%PROG_ZANDRONUM% -stdout "%CD%/PK3 Source" "%CD%/PK3_Source_Zandronum" %*