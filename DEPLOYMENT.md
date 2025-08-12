# Deployment Guide

This document covers production deployment of SocialCircle to Fly.io with custom domain configuration.

## 🚀 Fly.io Deployment

SocialCircle is configured for deployment to [Fly.io](https://fly.io) with custom domain **social.qingbo.us**.

### Prerequisites

- [Fly CLI](https://fly.io/docs/flyctl/) installed
- Fly.io account with billing enabled
- Domain ownership (qingbo.us)

### Initial Setup

1. **Install Fly CLI:**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to Fly:**
   ```bash
   flyctl auth login
   ```

3. **Deploy the application:**
   ```bash
   flyctl deploy
   ```

### Custom Domain Configuration

After successful deployment, configure the custom domain `social.qingbo.us`:

#### Step 1: Add SSL Certificate
```bash
# Add SSL certificate for custom domain
flyctl certs add social.qingbo.us

# Check certificate status (may take a few minutes)
flyctl certs show social.qingbo.us
```

#### Step 2: Get IP Addresses
```bash
# Get your app's assigned IP addresses
flyctl ips list
```

This will show something like:
```
VERSION IP               TYPE             REGION CREATED AT            
v6      2a09:8280:1::     global           -      2025-08-11T21:42:14Z  
v4      66.241.125.100   global           -      2025-08-11T21:42:14Z  
```

#### Step 3: Configure DNS

Configure your DNS provider (where you manage qingbo.us) with these records:

1. **A Record:**
   - Host: `social`
   - Value: `66.241.125.100` (IPv4 from step 2)
   - TTL: 300

2. **AAAA Record:**
   - Host: `social`
   - Value: `2a09:8280:1::` (IPv6 from step 2)
   - TTL: 300

#### Step 4: Verify Setup

```bash
# Check DNS propagation (may take up to 24 hours)
dig social.qingbo.us
dig AAAA social.qingbo.us

# Verify SSL certificate
flyctl certs check social.qingbo.us
```

### Environment Variables

Configure production secrets in Fly.io:

```bash
# Database URL (automatically configured)
flyctl secrets set DATABASE_URL="ecto://..."

# Secret key base (generate with: mix phx.gen.secret)
flyctl secrets set SECRET_KEY_BASE="your-secret-key-base"

# Coveralls token for coverage reporting
flyctl secrets set COVERALLS_REPO_TOKEN="your-coveralls-token"

# View all secrets
flyctl secrets list
```

### Monitoring & Logs

```bash
# View application logs
flyctl logs

# Monitor application status
flyctl status

# Scale application (if needed)
flyctl scale count 2

# View metrics
flyctl metrics
```

### Database Management

```bash
# Run database migrations
flyctl ssh console -C "/app/bin/migrate"

# Connect to production database
flyctl postgres connect -a social-circle-db

# Create database backup
flyctl postgres backup create -a social-circle-db
```

### Deployment Workflow

The application uses GitHub Actions for CI/CD:

1. **Push to main branch** triggers automatic deployment
2. **Tests run** with coverage reporting to Coveralls
3. **Assets build** (Tailwind CSS + esbuild)
4. **Deploy to Fly.io** (if tests pass)

### Rollback

If you need to rollback a deployment:

```bash
# List recent releases
flyctl releases

# Rollback to previous release
flyctl deploy --image registry.fly.io/social-circle:deployment-[PREVIOUS_ID]
```

### Cost Optimization

```bash
# Stop app when not in use
flyctl apps stop social-circle

# Start app when needed
flyctl apps start social-circle

# Configure auto-stop/start in fly.toml:
# auto_stop_machines = 'stop'
# auto_start_machines = true
# min_machines_running = 0
```

### Troubleshooting

#### SSL Certificate Issues
```bash
# Check certificate details
flyctl certs show social.qingbo.us

# Remove and re-add certificate
flyctl certs remove social.qingbo.us
flyctl certs add social.qingbo.us
```

#### Application Won't Start
```bash
# Check logs for errors
flyctl logs

# SSH into machine for debugging
flyctl ssh console

# Check resource usage
flyctl metrics
```

#### DNS Issues
```bash
# Test DNS resolution
nslookup social.qingbo.us
dig +trace social.qingbo.us

# Check from different locations
curl -I https://social.qingbo.us
```

### Security Considerations

- SSL certificates are automatically managed by Fly.io
- All traffic is forced to HTTPS
- Database connections are encrypted
- Secrets are stored securely in Fly.io vault
- Regular security updates via dependabot (GitHub)