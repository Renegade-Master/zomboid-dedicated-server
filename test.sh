docker run \
  --rm \
  --name zomboid-dedicated-server \
  --mount type=bind,source="$(pwd)/ZomboidDedicatedServer",target=/home/steam/ZomboidDedicatedServer \
  --mount type=bind,source="$(pwd)/ZomboidConfig",target=/home/steam/Zomboid \
  --env=AUTOSAVE_INTERVAL="16" \
  --env=GAME_PORT="25496" \
  --env=MAP_NAMES="BedfordFalls;North;South;West" \
  --env=MAX_PLAYERS="14" \
  --env=MAX_RAM="6144m" \
  --env=MOD_NAMES="BedfordFalls" \
  --env=MOD_WORKSHOP_IDS="522891356" \
  --env=PAUSE_ON_EMPTY="true" \
  --env=PUBLIC_SERVER="false" \
  --env=RCON_PASSWORD="github_action_test_rcon_password" \
  --env=RCON_PORT="27025" \
  --env=SERVER_NAME="GitHubActionTest" \
  --env=SERVER_PASSWORD="github_action_test_password" \
  ghcr.io/renegade-master/zomboid-dedicated-server:test

