# Prerequisites

## Azure/M365

- Azure tenant + subscription access
- Permission to create:
  - app registrations
  - service principals
  - Azure Bot registrations
- Permission to configure Teams app visibility policies

## Network / TLS

- DNS record per user bot domain -> public IP
- Inbound TCP 80/443 allowed at edge firewall/security group
- NAT forwarding 80/443 to the host running that user's OpenClaw endpoint

## Host

- Dedicated OpenClaw instance host/process for that user
- Local listener reachable at `127.0.0.1:3978/api/messages`
- Homebrew available (for Caddy script on macOS)

## Validation checks

- `dig +short <user-domain>` resolves correctly
- External checks to ports 80/443 succeed
- Local probe: `curl -i http://127.0.0.1:3978/api/messages`
