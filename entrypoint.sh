#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error when performing parameter expansion
set -o pipefail  # Exit if any command in a pipeline fails

echo "Starting entrypoint.sh script..."

# Set the server port from the environment variable, defaulting to 25565
SERVER_PORT=${SERVER_PORT:-25565}
echo "Server port: $SERVER_PORT"

# Function to parse JSON responses
jq_location="$(command -v jq)"
if [ -z "$jq_location" ]; then
    echo "Error: 'jq' command not found. Please install 'jq'." >&2
    exit 1
fi
echo "jq is installed at: $jq_location"

# Function to download the latest Paper or Waterfall JAR file based on the PROXY variable
download_server_jar() {
    local prefix="https://papermc.io/api/v2/projects"
    local project="paper"

    if [ "$PROXY" = "true" ]; then
        project="waterfall"
    fi

    local latestVersion
    latestVersion=$(curl -sSL "$prefix/$project" | jq -r '.versions | map(select(. != "latest")) | .[-1]') || {
        echo "Error: Failed to determine the latest version for $project" >&2
        exit 1
    }

    local latestBuild
    latestBuild=$(curl -sSL "$prefix/$project/versions/$latestVersion" | jq -r '.builds | .[-1]') || {
        echo "Error: Failed to determine the latest build for $project version $latestVersion" >&2
        exit 1
    }

    local downloadName
    downloadName="$project-$latestVersion-$latestBuild.jar"
    local download_url="$prefix/$project/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName"

    echo "Downloading $project JAR version $latestVersion (build $latestBuild)..."
    curl -sSL -o "server.jar" "$download_url" || {
        echo "Error: Failed to download $project JAR version $latestVersion (build $latestBuild)" >&2
        exit 1
    }
    echo "Downloaded $project JAR version $latestVersion (build $latestBuild)"
}

