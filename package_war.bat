@echo off
title EventSphere WAR Packager
echo ========================================================
echo        Packaging EventSphere into WAR Archive
echo ========================================================
echo.

set "JAR_EXE=C:\Program Files\Java\jdk-26.0.1\bin\jar.exe"
if not exist "%JAR_EXE%" (
    for /f "delims=" %%i in ('where jar 2^>nul') do set "JAR_EXE=%%i"
)

if not exist "%JAR_EXE%" (
    echo [ERROR] JDK jar tool not found. Ensure Java JDK is installed.
    pause
    exit /b 1
)

cd /d "C:\apache-tomcat-10.1.57\webapps\Eventsphere"
echo Building Eventsphere.war ...
"%JAR_EXE%" -cvf Eventsphere.war *.jsp css js images WEB-INF schema.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo [SUCCESS] Eventsphere.war created successfully in:
    echo C:\apache-tomcat-10.1.57\webapps\Eventsphere\Eventsphere.war
    echo ========================================================
    echo.
    echo To deploy to any Tomcat installation:
    echo Simply copy Eventsphere.war into the target tomcat/webapps/ directory!
) else (
    echo [ERROR] Failed to package WAR.
)
echo.
pause
