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
  $0 --domain <user-bot-domain> --email <acme-email> [--upstream 127.0.0.1:3978]
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
  echo "Homebrew not found: https://brew.sh"
  exit 1
fi

if ! brew list --versions caddy >/dev/null 2>&1; then
  brew install caddy
fi

CADDYFILE="/usr/local/etc/Caddyfile"
TS="$(date +%Y%m%d-%H%M%S)"
[[ -f "$CADDYFILE" ]] && cp "$CADDYFILE" "${CADDYFILE}.bak.${TS}"

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

echo "Configured personal endpoint: https://${DOMAIN}/api/messages"
echo "Ensure inbound TCP 80/443 is open and forwarded to this host for Let's Encrypt issuance."
