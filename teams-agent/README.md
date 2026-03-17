# Teams Agent Bot – Reusable Deployment Pack

This package captures the Teams agent bot setup work and turns Azure portal-heavy steps into scripts where possible.

## What this deploys

1. Azure AD app registration + service principal for the bot identity
2. Azure Bot resource (Channel Registration) tied to that identity
3. Microsoft Teams channel enablement on the bot
4. Bot messaging endpoint set to your public OpenClaw URL
5. OpenClaw host endpoint published at `https://<domain>/api/messages` (Caddy reverse proxy)

---

## Credentials / inputs you need

### Azure / Microsoft credentials

- Azure account with permissions to:
  - create app registrations (Entra ID)
  - create resource groups/resources in subscription
  - enable Teams channel on Azure Bot resource
- Azure subscription id
- Azure tenant id

### Runtime values you must provide

- `BotName` (example: `openclaw-teams-bot-prod`)
- `ResourceGroup` (example: `rg-openclaw-teams`)
- `Location` (example: `eastus`)
- `EndpointUrl` (example: `https://teamsbot.example.com/api/messages`)
- `Domain` for public HTTPS endpoint (example: `teamsbot.example.com`)
- `LetsEncryptEmail` for cert notices

### OpenClaw host prerequisites

- OpenClaw running and Teams channel listener bound on local host (`127.0.0.1:3978`)
- DNS A/CNAME pointing `Domain` to your host public IP
- Router/firewall forwarding TCP 80/443 to OpenClaw host

---

## File map

- `scripts/01-azure-bot-bootstrap.ps1`
  - Creates app registration + secret + service principal
  - Creates Azure Bot resource and sets endpoint
  - Enables Teams channel
  - Outputs values for OpenClaw env/config

- `scripts/02-configure-openclaw-endpoint.sh`
  - Installs/configures Caddy on macOS host
  - Publishes `https://<domain>/api/messages` to local `127.0.0.1:3978`

- `scripts/03-validate-deployment.ps1`
  - Checks Azure bot endpoint/channel status
  - Verifies endpoint reachability

- `scripts/deploy-all.ps1`
  - Runs bootstrap + validation in one command
  - Writes generated OpenClaw-friendly env file (`.env.generated`)

- `.env.example`
  - Template for OpenClaw Teams bot env/config values

---

## One-command option (recommended)

```powershell
pwsh ./scripts/deploy-all.ps1 \
  -SubscriptionId "<SUBSCRIPTION_ID>" \
  -TenantId "<TENANT_ID>" \
  -ResourceGroup "rg-openclaw-teams" \
  -Location "eastus" \
  -BotName "openclaw-teams-bot-prod" \
  -EndpointUrl "https://teamsbot.example.com/api/messages"
```

This command will:
1. create/update Azure resources
2. validate endpoint/channel configuration
3. write `teams-agent/.env.generated` with required OpenClaw values

> `./.env.generated` contains secrets. Treat it like a credential file.

---

## Step-by-step (clean redeploy)

### Step 1) Bootstrap Azure resources (PowerShell)

```powershell
pwsh ./scripts/01-azure-bot-bootstrap.ps1 \
  -SubscriptionId "<SUBSCRIPTION_ID>" \
  -TenantId "<TENANT_ID>" \
  -ResourceGroup "rg-openclaw-teams" \
  -Location "eastus" \
  -BotName "openclaw-teams-bot-prod" \
  -EndpointUrl "https://teamsbot.example.com/api/messages"
```

What this returns:
- `MICROSOFT_APP_ID`
- `MICROSOFT_APP_PASSWORD`
- Bot resource id/name

Save these securely.

---

### Step 2) Open firewall/NAT for ports 80 and 443

Before cert issuance can work, your domain must be publicly reachable on HTTP/HTTPS.

Required:
- Router/NAT: forward TCP `80` and `443` to your OpenClaw host
- Edge firewall/security group: allow inbound TCP `80` and `443`
- DNS: `teamsbot.example.com` points to your public IP

Optional (if macOS Application Firewall blocks inbound service traffic):

```bash
# Intel/Homebrew path example
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/caddy
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/caddy
```

Validation:
- `dig +short teamsbot.example.com` returns your public IP
- From outside your LAN, port checks to `80/443` succeed

---

### Step 3) Configure OpenClaw Teams endpoint on host

Run on your OpenClaw macOS host:

```bash
bash ./scripts/02-configure-openclaw-endpoint.sh \
  --domain teamsbot.example.com \
  --email you@example.com \
  --upstream 127.0.0.1:3978
```

This handles Caddy install/config/restart and TLS.

---

### Step 4) Free TLS certificate process (Let's Encrypt via Caddy)

`02-configure-openclaw-endpoint.sh` writes a Caddyfile with your email and domain. On restart, Caddy automatically:
- performs ACME HTTP challenge over port 80
- issues a free Let's Encrypt cert
- serves HTTPS on 443
- auto-renews certs before expiration

Quick checks:

```bash
# Validate cert presented by endpoint
curl -Iv https://teamsbot.example.com/api/messages

# Inspect caddy logs
brew services info caddy
```

If certificate issuance fails, 90% of the time it is one of:
- DNS not pointing to correct public IP
- port 80/443 not forwarded/open
- another service already bound to 80/443

---

### Step 5) Configure OpenClaw Teams channel credentials

Set the values from Step 1 in OpenClaw config/env (exact key names depend on your channel config style), then restart OpenClaw.

Minimum required values:
- Microsoft App ID
- Microsoft App Password/Client Secret
- Tenant ID (if tenant-scoped auth is configured)

---

### Step 6) Validate deployment

```powershell
pwsh ./scripts/03-validate-deployment.ps1 \
  -SubscriptionId "<SUBSCRIPTION_ID>" \
  -ResourceGroup "rg-openclaw-teams" \
  -BotName "openclaw-teams-bot-prod" \
  -EndpointUrl "https://teamsbot.example.com/api/messages"
```

---

## Notes on portal vs script

### Scripted now
- Entra app registration creation
- Secret creation
- Service principal creation
- Azure bot resource creation
- Endpoint update
- Teams channel enablement

### May still require one-time portal verification in some tenants
- Admin consent UX nuances for restricted tenants
- Teams policy controls in M365 tenant if channel appears blocked by org policy

---

## Security recommendations

- Store app secret in a secret manager (Azure Key Vault / 1Password / Bitwarden)
- Rotate bot secret on a schedule (e.g., every 90 days)
- Use least privilege RBAC on subscription/resource group
- Keep `AUTO_REPLY` off until monitoring/guardrails are validated

