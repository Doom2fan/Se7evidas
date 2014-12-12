@ECHO OFF
SETLOCAL

REM ACS stuff
SET PROG_ACC="%CD%/Tools/ACC/acc.EXE"
SET ACSSOURCE="%CD%/ACS Source"
SET ACS_DEST="%CD%/PK3 Source/acs"

%PROG_ACC% %ACSSOURCE%/Se7evidas.ACS %ACS_DEST%/Se7evidas.O

REM 7z stuff
SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"

DEL "%MAIN_7Z%/Se7evidas.PK3"
CD %PK3SOURCE%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*

CD %MAIN_7Z%
%PROG_7Z% a -t7z "%MAIN_7Z%/Se7evidas.7Z" -m0=LZMA2 -mx9 -ms=off "%MAIN_7Z%/Se7evidas.PK3" "%MAIN_7Z%/Se7evidas - Readme.TXT"

PAUSE