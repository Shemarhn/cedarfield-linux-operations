# Ongoing infrastructure care

This is a proposed client maintenance pathway, not a signed contract or an observed monthly engagement.

| Cadence | Agreed activity | Useful record |
| --- | --- | --- |
| Each maintenance window | Review app health, service errors, disk/resource health and access changes | Exceptions, cause, action and owner |
| Weekly or as scoped | Review backup freshness, integrity and expected data; review health/authentication failures and bans | Backup result and incident follow-up |
| Monthly or as scoped | Review security updates, required restarts, firewall allowances, service/config drift and credentials/access ownership | Change record, validation and concise operational report |
| Periodic agreed exercise | Restore a protected backup in a separate test environment and verify expected records | Restore evidence and runbook corrections |
| On a significant incident | Troubleshoot, restore agreed functionality, capture lessons and update operations procedure | Incident summary and next actions |

Actual cadence follows the system's needs, access and client's maintenance window. Automatic updates do not remove the need to review failed upgrades or pending reboots. For cloud clients, include a basic resource/cost review using existing billing access without adding paid tools.

The operational report should state checks completed, failures, changes, validation, residual concerns and next actions. Separate observed results from planned work. Agree included tasks, hours, exclusions and response expectations before recurring support starts. No 24/7 monitoring, emergency response guarantee, managed security service or production SLA is implied.

For this WSL2 lab, maintenance timers only run while the guest is active. External notification, off-device backup and a Proxmox boot/restore exercise remain planned.
