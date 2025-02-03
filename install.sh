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

# --- Ask user for port with default value 3000 ---
read -p "Enter the port for the Go server [3000]: " APP_PORT
APP_PORT=${APP_PORT:-3000}

echo "Using domain: $DOMAIN"
echo "Using port: $APP_PORT"

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

# --- Configure Caddy as a reverse proxy ---
CADDYFILE="/etc/caddy/Caddyfile"
echo "Configuring Caddy to reverse proxy from $DOMAIN to localhost:$APP_PORT..."
cat > "$CADDYFILE" <<EOF
$DOMAIN {
    reverse_proxy localhost:$APP_PORT
}
EOF

# Reload Caddy to apply the new configuration.
echo "Reloading Caddy..."
systemctl reload caddy

# --- Install Go if not already installed ---
if ! command -v go &>/dev/null; then
  echo "Installing Go..."
  apt install -y golang
else
  echo "Go is already installed."
fi

# --- Set up the Go application ---
APP_DIR="/opt/1of1ping"
mkdir -p "$APP_DIR"

# Check if the Go source file exists in the current directory.
SOURCE_FILE="./main.go"
if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: $SOURCE_FILE not found. Please ensure your Go source file is in the current directory."
  exit 1
fi

echo "Copying Go application source code from 1of1ping.go to $APP_DIR/main.go..."
cp "$SOURCE_FILE" "$APP_DIR/main.go"

# Substitute the placeholder {{APP_PORT}} with the actual port.
sed -i "s/{{APP_PORT}}/${APP_PORT}/g" "$APP_DIR/main.go"

# --- Build the Go application ---
echo "Compiling the Go application..."
cd "$APP_DIR"
go build -o 1of1ping

# Move the compiled binary to /usr/local/bin
echo "Installing the Go binary to /usr/local/bin..."
mv 1of1ping /usr/local/bin/1of1ping

# --- Create a systemd service for the Go application ---
SERVICE_FILE="/etc/systemd/system/1of1ping.service"
echo "Creating systemd service file at $SERVICE_FILE..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Go Ping Server (1of1ping)
After=network.target

[Service]
ExecStart=/usr/local/bin/1of1ping
Restart=always
User=root
WorkingDirectory=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration, enable and start the service.
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting the 1of1ping service..."
systemctl enable 1of1ping
systemctl start 1of1ping

echo "Installation complete."
echo "Caddy is configured for domain $DOMAIN and reverse proxies to localhost:$APP_PORT."
echo "The Go ping server (1of1ping) is running as a systemd service."