#!/bin/bash
# Persist Claude Code credentials in the `claude-auth` named volume while
# keeping the baked-in settings/hooks in /root/.claude.
set -e

mkdir -p /root/.claude /claude-auth

# If credentials already exist in the image layer (e.g. baked), move them
# into the persistent volume once so they survive container rebuilds.
# Skip when the file is a bind mount (host file reused), which must stay in place.
if [ -f /root/.claude/.credentials.json ] && [ ! -L /root/.claude/.credentials.json ] && ! findmnt /root/.claude/.credentials.json >/dev/null 2>&1; then
    if [ ! -f /claude-auth/.credentials.json ]; then
        cp /root/.claude/.credentials.json /claude-auth/.credentials.json
    fi
    rm -f /root/.claude/.credentials.json
fi

# Link the persistent credentials into Claude's config dir (if present),
# unless a host file is bind-mounted there.
if [ -f /claude-auth/.credentials.json ] && ! findmnt /root/.claude/.credentials.json >/dev/null 2>&1; then
    ln -sfn /claude-auth/.credentials.json /root/.claude/.credentials.json
fi

exec "$@"
