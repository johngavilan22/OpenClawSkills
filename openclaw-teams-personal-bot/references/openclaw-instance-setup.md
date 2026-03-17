# OpenClaw Instance Setup (Dedicated per User)

Use a separate OpenClaw instance per user. Do not share config/env files across users.

## Required bot values (from bootstrap script output)

- `MICROSOFT_APP_ID`
- `MICROSOFT_APP_PASSWORD`
- `AZURE_TENANT_ID`
- Bot endpoint URL (for verification)

## Configure on that user's OpenClaw instance

1. Add Teams channel credentials to the instance-specific config/env.
2. Ensure Teams channel is enabled for that instance.
3. Ensure local webhook listener is active on `127.0.0.1:3978`.
4. Restart only that user’s OpenClaw instance.

## Required isolation controls

- Separate service/process per user (system service name or container)
- Separate config directory per user
- Separate secrets storage per user
- Separate logs per user

## Suggested operational pattern

- Service naming: `openclaw-<alias>`
- Config path: `/etc/openclaw/<alias>/...` (or equivalent)
- Secret source: dedicated vault item per user
- Logs: `/var/log/openclaw/<alias>/...`

If any of these are shared, fix before enabling production access.
