#!/usr/bin/env bash
set -euo pipefail
# Execute inside the dedicated cedarfield network namespace only.
[[ $(ip netns identify) == cedarfield ]] || { echo 'Refusing firewall change outside lab namespace' >&2; exit 2; }
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.0.2.2 to 192.0.2.1 port 22222 proto tcp
ufw logging low
ufw --force enable
