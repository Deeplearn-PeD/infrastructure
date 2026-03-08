# Quick Start Guide

Get Kwar-AI infrastructure up and running in 30 minutes.

> **📍 IMPORTANT**: All steps in this guide are executed on your **LOCAL DEVELOPMENT MACHINE** (your computer).
> 
> OpenTofu and Ansible will automatically configure the **REMOTE HETZNER SERVER** for you. You do NOT need to manually SSH into the server for deployment.

## Prerequisites Check 💻

**Execute on: Local Machine**

```bash
# Check OpenTofu
tofu version

# Check Ansible
ansible --version

# Check SSH key
ls -la ~/.ssh/id_rsa.pub
```

## 5-Step Deployment

### Step 1: Setup Hetzner API (2 minutes) 💻

**Execute on: Local Machine**

```bash
./scripts/setup-hetzner-api.sh
```

This will:
- Guide you through creating a Hetzner API token
- Create `terraform.tfvars` with your token

### Step 2: Configure Secrets (5 minutes) 💻

**Execute on: Local Machine**

Edit `terraform.tfvars` and set these required values:

```bash
# Generate secure passwords
openssl rand -base64 32  # Run this 3 times

# Update terraform.tfvars with generated values:
# - postgres_password
# - secret_key
# - grafana_admin_password
```

Optional: Add API keys if you have them:
- `openai_api_key`
- `gemini_api_key`
- `zhipu_api_key`
- `deepseek_api_key`

### Step 3: Deploy Infrastructure (10 minutes) 💻 → 🖥️

**Execute on: Local Machine** (deploys to Remote Server)

```bash
./scripts/deploy.sh
```

This creates on the **REMOTE SERVER**:
- Hetzner CX43 server (Helsinki)
- 200GB storage volumes
- Firewall rules
- SSH keys
- Initial server setup via cloud-init

**Note the server IP address from the output.**

### Step 4: Configure DNS (2 minutes) 💻

**Execute on: Local Machine** (configure your DNS provider)

Add these A records to your domain (kwar-ai.com.br):

```
Type: A
Name: epidbot
Value: <SERVER_IP>
TTL: 300

Type: A
Name: libby
Value: <SERVER_IP>
TTL: 300

Type: A
Name: grafana
Value: <SERVER_IP>
TTL: 300
```

### Step 5: Deploy Services (10 minutes) 💻 → 🖥️

**Execute on: Local Machine** (configures Remote Server via Ansible)

Wait 5-10 minutes for DNS propagation, then:

```bash
./scripts/deploy-services.sh
```

This will connect to your server and **REMOTELY** install:
- Docker and Docker Compose
- Nginx with SSL (Let's Encrypt)
- Libby server (PostgreSQL + Ollama)
- EpidBot application
- Prometheus + Grafana monitoring

All of this happens **automatically on the remote server** via Ansible.

## Verify Deployment 💻

**Execute on: Local Machine**

```bash
./scripts/healthcheck.sh
```

Access your services:
- **EpidBot**: https://epidbot.kwar-ai.com.br
- **Libby API**: https://libby.kwar-ai.com.br/api/health
- **Grafana**: https://grafana.kwar-ai.com.br

## Common Commands 💻 → 🖥️

**Execute on: Local Machine** (unless noted otherwise)

```bash
# SSH into server (from local machine)
ssh -i ./ssh_keys/kwar-ai-ssh-key root@<SERVER_IP>

# Once on the REMOTE SERVER, you can run:
docker logs -f epidbot
docker logs -f libby-api
docker logs -f nginx-proxy

# Restart services (on REMOTE SERVER)
cd /opt/kwar-ai/epidbot && docker-compose restart
cd /opt/kwar-ai/libby && docker-compose restart

# Back to LOCAL MACHINE:
# Create backup
./scripts/backup.sh

# Health check
./scripts/healthcheck.sh
```
## Troubleshooting

### DNS Not Propagating 💻

**Execute on: Local Machine**

```bash
# Check DNS
dig epidbot.kwar-ai.com.br
nslookup epidbot.kwar-ai.com.br

# Wait longer (up to 30 minutes)
```

### SSL Certificate Issues 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

```bash
# SSH into server (from local machine)
ssh root@<SERVER_IP>

# On REMOTE SERVER: Check certificates
ls -la /opt/kwar-ai/nginx/ssl/

# On REMOTE SERVER: Force renewal
certbot renew --force-renewal
docker restart nginx-proxy
```

### Services Not Starting 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

```bash
# SSH into server (from local machine)
ssh root@<SERVER_IP>

# On REMOTE SERVER: Check container status
docker ps -a

# On REMOTE SERVER: View logs
docker logs libby-api
docker logs epidbot
docker logs libby-postgres

# On REMOTE SERVER: Restart all services
docker-compose -f /opt/kwar-ai/libby/docker-compose.yml restart
docker-compose -f /opt/kwar-ai/epidbot/docker-compose.yml restart
```

## Next Steps

1. **Configure Grafana**: Login and explore dashboards
2. **Initialize Libby**: Add documents to knowledge base
3. **Test EpidBot**: Start chatting with the assistant
4. **Set up CI/CD**: Configure GitHub secrets for automated deployments
5. **Monitor**: Check Grafana dashboards regularly
6. **Backup**: Verify automated backups are running

## Getting Help

- **Documentation**: See [README.md](README.md)
- **Issues**: Check [GitHub Issues](https://github.com/your-org/kwarai-infra/issues)
- **Logs**: Always check logs first with `docker logs <container_name>`

---

**Estimated total time: 30 minutes**
