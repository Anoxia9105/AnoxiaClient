@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool_build.ps1" %*
