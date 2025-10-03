import json
import os
import time
from datetime import datetime
from confluent_kafka import Producer
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuración
BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')
DATA_DIR = os.environ.get('DATA_DIR', '/data')
TOPIC = 'raw_ticks'  # Cambiado a 'raw_ticks' para coincidir con visualizer

# Configuración del producer
conf = {'bootstrap.servers': BOOTSTRAP_SERVERS}
producer = Producer(conf)

def delivery_report(err, msg):
    """Callback para reportar entrega de mensajes."""
    if err is not None:
        print(f'Mensaje fallido: {err}')
    else:
        print(f'Mensaje entregado a {msg.topic()} [{msg.partition()}] en offset {msg.offset()}')

class DataHandler(FileSystemEventHandler):
    """Manejador de eventos para cambios en archivos de datos."""
    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith('.json'):
            process_file(event.src_path)

def process_file(file_path):
    """Procesa un archivo JSON de ticks y envía a Kafka."""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        for tick in data:
            tick['timestamp'] = datetime.fromtimestamp(tick['timestamp']).isoformat() if isinstance(tick['timestamp'], (int, float)) else tick['timestamp']
            message = json.dumps(tick)
            producer.produce(TOPIC, key=tick.get('Symbol', 'unknown'), value=message, callback=delivery_report)
        producer.flush()
        print(f'Archivo {file_path} procesado y enviado a {TOPIC}.')
    except Exception as e:
        print(f'Error procesando {file_path}: {e}')

if __name__ == '__main__':
    print(f'Iniciando producer. Monitoreando {DATA_DIR}...')
    event_handler = DataHandler()
    observer = Observer()
    observer.schedule(event_handler, DATA_DIR, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    producer.flush()