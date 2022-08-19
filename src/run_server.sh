#!/usr/bin/env bash

#
#  Project Zomboid Dedicated Server using SteamCMD Docker Image.
#  Copyright (C) 2021-2022 Renegade-Master [renegade.master.dev@protonmail.com]
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#######################################################################
#   Author: Renegade-Master
#   Contributors: JohnEarle, ramielrowe
#   Description: Install, update, and start a Dedicated Project Zomboid
#       instance.
#######################################################################

# Set to `-x` for Debug logging
set +x -o pipefail

# Handle shutting down the server, with optional RCON quit for graceful shutdown
function shutdown() {
    if [[ "$RCON_ENABLED" == "true" ]]; then
        printf "\n### Sending RCON quit command\n"
        rcon --address "$BIND_IP:$RCON_PORT" --password "$RCON_PASSWORD" quit
    else
        printf "\n### RCON not enabled: cannot issue quit command.\nSending SIGTERM...\n"
        pkill -P $$
    fi
}

# Start the Server
function start_server() {
    printf "\n### Starting Project Zomboid Server...\n"
    timeout "$TIMEOUT" "$BASE_GAME_DIR"/start-server.sh \
        -cachedir="$CONFIG_DIR" \
        -adminusername "$ADMIN_USERNAME" \
        -adminpassword "$ADMIN_PASSWORD" \
        -ip "$BIND_IP" -port "$QUERY_PORT" \
        -servername "$SERVER_NAME" \
        -steamvac "$STEAM_VAC" "$USE_STEAM" &

    server_pid=$!
    wait $server_pid

    # NOTE(ramielrowe): Apparently the first wait will return immediately after
    #   the trap handler returns. The server can take a couple seconds to fully
    #   shutdown after the `quit` command. So, call wait once more to ensure
    #   the server is fully stopped.
    wait $server_pid

    printf "\n### Project Zomboid Server stopped.\n"
}

function apply_postinstall_config() {
    printf "\n### Applying Post Install Configuration...\n"

    # Set the Autosave Interval
    "$EDIT_CONFIG" "$SERVER_CONFIG" "SaveWorldEveryMinutes" "$AUTOSAVE_INTERVAL"

    # Set the Server game Port
    "$EDIT_CONFIG" "$SERVER_CONFIG" "SteamPort1" "$GAME_PORT"

    # Set the Max Players
    "$EDIT_CONFIG" "$SERVER_CONFIG" "MaxPlayers" "$MAX_PLAYERS"

    # Set the Mod names
    "$EDIT_CONFIG" "$SERVER_CONFIG" "Mods" "$MOD_NAMES"

    # Set the Map names
    "$EDIT_CONFIG" "$SERVER_CONFIG" "Map" "$MAP_NAMES"

    # Set the Mod Workshop IDs
    "$EDIT_CONFIG" "$SERVER_CONFIG" "WorkshopItems" "$MOD_WORKSHOP_IDS"

    # Set the Pause on Empty Server
    "$EDIT_CONFIG" "$SERVER_CONFIG" "PauseEmpty" "$PAUSE_ON_EMPTY"

    # Set the Server Publicity status
    "$EDIT_CONFIG" "$SERVER_CONFIG" "Open" "$PUBLIC_SERVER"

    # Set the Server query Port
    "$EDIT_CONFIG" "$SERVER_CONFIG" "DefaultPort" "$QUERY_PORT"

    # Set the Server RCON Password
    "$EDIT_CONFIG" "$SERVER_CONFIG" "RCONPassword" "$RCON_PASSWORD"

    # Set the Server RCON Port
    "$EDIT_CONFIG" "$SERVER_CONFIG" "RCONPort" "$RCON_PORT"

    # Set the Server Name
    "$EDIT_CONFIG" "$SERVER_CONFIG" "PublicName" "$SERVER_NAME"

    # Set the Server Password
    "$EDIT_CONFIG" "$SERVER_CONFIG" "Password" "$SERVER_PASSWORD"

    # Set the maximum amount of RAM for the JVM
    sed -i "s/-Xmx.*/-Xmx$MAX_RAM\",/g" "$SERVER_VM_CONFIG"

    printf "\n### Post Install Configuration applied.\n"
}

