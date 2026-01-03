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
echo "📋 Cloudflare Tunnel Setup Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Step 1: Authenticate with Cloudflare"
echo "────────────────────────────────────────────────────────"
echo "Run: cloudflared tunnel login"
echo ""
echo "This will output a URL. Open it in your browser and"
echo "select your domain to authorize cloudflared."
echo ""
echo "Step 2: Create the tunnel"
echo "────────────────────────────────────────────────────────"
echo "Run: cloudflared tunnel create nekodesu"
echo ""
echo "Step 3: Get the tunnel token"
echo "────────────────────────────────────────────────────────"
echo "Run: cloudflared tunnel token nekodesu"
echo ""
echo "Copy the token and add it to /opt/nekodesu/.env.production:"
echo "  CLOUDFLARE_TUNNEL_TOKEN=your_actual_token_here"
echo ""
echo "Step 4: Route DNS to the tunnel"
echo "────────────────────────────────────────────────────────"
echo "Run: cloudflared tunnel route dns nekodesu your-subdomain.your-domain.com"
echo ""
echo "Example:"
echo "  cloudflared tunnel route dns nekodesu nekodesu.dogbeach.club"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After completing all steps, deploy the application:"
echo "  cd /opt/nekodesu && ./script/deploy.sh"
echo ""
