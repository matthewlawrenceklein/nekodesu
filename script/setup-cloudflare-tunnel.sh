#!/bin/bash
set -e

echo "🌐 Setting up Cloudflare Tunnel for Nekodesu..."

# Install cloudflared if not present
if ! command -v cloudflared &> /dev/null; then
    echo "📦 Installing cloudflared..."
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    echo "✅ cloudflared installed"
else
    echo "✅ cloudflared already installed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Cloudflare Tunnel Setup Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option 1: Use Cloudflare Dashboard (Recommended)"
echo "────────────────────────────────────────────────────────"
echo "1. Go to https://one.dash.cloudflare.com/"
echo "2. Select your domain"
echo "3. Go to 'Traffic' → 'Cloudflare Tunnel'"
echo "4. Click 'Create a tunnel'"
echo "5. Name it 'nekodesu' and save"
echo "6. Copy the tunnel token"
echo "7. Add it to /opt/nekodesu/.env.production:"
echo "   CLOUDFLARE_TUNNEL_TOKEN=your_token_here"
echo "8. In the tunnel configuration, add a public hostname:"
echo "   - Subdomain: your-subdomain"
echo "   - Domain: your-domain.com"
echo "   - Service: http://web:80"
echo ""
echo "Option 2: Use CLI (Advanced)"
echo "────────────────────────────────────────────────────────"
echo "Run the following commands:"
echo ""
echo "# Authenticate with Cloudflare"
echo "cloudflared tunnel login"
echo ""
echo "# Create tunnel"
echo "cloudflared tunnel create nekodesu"
echo ""
echo "# Get tunnel ID"
echo "cloudflared tunnel list"
echo ""
echo "# Route DNS (replace with your subdomain and domain)"
echo "cloudflared tunnel route dns nekodesu your-subdomain.your-domain.com"
echo ""
echo "# Get tunnel token"
echo "cloudflared tunnel token nekodesu"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After setup, add the tunnel token to .env.production and run:"
echo "  cd /opt/nekodesu && ./script/deploy.sh"
echo ""
