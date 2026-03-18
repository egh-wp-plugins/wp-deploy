#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.deploy"

# Arguments
PLUGIN_NAME=$1
ENV=${2:-staging}
SPECIFIC_FILES=${3:-}

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
PRESERVE_FILE="$LOCAL_PATH/.deploy-preserve"

# Check if local plugin exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Local plugin directory not found: $LOCAL_PATH"
    exit 1
fi

echo "🚀 Syncing $PLUGIN_NAME to $ENV_NAME..."

# Ensure remote directory exists
ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "mkdir -p $REMOTE_PATH"

declare -a PRESERVED_PATHS=()

if [ -f "$PRESERVE_FILE" ]; then
    while IFS= read -r raw_path || [ -n "$raw_path" ]; do
        path="${raw_path%%#*}"
        path="${path#"${path%%[![:space:]]*}"}"
        path="${path%"${path##*[![:space:]]}"}"

        if [ -n "$path" ]; then
            PRESERVED_PATHS+=("$path")
        fi
    done < "$PRESERVE_FILE"
fi

if [ "${#PRESERVED_PATHS[@]}" -gt 0 ]; then
    echo "🛡️ Preserving remote paths during full deploy:"
    for path in "${PRESERVED_PATHS[@]}"; do
        echo "   - $path"
    done
fi

if [ -n "$SPECIFIC_FILES" ]; then
    IFS=',' read -r -a FILES <<< "$SPECIFIC_FILES"
    DEPLOY_FAILED=0

    for file in "${FILES[@]}"; do
        SOURCE_RELATIVE="${file//\\//}"
        SOURCE_PATH="$LOCAL_PATH/$SOURCE_RELATIVE"

        if [ ! -e "$SOURCE_PATH" ]; then
            echo "⚠️ Skipping missing path: $SOURCE_RELATIVE"
            continue
        fi

        REMOTE_TARGET="$REMOTE_PATH/$SOURCE_RELATIVE"
        REMOTE_DIR=$(dirname "$REMOTE_TARGET")

        ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "mkdir -p \"$REMOTE_DIR\""

        if [ -d "$SOURCE_PATH" ]; then
            echo "📤 Uploading directory: $SOURCE_RELATIVE"
            rsync -avz \
                -e "ssh -p $DEPLOY_PORT" \
                "$SOURCE_PATH/" "$DEPLOY_USER@$DEPLOY_HOST:$REMOTE_TARGET/"
        else
            echo "📤 Uploading file: $SOURCE_RELATIVE"
            rsync -avz \
                -e "ssh -p $DEPLOY_PORT" \
                "$SOURCE_PATH" "$DEPLOY_USER@$DEPLOY_HOST:$REMOTE_TARGET"
        fi

        if [ $? -ne 0 ]; then
            DEPLOY_FAILED=1
        fi
    done
else
    RSYNC_ARGS=(
        -avz
        --delete
        --exclude=.git
        --exclude=.gitignore
        --exclude=.DS_Store
        "--exclude=*- Copy*"
        --exclude=node_modules
    )

    for path in "${PRESERVED_PATHS[@]}"; do
        NORMALIZED_PATH="${path#./}"
        if [[ "$NORMALIZED_PATH" == */ ]]; then
            RSYNC_ARGS+=("--filter=P /${NORMALIZED_PATH}***")
            RSYNC_ARGS+=("--exclude=/${NORMALIZED_PATH}***")
        else
            RSYNC_ARGS+=("--filter=P /${NORMALIZED_PATH}")
            RSYNC_ARGS+=("--exclude=/${NORMALIZED_PATH}")
        fi
    done

    rsync "${RSYNC_ARGS[@]}" \
        -e "ssh -p $DEPLOY_PORT" \
        "$LOCAL_PATH/" "$DEPLOY_USER@$DEPLOY_HOST:$REMOTE_PATH/"

    DEPLOY_FAILED=$?
fi

if [ ${DEPLOY_FAILED:-0} -eq 0 ]; then
    # Fix permissions remotely
    ssh -p $DEPLOY_PORT "$DEPLOY_USER@$DEPLOY_HOST" "chmod 755 $REMOTE_PATH && find $REMOTE_PATH -type d -exec chmod 755 {} \; && find $REMOTE_PATH -type f -exec chmod 644 {} \;"
    echo "✅ Successfully deployed $PLUGIN_NAME to $ENV_NAME"
else
    echo "❌ Failed to deploy $PLUGIN_NAME"
    exit 1
fi
