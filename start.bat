@echo off
setlocal
cd /d "%~dp0"

rem Moteur de conteneurs : Docker s'il est demarre, sinon Podman. RGAA_ENGINE=docker ou podman pour forcer.
set "ENGINE=%RGAA_ENGINE%"
if defined ENGINE goto moteur_choisi
where docker >nul 2>nul
if not errorlevel 1 (
    docker info >nul 2>nul
    if not errorlevel 1 set "ENGINE=docker"
)
if defined ENGINE goto moteur_choisi
where podman >nul 2>nul
if not errorlevel 1 set "ENGINE=podman"
if defined ENGINE goto moteur_choisi
where docker >nul 2>nul
if not errorlevel 1 (
    echo Docker Desktop n'est pas demarre. Le lancer, attendre qu'il soit pret, puis relancer ce script.
    pause
    exit /b 1
)
echo Ni Docker ni Podman n'est installe :
echo   Docker Desktop : https://www.docker.com/products/docker-desktop/
echo   Podman Desktop : https://podman-desktop.io/
pause
exit /b 1

:moteur_choisi
%ENGINE% info >nul 2>nul
if not errorlevel 1 goto moteur_pret
if /i not "%ENGINE%"=="podman" goto moteur_arrete
rem Sous Windows, Podman tourne dans une machine virtuelle qu'il faut demarrer, et creer la premiere fois.
podman machine inspect >nul 2>nul
if errorlevel 1 (
    echo Creation de la machine virtuelle Podman, une seule fois...
    podman machine init
)
echo Demarrage de la machine virtuelle Podman...
podman machine start
%ENGINE% info >nul 2>nul
if not errorlevel 1 goto moteur_pret
:moteur_arrete
echo %ENGINE% n'est pas demarre. Le lancer, attendre qu'il soit pret, puis relancer ce script.
pause
exit /b 1

:moteur_pret
set "COMPOSE="
%ENGINE% compose version >nul 2>nul
if not errorlevel 1 set "COMPOSE=%ENGINE% compose"
if defined COMPOSE goto compose_pret
where %ENGINE%-compose >nul 2>nul
if not errorlevel 1 set "COMPOSE=%ENGINE%-compose"
if defined COMPOSE goto compose_pret
echo Il manque l'outil compose : installer %ENGINE%-compose, ou le plugin "%ENGINE% compose".
pause
exit /b 1

:compose_pret
if not exist .env call :creer_env

%COMPOSE% up -d
if errorlevel 1 (
    echo Le demarrage a echoue. Lire le message ci-dessus.
    pause
    exit /b 1
)

set "TOKEN="
for /f "tokens=2 delims==" %%t in ('findstr /b "RGAA_API_TOKENS=" .env') do if not defined TOKEN set "TOKEN=%%t"
set "BIND="
for /f "tokens=2 delims==" %%b in ('findstr /b "RGAA_BIND_ADDRESS=" .env') do if not defined BIND set "BIND=%%b"

echo.
echo ========================================
echo  RGAA Helper est pret
echo  Adresse : http://localhost:38080
if defined BIND if not "%BIND%"=="127.0.0.1" echo            http://ADRESSE-IP-DE-CETTE-MACHINE:38080 depuis une autre machine
echo  Jeton   : %TOKEN%
echo ========================================
rem .env cree avant la 1.0.2 : la liste limite encore les sites analysables.
set "HOSTS="
for /f "tokens=2 delims==" %%h in ('findstr /b "RGAA_ALLOWED_HOSTS=" .env') do if not defined HOSTS set "HOSTS=%%h"
if defined HOSTS if not "%HOSTS%"=="*" (
    echo  Sites limites a : %HOSTS%
    echo  Pour autoriser tous les sites, supprimer la ligne RGAA_ALLOWED_HOSTS de %CD%\.env, puis relancer ce script.
)
echo  Arret : %COMPOSE% down
echo.
pause
exit /b 0

:creer_env
powershell -NoProfile -Command "$b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); $t = -join ($b | ForEach-Object { $_.ToString('x2') }); (Get-Content .env.example) -replace '^RGAA_API_TOKENS=.*', ('RGAA_API_TOKENS=' + $t) | Set-Content -Encoding ascii .env"
exit /b 0
