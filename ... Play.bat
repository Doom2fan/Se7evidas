@ECHO OFF
SETLOCAL

SET PROG_GZDOOM="gzdoom.EXE"
SET PROG_ZDOOM="zdoom.EXE"
SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"
SET PROG_PROG=""
SET PROG_ARGS=""

ECHO 1 - GZDoom
ECHO 2 - ZDoom
ECHO 3 - Zandronum
CHOICE /C 123 /N

if %ERRORLEVEL% EQU 3 (
    SET PROG_PROG=%PROG_ZANDRONUM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" %*
) else if %ERRORLEVEL% EQU 2 (
    SET PROG_PROG=%PROG_ZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*
) else if %ERRORLEVEL% EQU 1 (
    SET PROG_PROG=%PROG_GZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %*
)

%PROG_PROG% %PROG_ARGS%