@ECHO OFF
SETLOCAL

if "%S7PROG_GZDOOM%" == "" (
    SET S7PROG_GZDOOM="gzdoom"
)
if "%S7PROG_QZDOOM%" == "" (
    SET S7PROG_QZDOOM="qzdoom"
)

SET PROG_PROG=""
SET PROG_ARGS=""

if %ERRORLEVEL% NEQ 0 (
    GOTO :Finish
)

ECHO 1 - GZDoom
ECHO 2 - QZDoom
ECHO 0 - Exit
CHOICE /C 120 /N

if %ERRORLEVEL% EQU 3 (
    goto :Finish
) else if %ERRORLEVEL% EQU 2 (
    SET PROG_PROG=%S7PROG_QZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" %S7_QZDOOMARGS% %*
) else if %ERRORLEVEL% EQU 1 (
    SET PROG_PROG=%S7PROG_GZDOOM%
    SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" %S7_GZDOOMARGS% %*
)

"%PROG_PROG%" %PROG_ARGS%

:Finish