#!/usr/bin/env bash
set -euo pipefail
[[ ${1:-} == --apply && $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only. Use --apply.' >&2; exit 2; }
[[ $(ip netns identify) == cedarfield ]] || { echo 'Run through ip netns exec cedarfield' >&2; exit 2; }
backup=/var/backups/cedarfield-prehardening
[[ -d $backup ]] || { echo 'Pre-hardening backup missing' >&2; exit 2; }
systemctl stop cedarfield.service cedarfield-health.timer
cp -a "$backup/cedarfield/app.conf" /etc/cedarfield/app.conf
cp -a "$backup/cedarfield.service" /etc/systemd/system/cedarfield.service
# Do not weaken SSH, configuration secrecy or firewall policy during routine rollback.
# Restore application service only. Guest console access remains available.
chmod 0600 /etc/cedarfield/app.conf
systemctl daemon-reload
systemctl restart cedarfield.service
for _ in {1..20}; do if curl --fail --silent http://127.0.0.1:8090/health; then echo; exit 0; fi; sleep 1; done
exit 1
