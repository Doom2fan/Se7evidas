@ECHO OFF
SETLOCAL

SET PROG_GZDOOM="%DOOMDIR%\... Older versions\GZDoom\Latest 1.9\gzdoom.EXE"

%PROG_GZDOOM% -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*