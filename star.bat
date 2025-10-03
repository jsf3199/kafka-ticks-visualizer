@echo off
setlocal enabledelayedexpansion
set LOGFILE=logs\startup.log

:: Crear directorio de logs si no existe
IF NOT EXIST logs (
    mkdir logs
    ECHO Creando directorio de logs si no existe... >> %LOGFILE%
)

ECHO ========================================
ECHO Iniciando kafka-ticks-visualizer
ECHO ======================================== >> %LOGFILE%
ECHO ========================================
ECHO Iniciando kafka-ticks-visualizer
ECHO ========================================

:: Paso 0: Limpieza previa exhaustiva para evitar conflictos
ECHO Paso 0: Limpieza previa exhaustiva para evitar conflictos. >> %LOGFILE%
ECHO Paso 0: Limpieza previa exhaustiva para evitar conflictos.
ECHO Eliminando contenedores residuales... >> %LOGFILE%
ECHO Eliminando contenedores residuales...
docker-compose down >nul 2>&1
ECHO Eliminando volúmenes residuales... >> %LOGFILE%
ECHO Eliminando volúmenes residuales...
docker volume rm kafka-ticks-visualizer_kafka-data >nul 2>&1
ECHO Limpiando caché de Docker... >> %LOGFILE%
ECHO Limpiando caché de Docker...
docker builder prune -af >> %LOGFILE% 2>&1

:: Paso 1: Verificando prerrequisitos
ECHO Paso 1: Verificando prerrequisitos. Asegúrese de tener Docker y Docker Compose instalados. >> %LOGFILE%
ECHO Paso 1: Verificando prerrequisitos. Asegúrese de tener Docker y Docker Compose instalados.
docker info >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Error: Docker no está corriendo. Inicie Docker Desktop y reintente. >> %LOGFILE%
    ECHO Error: Docker no está corriendo. Inicie Docker Desktop y reintente.
    pause
    exit /b 1
)
docker-compose version >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Error: Docker Compose no está instalado. Instálelo y reintente. >> %LOGFILE%
    ECHO Error: Docker Compose no está instalado. Instálelo y reintente.
    pause
    exit /b 1
)

:: Verificar disponibilidad de la imagen de Kafka
ECHO Verificando disponibilidad de bitnami/kafka:3.7.0... >> %LOGFILE%
ECHO Verificando disponibilidad de bitnami/kafka:3.7.0...
docker image inspect bitnami/kafka:3.7.0 >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Imagen bitnami/kafka:3.7.0 no encontrada localmente. Descargando... >> %LOGFILE%
    ECHO Imagen bitnami/kafka:3.7.0 no encontrada localmente. Descargando...
    docker pull bitnami/kafka:3.7.0 >> %LOGFILE% 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Error: No se pudo descargar bitnami/kafka:3.7.0. Intentando con bitnami/kafka:3.6.0... >> %LOGFILE%
        ECHO Error: No se pudo descargar bitnami/kafka:3.7.0. Intentando con bitnami/kafka:3.6.0...
        docker pull bitnami/kafka:3.6.0 >> %LOGFILE% 2>&1
        IF !ERRORLEVEL! NEQ 0 (
            ECHO Error: No se pudo descargar bitnami/kafka:3.6.0. Verifique la conexión a internet o inicie sesión con 'docker login'. >> %LOGFILE%
            ECHO Error: No se pudo descargar bitnami/kafka:3.6.0. Verifique la conexión a internet o inicie sesión con 'docker login'.
            ECHO Intentando iniciar sesión en Docker Hub... >> %LOGFILE%
            ECHO Intentando iniciar sesión en Docker Hub...
            docker login
            docker pull bitnami/kafka:3.6.0 >> %LOGFILE% 2>&1
            IF !ERRORLEVEL! NEQ 0 (
                ECHO Error: Falló la descarga de bitnami/kafka:3.6.0 incluso tras iniciar sesión. Verifique Docker Hub. >> %LOGFILE%
                ECHO Error: Falló la descarga de bitnami/kafka:3.6.0 incluso tras iniciar sesión. Verifique Docker Hub.
                pause
                exit /b 1
            )
        ) ELSE (
            ECHO Imagen bitnami/kafka:3.6.0 descargada exitosamente. Actualice docker-compose.yml para usar esta versión. >> %LOGFILE%
            ECHO Imagen bitnami/kafka:3.6.0 descargada exitosamente. Actualice docker-compose.yml para usar esta versión.
        )
    ) ELSE (
        ECHO Imagen bitnami/kafka:3.7.0 descargada exitosamente. >> %LOGFILE%
        ECHO Imagen bitnami/kafka:3.7.0 descargada exitosamente.
    )
) ELSE (
    ECHO Imagen bitnami/kafka:3.7.0 ya existe localmente. >> %LOGFILE%
    ECHO Imagen bitnami/kafka:3.7.0 ya existe localmente.
)

