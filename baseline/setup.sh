#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only' >&2; exit 2; }
[[ $(ip netns identify) == cedarfield ]] || { echo 'Run through ip netns exec cedarfield' >&2; exit 2; }
[[ ! -f /etc/cedarfield/app.conf ]] || { echo 'Baseline already exists; refusing to overwrite evidence or configuration' >&2; exit 2; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
install -d -m 0755 /etc/cedarfield /opt/cedarfield /var/lib/cedarfield
install -m 0644 "$root/app/server.py" /opt/cedarfield/server.py
python3 - <<'PY'
import secrets
from pathlib import Path
Path('/etc/cedarfield/app.conf').write_text('APP_DB=/var/lib/cedarfield/jobs.sqlite\nAPP_TOKEN=' + secrets.token_urlsafe(32) + '\n')
PY
chmod 0644 /etc/cedarfield/app.conf
cat > /etc/systemd/system/cedarfield.service <<'UNIT'
[Unit]
Description=Cedarfield baseline application
Requires=cedarfield-network.service
After=network.target cedarfield-network.service
[Service]
NetworkNamespacePath=/run/netns/cedarfield
EnvironmentFile=/etc/cedarfield/app.conf
ExecStart=/usr/bin/python3 /opt/cedarfield/server.py
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT
cp "$root/hardening/ssh/sshd_config" /etc/cedarfield/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/; s/PasswordAuthentication no/PasswordAuthentication yes/; /AuthenticationMethods publickey/d' /etc/cedarfield/sshd_config
# Accounts remain locked. No usable password is introduced. All listeners are loopback-only.
install -m 0644 "$root/hardening/systemd/cedarfield-ssh.service" /etc/systemd/system/cedarfield-ssh.service
cat > /etc/systemd/system/cedarfield-extra.service <<'UNIT'
[Unit]
Description=Unnecessary isolated baseline HTTP service
[Service]
NetworkNamespacePath=/run/netns/cedarfield
ExecStart=/usr/bin/python3 -m http.server 9099 --bind 192.0.2.1 --directory /opt/cedarfield
[Install]
WantedBy=multi-user.target
UNIT
systemctl disable --now ssh.service ssh.socket fail2ban.service 2>/dev/null || true
ufw --force disable
systemctl stop apt-daily.timer apt-daily-upgrade.timer
systemctl daemon-reload
systemctl enable --now cedarfield.service cedarfield-ssh.service cedarfield-extra.service
for _ in {1..20}; do if curl --fail --silent http://127.0.0.1:8090/health; then echo; exit 0; fi; sleep 1; done
exit 1
