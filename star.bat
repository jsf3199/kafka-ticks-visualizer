@echo off
setlocal enabledelayedexpansion

ECHO ========================================
ECHO Iniciando kafka-ticks-visualizer
ECHO ========================================

:: Verificar si Docker está corriendo
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Docker no está corriendo. Inicie Docker Desktop y reintente.
    pause
    exit /b 1
)

:: Crear directorio data si no existe
IF NOT EXIST data (
    mkdir data
    ECHO Directorio data creado.
)

:: Otorgar permisos al directorio data
icacls data /grant Users:F >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Advertencia: No se pudieron otorgar permisos completos al directorio data.
)

:: Limpiar caché de Docker
ECHO Limpiando caché de Docker...
docker builder prune -af

:: Descargar imágenes base
ECHO Descargando imágenes base...
docker pull python:3.8-slim >nul 2>&1
docker pull node:20-slim >nul 2>&1

:: Construir servicios
ECHO Construyendo servicios...
docker-compose build

IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Falló la construcción de contenedores.
    pause
    exit /b 1
)

:: Levantar servicios
ECHO Levantando servicios...
docker-compose up -d

IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Falló el arranque de contenedores.
    pause
    exit /b 1
)

:: Esperar inicialización
ECHO Esperando inicialización de servicios (30s)...
timeout /t 30 /nobreak >nul

:: Verificar estado
ECHO Estado de contenedores:
docker ps

:: Verificar puerto 3000
ECHO Verificando puerto 3000:
netstat -an | findstr :3000

ECHO ========================================
ECHO Visualizador iniciado exitosamente.
ECHO Acceda a http://localhost:3000
ECHO Para detener: docker-compose down
ECHO ========================================
pause