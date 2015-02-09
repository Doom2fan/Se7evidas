@ECHO OFF
SETLOCAL

REM ACS stuff
SET PROG_ACC="%CD%/Tools/ACC/acc.EXE"
SET ACSSOURCE="%CD%/ACS Source"
SET ACS_DEST="%CD%/PK3 Source/acs"

%PROG_ACC% %ACSSOURCE%/Se7evidas.c %ACS_DEST%/Se7evidas.O

REM 7z stuff
SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"

DEL Se7evidas.PK3 2>nul
CD %PK3SOURCE%
%PROG_7Z% A -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*

CD %MAIN_7Z%
DEL Se7evidas.7Z 2>nul
MKDIR Se7evidas
XCOPY Se7evidas.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-TODO.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-README.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
%PROG_7Z% A -t7z "%MAIN_7Z%/Se7evidas.7Z" -m0=LZMA2 -mx9 -ms=off "%MAIN_7Z%/Se7evidas"
RMDIR Se7evidas /S /Q

PAUSE