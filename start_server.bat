@echo off
title EventSphere Server Launcher
echo ========================================================
echo        Starting EventSphere Environment
echo ========================================================
echo.

:: 1. Check & Start MySQL
echo [1/3] Checking MySQL Server (Port 3306)...
netstat -ano | findstr :3306 >nul
if %errorlevel% equ 0 (
    echo     [OK] MySQL is already running.
) else (
    echo     Starting MySQL standalone daemon...
    start "" /B "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone
    timeout /t 3 /nobreak >nul
    echo     [OK] MySQL started.
)

:: 2. Check & Start Tomcat
echo.
echo [2/3] Checking Apache Tomcat Server (Port 8081)...
netstat -ano | findstr :8081 >nul
if %errorlevel% equ 0 (
    echo     [OK] Tomcat is already running on port 8081.
) else (
    echo     Starting Tomcat 10.1.57...
    start "Tomcat 10" cmd /c "set CATALINA_HOME=C:\apache-tomcat-10.1.57&& cd /d C:\apache-tomcat-10.1.57\bin&& catalina.bat run"
    timeout /t 5 /nobreak >nul
    echo     [OK] Tomcat started.
)

:: 3. Launch in Default Browser
echo.
echo [3/3] Opening EventSphere in your web browser...
start http://localhost:8081/Eventsphere/

echo.
echo ========================================================
echo  EventSphere is running at: http://localhost:8081/Eventsphere/
echo ========================================================
pause
