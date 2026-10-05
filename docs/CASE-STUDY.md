# Case study: Cedarfield service register

**Shemar Marks · Synthetic portfolio engagement · Local Ubuntu/WSL2 execution on 2026-10-05**

## Business problem

A fictional small business already had a useful application for tracking service jobs. The risk was in the host's operation: excessive application privilege, broad local configuration readability, permissive SSH settings, an unnecessary listener and no active inbound policy. The task was to improve those controls while keeping the register usable and leaving a maintenance procedure.

## Baseline and risk assessment

The live application returned health ok and three synthetic records. The service ran as root. Runtime configuration was 0644 root:root. Effective SSH policy allowed password authentication and root login, although accounts remained password-locked for isolation. UFW was inactive and an owned peer could reach TCP 9099 alongside SSH 22222. App 8090 remained loopback-only.

[The risk register](RISK-ASSESSMENT.md) connected each observation to a business consequence and verification check. No vulnerability exploitation was needed.

## Engineering decisions and change

Actual key access was verified before disabling password SSH. A dedicated unprivileged service identity replaced root application execution. Root-owned code, 0600 configuration and a 0750 state directory separated code, secrets and mutable data. systemd restricted privilege escalation and filesystem access.

The unnecessary service was disabled. UFW applied default-deny incoming with only the owned administrator source allowed to SSH. Fail2ban watched the dedicated SSH journal and installed UFW bans. Security-update timers and a five-minute health log established a documented operations path. A protected pre-change configuration copy made rollback reviewable.

All firewall/scanning work occurred between isolated owned namespaces in a new WSL2 Ubuntu guest. No home network or unrelated host was tested. The architecture used free local compute without creating AWS resources.

## Observed verification

The owned-peer scan changed from two open tested ports (22222, 9099) to one (22222). The app retained all original three jobs and health ok. Its actual process UID was 999, effective capabilities were zero and NoNewPrivs was 1. An unrelated local identity could not read private configuration.

Intended key login and SSH-forwarded application health succeeded after hardening. A harmless live unallowed listener on test TCP 19090 remained filtered from the peer, demonstrating packet policy rather than only a config listing. Four safe failed-key attempts produced one real Fail2ban ban and UFW reject rule. Removing the controlled ban restored intended access.

Six application tests passed before and after, along with shell syntax, ShellCheck and static configuration checks. The local backup contained three jobs with SQLite integrity ok. Reapplication preserved the workload. The application-only rollback returned health ok, and re-hardening restored a final verifier result of zero failures. Time synchronization reported active and synchronized.

[The evidence index](../evidence/README.md) identifies what each artifact proves and its limits. CI independently tests the application, scripts and static controls, and does not prove a VM deployment.

## Handover and maintenance

The repository contains a usable administrator/runbook path, health/log review, update review, firewall and ban procedures, protected backup guidance and rollback steps. An agreed recurring-care engagement could review those controls and record exceptions in a concise operational report. No customer contract or support guarantee is invented.

## Residual limits

This is one WSL2 Ubuntu host, not a Proxmox execution or production deployment. Shared application write identity, same-disk backup and local-only health logs remain. Active security timers establish configuration, not an observed future patch cycle. A key-only daemon and sandbox are not a comprehensive penetration test. Production availability, performance, SLA and off-device recovery remain unmeasured.

## Outcome and client relevance

The project reduced unnecessary exposure and application privilege, protected runtime configuration, verified intended access and preserved the useful workload. It demonstrates the practical shape of a Linux hardening engagement: assessed baseline, justified changes, observed checks, rollback and an operable handover.
