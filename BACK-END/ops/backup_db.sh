#!/usr/bin/env bash
# Nightly MySQL backup for the ROH ERP database.
# Reads credentials from ~/.my.cnf ([mysqldump] section, chmod 600), writes a
# compressed dump to ~/backups/roh-erp/ and keeps the last 14 days.
# Install: crontab entry  30 2 * * * $HOME/roh-erp-api/ops/backup_db.sh >> $HOME/backups/roh-erp/backup.log 2>&1
set -euo pipefail
umask 077

DB_NAME="${DB_NAME:-roherp}"
DEST="$HOME/backups/roh-erp"
KEEP_DAYS=14
mkdir -p "$DEST"

STAMP="$(date +%Y%m%d-%H%M)"
OUT="$DEST/${DB_NAME}-${STAMP}.sql.gz"

mysqldump --defaults-extra-file="$HOME/.my.cnf" --ssl-mode=REQUIRED \
  --single-transaction --routines --triggers --no-tablespaces "$DB_NAME" | gzip -9 > "$OUT.part"
mv "$OUT.part" "$OUT"

find "$DEST" -name "${DB_NAME}-*.sql.gz" -mtime +"$KEEP_DAYS" -delete
echo "$(date '+%F %T') backup ok: $(basename "$OUT") ($(du -h "$OUT" | cut -f1))"
