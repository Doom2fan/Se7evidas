@ECHO OFF
SETLOCAL

SET PROG_ACC="./Tools/GDCC/gdcc-acc.exe"
SET PROG_LD="./Tools/GDCC/gdcc-ld.exe"
SET ACSSOURCE="./ACS Source"
SET ACS_TEMP="./ACS Source/Temp"
SET ACS_DEST="./PK3 Source/acs"
SET ACS_DEST_ZANDRONUM="./PK3 Source Zandronum/acs"

RMDIR /S /Q %ACS_TEMP% 2>nul
RMDIR /S /Q %ACS_DEST% 2>nul
RMDIR /S /Q %ACS_DEST_ZANDRONUM% 2>nul
MKDIR %ACS_DEST%
MKDIR %ACS_DEST_ZANDRONUM%
MKDIR %ACS_TEMP%

%PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/Se7evidas.ir %ACSSOURCE%/Se7evidas.c
%PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/S7Rep.ir %ACSSOURCE%/S7Rep.c
%PROG_ACC% --bc-target ZDoom --bc-format ACSE --output %ACS_TEMP%/S7Rep_Zandronum.ir %ACSSOURCE%/Zandronum/S7Rep.c

PAUSE
CLS

%PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/Se7evidas.o %ACS_TEMP%/Se7evidas.ir
%PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/S7Rep.o %ACS_TEMP%/S7Rep.ir
%PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST_ZANDRONUM%/S7Rep.o %ACS_TEMP%/S7Rep_Zandronum.ir

PAUSE
RMDIR /S /Q %ACS_TEMP% 2>nul