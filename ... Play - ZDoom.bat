@ECHO OFF
SETLOCAL

SET PROG_ZDOOM="%ZDOOM64DIR%\zdoom.EXE"

%PROG_ZDOOM% -stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*