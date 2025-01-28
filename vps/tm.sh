#!/bin/bash

# Function to check if Docker is installed
is_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Step 1: Check if Docker is installed
if is_docker_installed; then
    echo "Docker is already installed. Skipping installation."
else
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

# Step 2: Run traffmonetizer container
echo "Running traffmonetizer container..."
docker_output=$(docker run -d --name tm traffmonetizer/cli_v2 start accept --token oUvchCoFrhuU52WxZVOh52H+PVW/xbAg3JizSGXzDAk= 2>&1)

# Step 3: Check if the container exited immediately
container_status=$(docker inspect --format='{{.State.Status}}' tm)

if [[ $container_status == "exited" ]]; then
    echo "Container failed to start. Checking for platform mismatch..."

    # Look for the specific platform mismatch warning
    if [[ $docker_output == *"platform (linux/amd64) does not match the detected host platform (linux/arm"* ]]; then
        echo "Platform mismatch detected. Switching to ARM container..."
        docker rm tm
        docker run -d --name tm traffmonetizer/cli_v2:arm32v7 start accept --token oUvchCoFrhuU52WxZVOh52H+PVW/xbAg3JizSGXzDAk=
    else
        echo "Container failed due to another issue."
    fi
else
    echo "Container started successfully."
fi

# Step 4: Run repocket container
echo "Running repocket container..."
docker run --name repocket -e RP_EMAIL=mjonhson996@gmail.com -e RP_API_KEY=90fe4047-d14f-4716-8f86-12e7aed14ef4 -d --restart=always repocket/repocket

# Step 5: Run repocket container
echo "Running packetshare container..."
docker run -d --restart unless-stopped packetshare/packetshare -accept-tos -email=demonsword18@outlook.com -password=Aa264580

echo "Setup completed."
