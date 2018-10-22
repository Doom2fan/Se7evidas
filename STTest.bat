@ECHO OFF
SETLOCAL

:loop
IF NOT "%1"=="" (
    IF "%1"=="-i" (
        SET acceptInput=1
        SHIFT
    )
    SHIFT
    GOTO :loop
)

if "%S7PROG_GZDOOM%" == "" (
    SET S7PROG_GZDOOM="gzdoom.exe"
)
if "%S7PROG_QZDOOM%" == "" (
    SET S7PROG_QZDOOM="qzdoom.exe"
)

SET PROG_PROG=""
SET PROG_ARGS=""
SET customArgs=""

if %ERRORLEVEL% NEQ 0 (
    GOTO :Finish
)

if %acceptInput% == 1 (
    SET /P customArgs="Input arguments: "
)

SET PROG_PROG=%S7PROG_GZDOOM%
SET PROG_ARGS=-stdout -file "%CD%/PK3 Source" %S7_GZDOOMARGS% %*

"%PROG_PROG%" %PROG_ARGS% %customArgs%

:Finish