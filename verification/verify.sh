#!/usr/bin/env bash
# ShellCheck cannot follow helper functions invoked through check's "$@".
# shellcheck disable=SC2317
set -euo pipefail
[[ $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only' >&2; exit 2; }
[[ $(ip netns identify) == cedarfield ]] || { echo 'Run through ip netns exec cedarfield' >&2; exit 2; }
failures=0
check() { if "$@"; then echo "PASS $*"; else echo "FAIL $*"; failures=$((failures+1)); fi; }
prop() { [[ $(systemctl show cedarfield -p "$1" --value) == "$2" ]]; }
sshprop() { sshd -T -f /etc/cedarfield/sshd_config | grep -Fx "$1 $2" >/dev/null; }
closed() { ! ss -H -lnt | awk '{print $4}' | grep -Eq ':9099$'; }
perms() { [[ $(stat -c '%a:%U:%G' /etc/cedarfield/app.conf) == '600:root:root' ]]; }
firewall() { ufw status verbose | grep -F 'deny (incoming)' >/dev/null; }
records() { python3 - <<'PY'
import json, urllib.request
with urllib.request.urlopen('http://127.0.0.1:8090/api/jobs') as res:
    jobs=json.load(res)['jobs']
assert [j['customer'] for j in jobs[:3]] == ['C-101','C-102','C-103']
assert len(jobs)>=3
PY
}
echo 'Cedarfield observed host checks'
date -u +%FT%TZ
check curl --fail --silent http://127.0.0.1:8090/health
echo
check records
check prop User cedarfield
check prop Group cedarfield
check prop NoNewPrivileges yes
check prop PrivateTmp yes
check prop ProtectSystem strict
check prop ProtectHome yes
check sshprop passwordauthentication no
check sshprop permitrootlogin no
check sshprop authenticationmethods publickey
check perms
check closed
check firewall
check systemctl is-active cedarfield.service cedarfield-ssh.service fail2ban.service
check systemctl is-active apt-daily.timer apt-daily-upgrade.timer cedarfield-health.timer
check test -f /var/lib/cedarfield-admin-proof
echo "Failures: $failures"
exit "$failures"
