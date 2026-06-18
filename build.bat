@echo off

set /p secret= < secret.txt
echo ZIP file encryption key: %secret%

setlocal

set project=ScriptedEditorScreenshot
set version=(5.4 5.5 5.6 5.7 5.8)

md BuildResults 2>NUL
md %temp%\%project% 2>NUL
for %%a in %version% do call :build %%a
rd /s /q %temp%\%project%
echo Build Results:
powershell -Command "dir BuildResults\*.zip | select Name,Length,LastWriteTime | Format-Table"
msg %username% Finished compiling %project%
pause
goto :eof

:build
set epic=
for /f "tokens=2* skip=2" %%a in ('reg query "HKLM\SOFTWARE\EpicGames\Unreal Engine\%1" /v "InstalledDirectory"') do set epic=%%b
if "%epic%"=="" goto :eof

echo Building %project% for Unreal %1
rd /s /q %temp%\%project%\%1 2>NUL
del BuildResults\%project%-%1.zip 2>NUL
md %temp%\%project%\%1 2>NUL

echo       Run UAT
call "%epic%\Engine\Build\BatchFiles\RunUAT.bat" BuildPlugin -Plugin="%CD%\%project%.uplugin" -Package="%temp%\%project%\%1" -Rocket >BuildResults\LogBuild-%1.txt
dir %temp%\%project%\%1\%project%.uplugin >NUL 2>NUL
if %errorlevel% equ 1 echo       Build error & goto :eof
rd /s /q %temp%\%project%\%1\Binaries 2>NUL
rd /s /q %temp%\%project%\%1\Intermediate 2>NUL
md %temp%\%project%\%1\Config

echo       Prepare FilterPlugin.ini and %project%.uplugin
copy /y Config\FilterPlugin.ini %temp%\%project%\%1\Config\FilterPlugin.ini 2>NUL >NUL
powershell -Command "(gc %temp%\%project%\%1\%project%.uplugin) -replace 'MarketplaceURL', 'FabURL' | Out-File -encoding ASCII %temp%\%project%\%1\%project%.uplugin"
del BuildResults\%project%-%1.zip 2>NUL
echo       Zipping

if not "%secret%" == "" (
	tar --passphrase %secret% --options zip:encryption -a -c -f BuildResults\%project%-%1.zip -C %temp%\%project%\%1\ *
)
if "%secret%" == "" (
	tar -a -c -f BuildResults\%project%-%1.zip -C %temp%\%project%\%1\ *
)
powershell -Command "dir BuildResults\%project%-%1.zip | select Name,Length,LastWriteTime | Format-List"
goto :eof
