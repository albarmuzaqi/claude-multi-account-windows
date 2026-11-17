@echo off
rem Double-click to install Claude 2. Other numbers/colors: install.cmd -Number 3 -Color blue
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
