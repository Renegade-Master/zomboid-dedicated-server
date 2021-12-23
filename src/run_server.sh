#!/usr/bin/env bash
#######################################################################
#   Author: Renegade-Master
#   Description: Install, update, and start a Dedicated Satisfactory
#       instance.
#######################################################################

# Set to `-x` for Debug logging
set +x

# Start the Satisfactory Server
function start_satisfactory() {
    printf "\n### Starting Satisfactory Server...\n"

    "$BASE_GAME_DIR"/FactoryServer.sh \
        -multihome="$BIND_IP" \
        -ServerQueryPort="$QUERY_PORT" \
        -Port="$GAME_PORT"

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

# Update the Satisfactory server
function update_satisfactory() {
    printf "\n### Updating Satisfactory Server...\n"

    $STEAM_PATH +runscript /home/steam/install_satisfactory.scmd

    printf "\n### Satisfactory Server updated.\n"
}

# Apply user configuration to the Satisfactory server
function apply_preinstall_config() {
    printf "\n### Applying Pre Install Configuration...\n"

    # Set the selected game version
    sed -i "s/beta .* /beta $GAME_VERSION /g" /home/steam/install_satisfactory.scmd

    printf "\n### Pre Install Configuration applied.\n"
}

# Change the folder permissions for install and save directory
function update_folder_permissions() {
    printf "\n### Updating Folder Permissions...\n"

    chown -R "${USER}:${USER}" "$BASE_GAME_DIR"
    chown -R "${USER}:${USER}" /home/steam/.config/Epic/FactoryGame/Saved/SaveGames

    printf "\n### Folder Permissions updated.\n"
}

# Set variables for use in the script
function set_variables() {
    printf "\n### Setting variables...\n"

    BASE_GAME_DIR="/home/steam/SatisfactoryDedicatedServer"
    CONFIG_DIR="${BASE_GAME_DIR}/FactoryGame/Saved/Config/LinuxServer"

    # Set the game version variable
    GAME_VERSION=${GAME_VERSION:-"public"}

    # Set the max players variable
    MAX_PLAYERS=${MAX_PLAYERS:-"16"}

    # Set the max players string variable
    read -r -d '' MAX_PLAYER_STRING << EOF
[/Script/Engine.GameSession]
MaxPlayers=$MAX_PLAYERS
EOF

    # Set the IP address variable
    BIND_IP=${BIND_IP:-"0.0.0.0"}

    # Set the IP Query Port variable
    QUERY_PORT=${QUERY_PORT:-"15777"}

    # Set the IP Game Port variable
    GAME_PORT=${GAME_PORT:-"7777"}
}

## Main
set_variables
update_folder_permissions
apply_preinstall_config
update_satisfactory
apply_postinstall_config
start_satisfactory
