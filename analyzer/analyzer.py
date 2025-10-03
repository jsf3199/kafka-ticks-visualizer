import os
import json
from collections import defaultdict, deque  # Agregada importación para defaultdict y deque
from datetime import datetime
from confluent_kafka import Consumer, Producer

# Configuración
BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')
AGG_TOPIC = 'ticks-aggregated'
ANALYZED_TOPIC = 'ticks-analyzed'
GROUP_ID = 'analyzer-group'
WINDOW_SIZE = 5  # Tamaño de ventana para media móvil

# Configuración del consumer y producer
consumer_conf = {'bootstrap.servers': BOOTSTRAP_SERVERS, 'group.id': GROUP_ID, 'auto.offset.reset': 'earliest'}
producer_conf = {'bootstrap.servers': BOOTSTRAP_SERVERS}
consumer = Consumer(consumer_conf)
producer = Producer(producer_conf)

# Estructura para históricos por símbolo
histories = defaultdict(lambda: deque(maxlen=WINDOW_SIZE))

def calculate_sma(prices):
    """Calcula media móvil simple (SMA)."""
    return sum(prices) / len(prices) if prices else 0

def process_aggregate(agg_msg):
    """Procesa agregado OHLC y calcula SMA del close."""
    agg = agg_msg['ohlc']
    symbol = agg_msg['symbol']
    timestamp = datetime.fromisoformat(agg_msg['timestamp'])

    # Agrega close al histórico
    histories[symbol].append(agg['close'])

    if len(histories[symbol]) == WINDOW_SIZE:
        sma = calculate_sma(list(histories[symbol]))
        analyzed = {
            'symbol': symbol,
            'timestamp': timestamp.isoformat(),
            'ohlc': agg,
            'sma_5': sma
        }
        producer.produce(ANALYZED_TOPIC, key=symbol, value=json.dumps(analyzed))
        producer.flush()
        print(f'Análisis enviado para {symbol}: SMA 5 = {sma}')

if __name__ == '__main__':
    print(f'Iniciando analyzer. Consumiendo de {AGG_TOPIC}...')
    consumer.subscribe([AGG_TOPIC])
    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                print(f'Error de consumer: {msg.error()}')
                continue
            agg_msg = json.loads(msg.value().decode('utf-8'))
            process_aggregate(agg_msg)
    except KeyboardInterrupt:
        pass
    finally:
        consumer.close()
        producer.flush()