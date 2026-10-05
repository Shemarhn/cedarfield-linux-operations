# Architecture

## Executed environment

Ubuntu 24.04 LTS imported into a new local WSL2 distribution from the official Canonical root filesystem. Its published SHA256 matched the downloaded image. systemd manages a standard-library Python/SQLite workload, a dedicated SSH daemon, health-check timer and Fail2ban. No AWS resources were created.

WSL distributions can share networking. To protect the existing Ubuntu installation, `lab/create-network.sh` creates two network namespaces with a veth link. `cedarfield` is the server and `cedarfield-client` is the owned test client. Addresses `192.0.2.1/30` and `192.0.2.2/30` are TEST-NET-1 documentation addresses used solely within this isolated link. No default route, bridge, forwarding rule or NAT gives these namespaces outside access.

## Trust boundaries

- Windows/WSL administration can access the new lab guest. This privileged boundary is outside application isolation.
- The server namespace permits TCP 22222 only from its owned peer. Application TCP 8090 remains loopback-bound.
- SSH requires the `cedaradmin` key and only permits local forwarding to `127.0.0.1:8090`. It cannot forward to arbitrary destinations.
- The service user can write `/var/lib/cedarfield` while `/opt/cedarfield` contains root-owned application code. Root reads the private environment file before starting the unprivileged service.
- systemd mount restrictions supplement ordinary ownership. They reduce application access but do not eliminate risk in the Python process, kernel or privileged operator.
- Fail2ban and UFW share the server namespace. Package-update timers run in the new distribution's ordinary namespace with internet access to Ubuntu archives.

`cedarfield-network.service` recreates the namespace pair during startup. App, SSH, firewall and Fail2ban depend on it. WSL shuts distributions down when no user session keeps them alive, so timer schedules are meaningful only while the guest runs. This differs from an always-on Proxmox VM.

## State and backup

SQLite uses WAL mode. The backup script uses the SQLite online backup API and verifies integrity, then copies private runtime configuration with restrictive permissions. The current backup destination is the same guest disk. Off-device copy and restore into an independent guest remain future work.

See [baseline](diagrams/baseline.svg) and [hardened](diagrams/hardened.svg) diagrams.
