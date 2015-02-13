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
%PROG_ACC% %ACSSOURCE%/S7_Rep.c %ACS_DEST%/S7_Rep.O

%PROG_ACC% %ACSSOURCE%/Zandronum/S7_Rep.c "./PK3 Source - Zandronum/acs/S7_Rep.O"

PAUSE