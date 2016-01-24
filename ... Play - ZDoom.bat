@ECHO OFF
SETLOCAL

SET PROG_ZDOOM="zdoom.EXE"

%PROG_ZDOOM% -stdout -file "%CD%/PK3_Source" -file "%CD%/PK3_Source_GZDoom" %*