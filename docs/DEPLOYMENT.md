# Deployment Guide

This guide covers deploying Nekodesu to production on a Hetzner VPC with Cloudflare Tunnel.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Cloudflare Network                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  your-subdomain.your-domain.com                        │ │
│  └────────────────────┬───────────────────────────────────┘ │
└─────────────────────────┼───────────────────────────────────┘
                          │ Cloudflare Tunnel
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Hetzner VPC Server                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ cloudflared  │  │  Rails Web   │  │  GoodJob     │     │
│  │  Container   │─▶│  Container   │  │  Worker      │     │
│  └──────────────┘  └──────┬───────┘  └──────┬───────┘     │
│                            │                  │              │
│                            └──────┬───────────┘              │
│                                   ▼                          │
│                          ┌──────────────┐                    │
│                          │  PostgreSQL  │                    │
│                          │   Database   │                    │
│                          └──────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Hetzner VPC server (Ubuntu 22.04 or later recommended)
- SSH access to the server
- GitHub account with repository access
- Cloudflare account with domain managed by Cloudflare
- `config/master.key` file (Rails credentials)

## Initial Server Setup

### 1. SSH into Your Hetzner Server

```bash
ssh root@YOUR_HETZNER_IP
```

### 2. Run Server Setup Script

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nekodesu/main/script/server-setup.sh | bash

# Or if you've already cloned the repo:
cd /opt/nekodesu
./script/server-setup.sh
```

This script will:
- Install Docker and Docker Compose
- Clone the repository to `/opt/nekodesu`
- Create `.env.production` from template
- Setup log rotation
- Create systemd service for auto-start on boot

### 3. Configure Environment Variables

Edit the production environment file:

```bash
nano /opt/nekodesu/.env.production
```

Required variables:

```bash
# Database Configuration
POSTGRES_USER=nekodesu
POSTGRES_PASSWORD=your_strong_password_here
POSTGRES_DB=nekodesu_production

# Rails Configuration
RAILS_MASTER_KEY=your_master_key_from_config_master_key
SECRET_KEY_BASE=generate_with_rails_secret

# Docker Image
GITHUB_REPOSITORY=your-username/nekodesu
IMAGE_TAG=latest

# Cloudflare Tunnel (will be added after tunnel setup)
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here
```

**Generate SECRET_KEY_BASE:**
```bash
docker run --rm ghcr.io/your-username/nekodesu:latest rails secret
```

**Get RAILS_MASTER_KEY:**
From your local development machine:
```bash
cat config/master.key
```

## Cloudflare Tunnel Setup

### Option 1: Cloudflare Dashboard (Recommended)

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Select your domain
3. Navigate to **Traffic** → **Cloudflare Tunnel**
4. Click **Create a tunnel**
5. Name it `nekodesu` and save
6. Copy the tunnel token
7. Add the token to `/opt/nekodesu/.env.production`:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=your_token_here
   ```
8. In the tunnel configuration, add a **Public Hostname**:
   - **Subdomain**: your-subdomain (e.g., `nekodesu`)
   - **Domain**: your-domain.com
   - **Service**: `http://web:80`
9. Save the configuration

### Option 2: CLI Setup

```bash
cd /opt/nekodesu
./script/setup-cloudflare-tunnel.sh
```

Follow the interactive prompts to:
- Install cloudflared
- Authenticate with Cloudflare
- Create tunnel
- Configure DNS routing
- Get tunnel token

## GitHub Actions Setup

### 1. Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `HETZNER_HOST` | Your Hetzner server IP | `5.78.106.36` |
| `HETZNER_USER` | SSH username | `root` |
| `HETZNER_SSH_KEY` | Private SSH key for server access | Contents of `~/.ssh/id_rsa` |

**Generate SSH Key (if needed):**
```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@YOUR_HETZNER_IP

# Copy private key to GitHub Secrets
cat ~/.ssh/id_ed25519
```

### 2. Enable GitHub Container Registry

The workflow automatically publishes Docker images to GitHub Container Registry (GHCR). Make sure:
- Your repository has **Actions** enabled
- Package visibility is set appropriately (public or private)

