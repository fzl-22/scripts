#!/bin/bash

# A script to clean up large cache and build artifact directories
# common in mobile development (Xcode, Gradle, CocoaPods).

# Exit immediately if a command exits with a non-zero status.
set -e

echo "📱 Mobile Developer Cleanup Script"
echo "---------------------------------"

# --- Configuration ---
# List of directories to clean.
# These are all safe to delete; the development tools will recreate them as needed.
TARGET_DIRS=(
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/Xcode/Archives"
    "$HOME/.gradle/caches"
    "$HOME/.cocoapods/repos"
)
# --- End Configuration ---

# Create a temporary file to store directory sizes.
SIZES_TEMP_FILE=$(mktemp)
trap 'rm -f "$SIZES_TEMP_FILE"' EXIT

echo "🔍 Searching for cache directories and calculating their sizes..."
echo "This can take a moment..."

total_size_kb=0
found_count=0

for dir in "${TARGET_DIRS[@]}"; do
    # Check if the directory exists and is not empty.
    if [ -d "$dir" ]; then
        # Get size in kilobytes (-sk).
        dir_size_kb=$(du -sk "$dir" | awk '{print $1}')
        if [ "$dir_size_kb" -gt 0 ]; then
            total_size_kb=$((total_size_kb + dir_size_kb))
            # Store size and path for sorting.
            echo "$dir_size_kb $dir" >> "$SIZES_TEMP_FILE"
            found_count=$((found_count + 1))
        fi
    fi
done

# Check if any directories were found.
if [ "$found_count" -eq 0 ]; then
    echo "✅ Nothing to clean up. Your mobile development caches are tidy!"
    exit 0
fi

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
echo "🗑️ The following caches will be DELETED (sorted by size):"
echo "----------------------------------------------------------------"

# Sort the file by size (numeric, reverse) and display.
sort -rn "$SIZES_TEMP_FILE" | while read -r size_kb path; do
    human_size=$(format_size "$size_kb")
    printf "[ %-9s ] %s\n" "$human_size" "$path"
done

human_readable_total=$(format_size $total_size_kb)

echo "----------------------------------------------------------------"
echo "Total size to be freed: $human_readable_total"
echo ""

read -p "Are you sure you want to permanently delete these directories? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled by user."
    exit 1
fi

echo ""
echo "🚀 Cleaning up..."

# Read from the SIZES_TEMP_FILE to delete the directories.
while read -r size_kb dir_to_delete; do
    if [ -d "$dir_to_delete" ]; then
        echo "  Deleting $dir_to_delete..."
        rm -rf "$dir_to_delete"
        echo "  ✅ Deleted."
    fi
done < "$SIZES_TEMP_FILE"

echo ""
echo "✨ Mobile development cleanup complete!"
echo "The deleted directories will be automatically recreated by the relevant tools when needed."

exit 0
