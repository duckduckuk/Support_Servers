#!/bin/bash

# ==============================================================================
#
# Title: Docker MQTT Last 3 Messages Viewer Setup
# Description: This script creates a Docker container with a simple, secure
#              web front end. The page itself is password-protected, and it
#              securely prompts for MQTT credentials to display messages.
# Author: Gemini
# Date: 2024-06-18
#
# ==============================================================================

# --- Function to check if Docker is installed and running ---
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker to use this script."
        exit 1
    fi
    if ! docker info &> /dev/null; then
        echo "Error: Docker is not running. Please start the Docker daemon."
        exit 1
    fi
}

# --- Configuration File ---
CONFIG_FILE="mqtt_viewer.conf"
APP_DIR="$(pwd)/mqtt_viewer_app"
NGINX_CONFIG_DIR="$APP_DIR/nginx"
DOCKER_IMAGE_NAME="mqtt-viewer-image"
DOCKER_CONTAINER_NAME="mqtt-viewer"

# --- Load or Get Configuration ---
load_or_get_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Configuration file found."
        source "$CONFIG_FILE"
        read -p "Use saved settings? (Header: \"$CUSTOM_HEADER\", Host: $MQTT_HOST) (y/n): " use_saved
        if [[ "$use_saved" == "y" || "$use_saved" == "Y" ]]; then
            echo "Using saved settings."
            return
        fi
    fi
    
    echo "--- Please provide page and connection details ---"
    
    echo
    echo "Step 1: Set a password for the web page itself."
    read -p "Enter a username for the Web Viewer page: " PAGE_USER
    read -sp "Enter a password for the Web Viewer page: " PAGE_PASSWORD
    echo
    
    echo
    echo "Step 2: Set the MQTT connection details."
    read -p "Enter a custom header for the page (default: MQTT Message Viewer): " CUSTOM_HEADER
    CUSTOM_HEADER=${CUSTOM_HEADER:-"MQTT Message Viewer"}
    read -p "Enter MQTT Host/IP: " MQTT_HOST
    read -p "Enter MQTT WebSocket Port (e.g., 9001): " MQTT_WS_PORT
    read -p "Enter MQTT Username (will be pre-filled in login form): " MQTT_USER
    read -p "Enter MQTT Topic to subscribe to (default: '#'): " MQTT_TOPIC
    MQTT_TOPIC=${MQTT_TOPIC:-#}
    read -p "Enter Web Server Port for this viewer (default: 8089): " WEB_PORT
    WEB_PORT=${WEB_PORT:-8089}
    
    # Save configuration (NOTE: Passwords are NOT saved to file)
    cat > "$CONFIG_FILE" <<EOF
PAGE_USER="$PAGE_USER"
PAGE_PASSWORD="$PAGE_PASSWORD"
CUSTOM_HEADER="$CUSTOM_HEADER"
MQTT_HOST="$MQTT_HOST"
MQTT_WS_PORT="$MQTT_WS_PORT"
MQTT_USER="$MQTT_USER"
MQTT_TOPIC="$MQTT_TOPIC"
WEB_PORT="$WEB_PORT"
EOF
    echo "Configuration saved to $CONFIG_FILE"
}

