#!/bin/bash

# A script to clean the caches of various package managers and development tools.
# It checks for the existence of each tool before attempting to clean its cache.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🧹 Package Manager Cache Cleanup Script"
echo "--------------------------------------"
echo "This script will attempt to clean the caches for Homebrew,"
echo "NPM, Yarn, Composer, Go, and Flutter/Pub."
echo ""

# --- Helper functions for each cleanup task ---

# Checks if a command exists on the system.
command_exists() {
    command -v "$1" &> /dev/null
}

clean_homebrew() {
    if command_exists brew; then
        echo "🍺 Cleaning Homebrew cache..."
        brew cleanup
        echo "✅ Homebrew cleanup complete."
    else
        echo "-> Homebrew not found, skipping."
    fi
    echo ""
}

clean_npm() {
    if command_exists npm; then
        echo "📦 Cleaning NPM cache..."
        npm cache clean --force
        echo "✅ NPM cache cleanup complete."
    else
        echo "-> NPM not found, skipping."
    fi
    echo ""
}

clean_yarn() {
    if command_exists yarn; then
        echo "🧶 Cleaning Yarn cache..."
        yarn cache clean
        echo "✅ Yarn cache cleanup complete."
    else
        echo "-> Yarn not found, skipping."
    fi
    echo ""
}

clean_composer() {
    if command_exists composer; then
        echo "🎼 Cleaning Composer (PHP) cache..."
        composer clear-cache
        echo "✅ Composer cache cleanup complete."
    else
        echo "-> Composer not found, skipping."
    fi
    echo ""
}

clean_go() {
    if command_exists go; then
        echo "🐹 Cleaning Go module cache..."
        go clean -modcache
        echo "✅ Go module cache cleanup complete."
    else
        echo "-> Go not found, skipping."
    fi
    echo ""
}

clean_flutter_pub() {
    if command_exists flutter; then
        echo "🐦 Repairing Flutter/Pub cache..."
        flutter pub cache repair
        echo "✅ Flutter/Pub cache repair complete."
    else
        echo "-> Flutter not found, skipping."
    fi
    echo ""
}

# --- Main script logic ---

main() {
    read -p "Are you sure you want to clean all package manager caches? (y/N) " -n 1 -r
    echo "" # Move to a new line.

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled by user."
        exit 1
    fi

    echo ""
    clean_homebrew
    clean_npm
    clean_yarn
    clean_composer
    clean_go
    clean_flutter_pub

    echo "✨ All cache cleanups complete!"
}

# Run the main function.
main

exit 0
