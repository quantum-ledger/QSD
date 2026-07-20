#!/bin/bash
# Run as root from cron, e.g. daily: 0 3 * * * /opt/QSD/vps-sqlite-backup.sh
set -euo pipefail
SRC="/opt/QSD/QSD.db"
DEST_DIR="/opt/QSD/backups"
test -f "$SRC" || exit 0
mkdir -p "$DEST_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
cp -a "$SRC" "$DEST_DIR/QSD-$TS.db"
chown QSD:QSD "$DEST_DIR/QSD-$TS.db" 2>/dev/null || true
# Newest first; drop first 14; remove the rest (keep 14 backups)
find "$DEST_DIR" -name 'QSD-*.db' -type f -printf '%T@ %p\n' | sort -nr | tail -n +15 | cut -d' ' -f2- | xargs -r rm -f
exit 0
