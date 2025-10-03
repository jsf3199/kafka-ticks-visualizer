const express = require('express');
const path = require('path');
const fs = require('fs');
const WebSocket = require('ws');
const { Kafka } = require('kafkajs');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Configuración de Kafka
const kafka = new Kafka({
  clientId: 'visualizer',
  brokers: ['kafka:9092'],
  retry: { initialRetryTime: 100, retries: 8 }
});
const consumer = kafka.consumer({ groupId: 'visualizer', sessionTimeout: 10000 });

// Ruta para listar símbolos
app.get('/symbols', (req, res) => {
  const dataDir = '/kafka-ticks-visualizer/data';
  try {
    const files = fs.readdirSync(dataDir);
    const symbols = files
      .filter(file => file.endsWith('.json'))
      .map(file => path.parse(file).name.toUpperCase());
    res.json({ symbols: [...new Set(symbols)] });
  } catch (error) {
    res.status(500).json({ error: 'Error al listar símbolos: ' + error.message });
  }
});

// Ruta para datos por símbolo y rango de timestamps
app.get('/data/:symbol', (req, res) => {
  const symbol = req.params.symbol.toUpperCase();
  const { start, end } = req.query;
  const filePath = path.join('/kafka-ticks-visualizer/data', `${symbol}.json`);
  try {
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'Archivo no encontrado para símbolo: ' + symbol });
    }
    let rawData = fs.readFileSync(filePath, 'utf8');
    let data = JSON.parse('[' + rawData.replace(/}\s*{/g, '}, {') + ']');

    if (start || end) {
      const startDate = start ? new Date(start) : new Date(0);
      const endDate = end ? new Date(end) : new Date();
      data = data.filter(tick => {
        const tickDate = new Date(tick.Timestamp);
        return tickDate >= startDate && tickDate <= endDate;
      });
    }

    data = data.slice(-1000); // Limitar para rendimiento
    res.json({
      symbol,
      ticks: data.map(tick => ({
        timestamp: new Date(tick.Timestamp).toISOString(),
        price: parseFloat(tick.Price),
        volume: parseInt(tick.TickVolume)
      }))
    });
  } catch (error) {
    res.status(500).json({ error: 'Error al cargar datos: ' + error.message });
  }
});

// Endpoint para sincronizar estado del gráfico
app.post('/sync-state', (req, res) => {
  const { symbol, start, end, zoom } = req.body;
  console.log(`Estado sincronizado para ${symbol}: start=${start}, end=${end}, zoom=${zoom}`);
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({ type: 'graph-move', symbol, start, end, zoom }));
    }
  });
  res.json({ status: 'synced' });
});

// Inicializar consumidor Kafka
async function runConsumer() {
  await consumer.connect();
  await consumer.subscribe({ topics: ['raw_ticks', 'analysis_results'], fromBeginning: true });
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      const data = JSON.parse(message.value.toString());
      console.log(`Mensaje recibido de ${topic}: ${data.Symbol || data.symbol} at ${data.Timestamp || data.timestamp}`);
    },
  });
}
runConsumer().catch(console.error);

// WebSocket para actualizaciones en vivo y sincronización
const wss = new WebSocket.Server({ port: 3001 });
wss.on('connection', (ws) => {
  console.log('Cliente conectado para sincronización');
  ws.on('message', (message) => {
    const data = JSON.parse(message);
    if (data.type === 'graph-move') {
      wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify(data));
        }
      });
    }
  });
  // Polling para cambios en archivos
  const interval = setInterval(() => {
    const dataDir = '/kafka-ticks-visualizer/data';
    fs.readdir(dataDir, (err, files) => {
      if (err) return;
      ws.send(JSON.stringify({ type: 'live_update', files: files.filter(f => f.endsWith('.json')) }));
    });
  }, 5000);
  ws.on('close', () => clearInterval(interval));
});
console.log('WebSocket server listening on port 3001 for live updates');

// Servir index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor visualizer escuchando en puerto ${PORT}`);
});