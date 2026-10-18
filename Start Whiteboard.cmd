@echo off
rem Starts the whiteboard helper (Windows PowerShell, nothing to install) and opens the whiteboard.
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0whiteboard-helper.ps1"
