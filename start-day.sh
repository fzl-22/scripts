#!/bin/bash

# A "Start My Day" script to automate the initial developer setup routine.
# It updates tools, starts services, and provides a summary of ongoing work.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "☀️ Good morning! Let's get your day started."
echo "-------------------------------------------"
echo ""

# --- Helper function to check if a command exists ---
command_exists() {
    command -v "$1" &> /dev
/null
}

# --- 1. Update Homebrew ---
if command_exists brew; then
    echo "🍺 Updating Homebrew..."
    # 'brew update' fetches latest formula info, but doesn't upgrade packages.
    # This is a safe, quick command to run daily.
    brew update
    echo "✅ Homebrew is up to date."
else
    echo "-> Homebrew not found, skipping update."
fi
echo ""

# --- 2. Start Essential Services (e.g., Docker) ---
# This checks if the Docker application process is running.
if ! pgrep -f "Docker.app" > /dev/null; then
    echo "🐳 Docker Desktop is not running. Starting it now..."
    # This command opens the Docker application.
    open -a Docker.app
    echo "-> Docker is starting up in the background."
else
    echo "✅ Docker Desktop is already running."
fi
echo ""

# --- 3. Check Git Repository Status ---
echo "📂 Checking the status of your Git repositories..."

# Add or remove your main project directories here.
PROJECT_DIRS=(
    "$HOME/Projects"
    "$HOME/Open Sources"
)

# Find all git repositories inside your project directories.
# The `find` command looks for any directory named ".git".
find "${PROJECT_DIRS[@]}" -type d -name ".git" | while read -r gitdir; do
    # Get the parent directory of ".git", which is the project root.
    project_path=$(dirname "$gitdir")

    # Navigate into the project directory to run git commands.
    (
        cd "$project_path"

        # Use 'git status --porcelain' to check for uncommitted changes.
        # It returns a non-empty string only if there are changes.
        if [ -n "$(git status --porcelain)" ]; then
            echo "  - dirty-  > $project_path (You have uncommitted changes)"
        else
            # If the directory is clean, check if it's ahead of the remote.
            # 'git status -sb' shows info like '## main...origin/main [ahead 1]'
            status=$(git status -sb)
            if [[ $status == *"ahead"* ]]; then
                 echo "  -ahead-  > $project_path (You have commits to push)"
            fi
        fi
    )
done
echo "✅ Git status check complete."
echo ""

# --- 4. Open Your Applications (Customize This Section!) ---
echo "🚀 Opening your standard applications..."

# Add or remove applications to this list to match your workflow.
open -a "iTerm"
open -a "Zed"
open -a "Arc"

echo ""
echo "-------------------------------------------"
echo "✨ All set! Have a great and productive day. ✨"
echo ""

exit 0
