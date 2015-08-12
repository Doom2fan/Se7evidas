@ECHO OFF
SETLOCAL

SET PROG_ZDOOM="%DOOMDIR%\. GZDoom\zdoom64.EXE"

%PROG_ZDOOM% -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*