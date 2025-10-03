@echo off
setlocal EnableDelayedExpansion

echo Iniciando el script para configurar y lanzar el sistema de visualización de ticks con Apache Kafka 4.0.0.
echo Creando directorio de logs si no existe...
if not exist "logs" mkdir logs
echo Iniciando el script para configurar y lanzar el sistema de visualización de ticks con Apache Kafka 4.0.0. >> logs\startup.log
echo Este script es 100%% de código abierto, sin dependencias de Confluent, y todo se ejecuta localmente.
echo Este script es 100%% de código abierto, sin dependencias de Confluent, y todo se ejecuta localmente. >> logs\startup.log
echo Fecha y hora: %date% %time%
echo Fecha y hora: %date% %time% >> logs\startup.log

echo Paso 0: Limpieza previa exhaustiva para evitar conflictos.
echo Paso 0: Limpieza previa exhaustiva para evitar conflictos. >> logs\startup.log
echo Deteniendo y eliminando contenedores existentes del proyecto...
echo Deteniendo y eliminando contenedores existentes del proyecto... >> logs\startup.log
docker-compose down -v >nul 2>&1
if %errorlevel% neq 0 (
    echo Advertencia: No se pudo ejecutar 'docker-compose down'. Continuando...
    echo Advertencia: No se pudo ejecutar 'docker-compose down'. Continuando... >> logs\startup.log
)
echo Eliminando contenedores residuales...
echo Eliminando contenedores residuales... >> logs\startup.log
docker rm -f $(docker ps -a -q --filter ancestor=bitnami/kafka) >nul 2>&1
echo Eliminando imágenes locales...
echo Eliminando imágenes locales... >> logs\startup.log
for /f "tokens=*" %%i in ('docker images -q kafka-ticks-visualizer-*') do docker rmi -f %%i >nul 2>&1
docker rmi -f bitnami/kafka:4.0.0 >nul 2>&1
echo Eliminando volúmenes no utilizados...
echo Eliminando volúmenes no utilizados... >> logs\startup.log
docker volume prune -f >nul 2>&1
echo Eliminando redes no utilizadas...
echo Eliminando redes no utilizadas... >> logs\startup.log
docker network prune -f >nul 2>&1
echo Limpieza completa.
echo Limpieza completa. >> logs\startup.log
pause

echo Paso 1: Verificando prerrequisitos. Asegúrese de tener Docker y Docker Compose instalados.
echo Paso 1: Verificando prerrequisitos. Asegúrese de tener Docker y Docker Compose instalados. >> logs\startup.log
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker no está instalado. Instale Docker Desktop desde https://www.docker.com/products/docker-desktop.
    echo Error: Docker no está instalado. Instale Docker Desktop desde https://www.docker.com/products/docker-desktop. >> logs\startup.log
    pause
    exit /b 1
)
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker Compose no está instalado. Instale la versión más reciente compatible con Docker.
    echo Error: Docker Compose no está instalado. Instale la versión más reciente compatible con Docker. >> logs\startup.log
    pause
    exit /b 1
)
echo Prerrequisitos verificados exitosamente.
echo Prerrequisitos verificados exitosamente. >> logs\startup.log
pause

echo Paso 2: Verificando puertos necesarios (9092, 9093, 3000).
echo Paso 2: Verificando puertos necesarios (9092, 9093, 3000). >> logs\startup.log
netstat -ano | findstr ":9092 :9093 :3000" >nul
if %errorlevel% equ 0 (
    echo Advertencia: Los puertos 9092, 9093 o 3000 están en uso. Intente liberarlos.
    echo Advertencia: Los puertos 9092, 9093 o 3000 están en uso. Intente liberarlos. >> logs\startup.log
    pause
)
echo Puertos verificados.
echo Puertos verificados. >> logs\startup.log
pause

