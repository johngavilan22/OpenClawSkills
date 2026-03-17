#!/usr/bin/env bash
set -euo pipefail

DOMAIN=""
EMAIL=""
UPSTREAM="127.0.0.1:3978"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --upstream) UPSTREAM="$2"; shift 2 ;;
    -h|--help)
      cat <<USAGE
Usage:
  $0 --domain teamsbot.example.com --email you@example.com [--upstream 127.0.0.1:3978]
USAGE
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "Missing required args --domain and --email"
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install Homebrew first: https://brew.sh"
  exit 1
fi

if ! brew list --versions caddy >/dev/null 2>&1; then
  echo "Installing caddy..."
  brew install caddy
fi

CADDYFILE="/usr/local/etc/Caddyfile"
TS="$(date +%Y%m%d-%H%M%S)"
if [[ -f "$CADDYFILE" ]]; then
  cp "$CADDYFILE" "${CADDYFILE}.bak.${TS}"
fi

cat > "$CADDYFILE" <<CONF
{
  email ${EMAIL}
}

${DOMAIN} {
  encode gzip

  handle /api/messages* {
    reverse_proxy ${UPSTREAM}
  }

  respond 404
}
CONF

caddy validate --config "$CADDYFILE"
brew services restart caddy

echo "Endpoint configured: https://${DOMAIN}/api/messages"
echo "Azure Bot endpoint should match this URL exactly."
