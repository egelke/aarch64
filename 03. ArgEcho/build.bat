@if not exist obj mkdir obj
clang -g -c -target aarch64-pc-windows-msvc -o obj\main.obj main.s

@if not exist bin mkdir bin
link /OUT:bin\ArgEcho.exe "kernel32.lib" "Shell32.lib" /DEBUG /MACHINE:ARM64 /SUBSYSTEM:CONSOLE /NOLOGO /NODEFAULTLIB /ENTRY:"_start" obj\main.obj

xcopy /Y bin\ArgEcho.* \\%REMOTE_AARCH64_COMPUTER%\Data