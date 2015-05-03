@ECHO OFF
SETLOCAL

REM ACS Stuff
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
%PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/Se7evidas.o %ACS_TEMP%/Se7evidas.ir
REM %PROG_LD% --bc-target ZDoom --bc-format ACSE --output %ACS_DEST%/S7_Rep.o %ACS_TEMP%/S7_Rep.ir
REM %PROG_LD% --bc-target ZDoom --bc-format ACSE --output "./PK3 Source - Zandronum/acs/S7_Rep.o" %ACS_TEMP%/Zandro/S7_Rep.ir

PAUSE
RMDIR /S /Q %ACS_TEMP% 2>nul

REM 7z stuff
SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"
SET PK3SOURCE_ZANDRO="%CD%/PK3 Source - Zandronum"

DEL "%MAIN_7Z%/Se7evidas.PK3" 2>nul
DEL "%MAIN_7Z%/Se7evidas_Zandro.PK3" 2>nul
CD %PK3SOURCE%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

CD %PK3SOURCE_ZANDRO%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas_Zandro.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

DEL Se7evidas.7Z 2>nul
MKDIR Se7evidas
XCOPY Se7evidas.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas_Zandro.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-TODO.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-README.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
%PROG_7Z% A -t7z "%MAIN_7Z%/Se7evidas.7Z" -m0=LZMA2 -mx9 -ms=off "%MAIN_7Z%/Se7evidas/*"
RMDIR Se7evidas /S /Q

PAUSE