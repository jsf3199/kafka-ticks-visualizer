@echo off
setlocal enabledelayedexpansion

:: Configuración del log
set LOGFILE=C:\kafka-ticks-visualizer\docker-setup.log
echo [%date% %time%] Iniciando puesta a punto de Docker > %LOGFILE%

:: Verificación inicial: Comprobar si Docker está instalado y corriendo
echo Verificando si Docker está disponible...
docker --version >> %LOGFILE% 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Docker no está instalado o no se puede acceder. Instálelo antes de continuar. >> %LOGFILE%
    echo ERROR: Docker no está disponible. Revise el log para detalles.
    pause
    exit /b 1
)
echo [%date% %time%] Docker está disponible. >> %LOGFILE%

:: Paso 1: Verificar existencia de docker-compose.yml
if not exist docker-compose.yml (
    echo [%date% %time%] ERROR: Archivo docker-compose.yml no encontrado en el directorio actual. >> %LOGFILE%
    echo ERROR: docker-compose.yml no existe. Cree uno o ajuste la configuración.
    pause
    exit /b 1
)
echo [%date% %time%] docker-compose.yml encontrado. >> %LOGFILE%

:: Paso 2: Construir y levantar los servicios con Docker Compose
echo [%date% %time%] Paso 2: Construyendo y levantando servicios con Docker Compose... >> %LOGFILE%
docker-compose up -d --build >> %LOGFILE% 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Fallo al levantar los servicios. Revise el log. >> %LOGFILE%
    echo ERROR: Fallo en docker-compose up. Revise %LOGFILE%.
    pause
    exit /b 1
)
echo [%date% %time%] Servicios levantados. >> %LOGFILE%

:: Paso 3: Verificar estado de los contenedores (running y healthy)
echo [%date% %time%] Paso 3: Verificando estado de los contenedores... >> %LOGFILE%
docker ps >> %LOGFILE% 2>&1
set "UNHEALTHY=0"
for /f "tokens=*" %%i in ('docker ps --format "{{.Names}} {{.Status}}"') do (
    echo %%i | findstr /C:"unhealthy" >nul
    if !errorlevel! equ 0 (
        set /a UNHEALTHY+=1
    )
)
if !UNHEALTHY! gtr 0 (
    echo [%date% %time%] ADVERTENCIA: Hay !UNHEALTHY! contenedores unhealthy. Revise y corrija. >> %LOGFILE%
) else (
    echo [%date% %time%] Todos los contenedores están healthy. >> %LOGFILE%
)

:: Paso 4: Verificar montajes de volúmenes (data y logs)
echo [%date% %time%] Paso 4: Verificando montajes de volúmenes... >> %LOGFILE%
docker inspect kafka-ticks-visualizer-visualizer-1 --format "{{ json .Mounts }}" >> %LOGFILE% 2>&1
echo [%date% %time%] Verificación de volúmenes completada. >> %LOGFILE%

:: Finalización
echo [%date% %time%] Puesta a punto finalizada. Acceda a http://localhost:3000 para verificar la interfaz. >> %LOGFILE%
echo Puesta a punto completada. Revise el log en %LOGFILE% para detalles.
pause
endlocal