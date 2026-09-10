#!/bin/sh
# Automated nightly MariaDB backup with rotation.
# Runs inside a lightweight container that has the mariadb client tools
# (see the `backup` service in docker-compose.yml) — it never touches the
# database's own data directory, only talks to it over the network.
set -eu

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
mkdir -p /backups

echo "[backup] service started — dumping every 24h, keeping ${RETENTION_DAYS} days"

while true; do
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  FILE="/backups/sarathy_${TIMESTAMP}.sql.gz"

  echo "[backup] $(date -Iseconds) starting dump -> ${FILE}"
  if mysqldump -h mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" --single-transaction --all-databases | gzip > "${FILE}"; then
    echo "[backup] $(date -Iseconds) dump complete ($(du -h "${FILE}" | cut -f1))"
  else
    echo "[backup] $(date -Iseconds) DUMP FAILED — check MariaDB connectivity/credentials" >&2
    rm -f "${FILE}"
  fi

  find /backups -name "sarathy_*.sql.gz" -mtime "+${RETENTION_DAYS}" -delete
  echo "[backup] sleeping 24h"
  sleep 86400
done