# Test if this is the the first time the server has run
function test_first_run() {
    printf "\n### Checking if this is the first run...\n"

    if [[ ! -f "$SERVER_CONFIG" ]] || [[ ! -f "$SERVER_RULES_CONFIG" ]]; then
        printf "\n### This is the first run.\nStarting server for %s seconds\n" "$TIMEOUT"
        start_server
        TIMEOUT=0
    else
        printf "\n### This is not the first run.\n"
        TIMEOUT=0
    fi

    printf "\n### First run check complete.\n"
}

# Update the server
function update_server() {
    printf "\n### Updating Project Zomboid Server...\n"

    steamcmd.sh +runscript "$STEAM_INSTALL_FILE"

    printf "\n### Project Zomboid Server updated.\n"
}

# Apply user configuration to the server
function apply_preinstall_config() {
    printf "\n### Applying Pre Install Configuration...\n"

    # Set the selected game version
    sed -i "s/beta .* /beta $GAME_VERSION /g" "$STEAM_INSTALL_FILE"

    printf "\n### Pre Install Configuration applied.\n"
}

# Set variables for use in the script
function set_variables() {
    printf "\n### Setting variables...\n"

    TIMEOUT="60"
    EDIT_CONFIG="/home/steam/edit_server_config.py"
    STEAM_INSTALL_FILE="/home/steam/install_server.scmd"
    BASE_GAME_DIR="/home/steam/ZomboidDedicatedServer"
    CONFIG_DIR="/home/steam/Zomboid"

    # Set the Server Admin Password variable
    ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}

    # Set the Server Admin Password variable
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-"changeme"}

    # Set the Autosave Interval variable
    AUTOSAVE_INTERVAL=${AUTOSAVE_INTERVAL:-"15"}

    # Set the IP address variable
    # NOTE: Project Zomboid cannot handle the IN_ANY address
    if [[ -z "$BIND_IP" ]] || [[ "$BIND_IP" == "0.0.0.0" ]]; then
        BIND_IP=($(hostname -I))
        BIND_IP="${BIND_IP[0]}"
    else
        BIND_IP="$BIND_IP"
    fi
    echo "$BIND_IP" > "$CONFIG_DIR/ip.txt"

    # Set the IP Game Port variable
    GAME_PORT=${GAME_PORT:-"8766"}

    # Set the game version variable
    GAME_VERSION=${GAME_VERSION:-"public"}

    # Set the Max Players variable
    MAX_PLAYERS=${MAX_PLAYERS:-"16"}

    # Set the Maximum RAM variable
    MAX_RAM=${MAX_RAM:-"4096m"}

    # Set the Mods to use from workshop
    MOD_NAMES=${MOD_NAMES:-""}
    MOD_WORKSHOP_IDS=${MOD_WORKSHOP_IDS:-""}

    # Set the Maps to use
    MAP_NAMES=${MAP_NAMES:-"Muldraugh, KY"}

    # Set the Pause on Empty variable
    PAUSE_ON_EMPTY=${PAUSE_ON_EMPTY:-"true"}

    # Set the Server Publicity variable
    PUBLIC_SERVER=${PUBLIC_SERVER:-"true"}

    # Set the IP Query Port variable
    QUERY_PORT=${QUERY_PORT:-"16261"}

    # Set the Server name variable
    SERVER_NAME=${SERVER_NAME:-"ZomboidServer"}

    # Set the Server Password variable
    SERVER_PASSWORD=${SERVER_PASSWORD:-""}

    # Set Steam VAC Protection variable
    STEAM_VAC=${STEAM_VAC:-"true"}

    # Set server type variable
    if [[ -z "$USE_STEAM" ]] || [[ "$USE_STEAM" == "true" ]]; then
        USE_STEAM=""
    else
        USE_STEAM="-nosteam"
    fi

    # Set RCON configuration
    if [[ -z "$RCON_PORT" ]] || [[ "$RCON_PORT" == "0" ]]; then
        RCON_ENABLED="false"
    else
        RCON_ENABLED="true"
        RCON_PORT=${RCON_PORT:-"27015"}
        RCON_PASSWORD=${RCON_PASSWORD:-"changeme_rcon"}
    fi

    SERVER_CONFIG="$CONFIG_DIR/Server/$SERVER_NAME.ini"
    SERVER_VM_CONFIG="$BASE_GAME_DIR/ProjectZomboid64.json"
    SERVER_RULES_CONFIG="$CONFIG_DIR/Server/${SERVER_NAME}_SandboxVars.lua"
}

## Main
set_variables
apply_preinstall_config
update_server
test_first_run
apply_postinstall_config

# Intercept termination signals to stop the server gracefully
trap shutdown SIGTERM SIGINT

start_server
