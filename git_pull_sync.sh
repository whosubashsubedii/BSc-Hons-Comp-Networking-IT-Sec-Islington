#!/bin/bash

# Cross-platform Git Pull/Clone Script
# Features: Dry-run mode, logging, timestamped operations
# Usage: ./git_pull_syn.sh [-d|--dry-run] [log_file]

# Configuration - ADDED NEW REPOSITORY
MAIN_REPO="git@github.com:whosubashsubedii/Islington-College.git"
SUBREPOS=(
    "Year 1/2nd SemiStar/Cyber Security Fundamentals/CSF Coursework/Cybersecurity-Fundamentals-Coursework|git@github.com:whosubashsubedii/Cybersecurity-Fundamentals-Coursework.git"
    "Year 1/2nd SemiStar/Fundamentals of Computing/Fundamentals-of-Computing-Coursework|git@github.com:whosubashsubedii/Fundamentals-of-Computing-Coursework.git"
    "Year 1/2nd SemiStar/Programming/Coursework/Java-Programming-Coursework|git@github.com:whosubashsubedii/Java-Programming-Coursework.git"
    "Year 1/2nd SemiStar/Programming/Coursework/10-Independent-Java-Learning-Coursework|git@github.com:whosubashsubedii/10-Independent-Java-Learning-Coursework.git"
    "Year 1/1st SemiStar/Introduction to Information Systems/Course Work/Final Group Coursework Information System/Code file/daud-shoes-collection-v1|git@github.com:whosubashsubedii/daud-shoes-collection-v1.git"  # NEW
)

# Initialize variables
DRY_RUN=false
LOG_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
        DRY_RUN=true
        shift
        ;;
        *)
        LOG_FILE="$1"
        shift
        ;;
    esac
done

# Setup logging
exec 3>&1  # Save original stdout
if [ -n "$LOG_FILE" ]; then
    exec > >(tee -i "$LOG_FILE") 2>&1
    echo "Logging to: $LOG_FILE"
fi

handle_error() {
    echo "Error: $1" >&2
    exit 1
}

print_command() {
    echo "   [DRY RUN] $*"
}

run_command() {
    if $DRY_RUN; then
        print_command "$@"
    else
        echo "   $*"
        "$@"
    fi
}

safe_cd() {
    if $DRY_RUN; then
        print_command "cd" "$1"
    else
        cd "$1" || handle_error "Cannot access directory: $1"
    fi
}

process_repo() {
    local path="$1"
    local url="$2"
    
    echo "Processing: $(basename "$path")"
    
    # Handle directory creation
    if [ ! -d "$path" ]; then
        echo "Creating directory structure"
        run_command mkdir -p "$(dirname "$path")"
    fi

    if [ ! -d "$path/.git" ]; then
        echo "Cloning repository"
        run_command git clone "$url" "$path"
    else
        echo "Pulling updates"
        safe_cd "$path"
        run_command git pull --ff-only
        safe_cd - > /dev/null
    fi
}

# Main execution
echo "Starting repository sync at $(date +'%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------"

# Main repo operations
if [ ! -d ".git" ]; then
    echo "Main Repository: Cloning"
    run_command git clone --recurse-submodules "$MAIN_REPO" .
else
    echo "Main Repository: Updating"
    run_command git pull --ff-only
    
    # Initialize submodules
    if [ -f ".gitmodules" ]; then
        echo "Initializing submodules"
        run_command git submodule update --init --recursive
    fi
fi

# Process sub-repositories
for entry in "${SUBREPOS[@]}"; do
    IFS="|" read -r subpath suburl <<< "$entry"
    echo "----------------------------------------"
    process_repo "$subpath" "$suburl"
done

echo "----------------------------------------"
echo "All repositories synchronized at $(date +'%H:%M:%S')"