#!/bin/bash

# Cross-platform Git Commit/Push Script
# Features: Timestamped commits, dry-run mode, logging
# Usage: ./git_push_syn.sh [-d|--dry-run] [log_file]

# Configuration - ADDED NEW REPOSITORY
MAIN_REPO_DIR="."
SUBREPOS=(
    "Year 1/2nd SemiStar/Cyber Security Fundamentals/CSF Coursework/Cybersecurity-Fundamentals-Coursework"
    "Year 1/2nd SemiStar/Fundamentals of Computing/Fundamentals-of-Computing-Coursework"
    "Year 1/2nd SemiStar/Programming/Coursework/Java-Programming-Coursework"
    "Year 1/2nd SemiStar/Programming/Coursework/10-Independent-Java-Learning-Coursework"
    "Year 1/1st SemiStar/Introduction to Information Systems/Course Work/Final Group Coursework Information System/Code file/daud-shoes-collection-v1"
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

commit_and_push() {
    local repo_dir="$1"
    local repo_name=$(basename "$repo_dir")
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    echo "Processing: $repo_name"
    safe_cd "$repo_dir"
    
    # Check for changes
    if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
        echo "No changes"
        safe_cd - > /dev/null
        return
    fi
    
    # Perform operations
    echo "   • Staging changes"
    run_command git add .
    
    echo "   • Committing changes ($timestamp)"
    run_command git commit -m "Completed at $timestamp"
    
    echo "   • Pushing updates"
    if run_command git push; then
        echo "Push successful"
    else
        echo "Push failed - attempting pull/retry"
        run_command git pull --rebase
        run_command git push
    fi
    
    safe_cd - > /dev/null
}

# Main execution
echo "Starting commit/push at $(date +'%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------"

# Process sub-repositories first
for subpath in "${SUBREPOS[@]}"; do
    commit_and_push "$subpath"
    echo "----------------------------------------"
done

# Process main repository
echo "Main Repository"
commit_and_push "$MAIN_REPO_DIR"

echo "----------------------------------------"
echo "All changes committed/pushed at $(date +'%H:%M:%S')"