### 3. Workflow Triggers

The deployment workflow (`.github/workflows/deploy.yml`) runs on:
- Push to `main` branch
- Manual trigger via **Actions** tab

## Initial Deployment

### 1. Deploy from Server

```bash
cd /opt/nekodesu
./script/deploy.sh
```

This will:
- Pull latest Docker images
- Create database
- Run migrations
- Start all services (web, worker, db, cloudflared)
- Verify health checks

### 2. Verify Deployment

Check services are running:
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml ps
```

View logs:
```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f web
```

### 3. Create First User

```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml exec web bin/rails console
```

In the Rails console:
```ruby
User.create!(email: "your@email.com")
```

### 4. Access Application

Visit your configured subdomain: `https://your-subdomain.your-domain.com`

## Continuous Deployment

Once GitHub Actions is configured, deployments are automatic:

1. Push code to `main` branch
2. GitHub Actions runs tests
3. Builds Docker image and pushes to GHCR
4. SSHs into Hetzner server
5. Pulls latest image
6. Runs migrations
7. Restarts services with zero-downtime

## Maintenance Commands

### View Logs
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml logs -f [service]
```

### Restart Services
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml restart
```

### Run Rails Console
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml exec web bin/rails console
```

### Run Database Migrations
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml run --rm web bin/rails db:migrate
```

### Backup Database
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml exec db pg_dump -U nekodesu nekodesu_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml exec -T db psql -U nekodesu nekodesu_production < backup.sql
```

### Update Application
```bash
cd /opt/nekodesu
git pull origin main
./script/deploy.sh
```

### Stop Services
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml down
```

### Clean Up Old Images
```bash
docker image prune -af --filter "until=72h"
```

## Monitoring

### Health Checks

The application includes health checks:
- Web: `http://localhost:80/up`
- Docker Compose monitors service health automatically

### View Service Status
```bash
cd /opt/nekodesu
docker compose -f docker-compose.prod.yml ps
```

### Check Resource Usage
```bash
docker stats
```

## Troubleshooting

### Services Won't Start

Check logs:
```bash
docker compose -f docker-compose.prod.yml logs
```

Common issues:
- Missing environment variables in `.env.production`
- Database connection issues
- Port conflicts

### Database Connection Errors

Verify database is running:
```bash
docker compose -f docker-compose.prod.yml ps db
```

Check database logs:
```bash
docker compose -f docker-compose.prod.yml logs db
```

### Cloudflare Tunnel Not Working

Check cloudflared logs:
```bash
docker compose -f docker-compose.prod.yml logs cloudflared
```

Verify tunnel token is correct in `.env.production`

### Out of Disk Space

Clean up Docker resources:
```bash
docker system prune -af --volumes
```

Check disk usage:
```bash
df -h
du -sh /var/lib/docker
```

## Security Considerations

1. **Keep secrets secure**: Never commit `.env.production` or `config/master.key`
2. **Use strong passwords**: Generate strong database passwords
3. **SSH key authentication**: Disable password authentication for SSH
4. **Regular updates**: Keep server and Docker images updated
5. **Firewall**: Configure UFW to only allow necessary ports
6. **Backup regularly**: Automate database backups

## Rollback Procedure

If a deployment fails:

1. **Check previous image tags:**
   ```bash
   docker images | grep nekodesu
   ```

2. **Update IMAGE_TAG in .env.production:**
   ```bash
   IMAGE_TAG=main-abc123def456  # Previous working commit SHA
   ```

3. **Redeploy:**
   ```bash
   ./script/deploy.sh
   ```

## Performance Tuning

### Database Connection Pooling

Edit `config/database.yml` to adjust pool size based on your server resources.

### Worker Concurrency

Adjust GoodJob worker concurrency by setting environment variable:
```bash
GOOD_JOB_MAX_THREADS=5
```

### Resource Limits

Add resource limits to `docker-compose.prod.yml` if needed:
```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

## Support

For issues or questions:
- Check logs first
- Review this documentation
- Check GitHub Issues
- Consult Docker and Rails documentation
