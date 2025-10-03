const priceCtx = document.getElementById('tickChart').getContext('2d');
const volumeCtx = document.getElementById('volumeChart').getContext('2d');
const symbolSelector = document.createElement('select');
const controlsDiv = document.getElementById('controls');
const symbolLabel = document.createElement('label');
symbolLabel.textContent = 'Símbolo: ';
symbolLabel.appendChild(symbolSelector);
controlsDiv.prepend(symbolLabel);
let priceChart, volumeChart;

// Configuración inicial del gráfico de precios
priceChart = new Chart(priceCtx, {
  type: 'line',
  data: {
    datasets: [
      {
        label: 'Bid',
        data: [],
        borderColor: 'rgb(75, 192, 192)',
        pointRadius: 1, // Mostrar cada tick como un punto
        tension: 0.1
      },
      {
        label: 'Ask',
        data: [],
        borderColor: 'rgb(255, 99, 132)',
        pointRadius: 1, // Mostrar cada tick como un punto
        tension: 0.1
      }
    ]
  },
  options: {
    responsive: true,
    animation: false,
    scales: {
      x: {
        // No mostrar etiquetas en el gráfico de precios para evitar duplicados
        ticks: { display: false },
        type: 'time',
        time: { unit: 'second' },
      },
      y: {
        type: 'linear',
        title: { display: true, text: 'Precio' }
      }
    },
    plugins: {
      legend: { align: 'start' },
      zoom: {
        zoom: { wheel: { enabled: true }, pinch: { enabled: true }, mode: 'x' },
        pan: { enabled: true, mode: 'x' },
        // Sincronizar el gráfico de volumen cuando el de precios cambia
        onZoomComplete: ({chart}) => syncCharts(chart),
        onPanComplete: ({chart}) => syncCharts(chart)
      }
    }
  }
});

// Estado de la aplicación
let currentSymbol = null;
const MAX_POINTS = 2000;
let needsUpdate = false;

// Configuración inicial del gráfico de volumen
volumeChart = new Chart(volumeCtx, {
  type: 'bar',
  data: {
    datasets: [{
      label: 'Volumen',
      data: [],
      backgroundColor: 'rgba(150, 150, 150, 0.5)'
    }]
  },
  options: {
    responsive: true,
    animation: false,
    scales: {
      x: {
        type: 'time',
        time: { unit: 'second' },
        title: { display: true, text: 'Tiempo' }
      },
      y: {
        beginAtZero: true,
        title: { display: true, text: 'Volumen' }
      }
    },
    plugins: {
      legend: { display: false },
      tooltip: { enabled: false } // Desactivar tooltips para el gráfico de volumen
    }
  }
});

function syncCharts(sourceChart) {
  const {min, max} = sourceChart.scales.x;
  volumeChart.options.scales.x.min = min;
  volumeChart.options.scales.x.max = max;
  volumeChart.update('none');
}
function connectWS() {
  const ws = new WebSocket(`ws://${window.location.hostname}:3001`);

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    // Solo procesar el tick si corresponde al símbolo seleccionado
    if (msg.type === 'live_tick' && msg.symbol === currentSymbol) {
      addTick(msg.tick);
    }
  };

  ws.onclose = () => setTimeout(connectWS, 2000);
}

// Cargar datos históricos para un símbolo
async function loadSymbolData(symbol) {
  if (!symbol) return;
  currentSymbol = symbol;

  try {
    const response = await fetch(`/data/${symbol}`);
    if (!response.ok) {
      throw new Error(`Error al cargar datos: ${response.statusText}`);
    }
    const data = await response.json();

    // Limpiar datos anteriores
    priceChart.data.datasets[0].data = [];
    priceChart.data.datasets[1].data = [];
    volumeChart.data.datasets[0].data = [];

    // Cargar datos históricos
    data.ticks.forEach(tick => {
      const x = parseTimestamp(tick.timestamp);
      priceChart.data.datasets[0].data.push({ x, y: tick.bid || tick.price });
      priceChart.data.datasets[1].data.push({ x, y: tick.ask || tick.price });
      volumeChart.data.datasets[0].data.push({ x, y: tick.volume });
    });

    priceChart.update('none');
    volumeChart.update('none');
  } catch (error) {
    console.error('No se pudieron cargar los datos históricos:', error);
  }
}
function parseTimestamp(ts) {
  const d = new Date(ts);
  return d.getTime();
}

function addTick(tick) {
  const x = parseTimestamp(tick.timestamp);

  priceChart.data.datasets[0].data.push({ x, y: tick.bid || tick.price });
  priceChart.data.datasets[1].data.push({ x, y: tick.ask || tick.price });
  volumeChart.data.datasets[0].data.push({ x, y: tick.volume });

  // Limitar tamaño de buffers
  priceChart.data.datasets.forEach(ds => {
    if (ds.data.length > MAX_POINTS) ds.data.shift();
  });
  const volDs = volumeChart.data.datasets[0];
  if (volDs.data.length > MAX_POINTS) volDs.data.shift();

  needsUpdate = true;
}

// Loop de actualización con throttle
function updateLoop() {
  if (needsUpdate) {
    priceChart.update('none');
    volumeChart.update('none');
    needsUpdate = false;
  }
  requestAnimationFrame(updateLoop);
}

// Controles
document.getElementById('resetZoom').addEventListener('click', () => {
  priceChart.resetZoom();
  // La sincronización se encargará del gráfico de volumen
});

document.getElementById('scaleMode').addEventListener('change', (e) => {
  priceChart.options.scales.y.type = e.target.value;
  priceChart.update();
});

symbolSelector.addEventListener('change', (e) => {
  loadSymbolData(e.target.value);
});

// Inicializar
async function initialize() {
  try {
    const response = await fetch('/symbols');
    const { symbols } = await response.json();

    if (symbols && symbols.length > 0) {
      symbols.forEach(s => {
        const option = document.createElement('option');
        option.value = s;
        option.textContent = s;
        symbolSelector.appendChild(option);
      });
      await loadSymbolData(symbols[0]); // Cargar el primer símbolo por defecto
    }
  } catch (error) {
    console.error('Error al inicializar símbolos:', error);
  }
  connectWS();
  updateLoop();
}

initialize();
