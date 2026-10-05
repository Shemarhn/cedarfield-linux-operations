#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only' >&2; exit 2; }
dest=/var/backups/cedarfield
install -d -m 0700 "$dest"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
umask 077
python3 - "$dest/$stamp.sqlite" <<'PY'
import sqlite3, sys
with sqlite3.connect('/var/lib/cedarfield/jobs.sqlite') as src, sqlite3.connect(sys.argv[1]) as dst:
    src.backup(dst)
    if dst.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
        raise SystemExit('Backup integrity failed')
    print('backup jobs=' + str(dst.execute('SELECT COUNT(*) FROM jobs').fetchone()[0]))
    print('backup integrity=ok')
PY
cp -a /etc/cedarfield/app.conf "$dest/$stamp.conf"
echo 'Local backup and private configuration copy complete; separate storage still required.'
