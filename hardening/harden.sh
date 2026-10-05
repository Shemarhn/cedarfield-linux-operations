#!/usr/bin/env bash
set -euo pipefail
mode=${1:---check}
[[ $mode == --check || $mode == --apply ]] || { echo 'Use --check or --apply' >&2; exit 2; }
[[ $EUID == 0 ]] || { echo 'Run as root on the dedicated lab guest' >&2; exit 2; }
[[ -f /etc/cedarfield-lab ]] || { echo 'Refusing: dedicated lab marker missing' >&2; exit 2; }
[[ $(ip netns identify) == cedarfield ]] || { echo 'Run through ip netns exec cedarfield' >&2; exit 2; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for tool in systemctl sshd ufw fail2ban-client python3; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 2; }; done
[[ -f /var/lib/cedarfield-admin-proof ]] || { echo 'Verify a real SSH key login and record proof first' >&2; exit 2; }
sshd -t -f "$root/hardening/ssh/sshd_config"
if [[ $mode == --check ]]; then
  echo 'CHECK OK: lab marker, key-access proof, packages and proposed SSH syntax'
  echo 'Would back up configs, reduce app privilege, restrict permissions, apply firewall/SSH/log/update policies and verify health.'
  exit 0
fi
backup=/var/backups/cedarfield-prehardening
if [[ ! -d $backup ]]; then
  install -d -m 0700 "$backup"
  cp -a /etc/cedarfield /etc/systemd/system/cedarfield.service /etc/ufw "$backup/"
  cp -a /etc/fail2ban/jail.d "$backup/fail2ban-jail.d"
  cp -a /etc/apt/apt.conf.d/20auto-upgrades "$backup/20auto-upgrades"
  systemctl is-active cedarfield-extra.service > "$backup/extra-state" || true
fi
id cedarfield >/dev/null 2>&1 || useradd --system --home /nonexistent --shell /usr/sbin/nologin cedarfield
install -d -o root -g root -m 0755 /opt/cedarfield
install -o root -g root -m 0644 "$root/app/server.py" /opt/cedarfield/server.py
chown -R cedarfield:cedarfield /var/lib/cedarfield
chmod 0750 /var/lib/cedarfield
find /var/lib/cedarfield -type f -exec chmod 0600 {} +
chown root:root /etc/cedarfield /etc/cedarfield/app.conf
chmod 0700 /etc/cedarfield
chmod 0600 /etc/cedarfield/app.conf
install -m 0600 "$root/hardening/ssh/sshd_config" /etc/cedarfield/sshd_config
install -m 0644 "$root/hardening/systemd/cedarfield.service" /etc/systemd/system/cedarfield.service
install -m 0644 "$root/hardening/fail2ban/cedarfield.conf" /etc/fail2ban/jail.d/cedarfield.conf
install -d /etc/systemd/system/fail2ban.service.d
printf '[Unit]\nRequires=cedarfield-network.service\nAfter=cedarfield-network.service\n[Service]\nNetworkNamespacePath=/run/netns/cedarfield\n' > /etc/systemd/system/fail2ban.service.d/network.conf
install -d /etc/systemd/system/ufw.service.d
printf '[Unit]\nRequires=cedarfield-network.service\nAfter=cedarfield-network.service\n[Service]\nNetworkNamespacePath=/run/netns/cedarfield\n' > /etc/systemd/system/ufw.service.d/network.conf
install -m 0644 "$root/hardening/updates/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
install -m 0644 "$root/hardening/updates/52cedarfield-security" /etc/apt/apt.conf.d/52cedarfield-security
install -m 0755 "$root/operations/health-check.sh" /usr/local/sbin/cedarfield-health
install -m 0644 "$root/operations/cedarfield-health.service" /etc/systemd/system/cedarfield-health.service
install -m 0644 "$root/operations/cedarfield-health.timer" /etc/systemd/system/cedarfield-health.timer
sshd -t -f /etc/cedarfield/sshd_config
systemctl disable --now cedarfield-extra.service
bash "$root/hardening/firewall/policy.sh"
systemctl daemon-reload
systemctl restart cedarfield.service cedarfield-ssh.service fail2ban.service
systemctl enable fail2ban.service
systemctl enable --now cedarfield-health.timer
systemctl start cedarfield-health.service
systemctl enable --now apt-daily.timer apt-daily-upgrade.timer systemd-timesyncd.service
for _ in {1..20}; do
  if curl --fail --silent http://127.0.0.1:8090/health; then echo; exit 0; fi
  sleep 1
done
echo 'Health failed. Preserve evidence and use the documented rollback.' >&2
exit 1
