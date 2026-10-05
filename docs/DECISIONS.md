# Engineering decisions

| Decision | Reason | Tradeoff |
| --- | --- | --- |
| Local Ubuntu/WSL2 with an isolated network pair | Free existing compute provided executable Linux evidence without waiting for Proxmox access | WSL2 differs from a full Proxmox guest and shared kernel/network behavior requires explicit namespaces |
| Standard-library Python workload | Small real HTTP/SQLite app keeps attention on host engineering and avoids dependency sprawl | It is a portfolio workload, not a production web framework/server |
| App on loopback, admin via scoped SSH forwarding | No application ingress is needed by this lab's administrator | A real multi-user business app would need a scoped access design, TLS and individual identities |
| Key proof before password disablement | Preserves required administration and reduces lockout risk | The marker is an operator-controlled prerequisite, not cryptographic proof of access |
| Dedicated service UID plus systemd restrictions | Reduces the privileges and writable filesystem the workload needs | Root, kernel and systemd remain trusted. No claim of perfect containment |
| Root-owned 0600 runtime environment file | Keeps runtime credential out of source and unreadable by unrelated users | The app needs its credential in memory/environment. Root remains able to inspect it |
| UFW and Fail2ban inside the isolated namespace | Provides understandable host policy and event-driven authentication blocking | Namespace setup is lab-specific. Short bans supplement key-only access |
| Security updates without automatic reboot | Keeps security maintenance active while leaving restart decisions explicit | Timer operation and pending reboot review require a running guest and agreed maintenance window |
| Local health logging | Provides an observable operational signal without paid services | No off-host alert or guaranteed response is implemented |
| Local integrity-checked backup | Demonstrates an operational data-protection step for free | Same-disk backup is not independent disaster recovery |
| Application-only rollback | Recovers previous app service/config without reopening network/SSH controls | The baseline service runs as root in this isolated exercise. Re-hardening follows immediately |

Intentionally excluded: cloud deployment, paid services, public ingress, offensive exploitation, remote management agents, enterprise high availability and 24/7 support claims. No account credentials or browser sessions enter the repository.
