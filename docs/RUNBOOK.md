# Operations runbook

Scope: dedicated Cedarfield Ubuntu guest and its isolated server/client namespaces. Root console access through WSL is the recovery path. Do not reuse its network-specific scripts on production without adapting the access policy.

## Start and check

Start the lab distribution from its existing WSL registration. systemd recreates its network namespaces. Keep an interactive WSL session open during demonstrations because systemd timers alone do not keep WSL running.

```sh
systemctl status cedarfield-network cedarfield cedarfield-ssh --no-pager
ip netns exec cedarfield curl --fail http://127.0.0.1:8090/health
ip netns exec cedarfield bash /root/cedarfield/verification/verify.sh
```

## Administrator access and application forwarding

Use the already provisioned private key in the owned client namespace. Verify the host key against the console-provisioned known-hosts file. Never publish either file.

```sh
ip netns exec cedarfield-client ssh -i PRIVATE_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=TRUSTED_HOSTS -p 22222 cedaradmin@192.0.2.1
# Application access through the same owned client:
ip netns exec cedarfield-client ssh -N -L 127.0.0.1:18090:127.0.0.1:8090 -i PRIVATE_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=TRUSTED_HOSTS -p 22222 cedaradmin@192.0.2.1
# In another client-namespace console:
ip netns exec cedarfield-client curl http://127.0.0.1:18090/health
```

Host console remains available if SSH or Fail2ban blocks access. Do not disable password authentication on another server without a successful independent key connection and a recovery console.

## Service management and logs

```sh
systemctl restart cedarfield
journalctl -u cedarfield --since today --no-pager
journalctl -u cedarfield-ssh --since today --no-pager
journalctl -t cedarfield-health --since today --no-pager
systemctl start cedarfield-health.service
```

App logs contain method and route without headers, bodies or client addresses. SSH logs may contain authentication metadata, so inspect privately and sanitize extracts before sharing. A successful health request checks database access but does not establish business recovery, performance or all functional paths.

## Firewall and failed-login review

```sh
ip netns exec cedarfield ufw status verbose
ip netns exec cedarfield fail2ban-client status sshd
ip netns exec cedarfield fail2ban-client set sshd unbanip 192.0.2.2
```

Unban only after understanding the event. The example peer is the owned test client. Fail2ban's temporary ban supplements keys; it does not replace access control. Check namespace and SSH listen address before troubleshooting routing.

## Updates and reboot review

```sh
apt list --upgradable
apt-config dump
systemctl status apt-daily.timer apt-daily-upgrade.timer
test -f /var/run/reboot-required && cat /var/run/reboot-required || true
```

Security origins and periodic updates are configured. Review update logs privately, available disk space and required service restarts. Schedule a guest restart during an agreed maintenance window, then verify app, key access, namespace, firewall and health checks. WSL time-sync evidence does not replace a full VM boot validation.

## Backup awareness

```sh
bash /root/cedarfield/operations/backup.sh
```

Root-only local copies preserve an online SQLite snapshot and private configuration. Confirm integrity and expected job count. Keep an independent encrypted copy outside the guest for a real deployment. Same-disk copies cannot recover a lost virtual disk. The current project verified snapshot integrity and exercised configuration/service rollback, not full off-device disaster recovery.

## Troubleshooting and rollback

If health fails, inspect service status/journal, state ownership, disk capacity and config existence. Do not print the runtime credential. If SSH fails, use the console to inspect `sshd -T -f /etc/cedarfield/sshd_config`, Fail2ban and UFW in the server namespace. If namespace services fail after a restart, check the network unit and `/run/netns` before starting dependent services.

For a regression in this disposable lab:

```sh
ip netns exec cedarfield bash /root/cedarfield/operations/rollback.sh --apply
# Capture health and reason, then reapply after correcting the change:
ip netns exec cedarfield bash /root/cedarfield/hardening/harden.sh --apply
ip netns exec cedarfield bash /root/cedarfield/verification/verify.sh
```

Rollback restores app service/config only, preserves current data, hardened SSH/firewall and private config permissions. It temporarily restores baseline root execution, so use only in this isolated lab, then re-harden. For client work, keep an approved previous unprivileged release/config, scope each reverted control and record acceptance checks.

## Closeout

Stop only this lab with `wsl --terminate CedarfieldLab` on the host after retaining evidence. Its disk stays available for another demonstration. Never unregister a distribution or delete its disk without an explicit data-retention decision.
