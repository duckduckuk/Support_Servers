#!/bin/bash

# ==============================================================================
#
# Title: Docker MQTT Broker & Secure Custom Web Dashboard Setup Script
# Description: This script automates the setup of an Eclipse Mosquitto MQTT
#              broker and a custom, Nginx-served web dashboard using Docker.
#              The web dashboard is protected by Nginx Basic Authentication.
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
echo "   MQTT Broker & Secure Web Dashboard Docker Setup"
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

# 3. Create index.html with login modal
cat > "$DASHBOARD_APP_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MQTT Web Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        #main-content { display: none; }
        .log-box { height: 400px; background-color: #fff; border: 1px solid #dee2e6; border-radius: 0.375rem; overflow-y: scroll; font-family: monospace; font-size: 0.9em; }
    </style>
</head>
<body class="p-4">

    <!-- Login Modal -->
    <div class="modal fade" id="loginModal" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">MQTT Broker Connection</h5>
                </div>
                <div class="modal-body">
                    <p class="text-muted">Enter your MQTT credentials to connect to the broker.</p>
                    <div class="mb-3">
                        <label for="mqtt-user" class="form-label">Username</label>
                        <input type="text" class="form-control" id="mqtt-user" value="${MQTT_USER}">
                    </div>
                    <div class="mb-3">
                        <label for="mqtt-pass" class="form-label">Password</label>
                        <input type="password" class="form-control" id="mqtt-pass">
                    </div>
                    <div id="login-error" class="text-danger mt-2" style="display:none;"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" id="connect-btn" class="btn btn-primary">Connect</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Dashboard -->
    <div class="container" id="main-content">
        <header class="d-flex justify-content-between align-items-center mb-4">
            <h1 class="h3">MQTT Web Dashboard</h1>
            <div>
                <strong>Status:</strong> <span id="status" class="badge bg-secondary">DISCONNECTED</span>
            </div>
        </header>
        <div class="card mb-4">
            <div class="card-header">Publish Message</div>
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-6"><label for="pub-topic" class="form-label">Topic</label><input type="text" class="form-control" id="pub-topic" value="test/topic"></div>
                    <div class="col-md-6"><label for="pub-payload" class="form-label">Payload</label><input type="text" class="form-control" id="pub-payload" value='{"message": "hello"}'></div>
                </div>
                <button id="publish-btn" class="btn btn-primary mt-3">Publish</button>
            </div>
        </div>
        <div class="card">
            <div class="card-header">Subscribe & Message Log</div>
            <div class="card-body">
                <div class="input-group mb-3"><input type="text" class="form-control" id="sub-topic" value="#"><button id="subscribe-btn" class="btn btn-success">Subscribe</button></div>
                <div id="messages" class="log-box p-2"></div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/paho-mqtt/1.1.0/paho-mqtt.min.js"></script>
    <script src="app.js"></script>
</body>
</html>
EOF

# 4. Create app.js for dynamic login
cat > "$DASHBOARD_APP_DIR/app.js" <<EOF
// --- App State & Config ---
const WS_PORT = ${MQTT_WS_PORT};
let client;

// --- DOM Elements ---
const statusSpan = document.getElementById('status');
const messagesDiv = document.getElementById('messages');
const publishBtn = document.getElementById('publish-btn');
const subscribeBtn = document.getElementById('subscribe-btn');
const connectBtn = document.getElementById('connect-btn');
const userInput = document.getElementById('mqtt-user');
const passInput = document.getElementById('mqtt-pass');
const loginErrorDiv = document.getElementById('login-error');
const mainContent = document.getElementById('main-content');

// --- Modal Setup ---
const loginModal = new bootstrap.Modal(document.getElementById('loginModal'));

// --- Core MQTT Functions ---
function connect(username, password) {
    loginErrorDiv.style.display = 'none';
    const hostname = window.location.hostname;
    const clientId = "WebAppClient_" + parseInt(Math.random() * 1000);
    client = new Paho.Client(hostname, WS_PORT, clientId);
    client.onConnectionLost = onConnectionLost;
    client.onMessageArrived = onMessageArrived;

    const connectOptions = {
        onSuccess: onConnect,
        onFailure: onFailure,
        userName: username,
        password: password,
        useSSL: window.location.protocol === 'https:',
        cleanSession: true
    };
    logMessage('System', \`Connecting to ws://\${hostname}:\${WS_PORT}...\`);
    client.connect(connectOptions);
}

function onConnect() {
    statusSpan.textContent = 'CONNECTED';
    statusSpan.className = 'badge bg-success';
    logMessage('System', 'Successfully connected!');
    loginModal.hide();
    mainContent.style.display = 'block';
    subscribe(document.getElementById('sub-topic').value);
}

function onFailure(response) {
    statusSpan.textContent = 'FAILED';
    statusSpan.className = 'badge bg-danger';
    logMessage('Error', \`Connection failed: \${response.errorMessage}\`);
    loginErrorDiv.textContent = \`Connection failed: \${response.errorMessage}\`;
    loginErrorDiv.style.display = 'block';
}

function onConnectionLost(responseObject) {
    if (responseObject.errorCode !== 0) {
        statusSpan.textContent = 'DISCONNECTED';
        statusSpan.className = 'badge bg-secondary';
        mainContent.style.display = 'none';
        loginModal.show();
        logMessage('Error', \`Connection lost: \${responseObject.errorMessage}\`);
    }
}

function onMessageArrived(message) {
    logMessage(message.destinationName, message.payloadString, 'in');
}

function publish() {
    const topic = document.getElementById('pub-topic').value;
    const payload = document.getElementById('pub-payload').value;
    if (!client || !client.isConnected() || !topic) return;
    const message = new Paho.Message(payload);
    message.destinationName = topic;
    client.send(message);
    logMessage(topic, payload, 'out');
}

function subscribe(topic) {
    if (!client || !client.isConnected() || !topic) return;
    logMessage('System', \`Subscribing to: \${topic}\`);
    client.subscribe(topic);
}

function logMessage(topic, payload, direction = 'system') {
    const time = new Date().toLocaleTimeString();
    const div = document.createElement('div');
    const colorClass = direction === 'in' ? 'text-primary' : (direction === 'out' ? 'text-info' : '');
    const arrow = direction === 'in' ? '->' : (direction === 'out' ? '<-' : '');
    div.innerHTML = \`[\${time}] <strong class="\${colorClass}">\${arrow} [\${topic}]</strong>: \${payload}\`;
    messagesDiv.appendChild(div);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

// --- Event Listeners ---
window.addEventListener('load', () => loginModal.show());
connectBtn.addEventListener('click', () => {
    connect(userInput.value, passInput.value);
});
publishBtn.addEventListener('click', publish);
subscribeBtn.addEventListener('click', () => subscribe(document.getElementById('sub-topic').value));
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
echo "         🚀 Secure MQTT Setup Complete! 🚀"
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

