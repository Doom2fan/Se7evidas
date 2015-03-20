@ECHO OFF
SETLOCAL

SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"
SET PK3SOURCE_ZANDRO="%CD%/PK3 Source - Zandronum"

DEL "%MAIN_7Z%/Se7evidas.PK3" 2>nul
DEL "%MAIN_7Z%/Se7evidas_Zandro.PK3" 2>nul
CD %PK3SOURCE%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

CD %PK3SOURCE_ZANDRO%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas_Zandro.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

SET PROG_ZANDRONUM="C:\Users\Chronos Ouroboros\Games\Doom\__________ Other ports\Zandronum 2.0\zandronum.EXE"

%PROG_ZANDRONUM% -file "%MAIN_7Z%/Se7evidas.PK3" -file "%MAIN_7Z%/Se7evidas_Zandro.PK3" -file %1 -file %2 -file %3 -file %4 -file  %5 -file %6