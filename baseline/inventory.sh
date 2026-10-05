#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only' >&2; exit 2; }
[[ $(ip netns identify) == cedarfield ]] || { echo 'Run through ip netns exec cedarfield' >&2; exit 2; }
echo 'UTC capture:'
date -u +%FT%TZ
echo 'OS and virtualization:'
. /etc/os-release
printf '%s\n' "$PRETTY_NAME"
systemd-detect-virt
echo 'Lab listeners (unrelated namespace listeners excluded):'
ss -lntp | awk 'NR==1 || /:(8090|9099|22222) /'
echo 'Application health and records:'
curl --fail --silent http://127.0.0.1:8090/health; echo
curl --fail --silent http://127.0.0.1:8090/api/jobs; echo
echo 'Effective lab SSH controls:'
sshd -T -f /etc/cedarfield/sshd_config | awk '/^(port|listenaddress|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|permitopen) /'
echo 'Identity, sandbox and file permissions:'
systemctl show cedarfield -p User -p Group -p NoNewPrivileges -p PrivateTmp -p ProtectSystem -p ProtectHome -p ReadWritePaths -p UMask -p MainPID
stat -c '%a %U:%G %n' /etc/cedarfield/app.conf /opt/cedarfield/server.py /var/lib/cedarfield /var/lib/cedarfield/jobs.sqlite
echo 'Firewall:'
ufw status verbose
echo 'Update timers:'
systemctl is-active apt-daily.timer apt-daily-upgrade.timer || true
echo 'Safe app journal excerpt:'
journalctl -u cedarfield --no-pager -n 8 -o cat
