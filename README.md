# Project Zomboid Dedicated Server

## Disclaimer

**Note:** This image is not officially supported by Valve, nor by The Indie Stone.

If issues are encountered, please report them on
the [GitHub repository](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/new/choose)

## Badges

[![Build and Test Server Image](https://github.com/Renegade-Master/zomboid-dedicated-server/actions/workflows/docker-build.yml/badge.svg?branch=main)](https://github.com/Renegade-Master/zomboid-dedicated-server/actions/workflows/docker-build.yml)
[![Docker Repository on Quay](https://quay.io/repository/renegade_master/zomboid-dedicated-server/status "Docker Repository on Quay")](https://quay.io/repository/renegade_master/zomboid-dedicated-server)

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/renegademaster/zomboid-dedicated-server?label=Latest%20Version)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/renegademaster/zomboid-dedicated-server?label=Image%20Size)
![DockerHub Pulls](https://img.shields.io/docker/pulls/renegademaster/zomboid-dedicated-server?label=DockerHub%20Pull%20Count)

## Description

Dedicated Server for Project Zomboid using Docker, and optionally Docker-Compose.
Built almost from scratch to be the smallest Project Zomboid Dedicated Server around!

**Note:** This Image is "rootless", and therefore should not be run as the `root` user.
Attempting to do so will prevent the server from starting (
see [#8](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/8)
, [#14](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/14)).

Bare-Minimum instructions to get a server running:

```shell
# Pull the latest image:
docker pull renegademaster/zomboid-dedicated-server:latest

# Make two folders
mkdir ZomboidConfig ZomboidDedicatedServer

# Run the server (with bare minimum options):
docker run --detach \
    --mount type=bind,source="$(pwd)/ZomboidDedicatedServer",target=/home/steam/ZomboidDedicatedServer \
    --mount type=bind,source="$(pwd)/ZomboidConfig",target=/home/steam/Zomboid \
    --publish 16261:16261/udp --publish 8766:8766/udp \
    --name zomboid-server \
    docker.io/renegademaster/zomboid-dedicated-server:latest
```

### Assurance / Testing

For every commit, the server is built and started briefly using GitHub Actions. This is to ensure that the server always
works, and makes it less likely that there will be a version released that does not function. The main configurations
are changed and checked after starting the server to verify that it is possible for a user to configure their instance.
Custom Ports and Remote RCON commands are also used during the validation to ensure that the user can host the server
using any Port combination of their choice. You can view the previous Action
runs [here](https://github.com/Renegade-Master/zomboid-dedicated-server/actions/workflows/docker-build.yml).

## Links

### Source:

- [GitHub Repository](https://github.com/Renegade-Master/zomboid-dedicated-server)

### Images:

| Provider                                                                                                               | Image                                               | Pull Command                                                                                                                                     |
| ---------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| [GitHub Packages](https://github.com/Renegade-Master/zomboid-dedicated-server/pkgs/container/zomboid-dedicated-server) | `ghcr.io/renegade-master/zomboid-dedicated-server`  | `docker pull ghcr.io/renegade-master/zomboid-dedicated-server:x.y.z`<br/>`docker pull ghcr.io/renegade-master/zomboid-dedicated-server:latest`   |
| [DockerHub](https://hub.docker.com/r/renegademaster/zomboid-dedicated-server)                                          | `docker.io/renegademaster/zomboid-dedicated-server` | `docker pull docker.io/renegademaster/zomboid-dedicated-server:x.y.z`<br/>`docker pull docker.io/renegademaster/zomboid-dedicated-server:latest` |
| [Red Hat Quay](https://quay.io/repository/renegade_master/zomboid-dedicated-server)                                    | `quay.io/renegade_master/zomboid-dedicated-server`  | `docker pull quay.io/renegade_master/zomboid-dedicated-server:x.y.z`<br/>`docker pull quay.io/renegade_master/zomboid-dedicated-server:latest`   |

### External Resources:

- [Dedicated Server Wiki](https://pzwiki.net/wiki/Dedicated_Server)
- [Dedicated Server Configuration](https://pzwiki.net/wiki/Server_Settings)
- [Steam DB Page](https://steamdb.info/app/380870/)

## Prerequisites

### Directories

Two directories are required to be present on the host:

| Name               | Directory                | Description                                          |
| ------------------ | ------------------------ | ---------------------------------------------------- |
| Configuration Data | `ZomboidConfig`          | For storing the server configuration and save files. |
| Installation Data  | `ZomboidDedicatedServer` | For storing the server game data.                    |

These folders must be created in the directory that you intend to run the Docker image from. This could be a folder that
you have created in some kind of "server directory", or it could be the root of this repository after you have cloned it
down. **_If these folders are not present when the Docker image starts, you will get permissions errors_** (
see [#8](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/8)
, [#14](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/14)
, [#17](https://github.com/Renegade-Master/zomboid-dedicated-server/issues/17)) because the Docker engine will create
the folders at Container runtime. This creates them under the `root` user on the host which causes permissions
conflicts.

The 'Configuration Data' folder is where the server configuration and save files are stored. This folder can be opened
and edited just like if you were running the server without Docker. You can backup your save files, or edit the server
configuration files. You should start the server once successfully before attempting to edit files in the 'Configuration
Data' folder. Once the files are generated, it is safe to edit them. Most configuration option changes will require a
restart of the server to properly take effect. Most of these settings are also configurable from the in-game Admin menu.

The 'Installation Data' folder is where the server game data is stored. This folder can be opened and edited, but a full
restart of the server can sometimes reset changes to this folder during file verification. Therefore, the recommended
way to change files that would be stored in this folder is to use the Environment Variables in the 'Optional Arguments'
table provided by the Docker image.

### Ports

There are a total of three ports that can be utilised by the server, but only two are strictly required:

| Name         | Default Port | Description                                                      | Required |
| ------------ | ------------ | ---------------------------------------------------------------- | -------- |
| `QUERY_PORT` | `16261`      | Port used by the server to listen for connections.               | `true`   |
| `GAME_PORT`  | `8766`       | Port used by the server to communicate with connected clients.   | `true`   |
| `RCON_PORT`  | `27015`      | Port used by the server to listen for RCON connections/commands. | `false`  |

All Ports are configurable to use different Port numbers, however you must be aware that by changing a Port in the game
configuration files, that you must also expose the changed (or default) Port in the Docker run command `--publish ...`
or present under the `services.zomboid-server.ports` configuration key of the Docker-Compose file. Also, _**it is
essential that these Ports are not blocked by a firewall**_. If you are behind a router and/or firewall, you will almost
definitely need to open these Ports in order for anyone else outside your network to connect to the server. Port
forwarding, and opening Ports in hosted servers is not within the scope of this project. To get instructions for your
specific use case you will need to ask your ISP, Server Provider, or consult the instructions on your Third-Party
Router.

The strictly required Ports (`QUERY_PORT` and `GAME_PORT`) are used by the server to listen for connections and
communicate with connected clients. These Ports must be assigned a value, and must be accessible from the Internet
(i.e. "forwarded").

If you intend to use RCON to interact with the server, then it follows that that Port (`RCON_PORT`) must also be open
for connections. This is not required if you do not intend to use RCON, and in this scenario, keeping it closed enhances
the security of your server. If you do not wish to use RCON, then it does not need to be present in the Docker run
command, nor in the Docker-Compose file.

## Instructions

The server can be run using plain Docker, or using Docker-Compose. The end-result is the same, but Docker-Compose is
recommended for ease of configuration.

_Optional arguments table_:

| Argument            | Description                                                            | Values            | Default       |
| ------------------- | ---------------------------------------------------------------------- | ----------------- | ------------- |
| `ADMIN_PASSWORD`    | Server Admin account password                                          | [a-zA-Z0-9]+      | changeme      |
| `ADMIN_USERNAME`    | Server Admin account username                                          | [a-zA-Z0-9]+      | superuser     |
| `AUTOSAVE_INTERVAL` | Interval between autosaves in minutes                                  | [0-9]+            | 15m           |
| `BIND_IP`           | IP to bind the server to                                               | 0.0.0.0           | 0.0.0.0       |
| `GAME_PORT`         | Port for sending game data to clients                                  | 1000 - 65535      | 8766          |
| `GAME_VERSION`      | Game version to serve                                                  | [a-zA-Z0-9_]+     | `public`      |
| `MAP_NAMES`         | Map Names (e.g. North;South)                                           | map1;map2;map3    | Muldraugh, KY |
| `MAX_PLAYERS`       | Maximum players allowed in the Server                                  | [0-9]+            | 16            |
| `MAX_RAM`           | Maximum amount of RAM to be used                                       | ([0-9]+)m         | 4096m         |
| `MOD_NAMES`         | Workshop Mod Names (e.g. ClaimNonResidential;MoreDescriptionForTraits) | mod1;mod2;mod     |               |
| `MOD_WORKSHOP_IDS`  | Workshop Mod IDs (e.g. 2160432461;2685168362)                          | xxxxxx;xxxxx;     |               |
| `PAUSE_ON_EMPTY`    | Pause the Server when no Players are connected                         | (true&vert;false) | true          |
| `PUBLIC_SERVER`     | If set to `true` only Pre-Approved/Allowed players can join the server | (true&vert;false) | true          |
| `QUERY_PORT`        | Port for other players to connect to                                   | 1000 - 65535      | 16261         |
| `RCON_PASSWORD`     | Password for authenticating incoming RCON commands                     | [a-zA-Z0-9]+      | changeme_rcon |
| `RCON_PORT`         | Port to listen on for RCON commands                                    | (true&vert;false) | 27015         |
| `SERVER_NAME`       | Publicly visible Server Name                                           | [a-zA-Z0-9]+      | ZomboidServer |
| `SERVER_PASSWORD`   | Server password                                                        | [a-zA-Z0-9]+      |               |
| `STEAM_VAC`         | Use Steam VAC anti-cheat                                               | (true&vert;false) | true          |
| `USE_STEAM`         | Create a Steam Server, or a Non-Steam Server                           | (true&vert;false) | true          |

### Docker

The following are instructions for running the server using the Docker image.

1. Acquire the image locally:

   - Pull the image from DockerHub:

     ```shell
     docker pull renegademaster/zomboid-dedicated-server:<tagname>
     ```

   - Or alternatively, build the image:

     ```shell
     git clone https://github.com/Renegade-Master/zomboid-dedicated-server.git \
         && cd zomboid-dedicated-server

     docker build -t docker.io/renegademaster/zomboid-dedicated-server:<tag> -f docker/zomboid-dedicated-server.Dockerfile .
     ```

2. Run the container:

   **\*Note**: Arguments inside square brackets are optional. If the default ports are to be overridden, then the
   `published` ports below must also be changed\*

   ```shell
   mkdir ZomboidConfig ZomboidDedicatedServer

   docker run --detach \
       --mount type=bind,source="$(pwd)/ZomboidDedicatedServer",target=/home/steam/ZomboidDedicatedServer \
       --mount type=bind,source="$(pwd)/ZomboidConfig",target=/home/steam/Zomboid \
       --publish 16261:16261/udp --publish 8766:8766/udp [--publish 27015:27015/tcp] \
       --name zomboid-server \
       [--env=ADMIN_PASSWORD=<value>] \
       [--env=ADMIN_USERNAME=<value>] \
       [--env=AUTOSAVE_INTERVAL=<value>] \
       [--env=BIND_IP=<value>] \
       [--env=GAME_PORT=<value>] \
       [--env=GAME_VERSION=<value>] \
       [--env=MAP_NAMES=<value>] \
       [--env=MAX_PLAYERS=<value>] \
       [--env=MAX_RAM=<value>] \
       [--env=MOD_NAMES=<value>] \
       [--env=MOD_WORKSHOP_IDS=<value>] \
       [--env=PAUSE_ON_EMPTY=<value>] \
       [--env=PUBLIC_SERVER=<value>] \
       [--env=QUERY_PORT=<value>] \
       [--env=RCON_PASSWORD=<value>] \
       [--env=RCON_PORT=<value>] \
       [--env=SERVER_NAME=<value>] \
       [--env=SERVER_PASSWORD=<value>] \
       [--env=STEAM_VAC=<value>] \
       [--env=USE_STEAM=<value>] \
       docker.io/renegademaster/zomboid-dedicated-server[:<tagname>]
   ```

3. Optionally, reattach the terminal to the log output (**\*Note**: this is not an Interactive Terminal\*)

   ```shell
   docker logs --follow zomboid-server
   ```

4. Once you see `LuaNet: Initialization [DONE]` in the console, people can start to join the server.

### Docker-Compose

The following are instructions for running the server using Docker-Compose.

1. Download the repository:

   ```shell
   git clone https://github.com/Renegade-Master/zomboid-dedicated-server.git \
       && cd zomboid-dedicated-server
   ```

2. Make any configuration changes you want to in the `docker-compose.yaml` file. In
   the `services.zomboid-server.environment` section, you can change values for the server configuration.

   **\*Note**: If the default ports are to be overridden, then the `published` ports must also be changed\*

3. Run the following commands:

   - Make the data and configuration directories:

     ```shell
     mkdir ZomboidConfig ZomboidDedicatedServer
     ```

   - Pull the image from DockerHub:

     ```shell
     docker-compose up --detach
     ```

   - Or alternatively, build the image:

     ```shell
     docker-compose up --build --detach
     ```

4. Optionally, reattach the terminal to the log output (**\*Note**: this is not an Interactive Terminal\*)

   ```shell
   docker-compose logs --follow
   ```

5. Once you see `LuaNet: Initialization [DONE]` in the console, people can start to join the server.
