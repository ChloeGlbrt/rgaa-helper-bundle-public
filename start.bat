@echo off
setlocal
cd /d "%~dp0"

where docker >nul 2>nul
if errorlevel 1 (
    echo Docker n'est pas installe. Installer Docker Desktop : https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)
docker info >nul 2>nul
if errorlevel 1 (
    echo Docker Desktop n'est pas demarre. Le lancer, attendre qu'il soit pret, puis relancer ce script.
    pause
    exit /b 1
)

if not exist .env call :creer_env

docker compose up -d
if errorlevel 1 (
    echo Le demarrage a echoue. Lire le message ci-dessus.
    pause
    exit /b 1
)

set "TOKEN="
for /f "tokens=2 delims==" %%t in ('findstr /b "RGAA_API_TOKENS=" .env') do if not defined TOKEN set "TOKEN=%%t"

echo.
echo ========================================
echo  RGAA Helper est pret
echo  Adresse : http://localhost:38080
echo  Jeton   : %TOKEN%
echo ========================================
echo  Arret : docker compose down
echo.
pause
exit /b 0

:creer_env
powershell -NoProfile -Command "$b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); $t = -join ($b | ForEach-Object { $_.ToString('x2') }); (Get-Content .env.example) -replace '^RGAA_API_TOKENS=.*', ('RGAA_API_TOKENS=' + $t) | Set-Content -Encoding ascii .env"
exit /b 0

