@ECHO OFF
SETLOCAL

if "%S7PROG_GZDOOM%" == "" (
    SET S7PROG_GZDOOM="gzdoom"
)

SET PROG_PROG=""
SET PROG_ARGS=""

if %ERRORLEVEL% NEQ 0 (
    GOTO :Finish
)

rem ECHO 1 - GZDoom
rem ECHO 0 - Exit
rem CHOICE /C 10 /N

rem if %ERRORLEVEL% EQU 2 (
rem     goto :Finish
rem ) else if %ERRORLEVEL% EQU 1 (
    SET PROG_PROG=%S7PROG_GZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" %S7_GZDOOMARGS% %*
rem )

"%PROG_PROG%" %PROG_ARGS%

:Finish