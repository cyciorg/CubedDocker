# Stage 1: Build stage
FROM eclipse-temurin:17-jdk AS builder

# Install necessary packages for building
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Download and install jq
RUN curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/bin/jq

# Set up the Minecraft server directory
WORKDIR /minecraft/servers

# Copy the entry point script
COPY entrypoint.sh .

# Stage 2: Final image
FROM eclipse-temurin:17-jdk

# Create a non-root user to run the Minecraft server
RUN groupadd -r minecraft && useradd -r -g minecraft minecraft

# Set environment variables
ENV MEMORY="2G" \
    VIEW_DISTANCE=10 \
    MAX_PLAYERS=20 \
    SERVER_NAME="server1"

# Set up the Minecraft server directory
WORKDIR /minecraft/servers

# Copy files from the builder stage
COPY --from=builder /minecraft/servers .

# Install jq in the final image
RUN apt-get update && \
    apt-get install -y jq && \
    rm -rf /var/lib/apt/lists/*

# Ensure jq is executable
RUN chmod +x /usr/bin/jq

# Change ownership of files to the minecraft user
RUN chown -R minecraft:minecraft /minecraft

# Switch to the minecraft user
USER minecraft

# Copy entrypoint.sh to the server directory
COPY entrypoint.sh /minecraft/servers${SERVER_NAME}

# Set the entrypoint to start the Minecraft server
ENTRYPOINT ["/minecraft/servers/${SERVER_NAME}/entrypoint.sh"]
