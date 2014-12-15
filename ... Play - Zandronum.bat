@ECHO OFF
SETLOCAL

SET PROG_ACC="./Tools/ACC/acc.EXE"
SET ACSSOURCE="./ACS Source"
SET ACS_DEST="./PK3 Source/acs"

RMDIR /S /Q "./PK3 Source/acs"
MKDIR "./PK3 Source/acs"
%PROG_ACC% %ACSSOURCE%/Se7evidas.ACS %ACS_DEST%/Se7evidas.O

SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"

DEL "%MAIN_7Z%/Se7evidas.PK3"
CD %PK3SOURCE%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

SET PROG_ZANDRONUM="../../zandronum.EXE"

%PROG_ZANDRONUM% -file "%MAIN_7Z%/Se7evidas.PK3" -file %1 -file %2 -file %3 -file %4 -file  %5 -file %6