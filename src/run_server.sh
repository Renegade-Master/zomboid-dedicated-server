#!/usr/bin/env bash
#######################################################################
#   Author: Renegade-Master
#   Description: Install, update, and start a Dedicated Zomboid
#       instance.
#######################################################################

# Set to `-x` for Debug logging
set +x

# Start the Server
function start_server() {
    printf "\n### Starting Zomboid Server...\n"

    "$BASE_GAME_DIR"/start-server.sh
}

function apply_postinstall_config() {
    printf "\n### Applying Post Install Configuration...\n"

    # Set the maximum number of players if it hasn't been set already
    if grep -q "MaxPlayers=" "$CONFIG_DIR/Game.ini"; then
        sed -i "s/MaxPlayers=.*/MaxPlayers=$MAX_PLAYERS/g" "$CONFIG_DIR/Game.ini"
    else
        echo "$MAX_PLAYER_STRING" >> "$CONFIG_DIR/Game.ini"
    fi

    printf "\n### Post Install Configuration applied.\n"
}

# Update the server
function update_server() {
    printf "\n### Updating Zomboid Server...\n"

    "$STEAM_PATH" +runscript /home/steam/install_server.scmd

    printf "\n### Zomboid Server updated.\n"
}

# Apply user configuration to the server
function apply_preinstall_config() {
    printf "\n### Applying Pre Install Configuration...\n"

    # Set the selected game version
    sed -i "s/beta .* /beta $GAME_VERSION /g" /home/steam/install_server.scmd

    printf "\n### Pre Install Configuration applied.\n"
}

# Change the folder permissions for install and save directory
function update_folder_permissions() {
    printf "\n### Updating Folder Permissions...\n"

    chown -R "$(id -u):$(id -g)" "$BASE_GAME_DIR"
    chown -R "$(id -u):$(id -g)" "$CONFIG_DIR"

    printf "\n### Folder Permissions updated.\n"
}

# Set variables for use in the script
function set_variables() {
    printf "\n### Setting variables...\n"

    BASE_GAME_DIR="/home/steam/ZomboidDedicatedServer"
    CONFIG_DIR="/home/steam/Zomboid/"

    # Set the game version variable
    GAME_VERSION=${GAME_VERSION:-"public"}

    # Set the IP address variable
    BIND_IP=${BIND_IP:-"0.0.0.0"}

    # Set the IP Query Port variable
    QUERY_PORT=${QUERY_PORT:-"16261"}

    # Set the IP Game Port variable
    GAME_PORT=${GAME_PORT:-"8766"}
}

## Main
set_variables
update_folder_permissions
apply_preinstall_config
update_server
#apply_postinstall_config
start_server
