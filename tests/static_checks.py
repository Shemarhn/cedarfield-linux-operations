"""Guard important safety properties in committed configuration."""
from pathlib import Path
root = Path(__file__).parents[1]
unit=(root/'hardening/systemd/cedarfield.service').read_text()
for value in ('User=cedarfield', 'NoNewPrivileges=true', 'ProtectSystem=strict', 'ProtectHome=true', 'ReadWritePaths=/var/lib/cedarfield'):
    assert value in unit, value
ssh=(root/'hardening/ssh/sshd_config').read_text()
for value in ('ListenAddress 192.0.2.1','PasswordAuthentication no','PermitRootLogin no','AuthenticationMethods publickey'):
    assert value in ssh, value
for name in ('hardening/harden.sh','baseline/setup.sh','operations/rollback.sh'):
    assert '/etc/cedarfield-lab' in (root/name).read_text(), name
print('Static configuration and lab-scope checks passed')
