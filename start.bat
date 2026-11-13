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

rem Sites autorises : sites-autorises.txt, un par ligne, plus RGAA_ALLOWED_HOSTS d'un ancien .env s'il y en a un.
set "HOSTS="
if exist sites-autorises.txt for /f "usebackq eol=# tokens=1" %%h in ("sites-autorises.txt") do call :ajouter_site "%%h"
for /f "tokens=2 delims==" %%a in ('findstr /b "RGAA_ALLOWED_HOSTS=" .env') do call :ajouter_liste "%%a"
if not defined HOSTS set "HOSTS=localhost,127.0.0.1"
set "RGAA_ALLOWED_HOSTS=%HOSTS%"

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
echo.
echo  Sites autorises : %HOSTS%
echo  Pour analyser un autre site, ajouter son adresse - une par ligne, sans https:// - dans le fichier :
echo    %CD%\sites-autorises.txt
echo  Pour l'ouvrir : notepad "%CD%\sites-autorises.txt"
echo  Enregistrer, puis relancer ce script.
echo.
echo  Arret : %COMPOSE% down
echo.
pause
exit /b 0

:ajouter_liste
rem Liste separee par des virgules. Pas de "for %%h in (...)" : il prendrait *.monsite.fr pour des noms de fichiers.
set "RESTE=%~1"
:ajouter_liste_suite
if not defined RESTE exit /b 0
set "ELEMENT="
for /f "tokens=1* delims=," %%x in ("%RESTE%") do (
    set "ELEMENT=%%x"
    set "RESTE=%%y"
)
if not defined ELEMENT exit /b 0
call :ajouter_site "%ELEMENT%"
goto ajouter_liste_suite

:ajouter_site
rem Retire https://, http:// et le chemin, pour accepter une adresse copiee du navigateur ; ignore les doublons.
set "SITE=%~1"
set "SITE=%SITE:https://=%"
set "SITE=%SITE:http://=%"
for /f "delims=/" %%p in ("%SITE%") do set "SITE=%%p"
if not defined SITE exit /b 0
if not defined HOSTS (
    set "HOSTS=%SITE%"
    exit /b 0
)
echo ,%HOSTS%, | findstr /i /l /c:",%SITE%," >nul && exit /b 0
set "HOSTS=%HOSTS%,%SITE%"
exit /b 0

:creer_env
powershell -NoProfile -Command "$b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); $t = -join ($b | ForEach-Object { $_.ToString('x2') }); (Get-Content .env.example) -replace '^RGAA_API_TOKENS=.*', ('RGAA_API_TOKENS=' + $t) | Set-Content -Encoding ascii .env"
exit /b 0
