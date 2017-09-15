@echo off

rem -------------------------------------------------------------------
rem CA initialization script for Windows.
rem This script needs an environment that OpenSSL has been installed.
rem
rem TODO: Stop the parent process if this script end up with an error.
rem
rem -------------------------------------------------------------------

if "%~1" EQU "" goto usage
if "%~2" NEQ "" goto usage

set OUTDIR=%~1

if NOT EXIST "%OUTDIR%\" (
    echo ERROR: output directory does not exist: %OUTDIR%
    exit /b 1
)

set OUTFILE=%OUTDIR%\ca.pem

if EXIST "%OUTFILE%" (
    rem echo INFO: output file already exists: %OUTFILE%
    exit /b 0
)

:main
    openssl genrsa -out "%OUTDIR%/ca-key.pem" 2048
    openssl req -x509 -new -nodes -key "%OUTDIR%/ca-key.pem" -days 10000 -out "%OUTFILE%" -subj "/CN=kube-ca"
exit /b 0

:usage
    echo USAGE: %0 ^<output-dir^>
    echo   example: %0 ./ssl
exit /b 1
