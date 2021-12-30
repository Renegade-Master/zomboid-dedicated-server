#!/usr/bin/env bash
#######################################################################
#   Author: Renegade-Master
#	Contributor: JohnEarle
#   Description: Install, update, and start a Dedicated Project Zomboid
#       instance.
#######################################################################

# Set to `-x` for Debug logging
set +x
# Start the Server for the first time to generate configuration files for editing
function start_server_initial() {
	clear
    printf "\n### Starting Project Zomboid Server...\n"
    timeout 30 "$BASE_GAME_DIR"/start-server.sh \
        -adminusername "$ADMIN_USERNAME" \
        -adminpassword "$ADMIN_PASSWORD" \
        -ip "$BIND_IP" -port "$QUERY_PORT" \
        -servername "$SERVER_NAME" \
        -steamvac "$STEAM_VAC" "$USE_STEAM"
}

# Start the Server
function start_server() {
    printf "\n### Starting Project Zomboid Server...\n"
    "$BASE_GAME_DIR"/start-server.sh \
        -adminusername "$ADMIN_USERNAME" \
        -adminpassword "$ADMIN_PASSWORD" \
        -ip "$BIND_IP" -port "$QUERY_PORT" \
        -servername "$SERVER_NAME" \
        -steamvac "$STEAM_VAC" "$USE_STEAM"
}
function apply_postinstall_config() {
    printf "\n### Applying Post Install Configuration...\n"
	
	# Set the Server Name
    sed -i "s/PVP=.*/PVP=$SERVER_PVP/g" "$SERVER_CONFIG"

    # Set the Server Name
    sed -i "s/PublicName=.*/PublicName=$SERVER_NAME/g" "$SERVER_CONFIG"

    # Set the Server Publicity status
    sed -i "s/Open=.*/Open=$PUBLIC_SERVER/g" "$SERVER_CONFIG"

    # Set the Server query Port
    sed -i "s/DefaultPort=.*/DefaultPort=$QUERY_PORT/g" "$SERVER_CONFIG"

    # Set the Server Password
    sed -i "s/Password=.*/Password=$SERVER_PASSWORD/g" "$SERVER_CONFIG"

    # Set the Autosave Interval
    sed -i "s/SaveWorldEveryMinutes=.*/SaveWorldEveryMinutes=$AUTOSAVE_INTERVAL/g" "$SERVER_CONFIG"

    # Set the Car Spawn Rate
    sed -i "s/CarSpawnRate = .*/CarSpawnRate = $CAR_SPAWN_RATE,/g" "$SERVER_RULES_CONFIG"

    # Set the Max Players
    sed -i "s/MaxPlayers=.*/MaxPlayers=$MAX_PLAYERS/g" "$SERVER_CONFIG"

    # Set the maximum amount of RAM for the JVM
    sed -i "s/-Xmx.*/-Xmx$MAX_RAM\",/g" "$SERVER_VM_CONFIG"

    # Set the Pause on Empty Server
    sed -i "s/PauseEmpty=.*/PauseEmpty=$PAUSE_ON_EMPTY/g" "$SERVER_CONFIG"

    # Set the Player Safehouse
    sed -i "s/PlayerSafehouse=.*/PlayerSafehouse=$PLAYER_SAFEHOUSE/g" "$SERVER_CONFIG"

    # Set the Player Safehouse Respawn
    sed -i "s/SafehouseAllowRespawn=.*/SafehouseAllowRespawn=$PLAYER_SAFEHOUSE/g" "$SERVER_CONFIG"

    # Set the Sleep Until Morning
    sed -i "s/SleepAllowed=.*/SleepAllowed=$PLAYER_SAFEHOUSE/g" "$SERVER_CONFIG"

    # Set the Spawn with Starter Kit
    sed -i "s/StarterKit = .*/StarterKit = $STARTER_KIT,/g" "$SERVER_RULES_CONFIG"

    # Set the Weapon Multi Hit
    sed -i "s/MultiHitZombies = .*/MultiHitZombies = $WEAPON_MULTI_HIT,/g" "$SERVER_RULES_CONFIG"
	
	# Set the Mod names (delimited by ; | EG: ClaimNonResidential;MoreDescriptionForTraits)
	sed -i "s/Mods=.*/Mods=$MOD_NAMES/g" "$SERVER_CONFIG"
	
	# Set the Mod Workshop IDs (delimited by ; | EG: 2160432461;2685168362)
	sed -i "s/WorkshopItems=.*/WorkshopItems=$MOD_WORKSHOP_IDS/g" "$SERVER_CONFIG"

    printf "\n### Post Install Configuration applied.\n"
}

# Update the server
function update_server() {
    printf "\n### Updating Project Zomboid Server...\n"

    "$STEAM_PATH" +runscript /home/steam/install_server.scmd

    printf "\n### Project Zomboid Server updated.\n"
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

# start the server to generate configuration file - Prep for post install parameters [30 second start then kill]
function first_start_config_ops()
{
	if[! -d "/root/Zomboid/"]
	{
		printf "\n### First Boot Detected - Burst Startup to create config files.\n"
		start_server_initial
		apply_postinstall_config
	}
}
# Set variables for use in the script
function set_variables() {
    printf "\n### Setting variables...\n"

    BASE_GAME_DIR="/home/steam/ZomboidDedicatedServer"
    CONFIG_DIR="/root/Zomboid"

    # Set the IP address variable
    # NOTE: Project Zomboid cannot handle the IN_ANY address
    if [[ -z "$BIND_IP" ]] || [[ "$BIND_IP" == "0.0.0.0" ]]; then
        BIND_IP=($(hostname -I))
        BIND_IP="${BIND_IP[0]}"
    else
        BIND_IP="$BIND_IP"
    fi
	
	# Set PVP variable
	SERVER_PVP=${SERVER_PVP:-"false"}
    # Set the game version variable
    GAME_VERSION=${GAME_VERSION:-"public"}

    # Set the Server Publicity variable
    PUBLIC_SERVER=${PUBLIC_SERVER:-"true"}

    # Set the IP Query Port variable
    QUERY_PORT=${QUERY_PORT:-"16261"}

    # Set the IP Game Port variable
    GAME_PORT=${GAME_PORT:-"8766"}

    # Set the Server name variable
    SERVER_NAME=${SERVER_NAME:-"ZomboidServer"}

    # Set the Server Password variable
    SERVER_PASSWORD=${SERVER_PASSWORD:-""}

    # Set the Server Admin Password variable
    ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}

    # Set the Server Admin Password variable
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-"changeme"}

    # Set server type variable
    if [[ -z "$USE_STEAM" ]] || [[ "$USE_STEAM" == "true" ]]; then
        USE_STEAM=""
    else
        USE_STEAM="-nosteam"
    fi

    # Set Steam VAC Protection variable
    STEAM_VAC=${STEAM_VAC:-"true"}

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
	
	# Set the Mods to use from workshop
	MOD_NAMES = ${MOD_NAMES:-""}
	MOD_WORKSHOP_IDS = ${MOD_WORKSHOP_IDS:-""}

    SERVER_CONFIG="$CONFIG_DIR/Server/$SERVER_NAME.ini"
    SERVER_VM_CONFIG="$BASE_GAME_DIR/ProjectZomboid64.json"
    SERVER_RULES_CONFIG="$CONFIG_DIR/Server/${SERVER_NAME}_SandboxVars.lua"
}

## Main
set_variables
update_folder_permissions
apply_preinstall_config
update_server
first_start_config_ops
apply_postinstall_config
start_server
	
