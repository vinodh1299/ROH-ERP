#!/usr/bin/env bash
# Copies the server's nightly database backups to this computer, so a copy exists
# off the server. Keeps the last 90 days locally.
# Usage: BACK-END/ops/pull_backups.sh [destination folder]   (default ~/ROH-Backups)
set -euo pipefail
umask 077

HOST="dh_tdq9bh@vps18579.dreamhostps.com"
REMOTE_DIR="backups/roh-erp"
DEST="${1:-$HOME/ROH-Backups}"
KEEP_DAYS=90
mkdir -p "$DEST"

# rsync only fetches files that aren't here yet; retries cover the flaky SSH link.
for attempt in 1 2 3 4; do
  if rsync -az --ignore-existing -e "ssh -o ConnectTimeout=20 -o ServerAliveInterval=10" \
      --include='roherp-*.sql.gz' --exclude='*' "$HOST:$REMOTE_DIR/" "$DEST/"; then
    break
  fi
  echo "retry $attempt"; sleep 5
done

find "$DEST" -name 'roherp-*.sql.gz' -mtime +"$KEEP_DAYS" -delete
LATEST="$(ls -t "$DEST"/roherp-*.sql.gz 2>/dev/null | head -1)"
echo "$(date '+%F %T') copies: $(ls "$DEST"/roherp-*.sql.gz 2>/dev/null | wc -l | tr -d ' '), latest: $(basename "${LATEST:-none}")"
