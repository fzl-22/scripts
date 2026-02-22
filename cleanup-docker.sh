#!/bin/bash

# A script to clean up unused Docker assets to reclaim disk space.
# Includes an aggressive option to remove all unused images.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🐳 Docker Cleanup Script"
echo "-------------------------"

# Function to kill the Docker cagent process if it's running.
kill_docker_cagent() {
    echo "🔎 Checking for lingering Docker cagent process..."
    if pgrep -f "Docker.app/Contents/Resources/bin/cagent" > /dev/null; then
        echo "🔪 Lingering cagent process found. Attempting to kill it..."
        pkill -f "Docker.app/Contents/Resources/bin/cagent"
        echo "✅ cagent process killed."
    else
        echo "👍 No lingering cagent process found."
    fi
    echo ""
}

# Kill the cagent process before proceeding.
kill_docker_cagent

# Check if Docker is running.
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker does not seem to be running."
    echo "Please start Docker and try again."
    exit 1
fi

echo "📊 Here's your current Docker disk usage:"
docker system df
echo "--------------------------------"
echo ""

# --- Full System Prune (including unused images) ---
echo "The main cleanup step will remove the following:"
echo "  - All stopped containers"
echo "  - All build cache"
echo "  - All unused networks"
echo "  - All unused images (images not associated with any container)"
echo ""
echo "This is the most effective way to reclaim disk space from unused images."
echo "NOTE: Images currently marked as 'in use' (e.g., by Kubernetes) are safe and will NOT be deleted."
echo ""

read -p "Are you sure you want to remove all unused images? (y/N) " -n 1 -r
echo "" # Move to a new line.

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Running aggressive Docker cleanup (docker system prune --all)..."
    docker system prune --all -f
    echo "✅ Aggressive cleanup complete."
else
    echo "Skipping aggressive image cleanup. Running standard prune instead..."
    echo "This will only remove 'dangling' images."
    docker system prune -f
    echo "✅ Standard cleanup complete."
fi
echo ""

# --- Volume Prune ---
echo "--------------------------------"
echo "⚠️  WARNING: The next step is to remove unused Docker volumes. ⚠️"
echo "This will permanently delete data from volumes that are not currently"
echo "associated with at least one container. This is useful for cleaning"
echo "up old database data, but be careful if you have volumes you might"
echo "want to re-attach to a new container later."
echo ""

read -p "Do you want to delete all unused Docker volumes? (y/N) " -n 1 -r
echo "" # Move to a new line.

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deleting unused volumes (docker volume prune)..."
    docker volume prune -f
    echo "✅ Volume cleanup complete."
else
    echo "Skipping volume cleanup."
fi
echo ""

# --- Final Disk Usage ---
echo "--------------------------------"
echo "📊 Here's your updated Docker disk usage:"
docker system df

echo ""
echo "✨ Docker cleanup complete!"

exit 0
