@echo off
REM Script de inicio rápido para Kafka Ticks Visualizer

REM Detener y eliminar contenedores existentes
cd /d %~dp0

docker-compose down

REM Reconstruir y levantar todos los servicios
call docker-compose up --build -d

REM Esperar unos segundos para que los servicios arranquen
ping -n 10 127.0.0.1 >nul

REM Abrir la página del visualizador en el navegador predeterminado
start http://localhost:3000

echo Visualizador iniciado. Puedes cerrar esta ventana.
pause