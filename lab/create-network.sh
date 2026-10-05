#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 && -f /etc/cedarfield-lab ]] || { echo 'Dedicated lab guest only' >&2; exit 2; }
if ip netns list | grep -Eq '^cedarfield( |$)'; then echo 'Lab namespace already exists'; exit 0; fi
ip netns add cedarfield
ip netns add cedarfield-client
ip link add cf-server type veth peer name cf-client
ip link set cf-server netns cedarfield
ip link set cf-client netns cedarfield-client
ip -n cedarfield address add 192.0.2.1/30 dev cf-server
ip -n cedarfield-client address add 192.0.2.2/30 dev cf-client
ip -n cedarfield link set lo up
ip -n cedarfield link set cf-server up
ip -n cedarfield-client link set lo up
ip -n cedarfield-client link set cf-client up
# No default route, forwarding, bridge or NAT. These TEST-NET-1 addresses
# connect only two owned network namespaces and reveal no home LAN detail.
echo 'Isolated server/client pair ready. No external route.'
