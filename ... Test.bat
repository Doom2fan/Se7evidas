@ECHO OFF
SETLOCAL

SET PROG_GZDOOM="gzdoom.EXE"
SET PROG_ZDOOM="zdoom.EXE"
SET PROG_ZANDRONUM="%DOOMDIR%\Zandronum\zandronum.EXE"
SET PROG_PROG=""
SET PROG_ARGS=""

MAKE all

if %ERRORLEVEL% NEQ 0 (
    GOTO :Finish
)

ECHO.
ECHO 1 - GZDoom
ECHO 2 - ZDoom
ECHO 3 - Zandronum
ECHO 0 - Exit
CHOICE /C 1230 /N

if %ERRORLEVEL% EQU 4 (
    goto :Finish
) else if %ERRORLEVEL% EQU 3 (
    SET PROG_PROG=%PROG_ZANDRONUM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_Zandronum" %S7_ZANDROARGS% %*
) else if %ERRORLEVEL% EQU 2 (
    SET PROG_PROG=%PROG_ZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %S7_ZDOOMARGS% %*
) else if %ERRORLEVEL% EQU 1 (
    SET PROG_PROG=%PROG_GZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" -file "%CD%/PK3_Source_GZDoom" %S7_GZDOOMARGS% %*
)

%PROG_PROG% %PROG_ARGS%

:Finish