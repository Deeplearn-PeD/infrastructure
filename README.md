# Kwar-AI Infrastructure

Complete infrastructure as code (IaC) deployment for Kwar-AI services using OpenTofu (Terraform) and Ansible on Hetzner Cloud.

## 🎯 Overview

This repository contains the infrastructure code to deploy and manage two AI-powered services:

- **EpidBot**: AI assistant for Brazilian public health data (DATASUS)
- **Libby Server**: RAG (Retrieval-Augmented Generation) document embedding and retrieval system

### Architecture

This infrastructure uses a **hybrid deployment strategy**:

- **Main website** (`kwar-ai.com.br`) → GitHub Pages (separate repository)
- **Applications** (`*.kwar-ai.com.br`) → Hetzner Cloud (this repository)

```
┌─────────────────────────────────────────────────────────┐
│                  kwar-ai.com.br                          │
│              (GitHub Pages - Separate)                   │
│                   185.199.111.153                        │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Separate Infrastructure
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Hetzner Cloud Server CX43 (This Repo)            │
│              (8 vCPU, 16GB RAM, Helsinki)                │
│                                                            │
│  ┌──────────────────────────────────────────────┐       │
│  │   Nginx Reverse Proxy (443)                  │       │
│  │   - Let's Encrypt SSL                        │       │
│  │   - Rate limiting                            │       │
│  └──────┬───────────────────────┬──────────────┘       │
│         │                      │                        │
│  ┌──────▼──────┐         ┌────▼──────────┐            │
│  │  EpidBot    │         │    Libby      │            │
│  │  (7860)     │         │   (8000)      │            │
│  │  Gradio UI  │         │   RAG API     │            │
│  └─────────────┘         └───┬───────────┘            │
│                              │                          │
│                 ┌────────────┼────────────┐            │
│                 │            │            │            │
│           ┌─────▼────┐ ┌────▼─────┐ ┌───▼──────┐      │
│           │PostgreSQL│ │  Ollama  │ │Prometheus│      │
│           │pgvector  │ │   LLM    │ │ Grafana  │      │
│           └──────────┘ └──────────┘ └──────────┘      │
│                                                        │
│  Deployed via: GitHub Actions (This Repository)        │
└────────────────────────────────────────────────────────┘

GitHub Actions Workflow:
  Push → Validate → Deploy to Hetzner → Health Check
  (Does NOT touch GitHub Pages website)
```

## 🚀 Features

- ✅ **Infrastructure as Code**: Complete infrastructure defined in OpenTofu/Terraform
- ✅ **Automated Deployment**: One-command deployment with Ansible
- ✅ **SSL/TLS**: Automatic Let's Encrypt certificate management
- ✅ **Monitoring**: Prometheus + Grafana for metrics and dashboards
- ✅ **Alerting**: Email alerts for critical issues
- ✅ **Backups**: Automated daily backups with retention policy
- ✅ **Security**: Firewall, fail2ban, SSH hardening
- ✅ **CI/CD**: GitHub Actions for automated deployments
- ✅ **Cost-Effective**: ~€20/month on Hetzner Cloud

## 📋 Prerequisites

### Required