:: Crear directorio data si no existe
ECHO Creando directorio de datos si no existe... >> %LOGFILE%
ECHO Creando directorio de datos si no existe...
IF NOT EXIST data (
    mkdir data
    ECHO Directorio data creado. >> %LOGFILE%
    ECHO Directorio data creado.
) ELSE (
    ECHO Directorio data ya existe. >> %LOGFILE%
    ECHO Directorio data ya existe.
)

:: Verificar permisos del directorio data
ECHO Verificando permisos del directorio data... >> %LOGFILE%
ECHO Verificando permisos del directorio data...
icacls data >> %LOGFILE% 2>&1
icacls data /grant Usuarios:F >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Advertencia: No se pudieron otorgar permisos completos al directorio data. Intentando como administrador... >> %LOGFILE%
    ECHO Advertencia: No se pudieron otorgar permisos completos al directorio data. Intentando como administrador...
    powershell -Command "Start-Process icacls -ArgumentList 'data /grant Usuarios:F' -Verb RunAs" >nul 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Error: No se pudieron otorgar permisos. Ejecute manualmente como administrador: icacls data /grant Usuarios:F >> %LOGFILE%
        ECHO Error: No se pudieron otorgar permisos. Ejecute manualmente como administrador: icacls data /grant Usuarios:F
        ECHO Alternativa: Elimine y recree el directorio data con permisos correctos. >> %LOGFILE%
        ECHO Alternativa: Elimine y recree el directorio data con permisos correctos.
        ECHO 1. Eliminar: Remove-Item -Recurse -Force data >> %LOGFILE%
        ECHO 2. Crear: mkdir data >> %LOGFILE%
        ECHO 3. Permisos: icacls data /grant Usuarios:F >> %LOGFILE%
    ) ELSE (
        ECHO Permisos otorgados como administrador. >> %LOGFILE%
        ECHO Permisos otorgados como administrador.
    )
) ELSE (
    ECHO Permisos otorgados correctamente. >> %LOGFILE%
    ECHO Permisos otorgados correctamente.
)

:: Paso 2: Verificando puertos necesarios
ECHO Paso 2: Verificando puertos necesarios (9092, 9093, 3000). >> %LOGFILE%
ECHO Paso 2: Verificando puertos necesarios (9092, 9093, 3000).
FOR %%P IN (9092 9093 3000) DO (
    netstat -an | findstr :%%P >nul
    IF !ERRORLEVEL! EQU 0 (
        ECHO Error: El puerto %%P está en uso. Cierre el proceso que lo usa o cambie el puerto en docker-compose.yml. >> %LOGFILE%
        ECHO Error: El puerto %%P está en uso. Cierre el proceso que lo usa o cambie el puerto en docker-compose.yml.
        pause
        exit /b 1
    )
)

:: Paso 3: Verificando archivos necesarios
ECHO Paso 3: Verificando archivos necesarios. >> %LOGFILE%
ECHO Paso 3: Verificando archivos necesarios.
FOR %%F IN (
    "producer\Dockerfile.producer"
    "aggregator\Dockerfile.aggregator"
    "analyzer\Dockerfile.analyzer"
    "visualizer\Dockerfile.visualizer"
    "producer\requirements.txt"
    "aggregator\requirements.txt"
    "analyzer\requirements.txt"
    "visualizer\package.json"
    "docker-compose.yml"
) DO (
    IF NOT EXIST %%F (
        ECHO Error: Falta el archivo %%F. >> %LOGFILE%
        ECHO Error: Falta el archivo %%F.
        pause
        exit /b 1
    )
)

:: Paso 4: Construyendo imágenes Docker
ECHO Paso 4: Construyendo imágenes Docker. >> %LOGFILE%
ECHO Paso 4: Construyendo imágenes Docker.
docker-compose build --no-cache >> %LOGFILE% 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Error: Falló la construcción de contenedores. Revise los Dockerfiles y requirements.txt en logs\startup.log. >> %LOGFILE%
    ECHO Error: Falló la construcción de contenedores. Revise los Dockerfiles y requirements.txt en logs\startup.log.
    pause
    exit /b 1
)

