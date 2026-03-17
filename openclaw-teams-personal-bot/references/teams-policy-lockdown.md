# Teams Policy Lockdown (Prevent Access by Others)

## Objective

Limit each personal bot so only the intended user (or approved group) can install/use it.

## Process

1. Publish/upload the bot app package to tenant catalog.
2. In Teams Admin Center, create or use an app permission policy that allows this bot app.
3. Assign policy only to intended user(s).
4. Remove this bot app from global/default-allow policies.

## Verification

- Intended user can find/install/open bot
- Non-authorized test user cannot find or install the bot
- Backend still enforces ACL (deny-by-default) even if policy misconfiguration occurs

## Important

Teams policy is not the only security control.
Always keep backend ACL checks active:

- Match incoming user identity to expected personal bot deployment
- Reject mismatched identities
- Log denied attempts with identity and timestamp
