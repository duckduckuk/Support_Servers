@echo off
echo.
cd c:\
cd "Program Files (x86)\"
cd TeamViewer
xcopy /s Connections_incoming.txt c:\admin\logo\
cd c:\admin\logo\
rename Connections_incoming.txt citb.jpg
dir
pause