#!/bin/bash

# Set path to the included jq binary
JQ_PATH="./jq"

# Function to parse JSON responses
parse_json() {
    local input="$1"
    local query="$2"
    "$JQ_PATH" -r "$query" <<<"$input"
}

# Function to download the latest Paper JAR file
download_paper_jar() {
    local prefix="https://papermc.io/api/v2/projects"

    # Fetch projects
    local projects=$(curl -sSL "$prefix" | jq -r '.projects')
    if [[ ! $projects =~ "paper" ]]; then
        echo "Paper project not found"
        return
    fi

    # Fetch version groups
    local version_groups=$(curl -sSL "$prefix/paper" | jq -r '.version_groups')
    local latestVersionGroup=$(echo "$version_groups" | jq -r '.[-1]')

    # Fetch versions
    local versions=$(curl -sSL "$prefix/paper/version_group/$latestVersionGroup" | jq -r '.versions')
    local latestVersion=$(echo "$versions" | jq -r '.[-1]')

    # Fetch builds
    local builds=$(curl -sSL "$prefix/paper/versions/$latestVersion" | jq -r '.builds')
    local latestBuild=$(echo "$builds" | jq -r '.[-1]')

    # Fetch download name
    local downloadName=$(curl -sSL "$prefix/paper/versions/$latestVersion/builds/$latestBuild" | jq -r '.downloads.application.name')

    # Download the JAR file
    local download_url="$prefix/paper/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName"
    echo "Downloading Paper JAR version $latestVersion (build $latestBuild)..."
    curl -sSL -o "paper.jar" "$download_url"
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


# Download the latest Paper JAR
download_paper_jar

# Start the Minecraft server
java $JVM_OPTS -jar "paper.jar" --view-distance=$VIEW_DISTANCE --max-players=$MAX_PLAYERS
