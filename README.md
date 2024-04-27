# CubedDocker: Dockerized Minecraft Server with Paper and Waterfall Integration

![Minecraft Server](https://static.wikia.nocookie.net/minecraft_gamepedia/images/e/ed/Magma_Cube.png/revision/latest/thumbnail/width/360/height/360?cb=20190805151823)

Welcome to the Minecraft Server Docker image! This Docker image provides a Minecraft server with Paper and Waterfall integration, allowing you to easily set up and run your own Minecraft server environment.

## Features

- **Paper and Waterfall Integration**: Utilizes the Paper and Waterfall projects for enhanced server performance and optimization.
- **Customizable Configuration**: Easily configure your Minecraft server settings using environment variables in the Docker Compose file.
- **Scalability**: Can handle up to 30 players with 4GB of memory and customizable world settings.

## Usage

To use this Docker image, make sure you have Docker installed on your system. Then, create a Docker Compose file (e.g., docker-compose.yml) with the following content:

```yaml
version: '3.8'

services:
  minecraft:
    image: philcyci/cubeddocker
    container_name: "Minecraft"
    ports:
      - "25565:25565"
    environment:
      PROXY: "true" # Use Waterfall
      MEMORY: "4G"
      VIEW_DISTANCE: 12
      MAX_PLAYERS: 30
      SERVER_NAME: "server1"
      MOTD: "Welcome to My Minecraft Server"
      PVP: "true"
      # Add more environment options as needed
    volumes:
      - minecraft_servers:/minecraft/servers
    restart: unless-stopped

volumes:
  minecraft_servers:
```
