# Architecture: Personal Bot per User

## Goal

Guarantee privacy and operational isolation by assigning each user:
1. a dedicated Teams bot identity (Entra App + Azure Bot resource)
2. a dedicated OpenClaw instance
3. a dedicated public endpoint/domain

## Isolation model

For each user U:

- Bot Identity: `app-U`
- Bot Resource: `bot-U`
- Endpoint: `https://<u-domain>/api/messages`
- OpenClaw instance: `openclaw-U` (own process/config/env/logs)

No shared bot app IDs across users.

## Naming standard (recommended)

- Resource group: `rg-openclaw-teams-personal`
- Bot name: `oc-<alias>-bot`
- Domain: `<alias>-bot.example.com`
- OpenClaw service: `openclaw-<alias>`

## Why this model

- Identity-level separation (not only policy-level)
- Lower blast radius for credential leaks
- Easier auditing and revocation per user
- Clean migration/deletion when user offboards
