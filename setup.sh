#!/bin/bash

# A setup script to automatically install custom aliases for workflow and cleanup scripts.
# It intelligently detects the user's shell (Zsh or Bash), checks if the aliases
# are already installed, and appends them to the correct configuration file if not.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Main Script Logic ---

main() {
    # 1. Detect the user's shell and determine the correct config file.
    local RC_FILE=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        RC_FILE="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        RC_FILE="$HOME/.bashrc"
    else
        echo "❌ Error: Unsupported shell detected: $SHELL"
        echo "This script only supports Zsh and Bash."
        echo "Please add the aliases manually."
        exit 1
    fi

    echo "🔧 Checking your shell configuration..."
    echo "-> Detected Shell: $(basename "$SHELL")"
    echo "-> Target File:    $RC_FILE"
    echo ""

    # 2. Create the config file if it doesn't exist.
    if [ ! -f "$RC_FILE" ]; then
        echo "-> Configuration file not found. Creating it for you..."
        touch "$RC_FILE"
        echo "✅ Created $RC_FILE."
        echo ""
    fi

    # 3. Use a unique comment as a marker to check if aliases are already installed.
    local MARKER="# --- Custom Workflow & Cleanup Aliases ---"
    if grep -q "$MARKER" "$RC_FILE"; then
        echo "✅ Your custom aliases are already installed in $RC_FILE."
        echo "No changes were made."
    else
        echo "-> Custom aliases not found. Installing them now..."

        # Append the aliases using a standard here-document, which is very portable.
        # The 'EOF' is quoted to prevent any variable expansion inside the block.
        cat <<'EOF' >> "$RC_FILE"

# --- Custom Workflow & Cleanup Aliases ---
# Added by setup.sh script from your custom scripts collection.
alias startday="$HOME/Scripts/start-day.sh"
alias cleanupprojects="$HOME/Scripts/cleanup-projects.sh"
alias cleanupdocker="$HOME/Scripts/cleanup-docker.sh"
alias cleanupmobile="$HOME/Scripts/cleanup-mobile.sh"
alias cleanupcaches="$HOME/Scripts/cleanup-caches.sh"
# --- End of Custom Aliases ---
EOF
        echo "✅ Successfully added the aliases to $RC_FILE."
    fi

    echo ""
    echo "--------------------------------------------------------"
    echo "✨ Setup complete!"
    echo ""
    echo "To activate your new aliases, please do one of the following:"
    echo "  1. Restart your terminal session."
    echo "  2. Run the command: source $RC_FILE"
    echo "--------------------------------------------------------"
}

# Run the main function of the script.
main

exit 0
