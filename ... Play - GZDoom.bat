@ECHO OFF
SETLOCAL

SET PROG_ACC="./Tools/ACC/acc.EXE"
SET ACSSOURCE="./ACS Source"
SET ACS_DEST="./PK3 Source/acs"

RMDIR /S /Q "./PK3 Source/acs" 2>nul
MKDIR "./PK3 Source/acs"
%PROG_ACC% %ACSSOURCE%/Se7evidas.c %ACS_DEST%/Se7evidas.O
%PROG_ACC% %ACSSOURCE%/Se7evidas_Rep.c %ACS_DEST%/Se7evidas_Rep.O

SET PROG_GZDOOM="../../gzdoom.EXE"

%PROG_GZDOOM% -file "%CD%/PK3 Source" %*