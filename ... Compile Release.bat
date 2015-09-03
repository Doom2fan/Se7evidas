@ECHO OFF
SETLOCAL

REM ACS Stuff

REM 7z stuff
SET MAIN_7Z=%CD%
SET PROG_7Z="%CD%/Tools/7z/7z"
SET PK3SOURCE="%CD%/PK3 Source"
SET PK3SOURCE_GZDOOM="%CD%/PK3_Source_GZDoom"
SET PK3SOURCE_ZANDRO="%CD%/PK3_Source_Zandronum"

DEL "%MAIN_7Z%/Se7evidas.PK3" 2>nul
DEL "%MAIN_7Z%/Se7evidas_Zandro.PK3" 2>nul
CD %PK3SOURCE%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

CD %PK3SOURCE_GZDOOM%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas_GZDoom.PK3" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*

CD %PK3SOURCE_ZANDRO%
%PROG_7Z% a -tzip "%MAIN_7Z%/Se7evidas_Zandro.PK3" "*" -mx0 -r -x!*.DB -X!*.DBS -X!*.WAD.BACKUP* -X!*.TMP*
CD %MAIN_7Z%

DEL Se7evidas.7Z 2>nul
MKDIR Se7evidas
XCOPY Se7evidas.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas_GZDoom.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas_Zandro.PK3 "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-TODO.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
XCOPY Se7evidas-README.TXT "%MAIN_7Z%/Se7evidas" /Q /Y 2>nul
%PROG_7Z% A -t7z "%MAIN_7Z%/Se7evidas.7Z" -m0=LZMA2 -mx9 -ms=off "%MAIN_7Z%/Se7evidas/*"
RMDIR Se7evidas /S /Q

PAUSE