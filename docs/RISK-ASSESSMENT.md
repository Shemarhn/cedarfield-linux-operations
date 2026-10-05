# Business risk assessment

The synthetic business needed reliable access to a service-job register. Priorities followed the baseline, required access and workload regression risk. These are assessed configuration risks, not exploited vulnerabilities or findings from a penetration test.

| Risk | Business consequence | Baseline observation | Treatment | Verification / residual limit |
| --- | --- | --- | --- | --- |
| R1 Password-based remote administration | Credential guessing or reuse can provide unintended administration | Effective password authentication yes and root login yes. Accounts remained password-locked in the isolated baseline | Verify key login first, then require public key, disable passwords and root SSH | Key login before/after and tunnel health passed. Effective configuration confirms policy. No password-guessing exploit claimed |
| R2 Excessive application privilege | Application compromise could gain unnecessary OS access | Service had no User/Group and ran as root | Dedicated service identity, root-owned code, restricted state, systemd sandbox | Process UID 999, capabilities zero, NoNewPrivs 1 and service properties observed. OS/kernel flaws remain |
| R3 Undefined network exposure | Unnecessary services can become reachable accidentally | Inactive firewall and unnecessary HTTP service on TCP 9099 reachable from owned peer | Default-deny host firewall, scoped SSH rule, remove unnecessary service | Peer scan reduced from two open ports to one among tested ports. Live unallowed listener filtered. No full-network audit |
| R4 Weak secret handling | Unintended local users can read a write credential | Runtime config mode 0644 root:root | Separate `/etc/cedarfield` config, 0600 root ownership, 0700 directory | Stat and actual `nobody` read denial passed. Root and the service environment remain privileged boundaries |
| R5 Missing security maintenance | Available security fixes may remain unapplied | Update timers inactive | Security origin policy, active automatic-update timers, planned reboot review | Effective apt policy and active timers observed. No future scheduled upgrade claimed |
| R6 Poor detection | Authentication/service failures may go unnoticed | No active Fail2ban protection or health-review procedure | Persistent operational procedure, journald app/auth logs, health timer, Fail2ban | Safe failed-key events caused a real ban and firewall rule. Health log shows ok. Remote notifications remain planned |
| R7 Hardening regression | Changes can interrupt the useful application | Required three-record workflow already healthy | Pre/post health and record checks, tests, config backup, rollback | Six application tests, original records, SSH tunnel health, rollback health and final verification passed. No production load test |

Security control effectiveness depends on actual client requirements. For a real engagement, scope the required users, networks, data, support hours and acceptance checks before applying a policy.
