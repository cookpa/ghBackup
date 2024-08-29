#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <github-username-or-organization> <backup-base-directory>"
    exit 1
fi

GITHUB_ENTITY="$1"
BACKUP_BASE_DIR="$2"

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it from https://cli.github.com/ and try again."
    exit 1
fi

GITHUB_ENTITY="$1"

# Fetch all repository names for the given user or organization
REPOS=$(gh repo list $GITHUB_ENTITY --limit 1000 --json name --jq '.[].name')

# Create a backup directory
BACKUP_DIR="${BACKUP_BASE_DIR}/$GITHUB_ENTITY-github-backup"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Function to clone or update a repository
clone_or_update_repo() {
    local REPO="$1"
    if [ -d "$REPO" ]; then
        # If the repo directory exists, pull the latest changes
        echo "Updating repository: $REPO"
        cd "$REPO"
        git fetch --all
        git pull --all
        cd ..
    else
        # If the repo directory does not exist, clone it
        echo "Cloning repository: $REPO"
        gh repo clone "$GITHUB_ENTITY/$REPO"
        cd "$REPO"
        git fetch --all
        cd ..
    fi
}

# Process each repository
for REPO in $REPOS; do
    clone_or_update_repo "$REPO"

    # Check if the wiki exists by attempting to fetch it
    WIKI_URL="https://github.com/$GITHUB_ENTITY/$REPO.wiki.git"
    WIKI_DIR="$REPO.wiki"

    if git ls-remote "$WIKI_URL" &> /dev/null; then
        # If the wiki exists, clone or update it
        echo "Wiki exists for $REPO. Processing wiki..."
        clone_or_update_repo "$WIKI_DIR"
    else
        echo "No wiki found for $REPO."
    fi
done

echo "Incremental backup completed in $BACKUP_DIR"