:: Paso 5: Iniciando los servicios con Docker Compose
ECHO Paso 5: Iniciando los servicios con Docker Compose. >> %LOGFILE%
ECHO Paso 5: Iniciando los servicios con Docker Compose.
docker-compose up -d >> %LOGFILE% 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Error: Falló el arranque de contenedores. Verifique los logs con 'docker logs kafka-ticks-visualizer-kafka-1' y logs\startup.log. >> %LOGFILE%
    ECHO Error: Falló el arranque de contenedores. Verifique los logs con 'docker logs kafka-ticks-visualizer-kafka-1' y logs\startup.log.
    ECHO Mostrando estado de contenedores: >> %LOGFILE%
    ECHO Mostrando estado de contenedores:
    docker ps -a >> %LOGFILE%
    docker ps -a
    pause
    exit /b 1
)

:: Verificar estado inicial de contenedores
ECHO Verificando estado inicial de contenedores... >> %LOGFILE%
ECHO Verificando estado inicial de contenedores...
docker ps -a >> %LOGFILE%
docker ps -a

:: Paso 6: Creando tópicos de Kafka
ECHO Paso 6: Creando tópicos de Kafka. >> %LOGFILE%
ECHO Paso 6: Creando tópicos de Kafka.
timeout /t 60 /nobreak >nul
docker exec kafka-ticks-visualizer-kafka-1 kafka-topics.sh --create --topic ticks --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 >> %LOGFILE% 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Advertencia: No se pudo crear el tópico 'ticks'. Puede que ya exista. Verifique con 'docker logs kafka-ticks-visualizer-kafka-1'. >> %LOGFILE%
    ECHO Advertencia: No se pudo crear el tópico 'ticks'. Puede que ya exista. Verifique con 'docker logs kafka-ticks-visualizer-kafka-1'.
) ELSE (
    ECHO Tópico 'ticks' creado exitosamente. >> %LOGFILE%
    ECHO Tópico 'ticks' creado exitosamente.
)

:: Paso 7: Verificando servicios saludables
ECHO Paso 7: Verificando servicios saludables. >> %LOGFILE%
ECHO Paso 7: Verificando servicios saludables.
FOR %%S IN (kafka producer aggregator analyzer visualizer) DO (
    docker inspect --format="{{.State.Health.Status}}" kafka-ticks-visualizer-%%S-1 >nul 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        ECHO Error: No se pudo verificar el estado de kafka-ticks-visualizer-%%S-1. Verifique 'docker logs kafka-ticks-visualizer-%%S-1'. >> %LOGFILE%
        ECHO Error: No se pudo verificar el estado de kafka-ticks-visualizer-%%S-1. Verifique 'docker logs kafka-ticks-visualizer-%%S-1'.
        pause
        exit /b 1
    )
    FOR /L %%I IN (1,1,45) DO (
        set STATUS=
        FOR /F %%J IN ('docker inspect --format="{{.State.Health.Status}}" kafka-ticks-visualizer-%%S-1') DO set STATUS=%%J
        IF "!STATUS!"=="healthy" (
            ECHO Servicio %%S está saludable. >> %LOGFILE%
            ECHO Servicio %%S está saludable.
            goto :next_service_%%S
        )
        timeout /t 2 /nobreak >nul
    )
    ECHO Error: Servicio %%S no está saludable después de 90s. Verifique 'docker logs kafka-ticks-visualizer-%%S-1' y logs\startup.log. >> %LOGFILE%
    ECHO Error: Servicio %%S no está saludable después de 90s. Verifique 'docker logs kafka-ticks-visualizer-%%S-1' y logs\startup.log.
    pause
    exit /b 1
    :next_service_%%S
)

:: Paso 8: Verificando datos históricos en data/
ECHO Paso 8: Verificando datos históricos en data/. >> %LOGFILE%
ECHO Paso 8: Verificando datos históricos en data/.
dir data\*.json >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
    ECHO Advertencia: No se encontraron archivos JSON en data/. Asegúrese de que cTrader haya generado BTCUSD.json. >> %LOGFILE%
    ECHO Advertencia: No se encontraron archivos JSON en data/. Asegúrese de que cTrader haya generado BTCUSD.json.
) ELSE (
    ECHO Archivos JSON encontrados en data/. >> %LOGFILE%
    ECHO Archivos JSON encontrados en data/.
)

:: Verificar estado final
ECHO Verificando estado de contenedores: >> %LOGFILE%
ECHO Verificando estado de contenedores:
docker ps >> %LOGFILE%
docker ps

:: Verificar puerto 3000
ECHO Verificando puerto 3000: >> %LOGFILE%
ECHO Verificando puerto 3000:
netstat -an | findstr :3000 >> %LOGFILE%
netstat -an | findstr :3000

ECHO ========================================
ECHO Proceso completado. Revisa logs\startup.log para detalles. >> %LOGFILE%
ECHO ========================================
ECHO Proceso completado. Revisa logs\startup.log para detalles.
ECHO Acceda a http://localhost:3000
ECHO Para detener: docker-compose down
ECHO ========================================
pause