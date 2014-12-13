@ECHO OFF
SETLOCAL

SET PROG_ACC="./Tools/ACC/acc.EXE"
SET ACSSOURCE="./ACS Source"
SET ACS_DEST="./PK3 Source/acs"

DEL "./PK3 Source/acs"
MKDIR "./PK3 Source/acs"
%PROG_ACC% %ACSSOURCE%/Se7evidas.ACS %ACS_DEST%/Se7evidas.O

SET PROG_GZDOOM="../../Final Duel/dis.EXE"

%PROG_GZDOOM% -file "%CD%/PK3 Source" -file %1 -file %2 -file %3 -file %4 -file  %5 -file %6