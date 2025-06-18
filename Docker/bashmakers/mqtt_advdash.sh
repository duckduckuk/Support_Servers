#!/bin/bash

# ==============================================================================
#
# Title: Docker MQTT Broker & Advanced Web Dashboard Setup Script
# Description: This script automates the setup of an Eclipse Mosquitto MQTT
#              broker and an advanced, Nginx-served web dashboard using Docker.
#              The dashboard is password-protected and includes real-time
#              charting, JSON formatting, and persistent history.
# Author: Gemini
# Date: 2024-06-18
#
# ==============================================================================

# --- Function to check if Docker is installed and running ---
check_docker() {
    echo "### Checking for Docker..."
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker to use this script."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo "Error: Docker is not running. Please start the Docker daemon."
        exit 1
    fi
    echo "### Docker is installed and running."
}

# --- Main Script ---

echo "======================================================"
echo "   MQTT Broker & Advanced Web Dashboard Docker Setup"
echo "======================================================"
echo
echo "This script will set up a password-protected Mosquitto MQTT broker"
echo "and a custom, password-protected web dashboard served by Nginx."
echo

# Check for Docker before proceeding
check_docker

# --- Gather Dashboard Authentication Details ---
echo
echo "--- Web Dashboard Security ---"
read -p "Enter a username for the Web Dashboard: " DASHBOARD_USER
while [ -z "$DASHBOARD_USER" ]; do
    echo "Dashboard username cannot be empty."
    read -p "Enter a username for the Web Dashboard: " DASHBOARD_USER
done

read -sp "Enter a password for the Web Dashboard: " DASHBOARD_PASSWORD
echo
while [ -z "$DASHBOARD_PASSWORD" ]; do
    echo "Dashboard password cannot be empty."
    read -sp "Enter a password for the Web Dashboard: " DASHBOARD_PASSWORD
    echo
done


# --- Gather MQTT Broker Credentials ---
echo
echo "--- MQTT Broker Credentials (for client connection) ---"
read -p "Enter a username for MQTT connection: " MQTT_USER
while [ -z "$MQTT_USER" ]; do
    echo "MQTT username cannot be empty."
    read -p "Enter a username for MQTT connection: " MQTT_USER
done

read -sp "Enter a password for the MQTT user: " MQTT_PASSWORD
echo
while [ -z "$MQTT_PASSWORD" ]; do
    echo "MQTT password cannot be empty."
    read -sp "Enter a password for the MQTT user: " MQTT_PASSWORD
    echo
done

# --- Gather Port Configuration ---
echo
echo "--- Port Configuration ---"
read -p "Enter external port for MQTT (default: 1883): " MQTT_PORT
MQTT_PORT=${MQTT_PORT:-1883}

read -p "Enter external port for MQTT over WebSockets (default: 9001): " MQTT_WS_PORT
MQTT_WS_PORT=${MQTT_WS_PORT:-9001}

read -p "Enter external port for the Web Dashboard (default: 8088): " WEB_UI_PORT
WEB_UI_PORT=${WEB_UI_PORT:-8088}

# --- Define Paths and Names ---
BROKER_CONTAINER_NAME="mosquitto-broker"
WEB_UI_CONTAINER_NAME="mqtt-custom-dashboard"
DASHBOARD_IMAGE_NAME="mqtt-dashboard-image"
NETWORK_NAME="mqtt-net"
BASE_DIR="$(pwd)"
MOSQUITTO_CONFIG_DIR="$BASE_DIR/mosquitto_config"
DASHBOARD_APP_DIR="$BASE_DIR/dashboard_app"
NGINX_CONFIG_DIR="$DASHBOARD_APP_DIR/nginx"

# --- Prepare Mosquitto Configuration ---
echo
echo "### Preparing Mosquitto configuration..."
mkdir -p "$MOSQUITTO_CONFIG_DIR"
docker run --rm -v "$MOSQUITTO_CONFIG_DIR:/mosquitto/config" eclipse-mosquitto:2 \
sh -c "touch /mosquitto/config/passwd && mosquitto_passwd -b /mosquitto/config/passwd $MQTT_USER $MQTT_PASSWORD"
cat > "$MOSQUITTO_CONFIG_DIR/mosquitto.conf" <<EOF
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_type all
listener 1883
protocol mqtt
listener 9001
protocol websockets
allow_anonymous false
password_file /mosquitto/config/passwd
EOF
echo "### Mosquitto configuration created in '$MOSQUITTO_CONFIG_DIR'."

