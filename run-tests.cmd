@echo off
SETLOCAL
SET RootDir=%~dp0

CALL soup build code\extension\

CALL soup run ..\soup\code\generate-test\ -args %RootDir%\code\run-tests.wren %RootDir%\out\Wren\Local\Cpp\0.16.2\J_HqSstV55vlb-x6RWC_hLRFRDU\script\bundles.sml
if %ERRORLEVEL% NEQ  0 exit /B %ERRORLEVEL%