- **Hetzner Cloud Account**: [Sign up here](https://hetzner.com/cloud)
- **Domain Name**: Configured with DNS management
- **OpenTofu**: [Install guide](https://opentofu.org/docs/intro/install/)
- **Ansible**: `pip install ansible`
- **SSH Key**: For server access

### Optional

- **API Keys**: 
  - OpenAI API key
  - Google Gemini API key
  - ZhipuAI API key
  - DeepSeek API key

## 🛠️ Quick Start

> **📍 IMPORTANT**: All steps in this Quick Start guide are executed on your **LOCAL DEVELOPMENT MACHINE** (your computer).
> 
> OpenTofu and Ansible will automatically configure the **REMOTE HETZNER SERVER** for you. You do NOT need to manually SSH into the server for deployment.
>
> **Execution Location Key:**
> - 💻 **LOCAL**: Run on your development machine
> - 🖥️ **REMOTE**: Automatically executed on Hetzner server (via cloud-init or Ansible)

### 1. Clone the Repository 💻

**Execute on: Local Machine**

```bash
git clone https://github.com/your-org/kwarai-infra.git
cd kwarai-infra
```

### 2. Configure Hetzner API Token 💻

**Execute on: Local Machine**

```bash
./scripts/setup-hetzner-api.sh
```

Follow the prompts to create and configure your Hetzner Cloud API token.

This script will:
- Guide you through creating a Hetzner API token
- Create `terraform.tfvars` file with your token

### 3. Configure Variables 💻

**Execute on: Local Machine**

Edit `terraform.tfvars` and set required variables:

```bash
# Required - Generate secure values
openssl rand -base64 32  # For passwords
openssl rand -hex 32     # For secret keys
```

Key variables to set:
- `postgres_password`: PostgreSQL database password
- `secret_key`: Application secret key
- `grafana_admin_password`: Grafana admin password
- `openai_api_key`: Your OpenAI API key (optional)
- `gemini_api_key`: Your Gemini API key (optional)

### 4. Deploy Infrastructure 💻 → 🖥️

**Execute on: Local Machine** (deploys to Remote Server)

```bash
./scripts/deploy.sh
```

This command will:
1. **LOCAL**: Initialize OpenTofu
2. **LOCAL**: Create execution plan
3. **REMOTE**: Create Hetzner Cloud server (CX43) in Helsinki
4. **REMOTE**: Attach storage volumes (200GB total)
5. **REMOTE**: Configure firewall (via Hetzner API)
6. **REMOTE**: Execute cloud-init for initial setup (Docker, firewall, security)
7. **LOCAL**: Generate Ansible inventory with server IP

### 5. Configure DNS 💻

**Execute on: Local Machine** (configure your DNS provider)

Add A records to your domain:

```
epidbot.kwar-ai.com.br    A    <SERVER_IP>
libby.kwar-ai.com.br      A    <SERVER_IP>
grafana.kwar-ai.com.br    A    <SERVER_IP>
```

Note: You'll get the `<SERVER_IP>` from the output of step 4.

### 6. Deploy Services 💻 → 🖥️

**Execute on: Local Machine** (configures Remote Server via Ansible)

Wait for DNS propagation (5-30 minutes), then:

```bash
./scripts/deploy-services.sh
```

This command will connect to your server and **REMOTELY** execute:
1. Install Docker and Docker Compose (if not already installed)
2. Configure Nginx with SSL certificates (Let's Encrypt)
3. Deploy Libby server with PostgreSQL and Ollama
4. Deploy EpidBot application
5. Set up Prometheus + Grafana monitoring stack
6. Configure automatic backups
7. Start all services with health checks

All of this happens **automatically on the remote server** via Ansible.

### 7. Verify Deployment 💻

**Execute on: Local Machine**

```bash
./scripts/healthcheck.sh
```

Access your services:
- **EpidBot**: https://epidbot.kwar-ai.com.br
- **Libby API**: https://libby.kwar-ai.com.br
- **Grafana**: https://grafana.kwar-ai.com.br

## 📁 Project Structure

```
kwarai-infra/
├── main.tf                    # Main infrastructure orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── terraform.tfvars.example   # Example configuration
│
├── modules/
│   ├── server/                # Hetzner server + cloud-init
│   ├── network/               # Firewall rules
│   ├── volumes/               # Persistent storage
│   └── monitoring/            # Prometheus/Grafana
│
├── ansible/
│   ├── playbook.yml           # Main deployment playbook
│   ├── inventory.ini          # Server inventory
│   ├── group_vars/            # Ansible variables
│   └── roles/
│       ├── docker/            # Docker installation
│       ├── nginx/             # Reverse proxy + SSL
│       ├── libby/             # Libby server
│       ├── epidbot/           # EpidBot application
│       └── monitoring/        # Monitoring stack
│
├── scripts/
│   ├── setup-hetzner-api.sh   # API token setup helper
│   ├── deploy.sh              # Infrastructure deployment
│   ├── deploy-services.sh     # Service deployment
│   ├── healthcheck.sh         # Health monitoring
│   ├── backup.sh              # Backup automation
│   └── destroy.sh             # Infrastructure cleanup
│
└── .github/
    └── workflows/
        ├── deploy.yml         # CI/CD deployment
        └── destroy.yml        # Infrastructure cleanup
```

## 🔧 Configuration

### Environment Variables

All services are configured via environment variables in `terraform.tfvars`:

```hcl
# Server Configuration
server_name   = "kwar-ai-server"
server_type   = "cx43"
location      = "hel1"

# Domain Configuration
domain_name       = "kwar-ai.com.br"
epidbot_subdomain = "epidbot.kwar-ai.com.br"
libby_subdomain   = "libby.kwar-ai.com.br"
grafana_subdomain = "grafana.kwar-ai.com.br"

# Database
postgres_db       = "libby"
postgres_user     = "libby"
postgres_password = "<GENERATE_SECURE_PASSWORD>"

# Security
secret_key = "<GENERATE_RANDOM_SECRET>"

# API Keys (optional)
openai_api_key   = "sk-..."
gemini_api_key   = "..."
zhipu_api_key    = "..."
deepseek_api_key = "..."

# Monitoring
enable_monitoring      = true
grafana_admin_password = "<GENERATE_PASSWORD>"
```

### SSL Certificates

Certificates are automatically obtained and renewed via Let's Encrypt/Certbot:

- Automatic certificate issuance during deployment
- Automatic renewal every month via cron
- Certificates stored in `/opt/kwar-ai/nginx/ssl/`

## 📊 Monitoring

### Grafana Dashboards

Access Grafana at: https://grafana.kwar-ai.com.br

Default credentials:
- Username: `admin`
- Password: Set in `terraform.tfvars`

Pre-configured dashboards:
- System metrics (CPU, memory, disk)
- Docker container metrics
- Application-specific metrics
- SSL certificate expiry

### Prometheus Metrics

Prometheus scrapes metrics from:
- Node Exporter (system metrics)
- cAdvisor (container metrics)
- Docker daemon
- Application endpoints

### Alerts

Alerts are configured for:
- High CPU usage (>80%)
- High memory usage (>85%)
- Low disk space (<15%)
- Container down
- SSL certificate expiry
- Service health check failures

Alerts are sent via email to the configured `admin_email`.

## 💾 Backup & Recovery

### Automated Backups

Backups run daily at 2 AM UTC and include:
- PostgreSQL database dump
- Libby data directory
- EpidBot data directory
- Docker volumes

Retention: 7 days by default

### Manual Backup 💻

**Execute on: Local Machine**

```bash
./scripts/backup.sh
```

This script will:
1. Connect to the remote server via SSH
2. Create backups of PostgreSQL, Libby, and EpidBot data
3. Download backups to your local machine in `./backups/` directory

Backups are stored locally in `./backups/` directory.

### Recovery 💻 → 🖥️

**Execute on: Local Machine** (applies to Remote Server)

To restore from backup, you'll need to SSH into the server:

```bash
# SSH into server (from local machine)
ssh root@<SERVER_IP>

# On the REMOTE SERVER, stop services
cd /opt/kwar-ai/libby && docker-compose down
cd /opt/kwar-ai/epidbot && docker-compose down

# Restore PostgreSQL (on REMOTE SERVER)
gunzip -c /path/to/backup/postgres_backup.sql.gz | \
  docker exec -i libby-postgres psql -U libby

# Restore data directories (on REMOTE SERVER)
tar -xzf /path/to/backup/libby_data.tar.gz -C /opt/kwar-ai/libby
tar -xzf /path/to/backup/epidbot_data.tar.gz -C /opt/kwar-ai/epidbot

# Start services (on REMOTE SERVER)
docker-compose up -d
```

## 🚀 CI/CD Pipeline

### Automatic Deployment

Push to `main` branch triggers:

1. **Validate**: OpenTofu format and validation
2. **Plan**: Generate execution plan
3. **Apply**: Deploy infrastructure changes
4. **Configure**: Run Ansible playbook
5. **Deploy**: Update Docker services
6. **Verify**: Health checks

### Required GitHub Secrets

Set these secrets in your GitHub repository:

```
HCLOUD_TOKEN              - Hetzner Cloud API token
SSH_PRIVATE_KEY           - SSH private key for server access
ADMIN_EMAIL               - Admin email address
POSTGRES_PASSWORD         - PostgreSQL password
SECRET_KEY                - Application secret key
GRAFANA_ADMIN_PASSWORD    - Grafana admin password
OPENAI_API_KEY           - OpenAI API key
GEMINI_API_KEY           - Gemini API key
ZHIPU_API_KEY            - ZhipuAI API key
DEEPSEEK_API_KEY         - DeepSeek API key
GITHUB_CLIENT_ID         - GitHub OAuth client ID
GITHUB_CLIENT_SECRET     - GitHub OAuth client secret
```

### Manual Deployment

Trigger deployment from GitHub Actions:
1. Go to Actions tab
2. Select "Deploy Infrastructure" workflow
3. Click "Run workflow"

## 🔒 Security

### Firewall Rules

Inbound traffic allowed only on:
- Port 22 (SSH)
- Port 80 (HTTP - redirects to HTTPS)
- Port 443 (HTTPS)

All other inbound traffic is blocked.

### SSH Hardening

- Password authentication disabled
- SSH key-only authentication
- Fail2ban for brute-force protection
- Root login with SSH key only

### SSL/TLS

- TLS 1.2 and 1.3 only
- Modern cipher suites
- HSTS enabled
- Automatic certificate renewal

### Application Security

- Secrets stored in environment variables
- No secrets in code repository
- Rate limiting on API endpoints
- Security headers in Nginx

## 💰 Cost Estimation

Monthly costs on Hetzner Cloud:

| Resource | Type | Cost |
|----------|------|------|
| Server | CX43 (8 vCPU, 16GB) | €15.60 |
| Storage | 200GB volumes | €4.80 |
| Traffic | 10TB included | €0.00 |
| **Total** | | **€20.40/month** |

## 🛠️ Troubleshooting

### Common Issues

#### 1. SSH Connection Refused 💻

**Execute on: Local Machine**

```bash
# Check if server is running
tofu show | grep status

# Verify SSH key
ssh -i ./ssh_keys/kwar-ai-ssh-key root@<SERVER_IP>
```

#### 2. SSL Certificate Error 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

```bash
# SSH into server
ssh root@<SERVER_IP>

# On REMOTE SERVER: Check certificate files
ls -la /opt/kwar-ai/nginx/ssl/

# On REMOTE SERVER: Renew certificates manually
certbot renew --force-renewal
```

#### 3. Service Not Responding 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

```bash
# SSH into server
ssh root@<SERVER_IP>

# On REMOTE SERVER: Check container status
docker ps -a

# On REMOTE SERVER: View logs
docker logs libby-api
docker logs epidbot

# On REMOTE SERVER: Restart services
cd /opt/kwar-ai/libby && docker-compose restart
cd /opt/kwar-ai/epidbot && docker-compose restart
```

#### 4. Database Connection Error 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

```bash
# SSH into server
ssh root@<SERVER_IP>

# On REMOTE SERVER: Check PostgreSQL status
docker exec libby-postgres pg_isready

# On REMOTE SERVER: Check database logs
docker logs libby-postgres

# On REMOTE SERVER: Reset database (WARNING: destroys data)
docker exec libby-postgres psql -U libby -c "DROP DATABASE libby;"
docker exec libby-postgres psql -U libby -c "CREATE DATABASE libby;"
```

### Logs 💻 → 🖥️

**Execute on: Local Machine** (commands run on Remote Server)

View logs by SSHing into the server:

```bash
# SSH into server
ssh root@<SERVER_IP>

# On REMOTE SERVER: View all services
docker-compose logs -f

# On REMOTE SERVER: View specific service
docker logs -f libby-api
docker logs -f epidbot
docker logs -f nginx-proxy

# On REMOTE SERVER: View system logs
journalctl -u docker
```

## 📚 Additional Resources

- **[GitHub Actions CI/CD Guide](GITHUB_ACTIONS.md)** - Complete documentation of the automated deployment pipeline
- [Quick Start Guide](QUICKSTART.md) - 30-minute deployment guide
- [Changelog](CHANGELOG.md) - Version history and updates
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [Issues](https://github.com/your-org/kwarai-infra/issues)
3. Create a new issue if needed

## 🗺️ Roadmap

- [ ] Add support for multiple environments (dev, staging, prod)
- [ ] Implement blue-green deployment strategy
- [ ] Add Kubernetes support
- [ ] Multi-region deployment
- [ ] Enhanced monitoring with custom metrics
- [ ] Automated disaster recovery
- [ ] Cost optimization scripts

---

**Built with ❤️ using OpenTofu, Ansible, and Docker**
