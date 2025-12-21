@echo off
rem use the .bat file's directory as the working directory.
pushd %~dp0

nmake /nologo /f NMakefile %1 %2 %3 %4 %5 %6 %7 %8 %9

rem restore original working directory.
popd
