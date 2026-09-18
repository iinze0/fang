#!/bin/bash
# Update FANG from GitHub (git pull only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -d .git ]]; then
    echo "Not a git clone. Get a fresh copy:"
    echo "  git clone https://github.com/iinze0/fang.git"
    exit 1
fi

echo "Fetching origin..."
git fetch origin

BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE="origin/${BRANCH}"

if ! git rev-parse --verify "$REMOTE" >/dev/null 2>&1; then
    REMOTE="origin/main"
fi

LOCAL=$(git rev-parse HEAD)
REMOTE_SHA=$(git rev-parse "$REMOTE")

if [[ "$LOCAL" == "$REMOTE_SHA" ]]; then
    echo "Already up to date ($BRANCH @ ${LOCAL:0:7})."
    exit 0
fi

echo "Updating $BRANCH ${LOCAL:0:7} -> ${REMOTE_SHA:0:7}"
git pull --ff-only origin "$BRANCH" || git pull --ff-only origin main
chmod +x fang.sh update.sh lib/*.sh 2>/dev/null || true
echo "Done. Run: sudo ./fang.sh"
