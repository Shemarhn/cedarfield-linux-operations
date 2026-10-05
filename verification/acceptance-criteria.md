# Acceptance criteria

Only observed checks receive PASS. The executed environment was a local Ubuntu 24.04 WSL2 distribution with isolated owned network namespaces.

| Acceptance check | Status | Evidence |
| --- | --- | --- |
| Application worked before changes | PASS | Baseline health, three records and six tests |
| Baseline risk and exposure documented | PASS | Inventory, peer scan and business risk register |
| Unnecessary exposure reduced | PASS | TCP 9099 disabled; peer scan reduced two open tested ports to one |
| App runs without root privilege | PASS | UID 999, dedicated service, zero capabilities, NoNewPrivs 1 |
| Runtime config protected | PASS | 0600 root:root, 0700 directory, nobody read denied |
| Stronger SSH preserves intended access | PASS | Effective policy, before/after key login and SSH tunnel health |
| Firewall policy enforced | PASS | Default deny, scoped source allowance and filtered live unallowed probe |
| Useful logging and health procedure | PASS | App journal, observed health log and timer |
| Update process configured | PASS | Effective security origin policy and active update timers |
| Future automatic upgrade cycle | NOT OBSERVED | Active timers do not establish later execution |
| Fail2ban detects and blocks safe failed attempts | PASS | Four failed events, actual one-peer ban/reject rule and unban recovery |
| Application still works after | PASS | Health ok, original three records, six tests and forwarded health |
| Backup implementation and integrity | PASS | Three-job SQLite snapshot, integrity ok |
| Full off-device data restore | PLANNED / NOT OBSERVED | Current backup remains on guest disk |
| Rollback and final recovery of controls | PASS | Rollback health ok, re-hardening and final zero failures |
| Ongoing maintenance procedure | PASS (DOCUMENTED) | Runbook and proposed care plan; no recurring contract executed |
| Proxmox guest boot validation | NOT OBSERVED | No Proxmox session used |
| Production uptime, SLA or penetration test | NOT APPLICABLE | Outside this synthetic engagement |

The scripted verifier checks host properties and workload state. Additional runtime, peer and operations evidence extends its coverage. A passing verifier alone does not establish every row above.
