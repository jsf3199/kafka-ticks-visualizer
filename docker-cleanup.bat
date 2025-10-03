@echo off
setlocal enabledelayedexpansion

:: Configuración del log
set LOGFILE=C:\kafka-ticks-visualizer\docker-cleanup.log
echo [%date% %time%] Iniciando limpieza completa de Docker > %LOGFILE%

:: Verificación inicial: Comprobar si Docker está instalado y corriendo
echo Verificando si Docker está disponible...
docker --version >> %LOGFILE% 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Docker no está instalado o no se puede acceder. Instálelo antes de continuar. >> %LOGFILE%
    echo ERROR: Docker no está disponible. Revise el log para detalles.
    pause
    exit /b 1
)
echo [%date% %time%] Docker está disponible. Procediendo con la limpieza. >> %LOGFILE%

:: Paso 1: Detener todos los contenedores
echo [%date% %time%] Paso 1: Deteniendo todos los contenedores... >> %LOGFILE%
for /f "tokens=1" %%i in ('docker ps -a -q') do (
    echo Deteniendo contenedor %%i >> %LOGFILE%
    docker stop %%i >> %LOGFILE% 2>&1
    if !errorlevel! neq 0 (
        echo [%date% %time%] ADVERTENCIA: Error al detener el contenedor %%i >> %LOGFILE%
    )
)
echo [%date% %time%] Verificación: Contenedores detenidos. >> %LOGFILE%
docker ps -a >> %LOGFILE% 2>&1

:: Paso 2: Eliminar todos los contenedores
echo [%date% %time%] Paso 2: Eliminando todos los contenedores... >> %LOGFILE%
for /f "tokens=1" %%i in ('docker ps -a -q') do (
    echo Eliminando contenedor %%i >> %LOGFILE%
    docker rm -f %%i >> %LOGFILE% 2>&1
    if !errorlevel! neq 0 (
        echo [%date% %time%] ADVERTENCIA: Error al eliminar el contenedor %%i >> %LOGFILE%
    )
)
echo [%date% %time%] Verificación: No deberían quedar contenedores. >> %LOGFILE%
docker ps -a >> %LOGFILE% 2>&1

:: Paso 3: Eliminar todas las imágenes
echo [%date% %time%] Paso 3: Eliminando todas las imágenes... >> %LOGFILE%
for /f "tokens=1" %%i in ('docker images -a -q') do (
    echo Eliminando imagen %%i >> %LOGFILE%
    docker rmi -f %%i >> %LOGFILE% 2>&1
    if !errorlevel! neq 0 (
        echo [%date% %time%] ADVERTENCIA: Error al eliminar la imagen %%i >> %LOGFILE%
    )
)
echo [%date% %time%] Verificación: No deberían quedar imágenes. >> %LOGFILE%
docker images -a >> %LOGFILE% 2>&1

:: Paso 4: Eliminar todas las redes personalizadas
echo [%date% %time%] Paso 4: Eliminando todas las redes personalizadas... >> %LOGFILE%
for /f "tokens=1" %%i in ('docker network ls --filter "type=custom" -q') do (
    echo Eliminando red %%i >> %LOGFILE%
    docker network rm %%i >> %LOGFILE% 2>&1
    if !errorlevel! neq 0 (
        echo [%date% %time%] ADVERTENCIA: Error al eliminar la red %%i >> %LOGFILE%
    )
)
echo [%date% %time%] Verificación: No deberían quedar redes personalizadas. >> %LOGFILE%
docker network ls >> %LOGFILE% 2>&1

:: Paso 5: Eliminar todos los volúmenes
echo [%date% %time%] Paso 5: Eliminando todos los volúmenes... >> %LOGFILE%
for /f "tokens=1" %%i in ('docker volume ls -q') do (
    echo Eliminando volumen %%i >> %LOGFILE%
    docker volume rm %%i >> %LOGFILE% 2>&1
    if !errorlevel! neq 0 (
        echo [%date% %time%] ADVERTENCIA: Error al eliminar el volumen %%i >> %LOGFILE%
    )
)
echo [%date% %time%] Verificación: No deberían quedar volúmenes. >> %LOGFILE%
docker volume ls >> %LOGFILE% 2>&1

:: Finalización
echo [%date% %time%] Limpieza completa finalizada. Revise %LOGFILE% para detalles. >> %LOGFILE%
echo Limpieza completada. Revise el log en %LOGFILE% para verificaciones.
pause
endlocal