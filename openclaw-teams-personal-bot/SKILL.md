---
name: openclaw-teams-personal-bot
description: Deploy isolated Microsoft Teams personal bots where each user gets a dedicated bot identity and dedicated OpenClaw backend instance. Use when setting up private per-user bot access, preventing cross-user visibility, implementing one-bot-per-user routing, or replicating secure personal bot deployments across environments.
---

# OpenClaw Teams Personal Bot

Implement one-bot-per-user isolation with a dedicated OpenClaw instance per user.

## Workflow

1. Read `references/architecture.md` to confirm isolation model and naming standards.
2. Read `references/prereqs.md` and collect required tenant, DNS, firewall, and host inputs.
3. Run `scripts/01-create-personal-bot.ps1` to create user-specific Entra app + Azure Bot + Teams channel.
4. On the user's OpenClaw host, run `scripts/02-configure-openclaw-endpoint.sh` to expose `https://<user-domain>/api/messages` with Caddy/Let's Encrypt.
5. Apply credentials on that same OpenClaw instance using `references/openclaw-instance-setup.md`.
6. Restrict Teams app visibility to the intended user/group per `references/teams-policy-lockdown.md`.
7. Run `scripts/03-validate-personal-bot.ps1` and confirm endpoint/channel isolation.

## Commands

### Azure bot bootstrap (per user)

```powershell
pwsh scripts/01-create-personal-bot.ps1 \
  -SubscriptionId "<SUBSCRIPTION_ID>" \
  -TenantId "<TENANT_ID>" \
  -ResourceGroup "rg-openclaw-teams-personal" \
  -Location "eastus" \
  -UserAlias "john" \
  -BotName "oc-john-bot" \
  -EndpointUrl "https://john-bot.example.com/api/messages"
```

### OpenClaw host endpoint

```bash
bash scripts/02-configure-openclaw-endpoint.sh \
  --domain john-bot.example.com \
  --email admin@example.com \
  --upstream 127.0.0.1:3978
```

### Validation

```powershell
pwsh scripts/03-validate-personal-bot.ps1 \
  -SubscriptionId "<SUBSCRIPTION_ID>" \
  -ResourceGroup "rg-openclaw-teams-personal" \
  -BotName "oc-john-bot" \
  -EndpointUrl "https://john-bot.example.com/api/messages"
```

## Output contract

After successful setup, ensure each personal deployment has:

- Unique `MICROSOFT_APP_ID`
- Unique `MICROSOFT_APP_PASSWORD`
- Unique public endpoint/domain
- Dedicated OpenClaw instance (separate process and config path)
- Teams policy assignment allowing only intended user(s)

If any item is shared across users, treat deployment as non-isolated and correct before production use.
