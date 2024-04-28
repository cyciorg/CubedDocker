#!/bin/bash

# Set path to the included jq binary
JQ_PATH="/usr/bin/jq"

# Function to parse JSON responses
parse_json() {
    local input="$1"
    local query="$2"
    "$JQ_PATH" -r "$query" <<<"$input"
}

# Function to download the latest Paper JAR file
download_paper_jar() {
    local prefix="https://papermc.io/api/v2/projects"
    local projects=$(curl -sSL "$prefix" | "$JQ_PATH" -r '.projects')

    if [[ ! $projects =~ "paper" ]]; then
        echo "Paper project not found"
        return
    fi

    local version_groups=$(curl -sSL "$prefix/paper" | "$JQ_PATH" -r '.version_groups')
    local latestVersionGroup=$(echo "$version_groups" | "$JQ_PATH" -r '.[0]')

    local versions=$(curl -sSL "$prefix/paper/version_group/$latestVersionGroup" | "$JQ_PATH" -r '.versions')
    local latestVersion=$(echo "$versions" | "$JQ_PATH" -r '.[0]')

    local builds=$(curl -sSL "$prefix/paper/versions/$latestVersion" | "$JQ_PATH" -r '.builds')
    local latestBuild=$(echo "$builds" | "$JQ_PATH" -r '.[0]')

    local downloadName=$(curl -sSL "$prefix/paper/versions/$latestVersion/builds/$latestBuild" | "$JQ_PATH" -r '.downloads.application.name')

    local download_url="$prefix/paper/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName"

    echo "Downloading Paper JAR version $latestVersion (build $latestBuild)..."
    curl -sSL -o "server.jar" "$download_url"
}

# Function to download the latest Waterfall JAR file
download_waterfall_jar() {
    local prefix="https://papermc.io/api/v2/projects"
    local projects=$(curl -sSL "$prefix" | "$JQ_PATH" -r '.projects')

    if [[ ! $projects =~ "waterfall" ]]; then
        echo "Waterfall project not found"
        return
    fi

    local version_groups=$(curl -sSL "$prefix/waterfall" | "$JQ_PATH" -r '.version_groups')
    local latestVersionGroup=$(echo "$version_groups" | "$JQ_PATH" -r '.[0]')

    local versions=$(curl -sSL "$prefix/waterfall/version_group/$latestVersionGroup" | "$JQ_PATH" -r '.versions')
    local latestVersion=$(echo "$versions" | "$JQ_PATH" -r '.[0]')

    local builds=$(curl -sSL "$prefix/waterfall/versions/$latestVersion" | "$JQ_PATH" -r '.builds')
    local latestBuild=$(echo "$builds" | "$JQ_PATH" -r '.[0]')

    local downloadName=$(curl -sSL "$prefix/waterfall/versions/$latestVersion/builds/$latestBuild" | "$JQ_PATH" -r '.downloads.application.name')

    local download_url="$prefix/waterfall/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName"

    echo "Downloading Waterfall JAR version $latestVersion (build $latestBuild)..."
    curl -sSL -o "server.jar" "$download_url"
}