# --- Generate Web App Files ---
generate_web_files() {
    echo "### Generating web application files in '$APP_DIR'..."
    mkdir -p "$APP_DIR"
    mkdir -p "$NGINX_CONFIG_DIR"

    # 1. Create Nginx password file for page access
    echo "### Creating page access password file..."
    docker run --rm httpd:2.4 htpasswd -Bbn "$PAGE_USER" "$PAGE_PASSWORD" > "$NGINX_CONFIG_DIR/.htpasswd"

    # 2. Create custom Nginx config with basic auth
    cat > "$NGINX_CONFIG_DIR/default.conf" <<EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        auth_basic "Restricted Viewer Access";
        auth_basic_user_file /etc/nginx/conf.d/.htpasswd;
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # 3. Create index.html with a login modal
    cat > "$APP_DIR/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${CUSTOM_HEADER}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .card { transition: all 0.3s ease-in-out; }
        .new-message { transform: scale(1.05); border-color: #0d6efd; }
        #main-content { display: none; }
    </style>
</head>
<body class="p-4">

    <!-- Login Modal -->
    <div class="modal fade" id="loginModal" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header"><h5 class="modal-title">MQTT Broker Login</h5></div>
                <div class="modal-body">
                    <p class="text-muted">Enter your credentials to connect to the broker.</p>
                    <div class="mb-3">
                        <label for="mqtt-user" class="form-label">Username</label>
                        <input type="text" class="form-control" id="mqtt-user">
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

    <!-- Main Content -->
    <div class="container" id="main-content">
        <header class="text-center mb-4">
            <h1 class="h3">${CUSTOM_HEADER}</h1>
            <p class="text-muted">
                Displaying the last 3 messages from topic: <code id="subscribed-topic"></code><br>
                Status: <span id="status" class="badge bg-secondary">DISCONNECTED</span>
            </p>
        </header>
        <div id="messages-container" class="row justify-content-center g-4"></div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/paho-mqtt/1.1.0/paho-mqtt.min.js"></script>
    <script src="config.js"></script>
    <script src="app.js"></script>
</body>
</html>
EOF

    # 4. Create config.js (without password)
    cat > "$APP_DIR/config.js" <<EOF
// MQTT Connection Configuration - Auto-generated
const mqttConfig = {
    hostname: "${MQTT_HOST}",
    port: parseInt("${MQTT_WS_PORT}"),
    username: "${MQTT_USER}",
    topic: "${MQTT_TOPIC}",
    clientId: "MQTTViewer_" + Date.now()
};
EOF

    # 5. Create app.js with login logic
    cat > "$APP_DIR/app.js" <<EOF
const statusSpan = document.getElementById('status');
const messagesContainer = document.getElementById('messages-container');
const topicSpan = document.getElementById('subscribed-topic');
const mainContent = document.getElementById('main-content');
const loginModalEl = document.getElementById('loginModal');
const loginModal = new bootstrap.Modal(loginModalEl);
const connectBtn = document.getElementById('connect-btn');
const userInput = document.getElementById('mqtt-user');
const passInput = document.getElementById('mqtt-pass');
const loginErrorDiv = document.getElementById('login-error');

let messages = [];
const MAX_MESSAGES = 3;

function connectToMqtt(username, password) {
    console.log(\`Attempting to connect to MQTT broker at ws://\${mqttConfig.hostname}:\${mqttConfig.port}\`);
    
    connectBtn.disabled = true;
    connectBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Connecting...';
    loginErrorDiv.style.display = 'none';

    const client = new Paho.Client(mqttConfig.hostname, mqttConfig.port, mqttConfig.clientId);
    client.onConnectionLost = onConnectionLost;
    client.onMessageArrived = onMessageArrived;

    const connectOptions = {
        timeout: 5,
        onSuccess: () => {
            statusSpan.textContent = 'CONNECTED';
            statusSpan.className = 'badge bg-success';
            client.subscribe(mqttConfig.topic);
            topicSpan.textContent = mqttConfig.topic;
            console.log("Successfully connected to MQTT broker.");
            loginModal.hide();
            mainContent.style.display = 'block';
        },
        onFailure: (res) => {
            const errorMsg = \`FAILED: \${res.errorMessage}\`;
            statusSpan.textContent = errorMsg;
            statusSpan.className = 'badge bg-danger';
            loginErrorDiv.textContent = errorMsg;
            loginErrorDiv.style.display = 'block';
            console.error("MQTT Connection Failed. Response:", res);
        },
        userName: username,
        password: password,
        useSSL: window.location.protocol === 'https:',
        cleanSession: true
    };
    
    client.connect(connectOptions);
}

function onConnectionLost(responseObject) {
    if (responseObject.errorCode !== 0) {
        statusSpan.textContent = 'DISCONNECTED';
        statusSpan.className = 'badge bg-secondary';
        console.error(\`MQTT connection lost: \${responseObject.errorMessage}\`);
        mainContent.style.display = 'none';
        loginModal.show();
    }
}

function onMessageArrived(message) {
    const newMessage = {
        topic: message.destinationName,
        payload: message.payloadString,
        timestamp: new Date().toLocaleTimeString()
    };
    messages.unshift(newMessage);
    if (messages.length > MAX_MESSAGES) messages.pop();
    renderMessages();
}

function renderMessages() {
    messagesContainer.innerHTML = '';
    if (messages.length === 0) {
        messagesContainer.innerHTML = '<p class="text-center text-muted">Waiting for messages...</p>';
        return;
    }
    messages.forEach((msg, index) => {
        const card = document.createElement('div');
        card.className = 'col-lg-4 col-md-6';
        card.innerHTML = \`
            <div class="card h-100">
                <div class="card-header">\${msg.topic}</div>
                <div class="card-body"><pre class="mb-0"><code>\${msg.payload.replace(/</g, "&lt;").replace(/>/g, "&gt;")}</code></pre></div>
                <div class="card-footer text-muted">Received at \${msg.timestamp}</div>
            </div>
        \`;
        messagesContainer.appendChild(card);
        if (index === 0) {
            setTimeout(() => {
                const cardElement = card.querySelector('.card');
                if (cardElement) cardElement.classList.add('new-message');
            }, 10);
        }
    });
}

// Initial setup
document.addEventListener('DOMContentLoaded', () => {
    userInput.value = mqttConfig.username; // Pre-fill username
    renderMessages();
    loginModal.show();
    
    connectBtn.addEventListener('click', () => {
        connectToMqtt(userInput.value, passInput.value);
    });

    loginModalEl.addEventListener('shown.bs.modal', () => {
        passInput.focus();
        connectBtn.disabled = false;
        connectBtn.textContent = 'Connect';
    });
});
EOF

    # 6. Create Dockerfile with Nginx basic auth config
    cat > "$APP_DIR/Dockerfile" <<EOF
FROM nginx:alpine
COPY . /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/.htpasswd /etc/nginx/conf.d/.htpasswd
EXPOSE 80
EOF

    echo "### Web files generated successfully."
}

# --- Build and Run Docker Container ---
build_and_run() {
    echo "### Building Docker image '$DOCKER_IMAGE_NAME'..."
    docker build -t "$DOCKER_IMAGE_NAME" "$APP_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image."
        exit 1
    fi

    echo "### Stopping and removing any existing container named '$DOCKER_CONTAINER_NAME'..."
    docker stop "$DOCKER_CONTAINER_NAME" &> /dev/null
    docker rm "$DOCKER_CONTAINER_NAME" &> /dev/null

    echo "### Starting new container..."
    docker run -d --name "$DOCKER_CONTAINER_NAME" -p "${WEB_PORT}:80" "$DOCKER_IMAGE_NAME"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to start Docker container."
        exit 1
    fi

    echo "========================================"
    echo "  🚀 Secure Viewer Setup Complete! 🚀"
    echo "========================================"
    echo "Your MQTT message viewer is running at:"
    echo "  URL: http://localhost:$WEB_PORT"
    echo
    echo "You will be prompted for two logins:"
    echo "  1. Page Access: Use the page username/password you just set."
    echo "  2. MQTT Broker: Use your actual MQTT credentials in the pop-up."
    echo "========================================"
}


# --- Main Script ---
check_docker
load_or_get_config
generate_web_files
build_and_run
