# Implementation

## Provisioned locally

The fresh Ubuntu rootfs SHA256 was `2a790896740b14d637dbdc583cce1ba081ac53b9e9cdb46dc09a2f73abbd9934`, matching the published Canonical checksum. Source: https://cloud-images.ubuntu.com/wsl/releases/noble/current/ . Microsoft documents imported distributions and per-distribution systemd settings at https://learn.microsoft.com/windows/wsl/use-custom-distro and https://learn.microsoft.com/windows/wsl/wsl-config . WSL interop and automatic Windows-drive mounting are disabled in the lab. A temporary drive mount transfers reviewed source/evidence and is unmounted afterward.

Installed free Ubuntu packages include openssh-server, ufw, fail2ban, unattended-upgrades, Python, curl, nmap, ShellCheck, SQLite and systemd-timesyncd. Mutations occurred in the new dedicated distribution only.

## Staged application

1. Create the `/etc/cedarfield-lab` scope marker on the dedicated guest.
2. Install `lab/create-network.sh` as `/usr/local/sbin/cedarfield-network`, install and enable its network service.
3. Provision `cedaradmin` with a privately generated SSH key and locked password. Keep the private key and host-key trust file outside Git.
4. Run `ip netns exec cedarfield bash baseline/setup.sh` once. It refuses an existing application config.
5. Capture inventory and owned-peer scan. Verify actual intended SSH key access with strict host-key verification, then record the successful login time in `/var/lib/cedarfield-admin-proof`.
6. Run `ip netns exec cedarfield bash hardening/harden.sh --check`, review scope, then `--apply`.
7. Run `ip netns exec cedarfield bash verification/verify.sh`, peer scan, event tests and operational checks.

The baseline enables permissive effective SSH policy but introduces no usable password. Root has no authorized SSH key and `AllowUsers` already scopes administration. The unnecessary service serves only root-owned application source across the isolated veth. This safely demonstrates exposure/configuration risk without exposing the user's physical network.

## Controls

Application: `cedarfield` system account, locked shell, root-owned code, state directory 0750 and files 0600. systemd applies NoNewPrivileges, PrivateTmp, ProtectSystem=strict, ProtectHome, PrivateDevices, empty capability bounding set and writable state path.

SSH: dedicated daemon on isolated peer-facing TCP 22222, verified key access, no root/password login, local forwarding only to application loopback. RuntimeDirectory creates `/run/sshd` on guest restarts.

Firewall: default deny inbound, allow outbound, explicit client-source allowance for SSH. The service override and script namespace guard scope policy to Cedarfield. No home LAN rule is changed.

Fail2ban: journald backend matches `cedarfield-ssh.service`, maxretry 3, 300-second window and 600-second ban, UFW action. The owned peer produced four failed-key events, one actual ban and blocked connection. Console unban restored legitimate key access.

Operations: security-update policy/timers, systemd-timesyncd, journald, five-minute health timer, online SQLite backup with integrity check and private config copy. No automatic reboot or paid alert service.

## Repeatability and rollback

The first apply preserves pre-hardening configs under `/var/backups/cedarfield-prehardening` with 0700 access. Reapply keeps that original backup and avoids duplicate firewall rules. The actual rollback restored the previous app service/config, returned health ok, and re-hardening restored all final acceptance checks. It kept hardened SSH/firewall policy and restrictive config permissions.

## Execution issues resolved

WSL guest restarts clear runtime namespace paths and `/run/sshd`. Explicit network-service dependencies and SSH RuntimeDirectory fixed startup. A verifier pipeline using early-exit grep incorrectly reported two SSH failures although effective settings were correct; reading the complete output fixed the checks. ShellCheck's indirect-callback warning is suppressed only in the verifier with an explanation. These were implementation issues, not observed security findings.

See [evidence](../evidence/README.md). No mutation script was applied to an unrelated host.