# Function to update server.properties
update_server_properties() {
    local server_properties="server.properties"

    echo "DEBUG: Server properties file: $server_properties"

    if [ -f "$server_properties" ]; then
        echo "DEBUG: Server properties file exists"
        while IFS='=' read -r key value
        do
            if [[ ! -z "${!key}" ]]; then
                sed -i "s|^\($key=\).*|\1${!key}|" "$server_properties"
            fi
        done < <(grep -v '^#' "$server_properties" | grep -v '^$')
        echo "DEBUG: Server properties updated successfully"
    else
        echo "DEBUG: Server properties file does not exist. Creating new file..."
        cat <<EOF > "$server_properties"
enable-jmx-monitoring=${MINECRAFT_ENABLE_JMX_MONITORING:-false}
rcon.port=${MINECRAFT_RCON_PORT:-25575}
level-seed=${MINECRAFT_LEVEL_SEED}
gamemode=${MINECRAFT_GAMEMODE:-survival}
enable-command-block=${MINECRAFT_ENABLE_COMMAND_BLOCK:-false}
enable-query=${MINECRAFT_ENABLE_QUERY:-false}
generator-settings=${MINECRAFT_GENERATOR_SETTINGS:-{}}
enforce-secure-profile=${MINECRAFT_ENFORCE_SECURE_PROFILE:-true}
level-name=${MINECRAFT_LEVEL_NAME:-world}
motd=${MINECRAFT_MOTD:-A Minecraft Server}
query.port=${MINECRAFT_QUERY_PORT:-25565}
pvp=${MINECRAFT_PVP:-true}
generate-structures=${MINECRAFT_GENERATE_STRUCTURES:-true}
max-chained-neighbor-updates=${MINECRAFT_MAX_CHAINED_NEIGHBOR_UPDATES:-1000000}
difficulty=${MINECRAFT_DIFFICULTY:-easy}
network-compression-threshold=${MINECRAFT_NETWORK_COMPRESSION_THRESHOLD:-256}
max-tick-time=${MINECRAFT_MAX_TICK_TIME:-60000}
require-resource-pack=${MINECRAFT_REQUIRE_RESOURCE_PACK:-false}
use-native-transport=${MINECRAFT_USE_NATIVE_TRANSPORT:-true}
max-players=${MINECRAFT_MAX_PLAYERS:-20}
online-mode=${MINECRAFT_ONLINE_MODE:-true}
enable-status=${MINECRAFT_ENABLE_STATUS:-true}
allow-flight=${MINECRAFT_ALLOW_FLIGHT:-false}
initial-disabled-packs=${MINECRAFT_INITIAL_DISABLED_PACKS}
broadcast-rcon-to-ops=${MINECRAFT_BROADCAST_RCON_TO_OPS:-true}
view-distance=${MINECRAFT_VIEW_DISTANCE:-10}
server-ip=${MINECRAFT_SERVER_IP}
resource-pack-prompt=${MINECRAFT_RESOURCE_PACK_PROMPT}
allow-nether=${MINECRAFT_ALLOW_NETHER:-true}
server-port=${MINECRAFT_SERVER_PORT:-25565}
enable-rcon=${MINECRAFT_ENABLE_RCON:-false}
sync-chunk-writes=${MINECRAFT_SYNC_CHUNK_WRITES:-true}
op-permission-level=${MINECRAFT_OP_PERMISSION_LEVEL:-4}
prevent-proxy-connections=${MINECRAFT_PREVENT_PROXY_CONNECTIONS:-false}
hide-online-players=${MINECRAFT_HIDE_ONLINE_PLAYERS:-false}
resource-pack=${MINECRAFT_RESOURCE_PACK}
entity-broadcast-range-percentage=${MINECRAFT_ENTITY_BROADCAST_RANGE_PERCENTAGE:-100}
simulation-distance=${MINECRAFT_SIMULATION_DISTANCE:-10}
rcon.password=${MINECRAFT_RCON_PASSWORD}
player-idle-timeout=${MINECRAFT_PLAYER_IDLE_TIMEOUT:-0}
force-gamemode=${MINECRAFT_FORCE_GAMEMODE:-false}
rate-limit=${MINECRAFT_RATE_LIMIT:-0}
hardcore=${MINECRAFT_HARDCORE:-false}
white-list=${MINECRAFT_WHITE_LIST:-false}
broadcast-console-to-ops=${MINECRAFT_BROADCAST_CONSOLE_TO_OPS:-true}
spawn-npcs=${MINECRAFT_SPAWN_NPCS:-true}
spawn-animals=${MINECRAFT_SPAWN_ANIMALS:-true}
log-ips=${MINECRAFT_LOG_IPS:-true}
function-permission-level=${MINECRAFT_FUNCTION_PERMISSION_LEVEL:-2}
initial-enabled-packs=${MINECRAFT_INITIAL_ENABLED_PACKS:-vanilla}
level-type=${MINECRAFT_LEVEL_TYPE:-minecraft:normal}
text-filtering-config=${MINECRAFT_TEXT_FILTERING_CONFIG}
spawn-monsters=${MINECRAFT_SPAWN_MONSTERS:-true}
enforce-whitelist=${MINECRAFT_ENFORCE_WHITELIST:-false}
spawn-protection=${MINECRAFT_SPAWN_PROTECTION:-16}
resource-pack-sha1=${MINECRAFT_RESOURCE_PACK_SHA1}
max-world-size=${MINECRAFT_MAX_WORLD_SIZE:-29999984}
EOF
        echo "DEBUG: New server properties file created"
    fi
}


# Function to start the Minecraft server within screen
start_minecraft_server() {
    echo "Starting Minecraft server..."
    screen -dmS minecraft java -Xmx${MEMORY} -Xms${MEMORY} -jar server.jar nogui || {
        echo "Error: Failed to start Minecraft server" >&2
        exit 1
    }
    echo "Minecraft server started."
}

# Accept the EULA if not already accepted
if [ ! -f "eula.txt" ]; then
    echo "eula=true" >"eula.txt" || {
        echo "Error: Failed to accept EULA" >&2
        exit 1
    }
fi

# Set the memory limit for the JVM
JVM_OPTS="-Xms${MEMORY:-2G} -Xmx${MEMORY:-2G}"

# Add more secure JVM options
JVM_OPTS="$JVM_OPTS \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true"

# Download the appropriate server JAR based on the PROXY option
download_server_jar || {
    echo "Error: Failed to download server JAR" >&2
    exit 1
}

# Add a delay for 5 seconds
sleep 5

# Update server.properties with environment variables
update_server_properties || {
    echo "Error: Failed to update server.properties" >&2
    exit 1
}

echo "Entrypoint script execution completed."

# Start the Minecraft server
start_minecraft_server || {
    echo "Error: Failed to start Minecraft server" >&2
    exit 1
}

tail -f /dev/null
