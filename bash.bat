@echo off

where git > "%TEMP%\zwvar"
set /p bashpath= <"%TEMP%\zwvar"
set bashpath="%bashpath:cmd\git.exe=bin\bash.exe%"
if exist %bashpath% (
    %bashpath% -li
) else (
    echo Bash dose not exist.
)