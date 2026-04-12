@echo off
SETLOCAL
SET RootDir=%~dp0

CALL soup build code\extension\

REM - Get the target
for /f %%i in ('soup target code\extension\') do set ExtensionOutputDirectory=%%i

CALL soup run ..\soup\code\generate-test\ -args %RootDir%\code\run-tests.wren %ExtensionOutputDirectory%\script\bundles.sml
if %ERRORLEVEL% NEQ  0 exit /B %ERRORLEVEL%