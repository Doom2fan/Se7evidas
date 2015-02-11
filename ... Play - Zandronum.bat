@ECHO OFF
SETLOCAL

SET PROG_ACC="./Tools/ACC/acc.EXE"
SET ACSSOURCE="./ACS Source"
SET ACS_DEST="./PK3 Source/acs"

RMDIR /S /Q "./PK3 Source/acs" 2>nul
RMDIR /S /Q "./PK3 Source - Zandronum/acs" 2>nul
MKDIR "./PK3 Source/acs"
MKDIR "./PK3 Source - Zandronum/acs"
%PROG_ACC% %ACSSOURCE%/Se7evidas.c %ACS_DEST%/Se7evidas.O
%PROG_ACC% %ACSSOURCE%/Se7evidas_Rep.c %ACS_DEST%/Se7evidas_Rep.O

%PROG_ACC% %ACSSOURCE%/Zandronum/Se7evidas_Rep.c ./PK3 Source - Zandronum/acs/Se7evidas_Rep.O

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