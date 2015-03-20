@ECHO OFF
SETLOCAL

SET PROG_ACC="C:/Users/Chronos Ouroboros/Games/Doom/GDCC/gdcc-acc.exe"
SET PROG_LD="C:/Users/Chronos Ouroboros/Games/Doom/GDCC/gdcc-ld.exe"
SET ACSSOURCE="./ACS Source"
SET ACS_TEMP="./ACS Source/Temp"
SET ACS_DEST="./PK3 Source/acs"

RMDIR /S /Q %ACS_TEMP% 2>nul
RMDIR /S /Q "./PK3 Source/acs" 2>nul
RMDIR /S /Q "./PK3 Source - Zandronum/acs" 2>nul
MKDIR "./PK3 Source/acs"
MKDIR "./PK3 Source - Zandronum/acs"
MKDIR %ACS_TEMP%
MKDIR %ACS_TEMP%/Zandro

%PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/Se7evidas.ir %ACSSOURCE%/Se7evidas.c
REM %PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/S7_Rep.ir %ACSSOURCE%/S7_Rep.c
REM %PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/Zandro/S7_Rep.ir %ACSSOURCE%/Zandronum/S7_Rep.c

PAUSE
CLS

%PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/Se7evidas.o %ACS_TEMP%/Se7evidas.ir
REM %PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/S7_Rep.o %ACS_TEMP%/S7_Rep.ir
REM %PROG_LD% --bc-target ZDoom --bc-format ACSE --output "./PK3 Source - Zandronum/acs/S7_Rep.o" %ACS_TEMP%/Zandro/S7_Rep.ir

PAUSE
RMDIR /S /Q %ACS_TEMP% 2>nul