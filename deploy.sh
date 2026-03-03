#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.deploy"

# Arguments
PLUGIN_NAME=$1
ENV=${2:-staging}

# Load environment variables relative to this script so the command works from any cwd
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo ".env.deploy file not found at $ENV_FILE!"
    exit 1
fi

# Set base path based on environment
if [ "$ENV" == "production" ]; then
    REMOTE_BASE=$REMOTE_BASE_PRODUCTION
    ENV_NAME="PRODUCTION"
else
    REMOTE_BASE=$REMOTE_BASE_STAGING
    ENV_NAME="STAGING"
fi

case "$LOCAL_PLUGINS_DIR" in
    /*) LOCAL_PLUGINS_PATH="$LOCAL_PLUGINS_DIR" ;;
    *) LOCAL_PLUGINS_PATH="$SCRIPT_DIR/$LOCAL_PLUGINS_DIR" ;;
esac

LOCAL_PATH="$LOCAL_PLUGINS_PATH/$PLUGIN_NAME"
REMOTE_PATH="$REMOTE_BASE/$PLUGIN_NAME"

# Check if local plugin exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Local plugin directory not found: $LOCAL_PATH"
    exit 1
fi

echo "🚀 Syncing $PLUGIN_NAME to $ENV_NAME..."

# Ensure remote directory exists
ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "mkdir -p $REMOTE_PATH"

# Run rsync
# Exclude system files and common backup suffixes
rsync -avz --delete \
    --exclude '.git' \
    --exclude '.gitignore' \
    --exclude '.DS_Store' \
    --exclude '*- Copy*' \
    --exclude 'node_modules' \
    -e "ssh -p $DEPLOY_PORT" \
    "$LOCAL_PATH/" "$DEPLOY_USER@$DEPLOY_HOST:$REMOTE_PATH/"

if [ $? -eq 0 ]; then
    # Fix permissions remotely
    ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "chmod 755 $REMOTE_PATH && find $REMOTE_PATH -type d -exec chmod 755 {} \; && find $REMOTE_PATH -type f -exec chmod 644 {} \;"
    echo "✅ Successfully deployed $PLUGIN_NAME to $ENV_NAME"
else
    echo "❌ Failed to deploy $PLUGIN_NAME"
    exit 1
fi
