#!/bin/bash

# A script to find and clean project dependencies and build artifacts.
# It finds specified directories, filters out excluded paths, displays their
# individual sizes, and moves them to a timestamped folder in the user's trash,
# preserving the original directory structure relative to the home directory.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🧹 Project Cleanup Script"
echo "--------------------------"

# --- Configuration ---
# Add or remove project root directories here.
SEARCH_DIRS=(
    "$HOME/Playground"
    "$HOME/Projects"
    "$HOME/Documents"
    "$HOME/Open Sources"
)

# Add or remove names of dependency/build artifact directories to target.
TARGETS=(
    "node_modules"
    "build"
    "vendor"
    "Pod"
    ".dart_tool"
    "venv"
    ".venv"
    "dist"
    ".fvm"
)

# Add patterns to prevent deletion of items in certain paths.
# These patterns are used with `grep` (regex is supported) to filter the results.
EXCLUSION_PATTERNS=(
    "/vendor/"
    "/web_src/"
    "/node_modules/"
)
# --- End Configuration ---

# Check if any search directories are defined.
if [ ${#SEARCH_DIRS[@]} -eq 0 ]; then
    echo "Error: No search directories configured. Please edit the SEARCH_DIRS array in the script."
    exit 1
fi

# Create temporary files.
RAW_TEMP_FILE=$(mktemp)
FILTERED_TEMP_FILE=$(mktemp)
SIZES_TEMP_FILE=$(mktemp)

# Ensure the temporary files are removed when the script exits.
trap 'rm -f "$RAW_TEMP_FILE" "$FILTERED_TEMP_FILE" "$SIZES_TEMP_FILE"' EXIT

echo "🔍 Searching for items to clean..."
echo "This might take a moment..."

# Build the `find` command's search conditions dynamically.
find_args=()
for target in "${TARGETS[@]}"; do
    [ ${#find_args[@]} -gt 0 ] && find_args+=("-o")
    find_args+=("-name" "$target" "-type" "d")
done

# Execute the find command and store the raw results.
find "${SEARCH_DIRS[@]}" \( "${find_args[@]}" \) -print -prune > "$RAW_TEMP_FILE"

# Filter the raw results to exclude specified patterns.
if [ ${#EXCLUSION_PATTERNS[@]} -gt 0 ]; then
    printf -v grep_pattern '|%s' "${EXCLUSION_PATTERNS[@]}"
    grep_pattern=${grep_pattern:1} # Remove the leading '|'
    grep -vE "$grep_pattern" "$RAW_TEMP_FILE" > "$FILTERED_TEMP_FILE"
else
    cp "$RAW_TEMP_FILE" "$FILTERED_TEMP_FILE"
fi

# Check if the filtered list is empty.
if [ ! -s "$FILTERED_TEMP_FILE" ]; then
    echo "✅ Nothing to clean up. Your directories are tidy!"
    exit 0
fi

echo ""
echo "Calculating sizes (this may also take a moment)..."
total_size_kb=0
while IFS= read -r item; do
    if [ -e "$item" ]; then
        item_size_kb=$(du -sk "$item" | awk '{print $1}')
        total_size_kb=$((total_size_kb + item_size_kb))
        # Store size and path for sorting.
        echo "$item_size_kb $item" >> "$SIZES_TEMP_FILE"
    fi
done < "$FILTERED_TEMP_FILE"

# Function to convert KB to a human-readable format.
format_size() {
    local kb=$1
    if [ "$kb" -ge 1048576 ]; then
        printf "%.2f GB" "$(echo "$kb / 1048576" | bc -l)"
    elif [ "$kb" -ge 1024 ]; then
        printf "%.2f MB" "$(echo "$kb / 1024" | bc -l)"
    else
        printf "%s KB" "$kb"
    fi
}

echo ""
echo "🗑️ The following items will be moved to the trash (sorted by size):"
echo "----------------------------------------------------------------"

# Sort the file by size (first column, numeric, reverse) and display.
sort -rn "$SIZES_TEMP_FILE" | while read -r size_kb path; do
    human_size=$(format_size "$size_kb")
    printf "[ %-9s ] %s\n" "$human_size" "$path"
done

human_readable_total=$(format_size $total_size_kb)

echo "----------------------------------------------------------------"
echo "Total size to be freed: $human_readable_total"
echo ""

read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled by user."
    exit 1
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TRASH_DIR="$HOME/.Trash/housekeeping_$TIMESTAMP"

echo "Creating trash directory: $TRASH_DIR"
mkdir -p "$TRASH_DIR"

echo "Moving items to trash..."

# Read from the SIZES_TEMP_FILE to move the items.
while read -r size_kb item; do
    if [ -e "$item" ]; then
        # Calculate the path relative to the home directory.
        # This removes the leading "$HOME/" from the path string.
        relative_path="${item#$HOME/}"

        # Determine the parent directory of the destination inside the trash.
        destination_parent_dir="$TRASH_DIR/$(dirname "$relative_path")"

        # Create the full directory structure inside the trash folder.
        mkdir -p "$destination_parent_dir"

        # Move the item into its preserved path inside the trash.
        mv "$item" "$destination_parent_dir/"
        echo "  Moved: $item"
    else
        echo "  Skipped (already deleted): $item"
    fi
done < "$SIZES_TEMP_FILE"

echo ""
echo "✨ Housekeeping complete!"
echo "All items have been moved to $TRASH_DIR, preserving original paths."

exit 0
