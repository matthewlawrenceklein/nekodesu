#!/bin/bash
set -e

echo "🖥️  Setting up Hetzner server for Nekodesu..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    sudo apt-get install docker-compose-plugin -y
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install git if not present
if ! command -v git &> /dev/null; then
    echo "📦 Installing git..."
    sudo apt-get install -y git
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/nekodesu
sudo chown $USER:$USER /opt/nekodesu
cd /opt/nekodesu

# Clone repository (if not already cloned)
if [ ! -d ".git" ]; then
    echo "📥 Cloning repository..."
    REPO_URL="https://github.com/matthewlawrenceklein/nekodesu.git"
    git clone $REPO_URL .
else
    echo "✅ Repository already cloned"
fi

# Create .env.production file from example
if [ ! -f ".env.production" ]; then
    echo "📝 Creating .env.production file..."
    cp .env.production.example .env.production
    echo "⚠️  IMPORTANT: Edit /opt/nekodesu/.env.production with your actual values"
    echo "   Run: nano /opt/nekodesu/.env.production"
else
    echo "✅ .env.production already exists"
fi

# Setup log rotation
echo "📋 Setting up log rotation..."
sudo tee /etc/logrotate.d/nekodesu > /dev/null <<EOF
/opt/nekodesu/log/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Create systemd service for auto-restart on boot (optional)
echo "🔄 Creating systemd service..."
sudo tee /etc/systemd/system/nekodesu.service > /dev/null <<EOF
[Unit]
Description=Nekodesu Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nekodesu
EnvironmentFile=/opt/nekodesu/.env.production
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nekodesu.service

echo ""
echo "✅ Server setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Edit production environment file:"
echo "   nano /opt/nekodesu/.env.production"
echo ""
echo "2. Generate Rails secrets:"
echo "   docker run --rm ghcr.io/matthewlawrenceklein/nekodesu:latest rails secret"
echo ""
echo "3. Setup Cloudflare Tunnel:"
echo "   cd /opt/nekodesu && ./script/setup-cloudflare-tunnel.sh"
echo ""
echo "4. Deploy the application:"
echo "   cd /opt/nekodesu && ./script/deploy.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
