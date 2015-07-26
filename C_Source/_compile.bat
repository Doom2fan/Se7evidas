@echo OFF
mkdir bin\
mkdir bin\libgdcc\
mkdir acs\
cls
color 7
setlocal EnableDelayedExpansion
echo --- Begin Build ---
set/a BUILT_FILES=0
set/a SKIPPED_FILES=0
set OUTFILE=Se7evidas
set GDCC=GDCC
set PATH=%PATH%;%GDCC%
set CFLAGS=--bc-target=ZDoom
set CC=gdcc-cc
set AS=gdcc-as
set LD=gdcc-ld

if "%1" == "clean" (
  goto make.clean
) else (
  if "%1" == "clean-all" (
    goto make.cleanall
  )
)

goto make.all

:make.clean
del bin\*.ir acs\*.bin
goto end

:make.cleanall
del bin\*.ir bin\libgdcc\*.ir acs\*.bin
goto end

:make.all
:make.libGDCC-ZDACS-asm
set TO_BUILD=bin\libgdcc\ZDACS-asm.ir
set FILES=%GDCC%\lib\src\libGDCC\ZDACS\*.asm
set EXECUTABLE=%AS%
set BUILD_RETURN=make.libGDCC-c
goto build

:make.libGDCC-c
set TO_BUILD=bin\libgdcc\c.ir
set FILES=%GDCC%\lib\src\libGDCC\*.c
set EXECUTABLE=%CC%
set BUILD_RETURN=make.libGDCC
goto build

:make.libGDCC
set TO_BUILD=bin\libgdcc\libGDCC.ir
set FILES=bin\libgdcc\*.ir
set EXECUTABLE=%LD%
set BUILD_RETURN=make.libc
set CFLAGS1=-c
goto build

:make.libc
set TO_BUILD=bin\libgdcc\libc.ir
set FILES=%GDCC%\lib\src\libc\*.c
set EXECUTABLE=%CC%
set BUILD_RETURN=make.ir
goto build

:make.ir
set TO_BUILD=bin\%OUTFILE%.ir
set FILES=src\*.c
set EXECUTABLE=%CC%
set BUILD_RETURN=make.bin
set ALWAYS_REBUILD=YES
set CFLAGS1=-iinc
goto build

:make.bin
set TO_BUILD="C:\Users\Chronos Ouroboros\Games\Doom\.. MEIN OWN FEKIN' MODS\Se7evidas\PK3_Source_GZDoom\acs\%OUTFILE%.o"
set FILES=bin\*.ir bin\libgdcc\*.ir
set EXECUTABLE=%LD%
set BUILD_RETURN=end
set ALWAYS_REBUILD=YES
goto build

:build.compile
echo --- Building !TO_BUILD! ---
set/a BUILT_FILES=%BUILT_FILES% + 1
!EXECUTABLE! !CFLAGS1! !CFLAGS! -o !TO_BUILD! !FILES!
echo !EXECUTABLE! !CFLAGS1! !CFLAGS! -o !TO_BUILD! !FILES!

goto build.finish

:build
if "!ALWAYS_REBUILD!" == "" (
  if not exist !TO_BUILD! (
    goto build.compile
  ) else (
    echo --- Already built !TO_BUILD!, skipping. ---
    set/a SKIPPED_FILES=%SKIPPED_FILES% + 1
  )
) else (
  goto build.compile
)

:build.finish
set CFLAGS1=
set LOGFILE=

goto !BUILD_RETURN!

:end
echo --- Finished. %BUILT_FILES% built, and %SKIPPED_FILES% skipped. ---
echo --- Press any key to exit. ---
endlocal
pause>nul
