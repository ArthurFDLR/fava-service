#!/bin/bash

# Load LEDGER_GIT from Docker secret if it's not already defined
if [ -z "$LEDGER_GIT" ] && [ -f "/run/secrets/ledger_git" ]; then
    LEDGER_GIT=$(cat /run/secrets/ledger_git)
fi

# Load configuration from Docker configs
source /app/app.conf
echo "$USER_CONF_FILE"
source "$USER_CONF_FILE"

# Check if LEDGER_GIT is defined
if [ -z "$LEDGER_GIT" ]; then
    echo "WARNING: The ledger URL is not set as environment variable (LEDGER_GIT) or Docker secret (/run/secrets/ledger_git). Exiting."
    exit 1
fi

if [ -z "$REPOSITORY_DIR" ]; then
    echo "WARNING: REPOSITORY_DIR environment variable is not set. Exiting."
    exit 1
fi

# Check if directory exists and pull or clone accordingly
if [ -d "$REPOSITORY_DIR" ]; then
    cd $REPOSITORY_DIR
    # Pull from the branch if BRANCH_NAME is defined, else default to the checked out branch
    echo "Pulling from branch ${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
    git pull origin ${BRANCH_NAME:-}
else
    # If BRANCH_NAME is defined, use it with the -b flag, else just clone
    echo "Cloning ledger repository..."
    if [ -z "$BRANCH_NAME" ]; then
        git clone $LEDGER_GIT $REPOSITORY_DIR
    else
        git clone -b $BRANCH_NAME $LEDGER_GIT $REPOSITORY_DIR
    fi
fi