# --- Prepare Custom Web Dashboard Files ---
echo
echo "### Preparing custom web dashboard files..."
mkdir -p "$DASHBOARD_APP_DIR"
mkdir -p "$NGINX_CONFIG_DIR"

# 1. Create Nginx password file
echo "### Creating dashboard password file..."
docker run --rm httpd:2.4 htpasswd -Bbn "$DASHBOARD_USER" "$DASHBOARD_PASSWORD" > "$NGINX_CONFIG_DIR/.htpasswd"

# 2. Create custom Nginx config
cat > "$NGINX_CONFIG_DIR/default.conf" <<EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/conf.d/.htpasswd;
        try_files \$uri \$uri/ =404;
    }
}
EOF

# 3. Create index.html with all new features
cat > "$DASHBOARD_APP_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Advanced MQTT Web Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
    <style>
        body { background-color: #f0f2f5; }
        #main-content { display: none; }
        .log-box { height: 400px; background-color: #fff; border: 1px solid #dee2e6; border-radius: 0.375rem; overflow-y: scroll; font-family: 'Fira Code', 'Courier New', monospace; font-size: 0.85em; }
        .log-entry { position: relative; padding-right: 30px; }
        .copy-btn { position: absolute; top: 5px; right: 5px; cursor: pointer; opacity: 0.3; }
        .copy-btn:hover { opacity: 1; }
        pre { margin: 0; white-space: pre-wrap; word-break: break-all; }
        .card { box-shadow: 0 0 1rem rgba(0,0,0,.05); }
    </style>
</head>
<body class="p-4">

    <!-- Login Modal -->
    <div class="modal fade" id="loginModal" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
            <div class="modal-header"><h5 class="modal-title">MQTT Broker Connection</h5></div>
            <div class="modal-body">
                <p class="text-muted">Enter your MQTT credentials to connect.</p>
                <div class="mb-3"><label for="mqtt-user" class="form-label">Username</label><input type="text" class="form-control" id="mqtt-user" value="${MQTT_USER}"></div>
                <div class="mb-3"><label for="mqtt-pass" class="form-label">Password</label><input type="password" class="form-control" id="mqtt-pass"></div>
                <div id="login-error" class="text-danger mt-2" style="display:none;"></div>
            </div>
            <div class="modal-footer"><button type="button" id="connect-btn" class="btn btn-primary">Connect</button></div>
        </div></div>
    </div>

    <!-- Main Dashboard -->
    <div class="container-fluid" id="main-content">
        <header class="d-flex justify-content-between align-items-center mb-4">
            <h1 class="h3">Advanced MQTT Web Dashboard</h1>
            <div><strong>Status:</strong> <span id="status" class="badge bg-secondary">DISCONNECTED</span></div>
        </header>

        <div class="row">
            <!-- Left Column -->
            <div class="col-xl-7">
                <!-- Publish & Subscribe -->
                <div class="card mb-4">
                    <div class="card-body">
                        <div class="row">
                            <div class="col-lg-6 mb-3 mb-lg-0">
                                <h5>Publish Message</h5>
                                <div class="mb-2"><label for="pub-topic" class="form-label">Topic</label><input type="text" class="form-control" id="pub-topic" list="topic-history-list" value="test/topic"></div>
                                <div class="mb-2"><label for="pub-payload" class="form-label">Payload</label><input type="text" class="form-control" id="pub-payload" value='{"temp": 21.5, "humidity": 45}'></div>
                                <button id="publish-btn" class="btn btn-primary">Publish</button>
                            </div>
                            <div class="col-lg-6">
                                <h5>Subscribe to Topic</h5>
                                <div class="input-group"><input type="text" class="form-control" id="sub-topic" list="topic-history-list" value="#"><button id="subscribe-btn" class="btn btn-success">Subscribe</button></div>
                            </div>
                        </div>
                        <datalist id="topic-history-list"></datalist>
                    </div>
                </div>
                <!-- Message Log -->
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center"><span>Message Log</span><button id="clear-log-btn" class="btn btn-sm btn-outline-danger">Clear Log</button></div>
                    <div class="card-body"><div id="messages" class="log-box p-2"></div></div>
                </div>
            </div>

            <!-- Right Column -->
            <div class="col-xl-5">
                <!-- Connection Info -->
                <div class="card mb-4">
                    <div class="card-header">Connection Details</div>
                    <div class="card-body"><ul class="list-group list-group-flush">
                        <li class="list-group-item"><strong>Host / IP Address:</strong> <code id="info-host"></code></li>
                        <li class="list-group-item"><strong>Standard MQTT Port:</strong> <code id="info-mqtt-port"></code></li>
                        <li class="list-group-item"><strong>WebSocket Port (for web):</strong> <code id="info-ws-port"></code></li>
                    </ul></div>
                </div>
                <!-- Chart -->
                <div class="card">
                    <div class="card-header">Real-time Chart</div>
                    <div class="card-body">
                        <div class="row g-2 mb-3">
                            <div class="col-sm-7"><label for="chart-topic" class="form-label">Topic</label><input type="text" class="form-control form-control-sm" id="chart-topic" list="topic-history-list" placeholder="e.g., home/sensors"></div>
                            <div class="col-sm-5"><label for="chart-key" class="form-label">JSON Key</label><input type="text" class="form-control form-control-sm" id="chart-key" placeholder="e.g., temp"></div>
                        </div>
                        <canvas id="dataChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Libraries -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/paho-mqtt/1.1.0/paho-mqtt.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <script>hljs.highlightAll();</script>
    <script src="app.js"></script>
</body>
</html>
EOF

# 4. Create app.js with improved login feedback
cat > "$DASHBOARD_APP_DIR/app.js" <<EOF
// --- App State & Config ---
const MQTT_PORT = ${MQTT_PORT};
const WS_PORT = ${MQTT_WS_PORT};
let client;
let dataChart;
let topicHistory = new Set();
const MAX_CHART_POINTS = 30;
const LS_LOG_KEY = 'mqttDashboardLog';
const LS_TOPIC_HISTORY_KEY = 'mqttTopicHistory';

// --- DOM Elements ---
const statusSpan = document.getElementById('status');
const messagesDiv = document.getElementById('messages');
const connectBtn = document.getElementById('connect-btn');
const userInput = document.getElementById('mqtt-user');
const passInput = document.getElementById('mqtt-pass');
const loginErrorDiv = document.getElementById('login-error');
const mainContent = document.getElementById('main-content');
const infoHost = document.getElementById('info-host');
const infoMqttPort = document.getElementById('info-mqtt-port');
const infoWsPort = document.getElementById('info-ws-port');
const publishBtn = document.getElementById('publish-btn');
const pubTopicInput = document.getElementById('pub-topic');
const pubPayloadInput = document.getElementById('pub-payload');
const subscribeBtn = document.getElementById('subscribe-btn');
const subTopicInput = document.getElementById('sub-topic');
const clearLogBtn = document.getElementById('clear-log-btn');
const topicHistoryList = document.getElementById('topic-history-list');
const chartTopicInput = document.getElementById('chart-topic');
const chartKeyInput = document.getElementById('chart-key');

// --- Modal Setup ---
const loginModal = new bootstrap.Modal(document.getElementById('loginModal'));

// --- Local Storage Functions ---
function saveLog() { localStorage.setItem(LS_LOG_KEY, messagesDiv.innerHTML); }
function loadLog() { messagesDiv.innerHTML = localStorage.getItem(LS_LOG_KEY) || ''; }
function clearLog() { messagesDiv.innerHTML = ''; saveLog(); }
function saveTopicHistory() { localStorage.setItem(LS_TOPIC_HISTORY_KEY, JSON.stringify(Array.from(topicHistory))); }
function loadTopicHistory() {
    const saved = JSON.parse(localStorage.getItem(LS_TOPIC_HISTORY_KEY) || '[]');
    topicHistory = new Set(saved);
    updateTopicDatalist();
}
function addTopicToHistory(topic) {
    if (topic && !topicHistory.has(topic)) {
        topicHistory.add(topic);
        saveTopicHistory();
        updateTopicDatalist();
    }
}
function updateTopicDatalist() {
    topicHistoryList.innerHTML = '';
    topicHistory.forEach(topic => {
        const option = document.createElement('option');
        option.value = topic;
        topicHistoryList.appendChild(option);
    });
}

// --- Charting Functions ---
function initChart() {
    const ctx = document.getElementById('dataChart').getContext('2d');
    dataChart = new Chart(ctx, {
        type: 'line',
        data: { labels: [], datasets: [{ label: 'Real-time Data', data: [], borderColor: 'rgb(75, 192, 192)', tension: 0.1, fill: false }] },
        options: { animation: { duration: 200 } }
    });
}

function updateChart(topic, payload) {
    const chartTopic = chartTopicInput.value;
    const chartKey = chartKeyInput.value;
    if (!chartTopic || !chartKey || topic !== chartTopic || !dataChart) return;
    
    try {
        const data = JSON.parse(payload);
        if (data && typeof data[chartKey] === 'number') {
            const value = data[chartKey];
            const label = new Date().toLocaleTimeString();

            dataChart.data.labels.push(label);
            dataChart.data.datasets[0].data.push(value);

            if (dataChart.data.labels.length > MAX_CHART_POINTS) {
                dataChart.data.labels.shift();
                dataChart.data.datasets[0].data.shift();
            }
            dataChart.update();
        }
    } catch (e) { /* Not valid JSON or key not found, ignore for chart */ }
}

// --- Core MQTT Functions ---
function connect(username, password) {
    loginErrorDiv.style.display = 'none';
    connectBtn.disabled = true;
    connectBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Connecting...';
    
    const hostname = window.location.hostname;
    client = new Paho.Client(hostname, WS_PORT, "WebAppClient_" + Date.now());
    client.onConnectionLost = onConnectionLost;
    client.onMessageArrived = onMessageArrived;
    
    const opts = { 
        onSuccess: onConnect, 
        onFailure: onFailure, 
        userName: username, 
        password: password, 
        useSSL: location.protocol === 'https:', 
        cleanSession: true 
    };
    
    logMessage('System', \`Connecting to ws://\${hostname}:\${WS_PORT}...\`);
    client.connect(opts);
}

function onConnect() {
    // Restore connect button
    connectBtn.disabled = false;
    connectBtn.textContent = 'Connect';

    statusSpan.textContent = 'CONNECTED';
    statusSpan.className = 'badge bg-success';
    logMessage('System', 'Successfully connected!');
    loginModal.hide();
    mainContent.style.display = 'block';
    infoHost.textContent = window.location.hostname;
    infoMqttPort.textContent = MQTT_PORT;
    infoWsPort.textContent = WS_PORT;
    subscribe(subTopicInput.value);
}

function onFailure(res) {
    // Restore connect button
    connectBtn.disabled = false;
    connectBtn.textContent = 'Connect';

    statusSpan.textContent = 'FAILED';
    statusSpan.className = 'badge bg-danger';
    const msg = \`Connection failed: \${res.errorMessage}\`;
    logMessage('Error', msg);
    console.error('MQTT Connection Failed:', res); // Log detailed error object
    loginErrorDiv.textContent = msg;
    loginErrorDiv.style.display = 'block';
}

function onConnectionLost(res) {
    if (res.errorCode !== 0) {
        statusSpan.textContent = 'DISCONNECTED';
        statusSpan.className = 'badge bg-secondary';
        mainContent.style.display = 'none';
        loginModal.show();
        logMessage('Error', \`Connection lost: \${res.errorMessage}\`);
    }
}

function onMessageArrived(message) {
    logMessage(message.destinationName, message.payloadString, 'in');
    updateChart(message.destinationName, message.payloadString);
}

function publish() {
    const topic = pubTopicInput.value.trim();
    const payload = pubPayloadInput.value;
    if (!client || !client.isConnected() || !topic) return;
    client.send(topic, payload, 0, false);
    logMessage(topic, payload, 'out');
    addTopicToHistory(topic);
}

function subscribe() {
    const topic = subTopicInput.value.trim();
    if (!client || !client.isConnected() || !topic) return;
    logMessage('System', \`Subscribing to: \${topic}\`);
    client.subscribe(topic);
    addTopicToHistory(topic);
}

// --- UI & Logging Functions ---
function logMessage(topic, payload, direction = 'system') {
    const time = new Date().toLocaleTimeString();
    const div = document.createElement('div');
    div.className = 'log-entry mb-2';

    let content;
    try {
        const jsonObj = JSON.parse(payload);
        content = \`<pre><code class="language-json">\${JSON.stringify(jsonObj, null, 2)}\</code></pre>\`;
    } catch (e) {
        content = \`<code>\${payload.replace(/</g, "&lt;").replace(/>/g, "&gt;")}</code>\`;
    }
    
    const copyIcon = \`<svg onclick="copyToClipboard(this)" class="copy-btn" xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M4 1.5H3a2 2 0 0 0-2 2V14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V3.5a2 2 0 0 0-2-2h-1v1h1a1 1 0 0 1 1 1V14a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V3.5a1 1 0 0 1 1-1h1v-1z"/><path d="M9.5 1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-3a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5h3zM-1 8a.5.5 0 0 1 .5-.5h1v-1a.5.5 0 0 1 1 0v1h1a.5.5 0 0 1 0 1h-1v1a.5.5 0 0 1-1 0v-1h-1A.5.5 0 0 1-1 8z"/></svg>\`;

    div.innerHTML = \`<div><small class="text-muted">[\${time}]</small> <strong class="text-primary">\${direction === 'in' ? '->' : ''}\${direction === 'out' ? '<-' : ''} [\${topic}]</strong></div>\${content}<span class="d-none raw-payload">\${payload}</span>\${copyIcon}\`;

    messagesDiv.appendChild(div);
    if(div.querySelector('code.language-json')) {
        hljs.highlightElement(div.querySelector('code.language-json'));
    }
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
    saveLog();
}

function copyToClipboard(element) {
    const rawPayload = element.parentElement.querySelector('.raw-payload').textContent;
    navigator.clipboard.writeText(rawPayload).then(() => {
        // Optional: show a "copied!" tooltip
    });
}

// --- Event Listeners ---
window.addEventListener('load', () => {
    loginModal.show();
    loadLog();
    loadTopicHistory();
    initChart();
});
connectBtn.addEventListener('click', () => connect(userInput.value, passInput.value));
publishBtn.addEventListener('click', publish);
subscribeBtn.addEventListener('click', subscribe);
clearLogBtn.addEventListener('click', clearLog);
EOF

# 5. Create Dockerfile to include Nginx config
cat > "$DASHBOARD_APP_DIR/Dockerfile" <<EOF
FROM nginx:alpine
COPY . /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/.htpasswd /etc/nginx/conf.d/.htpasswd
EXPOSE 80
EOF

echo "### Web dashboard files created in '$DASHBOARD_APP_DIR'."

# --- Build the custom dashboard Docker image ---
echo
echo "### Building the custom dashboard Docker image ($DASHBOARD_IMAGE_NAME)..."
docker build -t $DASHBOARD_IMAGE_NAME "$DASHBOARD_APP_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to build the dashboard Docker image."
    exit 1
fi

# --- Create Docker Network ---
echo
echo "### Creating a dedicated Docker network '$NETWORK_NAME'..."
docker network create $NETWORK_NAME &> /dev/null || true

# --- Start Mosquitto Broker Container ---
echo
echo "### Starting Mosquitto Broker container..."
docker run -d \
    --name $BROKER_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -p "${MQTT_PORT}:1883" \
    -p "${MQTT_WS_PORT}:9001" \
    -v "$MOSQUITTO_CONFIG_DIR/mosquitto.conf:/mosquitto/config/mosquitto.conf" \
    -v "$MOSQUITTO_CONFIG_DIR/passwd:/mosquitto/config/passwd" \
    -v "${BROKER_CONTAINER_NAME}_data:/mosquitto/data" \
    -v "${BROKER_CONTAINER_NAME}_log:/mosquitto/log" \
    eclipse-mosquitto:2

# --- Start Custom Web Dashboard Container ---
echo
echo "### Starting the Secure Web Dashboard container..."
docker run -d \
    --name $WEB_UI_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -p "${WEB_UI_PORT}:80" \
    $DASHBOARD_IMAGE_NAME

# --- Final Output ---
echo
echo "======================================================"
echo "         🚀 Advanced MQTT Setup Complete! 🚀"
echo "======================================================"
echo
echo "Secure Web Dashboard is accessible at:"
echo "  URL: http://localhost:$WEB_UI_PORT"
echo "  Username: $DASHBOARD_USER"
echo "  Password: [the dashboard password you entered]"
echo
echo "Once you log in to the dashboard, use your MQTT credentials to connect:"
echo "  MQTT Username: $MQTT_USER"
echo "  MQTT Password: [the MQTT password you entered]"
echo
echo "To stop the containers, run:"
echo "  docker stop $WEB_UI_CONTAINER_NAME $BROKER_CONTAINER_NAME"
echo
echo "To remove everything (containers, images, config), run:"
echo "  docker rm $WEB_UI_CONTAINER_NAME $BROKER_CONTAINER_NAME"
echo "  docker rmi $DASHBOARD_IMAGE_NAME"
echo "  rm -rf $MOSQUITTO_CONFIG_DIR $DASHBOARD_APP_DIR"
echo "======================================================"