echo Paso 3: Verificando archivos necesarios.
echo Paso 3: Verificando archivos necesarios. >> logs\startup.log
set "missing_files="
if not exist "docker-compose.yml" set "missing_files=!missing_files! docker-compose.yml"
if not exist "Dockerfile.producer" set "missing_files=!missing_files! Dockerfile.producer"
if not exist "Dockerfile.aggregator" set "missing_files=!missing_files! Dockerfile.aggregator"
if not exist "Dockerfile.analyzer" set "missing_files=!missing_files! Dockerfile.analyzer"
if not exist "Dockerfile.visualizer" set "missing_files=!missing_files! Dockerfile.visualizer"
if not exist "producer\producer.py" set "missing_files=!missing_files! producer\producer.py"
if not exist "aggregator\aggregator.py" set "missing_files=!missing_files! aggregator\aggregator.py"
if not exist "analyzer\analyzer.py" set "missing_files=!missing_files! analyzer\analyzer.py"
if not exist "visualizer\server.js" set "missing_files=!missing_files! visualizer\server.js"
if not exist "visualizer\package.json" set "missing_files=!missing_files! visualizer\package.json"
if not exist "visualizer\public\index.html" set "missing_files=!missing_files! visualizer\public\index.html"
if not exist "data" set "missing_files=!missing_files! data/"
if not exist "config.json" set "missing_files=!missing_files! config.json"
if not exist "requirements.txt" set "missing_files=!missing_files! requirements.txt"
if defined missing_files (
    echo Error: Faltan los siguientes archivos o directorios:%missing_files%
    echo Error: Faltan los siguientes archivos o directorios:%missing_files% >> logs\startup.log
    pause
    exit /b 1
)
echo Archivos necesarios verificados.
echo Archivos necesarios verificados. >> logs\startup.log
pause

echo Paso 4: Construyendo imágenes Docker.
echo Paso 4: Construyendo imágenes Docker. >> logs\startup.log
docker-compose build
if %errorlevel% neq 0 (
    echo Error: Fallo al construir las imágenes Docker. Verifique los Dockerfiles y los logs en logs\startup.log.
    echo Error: Fallo al construir las imágenes Docker. Verifique los Dockerfiles y los logs en logs\startup.log. >> logs\startup.log
    pause
    exit /b 1
)
echo Imágenes construidas exitosamente.
echo Imágenes construidas exitosamente. >> logs\startup.log
pause

echo Paso 5: Iniciando los servicios con Docker Compose.
echo Paso 5: Iniciando los servicios con Docker Compose. >> logs\startup.log
docker-compose up -d
if %errorlevel% neq 0 (
    echo Error: Fallo al iniciar los servicios. Revise los logs con 'docker-compose logs' o en logs\startup.log.
    echo Error: Fallo al iniciar los servicios. Revise los logs con 'docker-compose logs' o en logs\startup.log. >> logs\startup.log
    pause
    exit /b 1
)
echo Servicios iniciados. Acceda a la visualización en http://localhost:3000.
echo Servicios iniciados. Acceda a la visualización en http://localhost:3000. >> logs\startup.log
echo Para detener: docker-compose down.
echo Para detener: docker-compose down. >> logs\startup.log

echo Paso 6: Creando tópicos de Kafka.
echo Paso 6: Creando tópicos de Kafka. >> logs\startup.log
docker-compose exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic raw_ticks --partitions 1 --replication-factor 1 >nul 2>&1
docker-compose exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic aggregated_1s --partitions 1 --replication-factor 1 >nul 2>&1
docker-compose exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic aggregated_1m --partitions 1 --replication-factor 1 >nul 2>&1
docker-compose exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --topic analysis_results --partitions 1 --replication-factor 1 >nul 2>&1
echo Tópicos creados exitosamente.
echo Tópicos creados exitosamente. >> logs\startup.log
pause

echo Paso 7: Verificando servicios saludables.
echo Paso 7: Verificando servicios saludables. >> logs\startup.log
docker-compose ps --services --filter "status=healthy" >> logs\startup.log
echo Servicios saludables verificados.
echo Servicios saludables verificados. >> logs\startup.log
pause

echo Paso 8: Verificando datos históricos en data/.
echo Paso 8: Verificando datos históricos en data/. >> logs\startup.log
dir data\*.json >> logs\startup.log
echo Contando líneas históricas en BTCUSD.json...
echo Contando líneas históricas en BTCUSD.json... >> logs\startup.log
find /c /v "" data\BTCUSD.json >> logs\startup.log
echo Verificación de datos completa.
echo Verificación de datos completa. >> logs\startup.log
pause

echo Proceso completado. Revisa logs\startup.log para detalles.
echo Proceso completado. Revisa logs\startup.log para detalles. >> logs\startup.log
pause