# Baseline findings

These findings were actually observed in the isolated local lab; see [inventory](../evidence/baseline/inventory.txt) and [owned-peer scan](../evidence/baseline/peer-scan.txt).

- Application health ok and three persistent synthetic jobs.
- Service defaulted to root; sandbox properties off.
- Runtime configuration 0644 root:root; state directory 0755.
- Effective password SSH yes and root login yes. No usable password was created and allowed user already scoped to cedaradmin.
- Unnecessary HTTP TCP 9099 reachable from the owned peer. SSH TCP 22222 also open. Application TCP 8090 only on server loopback.
- Inactive UFW and update timers.

These observations demonstrate configuration/operation risk in a constructed baseline. They do not prove public exposure, compromise, credential theft or a real client incident.
