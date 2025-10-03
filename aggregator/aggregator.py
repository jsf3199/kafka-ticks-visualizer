import os
import json
from datetime import datetime, timedelta
from collections import defaultdict
from confluent_kafka import Consumer, Producer

# Configuración
BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')
RAW_TOPIC = 'raw_ticks'  # Cambiado para coincidir con producer
AGG_TOPIC = 'analysis_results'  # Cambiado para coincidir con visualizer
GROUP_ID = 'aggregator-group'

# Configuración del consumer y producer
consumer_conf = {'bootstrap.servers': BOOTSTRAP_SERVERS, 'group.id': GROUP_ID, 'auto.offset.reset': 'earliest'}
producer_conf = {'bootstrap.servers': BOOTSTRAP_SERVERS}
consumer = Consumer(consumer_conf)
producer = Producer(producer_conf)

# Estructura para agregados por símbolo e intervalo
aggregates = defaultdict(lambda: defaultdict(lambda: {'open': None, 'high': float('-inf'), 'low': float('inf'), 'close': None, 'volume': 0}))

def process_tick(tick):
    """Procesa un tick y actualiza agregados OHLC por minuto."""
    symbol = tick['Symbol']  # Ajustado a 'Symbol' del JSON
    timestamp = datetime.fromisoformat(tick['Timestamp'])  # Ajustado a 'Timestamp' del JSON
    interval = timestamp.replace(second=0, microsecond=0)  # Redondea al minuto
    agg = aggregates[symbol][interval]

    price = float(tick['Price'])
    volume = float(tick['TickVolume'])

    if agg['open'] is None:
        agg['open'] = price
    agg['high'] = max(agg['high'], price)
    agg['low'] = min(agg['low'], price)
    agg['close'] = price
    agg['volume'] += volume

def send_aggregate(symbol, interval, agg):
    """Envía agregado OHLC a Kafka."""
    message = {
        'symbol': symbol,
        'timestamp': interval.isoformat(),
        'ohlc': agg
    }
    producer.produce(AGG_TOPIC, key=symbol, value=json.dumps(message))
    producer.flush()
    print(f'Agregado enviado para {symbol} en {interval}: {agg}')

if __name__ == '__main__':
    print(f'Iniciando aggregator. Consumiendo de {RAW_TOPIC}...')
    consumer.subscribe([RAW_TOPIC])
    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                print(f'Error de consumer: {msg.error()}')
                continue
            tick = json.loads(msg.value().decode('utf-8'))
            process_tick(tick)
            # Envía agregados cada minuto (simplificado)
            now = datetime.now()
            for symbol in aggregates:
                for interval in list(aggregates[symbol]):
                    if now - interval > timedelta(minutes=1):
                        send_aggregate(symbol, interval, aggregates[symbol].pop(interval))
    except KeyboardInterrupt:
        pass
    finally:
        consumer.close()
        producer.flush()