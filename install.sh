#!/bin/bash
set -e

# --- Check for root privileges ---
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Try using sudo."
  exit 1
fi

# --- Ask user for domain ---
read -p "Enter your domain (e.g., example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Domain cannot be empty. Exiting."
  exit 1
fi

echo "Using domain: $DOMAIN"

# --- Update package lists ---
echo "Updating package lists..."
apt update

# --- Install prerequisites for Caddy ---
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl

# --- Install Caddy if not installed using updated instructions ---
if ! command -v caddy &>/dev/null; then
  echo "Installing Caddy server..."
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
  apt update
  apt install -y caddy
else
  echo "Caddy is already installed."
fi

# --- Configure Caddy with a ping endpoint ---
CADDYFILE="/etc/caddy/Caddyfile"
echo "Configuring Caddy to serve a ping endpoint on $DOMAIN..."
cat > "$CADDYFILE" <<EOF
$DOMAIN {
    handle /ping {
        header {
            Content-Type "text/plain"
            Cache-Control "no-store"
            Access-Control-Allow-Origin "*"
        }
        respond "pong"
    }
}
EOF

# Reload Caddy to apply the new configuration.
echo "Reloading Caddy..."
systemctl reload caddy

echo "Installation complete."
echo "Caddy is now configured for domain $DOMAIN with a ping endpoint at https://$DOMAIN/ping"