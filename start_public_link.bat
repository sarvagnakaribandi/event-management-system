@echo off
title EventSphere Public Link Generator
echo ========================================================
echo        Generating Global Public URL via Docker
echo ========================================================
echo.

echo Checking Docker daemon...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Desktop is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo  LOOK BELOW FOR YOUR PUBLIC HTTPS URL:
echo  (Copy the trycloudflare.com link and open it in any browser!)
echo ========================================================
echo.

docker run --rm --name cf-eventsphere cloudflare/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:8081
pause
