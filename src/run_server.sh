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

    # Set the Server Name
    sed -i "s/PublicName=.*/PublicName=$SERVER_NAME/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Server Password
    sed -i "s/Password=.*/Password=$SERVER_PASSWORD/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Autosave Interval
    sed -i "s/SaveWorldEveryMinutes=.*/SaveWorldEveryMinutes=$AUTOSAVE_INTERVAL/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Car Spawn Rate
    sed -i "s/CarSpawnRate = .*/CarSpawnRate = $CAR_SPAWN_RATE,/g" "$CONFIG_DIR/Server/servertest_SandboxVars.lua"

    # Set the Max Players
    sed -i "s/MaxPlayers=.*/MaxPlayers=$MAX_PLAYERS/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the maximum amount of RAM for the JVM
    sed -i "s/-Xmx.*/-Xmx$MAX_RAM \\\/g" "$BASE_GAME_DIR/start-server.sh"

    # Set the Pause on Empty Server
    sed -i "s/PauseEmpty=.*/PauseEmpty=$PAUSE_ON_EMPTY/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Player Safehouse
    sed -i "s/PlayerSafehouse=.*/PlayerSafehouse=$PLAYER_SAFEHOUSE/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Player Safehouse Respawn
    sed -i "s/SafehouseAllowRespawn=.*/SafehouseAllowRespawn=$PLAYER_SAFEHOUSE/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Sleep Until Morning
    sed -i "s/SleepAllowed=.*/SleepAllowed=$PLAYER_SAFEHOUSE/g" "$CONFIG_DIR/Server/servertest.ini"

    # Set the Spawn with Starter Kit
    sed -i "s/StarterKit = .*/StarterKit = $STARTER_KIT,/g" "$CONFIG_DIR/Server/servertest_SandboxVars.lua"

    # Set the Weapon Multi Hit
    sed -i "s/MultiHitZombies = .*/MultiHitZombies = $WEAPON_MULTI_HIT,/g" "$CONFIG_DIR/Server/servertest_SandboxVars.lua"

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

    # Set the IP address variable
    BIND_IP=${BIND_IP:-"0.0.0.0"}

    # Set the game version variable
    GAME_VERSION=${GAME_VERSION:-"public"}

    # Set the IP Query Port variable
    QUERY_PORT=${QUERY_PORT:-"16261"}

    # Set the IP Game Port variable
    GAME_PORT=${GAME_PORT:-"8766"}

    # Set the Server name variable
    SERVER_NAME=${SERVER_NAME:-"Zomboid Server"}

    # Set the Server Password variable
    SERVER_PASSWORD=${SERVER_PASSWORD:-""}

    # Set the Autosave Interval variable
    AUTOSAVE_INTERVAL=${AUTOSAVE_INTERVAL:-"15"}

    # Set the Car Spawn rate variable
    CAR_SPAWN_RATE=${CAR_SPAWN_RATE:-"3"}

    # Set the Max Players variable
    MAX_PLAYERS=${MAX_PLAYERS:-"16"}

    # Set the Maximum RAM variable
    MAX_RAM=${MAX_RAM:-"4096m"}

    # Set the Pause on Empty variable
    PAUSE_ON_EMPTY=${PAUSE_ON_EMPTY:-"true"}

    # Set Player Safehouse variable
    PLAYER_SAFEHOUSE=${PLAYER_SAFEHOUSE:-"true"}

    # Set the Player Safehouse Respawn variable
    SAFEHOUSE_RESPAWN=${SAFEHOUSE_RESPAWN:-"true"}

    # Set the Sleep until morning variable
    SLEEP_ALLOWED=${SLEEP_ALLOWED:-"true"}

    # Set the Starter Kit variable
    STARTER_KIT=${STARTER_KIT:-"true"}

    # Set the Weapon Multi-Hit variable
    WEAPON_MULTI_HIT=${WEAPON_MULTI_HIT:-"true"}
}

## Main
set_variables
update_folder_permissions
apply_preinstall_config
update_server
apply_postinstall_config
start_server
