@ECHO OFF
SETLOCAL

SET PROG_GZDOOM="gzdoom.EXE"

%PROG_GZDOOM% -stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*