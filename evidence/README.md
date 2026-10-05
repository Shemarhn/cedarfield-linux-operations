# Evidence index

Captured 2026-10-05 from an actual local Ubuntu 24.04 WSL2 guest. Baseline capture began at 15:01:40 UTC. Final verification followed staged hardening, safe event testing, backup, reapply, rollback and re-hardening. TEST-NET-1 addresses are deliberately chosen lab addresses, not the home LAN.

| Artifact | What it proves | What it does not prove |
| --- | --- | --- |
| [Baseline inventory](baseline/inventory.txt) | Live health/records, listeners, effective SSH, service properties, permissions, inactive UFW/timers | Public exposure, a real vulnerability exploit or paid client findings |
| [Baseline peer scan](baseline/peer-scan.txt) | Owned peer reached SSH and unnecessary HTTP among specified TCP ports | Full-port, UDP or physical-network scan |
| [Pre-change key access](baseline/admin-key-access.txt) | Successful intended key login before password disablement | External administration or identity-provider assurance |
| [Baseline tests](baseline/application-tests.txt) | Six application behavior/persistence tests passed | Production load, deployment or security certification |
| [Hardened inventory](hardened/inventory.txt) | Live original records, health, effective policies and service properties | Exhaustive enforcement of all controls |
| [Hardened peer scan](hardened/peer-scan.txt) | Only SSH open among 22222/8090/9099, other two filtered | Every possible port/path/service |
| [Runtime identity and read denial](hardened/process-and-permission-denial.txt) | Actual non-root UID/GID, no effective capabilities, NoNewPrivs 1; nobody cannot read config | Perfect containment, root/operator protection or kernel assurance |
| [SSH access](hardened/admin-key-access.txt), [tunnel health](hardened/ssh-tunnel-health.txt) | Intended administration and app forwarding work after hardening | Public TLS or multi-user application authorization |
| [Firewall denial test](hardened/firewall-denial-test.txt) | A real harmless listener on unallowed TCP 19090 was filtered from owned peer | Firewall enforcement outside isolated namespace |
| [Fail2ban event test](hardened/fail2ban-event-test.txt) | Four failed-key events, one actual peer ban/UFW reject, blocked SSH and legitimate access after unban | Internet attack detection, broad intrusion detection or production response time |
| [Update policy](hardened/update-policy.txt) | Effective apt security configuration | A future scheduled upgrade or completed patch cycle |
| [Time synchronization](hardened/time-sync.txt) | Service active and synchronized reported at capture | Proxmox clock behavior or independent time accuracy |
| [Health log](hardened/health-log.txt) | Actual successful local health checks recorded | Remote alert delivery or guaranteed monitoring coverage |
| [Backup](hardened/backup.txt) | Three-job online SQLite snapshot with integrity ok | Independent storage, full disaster recovery, RPO or recovery time |
| [Reapply](hardened/reapply.txt) | Second apply returned healthy workload without duplicate rules | General idempotence on arbitrary hosts |
| [Rollback](hardened/rollback-exercise.txt) | Application-only rollback returned health ok | Restoration of a lost virtual disk or complete security rollback |
| [Re-hardening](hardened/reharden-after-rollback.txt), [final verifier](hardened/final-verification.txt) | Final controls and required workload passed with zero failures | Production SLA, repeatability guarantee or all future states |
| [Post-change tests](hardened/application-tests.txt), [ShellCheck](hardened/shellcheck.txt) | Six application tests and shell lint passed | Running those tests within the app service sandbox; live host evidence is separate |
| [Captured HTML response](hardened/application-response.html) | Actual workload-rendered synthetic register response | A live hosted service or screenshot of Proxmox |

The check/apply output and logs preserve successes and boundaries. No passwords, runtime token, private keys, host trust files, private IPs, account IDs or VM disk exports are published. SSH transcripts are summarized to omit authentication metadata. Only synthetic customer data remains. Empty ShellCheck output means no diagnostic; execution exit status was successful.

The [SHA256 manifest](SHA256SUMS.txt) binds evidence files, excluding this index and the manifest itself. Local files and the Linux checks are distinct from the [GitHub CI run](https://github.com/Shemarhn/cedarfield-linux-operations/actions). CI validates app/config/scripts and refuses an unmarked host; it does not execute the host hardening workflow.
