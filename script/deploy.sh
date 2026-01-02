#!/bin/bash
set -e

echo "🚀 Deploying Nekodesu to production..."

# Check if we're in the right directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ Error: docker-compose.prod.yml not found"
    echo "   Please run this script from /opt/nekodesu"
    exit 1
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo "❌ Error: .env.production not found"
    echo "   Please create it from .env.production.example"
    exit 1
fi

# Load environment variables
echo "📋 Loading environment variables..."
set -a
source .env.production
set +a

# Validate required environment variables
REQUIRED_VARS=("POSTGRES_PASSWORD" "RAILS_MASTER_KEY" "SECRET_KEY_BASE" "GITHUB_REPOSITORY" "CLOUDFLARE_TUNNEL_TOKEN")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env.production"
        exit 1
    fi
done

# Login to GitHub Container Registry
echo "🔐 Logging in to GitHub Container Registry..."
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_USER" ]; then
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
else
    echo "⚠️  GITHUB_TOKEN or GITHUB_USER not set, skipping login"
    echo "   If image pull fails, add GITHUB_TOKEN and GITHUB_USER to .env.production"
fi

# Pull latest images
echo "📦 Pulling latest Docker images..."
docker compose -f docker-compose.prod.yml pull

# Create database if it doesn't exist
echo "🗄️  Ensuring database exists..."
docker compose -f docker-compose.prod.yml up -d db
sleep 5

# Run database migrations
echo "🗄️  Running database migrations..."
docker compose -f docker-compose.prod.yml run --rm web bin/rails db:create db:migrate

# Restart all services
echo "🔄 Restarting services..."
docker compose -f docker-compose.prod.yml up -d --remove-orphans

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 15

# Check service health
echo "🏥 Checking service health..."
if docker compose -f docker-compose.prod.yml ps | grep -q "unhealthy"; then
    echo "⚠️  Warning: Some services may be unhealthy"
    docker compose -f docker-compose.prod.yml ps
    echo ""
    echo "Check logs with: docker compose -f docker-compose.prod.yml logs"
else
    echo "✅ All services are healthy"
fi

# Show running services
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Running Services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose -f docker-compose.prod.yml ps

# Clean up old images
echo ""
echo "🧹 Cleaning up old Docker images..."
docker image prune -af --filter "until=72h"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "View logs:        docker compose -f docker-compose.prod.yml logs -f"
echo "View web logs:    docker compose -f docker-compose.prod.yml logs -f web"
echo "View worker logs: docker compose -f docker-compose.prod.yml logs -f worker"
echo "Rails console:    docker compose -f docker-compose.prod.yml exec web bin/rails console"
echo "Restart services: docker compose -f docker-compose.prod.yml restart"
echo "Stop services:    docker compose -f docker-compose.prod.yml down"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
