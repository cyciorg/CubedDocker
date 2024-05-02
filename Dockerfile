# Stage 1: Build stage
FROM eclipse-temurin:21 AS builder

# Install necessary packages for building
RUN apt-get update && \
    apt-get install -y curl screen && \
    rm -rf /var/lib/apt/lists/*

# Download and install jq
RUN curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/bin/jq

# Set up the Minecraft server directory
WORKDIR /minecraft/server

# Copy entrypoint script
COPY entrypoint.sh .

# Set permissions for the entrypoint script
RUN chmod +x entrypoint.sh

# Stage 2: Final image
FROM eclipse-temurin:21

# Install jq in the final image
RUN apt-get update && \
    apt-get install -y jq screen && \
    rm -rf /var/lib/apt/lists/*

# Ensure jq is executable
RUN chmod +x /usr/bin/jq

# Create minecraft user and group
RUN groupadd -r minecraft && useradd -r -g minecraft minecraft

# Set up the Minecraft server directory
WORKDIR /minecraft/server

# Copy entrypoint script from the builder stage
COPY --from=builder /minecraft/server/entrypoint.sh .

# Set permissions for the entrypoint script
RUN chmod +x entrypoint.sh

# Ensure correct permissions for the Minecraft server directory
RUN chown -R minecraft:minecraft /minecraft/server

# Switch to the minecraft user
USER minecraft

# Set the entry point to start the Minecraft server
CMD ["sh", "entrypoint.sh"]