# Function to update server.properties
update_server_properties() {
    local server_properties="server.properties"

    if [ -f "$server_properties" ]; then
        "$JQ_PATH" \
            ".view-distance=$VIEW_DISTANCE | \
             .max-players=$MAX_PLAYERS | \
             .motd=\"$MOTD\" | \
             .pvp=$PVP | \
             .enable-command-block=$ENABLE_COMMAND_BLOCK | \
             .spawn-protection=$SPAWN_PROTECTION | \
             .difficulty=\"$DIFFICULTY\" | \
             .max-world-size=$MAX_WORLD_SIZE | \
             .allow-nether=$ALLOW_NETHER | \
             .level-type=\"$LEVEL_TYPE\" | \
             .generator-settings=\"$GENERATOR_SETTINGS\" | \
             .allow-end=$ALLOW_END | \
             .enforce-whitelist=$ENFORCE_WHITELIST | \
             .online-mode=$ONLINE_MODE | \
             .spawn-animals=$SPAWN_ANIMALS | \
             .spawn-monsters=$SPAWN_MONSTERS | \
             .spawn-npcs=$SPAWN_NPCS | \
             .generate-structures=$GENERATE_STRUCTURES | \
             .allow-flight=$ALLOW_FLIGHT | \
             .level-seed=\"$LEVEL_SEED\" | \
             .max-build-height=$MAX_BUILD_HEIGHT" \
            "$server_properties" >"$server_properties.tmp" && mv "$server_properties.tmp" "$server_properties"
    else
        echo "view-distance=$VIEW_DISTANCE" >"$server_properties"
        echo "max-players=$MAX_PLAYERS" >>"$server_properties"
        echo "motd=$MOTD" >>"$server_properties"
        echo "pvp=$PVP" >>"$server_properties"
        echo "enable-command-block=$ENABLE_COMMAND_BLOCK" >>"$server_properties"
        echo "spawn-protection=$SPAWN_PROTECTION" >>"$server_properties"
        echo "difficulty=$DIFFICULTY" >>"$server_properties"
        echo "max-world-size=$MAX_WORLD_SIZE" >>"$server_properties"
        echo "allow-nether=$ALLOW_NETHER" >>"$server_properties"
        echo "level-type=$LEVEL_TYPE" >>"$server_properties"
        echo "generator-settings=$GENERATOR_SETTINGS" >>"$server_properties"
        echo "allow-end=$ALLOW_END" >>"$server_properties"
        echo "enforce-whitelist=$ENFORCE_WHITELIST" >>"$server_properties"
        echo "online-mode=$ONLINE_MODE" >>"$server_properties"
        echo "spawn-animals=$SPAWN_ANIMALS" >>"$server_properties"
        echo "spawn-monsters=$SPAWN_MONSTERS" >>"$server_properties"
        echo "spawn-npcs=$SPAWN_NPCS" >>"$server_properties"
        echo "generate-structures=$GENERATE_STRUCTURES" >>"$server_properties"
        echo "allow-flight=$ALLOW_FLIGHT" >>"$server_properties"
        echo "level-seed=$LEVEL_SEED" >>"$server_properties"
        echo "max-build-height=$MAX_BUILD_HEIGHT" >>"$server_properties"
    fi
}

# Function to start the Minecraft server
start_minecraft_server() {
    if [ -f "paper.jar" ]; then
        java "$JVM_OPTS" -jar "paper.jar"
    else
        echo "No Minecraft JAR file found. Downloading Paper JAR..."
        download_paper_jar
        java "$JVM_OPTS" -jar "paper.jar"
    fi
}

# Function to check server health and restart if necessary
check_server_health() {
    while true; do
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        ram_available=$(free -m | awk '/^Mem:/ {print $7}')

        if (( $(echo "$cpu_usage > 90" | bc -l) )) || (( $(echo "$ram_available < 500" | bc -l) )); then
            echo "Server is unhealthy (CPU usage: $cpu_usage%, RAM available: $ram_available MB). Restarting..."
            if [ "$PROXY" == "true" ]; then
                echo "Downloading Waterfall JAR..."
                download_waterfall_jar
                start_minecraft_server
            else
                echo "Downloading Paper JAR..."
                download_paper_jar
                start_minecraft_server
            fi
        else
            echo "Server is healthy (CPU usage: $cpu_usage%, RAM available: $ram_available MB)."
        fi

        sleep 60  # Check every minute
    done
}

# Accept the EULA if not already accepted
if [ ! -f "eula.txt" ]; then
    echo "eula=true" >"eula.txt"
fi

# Set the memory limit for the JVM
JVM_OPTS="-Xms${MEMORY} -Xmx${MEMORY}"

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

# Update server.properties with environment variables
update_server_properties

# Start the Minecraft server and check its health
check_server_health