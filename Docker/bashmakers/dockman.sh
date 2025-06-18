#!/bin/bash

# ==============================================================================
#
# Title: Simple Docker Container Manager
# Description: This script provides an interactive menu to view, start,
#              stop, and remove Docker containers.
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

# --- Function to list containers and get user selection ---
select_container() {
    # Get all containers and format them for display
    containers=($(docker ps -a --format "{{.ID}} {{.Names}} ({{.Status}})"))
    
    if [ ${#containers[@]} -eq 0 ]; then
        echo "No containers found."
        return 1
    fi
    
    echo "----------------------------------------"
    echo "      Available Docker Containers"
    echo "----------------------------------------"
    
    # Use a `while read` loop to handle container names with spaces correctly
    local i=1
    while read -r id name status; do
        printf "%-4s %-30s %s\n" "$i)" "$name" "$status"
        # Store ID and Name in arrays for later reference
        container_ids[$i]=$id
        container_names[$i]=$name
        ((i++))
    done < <(docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}")
    
    echo "----------------------------------------"
    read -p "Select a container (enter number, or 'q' to quit): " selection
    
    # Validate selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt $i ]; then
        SELECTED_ID=${container_ids[$selection]}
        SELECTED_NAME=${container_names[$selection]}
        return 0
    elif [ "$selection" == "q" ]; then
        exit 0
    else
        echo "Invalid selection. Please try again."
        return 1
    fi
}

# --- Function to display action menu ---
show_action_menu() {
    echo "----------------------------------------"
    echo "Selected Container: $SELECTED_NAME"
    echo "----------------------------------------"
    echo "Actions:"
    echo "  1) Start"
    echo "  2) Stop"
    echo "  3) Remove (delete)"
    echo "  4) View Logs"
    echo "  b) Back to main menu"
    echo "  q) Quit"
    echo "----------------------------------------"
    read -p "Choose an action: " action
    
    case $action in
        1)
            echo "Starting container $SELECTED_NAME..."
            docker start "$SELECTED_ID"
            ;;
        2)
            echo "Stopping container $SELECTED_NAME..."
            docker stop "$SELECTED_ID"
            ;;
        3)
            read -p "Are you sure you want to REMOVE $SELECTED_NAME? This cannot be undone. (y/n): " confirm
            if [ "$confirm" == "y" ]; then
                echo "Removing container $SELECTED_NAME..."
                docker rm "$SELECTED_ID"
            else
                echo "Removal cancelled."
            fi
            ;;
        4)
            echo "Displaying logs for $SELECTED_NAME (press Ctrl+C to exit)..."
            docker logs -f "$SELECTED_ID"
            ;;
        b)
            return
            ;;
        q)
            exit 0
            ;;
        *)
            echo "Invalid action."
            ;;
    esac
    read -n 1 -s -r -p "Press any key to continue..."
}

# --- Main Loop ---
check_docker

while true; do
    # Clear screen for better readability
    clear
    echo "========================================"
    echo "    Docker Container Manager"
    echo "========================================"
    
    if select_container; then
        show_action_menu
    else
        # If no containers, wait for user input before exiting or re-looping
        read -n 1 -s -r -p "Press any key to refresh or 'q' to quit." key
        if [ "$key" == "q" ]; then
          break
        fi
    fi
done

echo "Exiting."
