@echo off 
cd /d "%~dp0SQF-VM"

FOR /R "%~dp0.." %%G in (*.sqf) DO (
    rem echo sqfvm.exe -a --parse-only --load "./../.." -i "%%G"
    sqfvm.exe -a --parse-only --load "./../.." -i "%%G" --command-dummy-unary ofstream_new --command-dummy-binary "4|ofstream_write" --command-dummy-unary createProfileScope
)

rem sqfvm.exe -a --parse-only --load "./../../Project_0.Altis" -i "./../../%~1"
rem sqfvm.exe -a --load "./../../Project_0.Altis" -i "./../../%~1"
