@echo off
SETLOCAL
SET RootDir=%~dp0

soup run ..\soup\code\generate-test\ -args %RootDir%\code\RunTests.wren %RootDir%\out\Wren\Local\Cpp\0.14.0\J_HqSstV55vlb-x6RWC_hLRFRDU\script\Bundles.sml
if %ERRORLEVEL% NEQ  0 exit /B %ERRORLEVEL%