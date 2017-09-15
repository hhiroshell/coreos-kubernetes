@echo off

rem -------------------------------------------------------------------
rem CA initialization script for Windows.
rem This script needs an environment that OpenSSL and 7zip has been
rem installed.
rem
rem TODO: Stop the parent process if this script end up with an error.
rem
rem -------------------------------------------------------------------

if "%~1" EQU "" goto usage
if "%~2" EQU "" goto usage
if "%~3" EQU "" goto usage

set OUTDIR=%~1
set CERTBASE=%~2
set CN=%~3
set SANS=%~4

if NOT EXIST "%OUTDIR%\" (
    echo ERROR: output directory does not exist: %OUTDIR%
    exit /b 1
)

set OUTFILE=%OUTDIR%\%CN%.tar

if EXIST "%OUTFILE%" (
    rem echo INFO: output file already exists: %OUTFILE%
    exit /b 0
)

echo "Generating SSL artifacts in %OUTDIR%"

set CONFIGFILE=%OUTDIR%\%CERTBASE%-req.cnf
set CAFILE=%OUTDIR%\ca.pem
set CAKEYFILE=%OUTDIR%\ca-key.pem
set KEYFILE=%OUTDIR%\%CERTBASE%-key.pem
set CSRFILE=%OUTDIR%\%CERTBASE%.csr
set PEMFILE=%OUTDIR%\%CERTBASE%.pem

:main
    setlocal ENABLEDELAYEDEXPANSION
    set LF=^


    call :cnf_template
    echo %SANS%
    echo %SANS:,=!LF!%
    echo %SANS:,=!LF!%>>"%CONFIGFILE%"
    openssl genrsa -out "%KEYFILE%" 2048
    openssl req -new -key "%KEYFILE%" -out "%CSRFILE%" -subj "/CN=%CN%" -config "%CONFIGFILE%"
    openssl x509 -req -in "%CSRFILE%" -CA "%CAFILE%" -CAkey "%CAKEYFILE%" -CAcreateserial -out "%PEMFILE%" -days 365 -extensions v3_req -extfile "%CONFIGFILE%"
    pushd "%OUTDIR%"
        7z a -ttar "%CN%.tar" "ca.pem" "%CERTBASE%-key.pem" "%CERTBASE%.pem"
    popd
exit /b 0

:cnf_template
    echo [req]>>"%CONFIGFILE%"
    echo req_extensions = v3_req>>"%CONFIGFILE%"
    echo distinguished_name = req_distinguished_name>>"%CONFIGFILE%"
    echo.>>"%CONFIGFILE%"
    echo [req_distinguished_name]>>"%CONFIGFILE%"
    echo.>>"%CONFIGFILE%"
    echo [ v3_req ]>>"%CONFIGFILE%"
    echo basicConstraints = CA:FALSE>>"%CONFIGFILE%"
    echo keyUsage = nonRepudiation, digitalSignature, keyEncipherment>>"%CONFIGFILE%"
    echo subjectAltName = @alt_names>>"%CONFIGFILE%"
    echo.>>"%CONFIGFILE%"
    echo [alt_names]>>"%CONFIGFILE%"
    echo DNS.1 = kubernetes>>"%CONFIGFILE%"
    echo DNS.2 = kubernetes.default>>"%CONFIGFILE%"
    echo DNS.3 = kubernetes.default.svc>>"%CONFIGFILE%"
    echo DNS.4 = kubernetes.default.svc.cluster.local>>"%CONFIGFILE%"
    echo.>>"%CONFIGFILE%"
exit /b

:usage
    echo USAGE: %0 ^<output-dir^> ^<cert-base-name^> ^<CN^> [SAN,SAN,SAN]
    echo   example: %0 ./ssl worker kube-worker IP.1=127.0.0.1,IP.2=10.0.0.1
exit /b 1
