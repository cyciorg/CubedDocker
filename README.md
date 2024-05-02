# CubedDocker: Dockerized Minecraft Server with Paper and Waterfall Integration

## Minecraft Server

Welcome to the Minecraft Server Docker image! This Docker image provides a Minecraft server with Paper and Waterfall integration, allowing you to easily set up and run your own Minecraft server environment.

## Features

- **Paper and Waterfall Integration:** Utilizes the Paper and Waterfall projects for enhanced server performance and optimization.
- **Customizable Configuration:** Easily configure your Minecraft server settings using environment variables in the Docker Compose file.
- **Scalability:** Can handle up to 20 players with 4GB of memory and customizable world settings.

## Usage

To use this Docker image, make sure you have Docker installed on your system. Then, create a Docker Compose file (e.g., docker-compose.yml) with the following content:

```yaml
version: "3.8"

services:
  minecraft:
    image: phlcyci/cubeddocker
    container_name: Minecraft
    ports:
      - "25565:25565"
    environment:
      MEMORY: "4G"
      PROXY: "false"
    volumes:
      - minecraft_servers:/minecraft/server
    restart: unless-stopped

volumes:
  minecraft_servers:

```

## Customization

You can customize your Minecraft server by modifying the environment variables in the Docker Compose file. Here are the available options:

```yaml
environment:
      MEMORY: "4G"
      PROXY: "false"
      MINECRAFT_VIEW_DISTANCE: "12"
      MINECRAFT_MAX_PLAYERS: "30"
      MINECRAFT_SERVER_NAME: "server1"
      MINECRAFT_MOTD: "Welcome to My Minecraft Server"
      MINECRAFT_PVP: "true"
      MINECRAFT_ENABLE_JMX_MONITORING: "false"
      MINECRAFT_RCON_PORT: "25575"
      MINECRAFT_LEVEL_SEED: ""
      MINECRAFT_GAMEMODE: "survival"
      MINECRAFT_ENABLE_COMMAND_BLOCK: "false"
      MINECRAFT_ENABLE_QUERY: "false"
      MINECRAFT_GENERATOR_SETTINGS: "{}"
      MINECRAFT_ENFORCE_SECURE_PROFILE: "true"
      MINECRAFT_LEVEL_NAME: "world"
      MINECRAFT_QUERY_PORT: "25565"
      MINECRAFT_GENERATE_STRUCTURES: "true"
      MINECRAFT_MAX_CHAINED_NEIGHBOR_UPDATES: "1000000"
      MINECRAFT_DIFFICULTY: "easy"
      MINECRAFT_NETWORK_COMPRESSION_THRESHOLD: "256"
      MINECRAFT_MAX_TICK_TIME: "60000"
      MINECRAFT_REQUIRE_RESOURCE_PACK: "false"
      MINECRAFT_USE_NATIVE_TRANSPORT: "true"
      MINECRAFT_ONLINE_MODE: "true"
      MINECRAFT_ENABLE_STATUS: "true"
      MINECRAFT_ALLOW_FLIGHT: "false"
      MINECRAFT_INITIAL_DISABLED_PACKS: ""
      MINECRAFT_BROADCAST_RCON_TO_OPS: "true"
      MINECRAFT_SERVER_IP: ""
      MINECRAFT_RESOURCE_PACK_PROMPT: ""
      MINECRAFT_ALLOW_NETHER: "true"
      MINECRAFT_SERVER_PORT: "25565"
      MINECRAFT_ENABLE_RCON: "false"
      MINECRAFT_SYNC_CHUNK_WRITES: "true"
      MINECRAFT_OP_PERMISSION_LEVEL: "4"
      MINECRAFT_PREVENT_PROXY_CONNECTIONS: "false"
      MINECRAFT_HIDE_ONLINE_PLAYERS: "false"
      MINECRAFT_RESOURCE_PACK: ""
      MINECRAFT_ENTITY_BROADCAST_RANGE_PERCENTAGE: "100"
      MINECRAFT_SIMULATION_DISTANCE: "10"
      MINECRAFT_RCON_PASSWORD: ""
      MINECRAFT_PLAYER_IDLE_TIMEOUT: "0"
      MINECRAFT_FORCE_GAMEMODE: "false"
      MINECRAFT_RATE_LIMIT: "0"
      MINECRAFT_HARDCORE: "false"
      MINECRAFT_WHITE_LIST: "false"
      MINECRAFT_BROADCAST_CONSOLE_TO_OPS: "true"
      MINECRAFT_SPAWN_NPCS: "true"
      MINECRAFT_SPAWN_ANIMALS: "true"
      MINECRAFT_LOG_IPS: "true"
      MINECRAFT_FUNCTION_PERMISSION_LEVEL: "2"
      MINECRAFT_INITIAL_ENABLED_PACKS: "vanilla"
      MINECRAFT_LEVEL_TYPE: "minecraft:normal"
      MINECRAFT_TEXT_FILTERING_CONFIG: ""
      MINECRAFT_SPAWN_MONSTERS: "true"
      MINECRAFT_ENFORCE_WHITELIST: "false"
      MINECRAFT_SPAWN_PROTECTION: "16"
      MINECRAFT_RESOURCE_PACK_SHA1: ""
      MINECRAFT_MAX_WORLD_SIZE: "29999984"
```

## Connecting

To access the console, execute the following commands:

```bin
docker exec -it <ServiceName_or_ID> /bin/bash
screen -x minecraft
```

Replace <ServiceName_or_ID> with the name or ID of your Docker service.

## Plugins

To add plugins to your Minecraft instance repeat the following
```yaml
volumes:
  - ./path/to/your/plugins:/minecraft/server/plugins
```