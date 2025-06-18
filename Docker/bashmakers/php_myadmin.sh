#!/bin/bash

# ==============================================================================
#
# Title: Docker MySQL & phpMyAdmin Setup Script
# Description: This script automates the setup of MySQL and phpMyAdmin
#              containers using Docker. It prompts the user for necessary
#              configurations such as passwords and ports.
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
echo "  MySQL and phpMyAdmin Docker Container Setup"
echo "======================================================"
echo
echo "This script will guide you through setting up a MySQL database"
echo "and a phpMyAdmin container."
echo

# Check for Docker before proceeding
check_docker

# --- Gather MySQL Configuration ---
echo
echo "--- MySQL Configuration ---"
read -p "Enter the MySQL root password (e.g., 'my-secret-pw'): " MYSQL_ROOT_PASSWORD
while [ -z "$MYSQL_ROOT_PASSWORD" ]; do
    echo "MySQL root password cannot be empty."
    read -p "Enter the MySQL root password: " MYSQL_ROOT_PASSWORD
done

read -p "Enter the external port for MySQL (default: 3306): " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_CONTAINER_NAME="mysql-db"

# --- Gather phpMyAdmin Configuration ---
echo
echo "--- phpMyAdmin Configuration ---"
read -p "Enter the phpMyAdmin username (for MySQL connection): " PMA_USER
while [ -z "$PMA_USER" ]; do
    echo "phpMyAdmin username cannot be empty."
    read -p "Enter the phpMyAdmin username: " PMA_USER
done

read -p "Enter the password for the phpMyAdmin user: " PMA_PASSWORD
while [ -z "$PMA_PASSWORD" ]; do
    echo "Password for phpMyAdmin user cannot be empty."
    read -p "Enter the password for the phpMyAdmin user: " PMA_PASSWORD
done

read -p "Enter the external port for phpMyAdmin (default: 8080): " PMA_PORT
PMA_PORT=${PMA_PORT:-8080}
PMA_CONTAINER_NAME="phpmyadmin-ui"


# --- Create Docker Network ---
# Using a dedicated network is a best practice for container communication.
NETWORK_NAME="mysql-net"
echo
echo "### Creating a dedicated Docker network '$NETWORK_NAME'..."
docker network create $NETWORK_NAME &> /dev/null || true # Silently fail if it already exists


# --- Start MySQL Container ---
echo
echo "### Pulling the latest MySQL image..."
docker pull mysql:latest

echo
echo "### Starting MySQL container..."
docker run -d \
    --name $MYSQL_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MYSQL_USER="$PMA_USER" \
    -e MYSQL_PASSWORD="$PMA_PASSWORD" \
    -p "${MYSQL_PORT}:3306" \
    -v mysql_data:/var/lib/mysql \
    mysql:latest

# Check if MySQL container started successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to start the MySQL container. Please check your Docker setup and the provided details."
    exit 1
fi

echo "### MySQL container '$MYSQL_CONTAINER_NAME' is starting."


# --- Start phpMyAdmin Container ---
echo
echo "### Pulling the latest phpMyAdmin image..."
docker pull phpmyadmin:latest

echo
echo "### Starting phpMyAdmin container..."
# We wait a few seconds to give MySQL time to initialize
echo "### Waiting for MySQL to initialize before starting phpMyAdmin..."
sleep 15

docker run -d \
    --name $PMA_CONTAINER_NAME \
    --network $NETWORK_NAME \
    -e PMA_HOST=$MYSQL_CONTAINER_NAME \
    -e PMA_PORT=3306 \
    -p "${PMA_PORT}:80" \
    phpmyadmin:latest

# Check if phpMyAdmin container started successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to start the phpMyAdmin container."
    exit 1
fi

echo "### phpMyAdmin container '$PMA_CONTAINER_NAME' is starting."
echo

# --- Final Output ---
echo "======================================================"
echo "         🚀 Setup Complete! 🚀"
echo "======================================================"
echo
echo "MySQL is accessible on:"
echo "  Host: localhost"
echo "  Port: $MYSQL_PORT"
echo "  Root Password: $MYSQL_ROOT_PASSWORD"
echo
echo "phpMyAdmin is accessible at:"
echo "  URL: http://localhost:$PMA_PORT"
echo
echo "You can log in to phpMyAdmin with the following credentials:"
echo "  Server: $MYSQL_CONTAINER_NAME"
echo "  Username: $PMA_USER"
echo "  Password: $PMA_PASSWORD"
echo
echo "To stop the containers, run:"
echo "  docker stop $PMA_CONTAINER_NAME $MYSQL_CONTAINER_NAME"
echo
echo "To remove the containers (will also remove data unless volume is managed separately):"
echo "  docker rm $PMA_CONTAINER_NAME $MYSQL_CONTAINER_NAME"
echo "======================================================"

