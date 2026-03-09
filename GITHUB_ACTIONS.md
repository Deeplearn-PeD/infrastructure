# GitHub Actions CI/CD Documentation

This document explains how the automated deployment pipeline works for the Kwar-AI infrastructure.

## 🏗️ Architecture Overview

### Hybrid Deployment Strategy

```
┌─────────────────────────────────────────────────────────┐
│                  kwar-ai.com.br                          │
│              (GitHub Pages - Static Site)                │
│                   185.199.111.153                        │
│                                                           │
│  Deployed via: Separate GitHub repository                │
│  Workflow: Independent GitHub Pages deployment           │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Separate Infrastructure
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Hetzner Server (204.168.149.153)                 │
│                                                           │
│  ├─ epidbot.kwar-ai.com.br (Gradio App)                 │
│  ├─ libby.kwar-ai.com.br (RAG API)                      │
│  └─ grafana.kwar-ai.com.br (Monitoring)                 │
│                                                           │
│  Deployed via: This repository's GitHub Actions         │
│  Workflow: .github/workflows/deploy.yml                 │
└─────────────────────────────────────────────────────────┘
```

### What Gets Deployed Where

| Component | Domain | Infrastructure | Deployment Method |
|-----------|--------|----------------|-------------------|
| **Main Website** | `kwar-ai.com.br` | GitHub Pages | Separate repository workflow |
| **EpidBot** | `epidbot.kwar-ai.com.br` | Hetzner Cloud | This workflow |
| **Libby API** | `libby.kwar-ai.com.br` | Hetzner Cloud | This workflow |
| **Grafana** | `grafana.kwar-ai.com.br` | Hetzner Cloud | This workflow |

## 🔄 GitHub Actions Workflow

### Workflow File: `.github/workflows/deploy.yml`

#### **Triggers**

The workflow automatically runs on:

1. **Push to main branch** → Full deployment
2. **Pull requests** → Validation and planning only
3. **Manual trigger** → Via GitHub UI (workflow_dispatch)

#### **Workflow Jobs**

##### **Job 1: Validate** (Always runs)

```yaml
Purpose: Validate OpenTofu configuration
Steps:
  - Checkout code
  - Setup OpenTofu 1.6.0
  - Check code formatting (tofu fmt)
  - Initialize OpenTofu
  - Validate configuration
```

##### **Job 2: Plan** (Pull Requests only)

```yaml
Purpose: Show what changes will be made
Steps:
  - Create terraform.tfvars from secrets
  - Initialize OpenTofu
  - Generate execution plan
  - Post plan as PR comment
```

##### **Job 3: Apply** (Push to main only)

```yaml
Purpose: Deploy infrastructure changes
Environment: production
URL: https://epidbot.kwar-ai.com.br

Steps:
  1. Checkout code
  2. Setup OpenTofu
  3. Create terraform.tfvars from GitHub secrets
  4. Initialize OpenTofu
  5. Apply infrastructure (tofu apply -auto-approve)
     - Creates/updates Hetzner server
     - Configures firewall
     - Attaches volumes
     - Generates SSH keys
  6. Get server IP from outputs
  7. Setup SSH agent with private key
  8. Wait 60 seconds for server initialization
  9. Install Ansible and required collections
  10. Generate Ansible inventory with server IP
  11. Run Ansible playbook
      - Installs Docker & Docker Compose
      - Configures Nginx reverse proxy
      - Obtains SSL certificates (Let's Encrypt)
      - Deploys Libby server (PostgreSQL + Ollama)
      - Deploys EpidBot application
      - Deploys monitoring stack (Prometheus + Grafana)
  12. Run health checks
```

##### **Job 4: Deploy Services** (After Apply)

```yaml
Purpose: Update Docker services with latest images
Steps:
  1. Get server IP
  2. Setup SSH agent
  3. Pull latest Docker images for all services
  4. Restart containers with zero downtime
  5. Clean up old Docker images
  6. Verify services are responding
```

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

### **Infrastructure Secrets**

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `HCLOUD_TOKEN` | Hetzner Cloud API token | `suxq4LczRiyrB7mjjvk...` |
| `SSH_PRIVATE_KEY` | SSH private key for server access | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### **Configuration Secrets**

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `ADMIN_EMAIL` | Email for Let's Encrypt notifications | `admin@kwar-ai.com.br` |
| `POSTGRES_PASSWORD` | PostgreSQL database password | `openssl rand -base64 32` |
| `SECRET_KEY` | Application secret key | `openssl rand -hex 32` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `openssl rand -base64 32` |

### **API Keys** (Optional - set only if using)

| Secret Name | Description |
|-------------|-------------|
| `OPENAI_API_KEY` | OpenAI API key for GPT models |
| `GEMINI_API_KEY` | Google Gemini API key |
| `ZHIPU_API_KEY` | ZhipuAI API key |
| `DEEPSEEK_API_KEY` | DeepSeek API key |
| `GITHUB_CLIENT_ID` | GitHub OAuth client ID |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret |

## 🚀 Deployment Process

### **Automatic Deployment**

1. **Make changes** to infrastructure code (OpenTofu, Ansible, Docker configs)
2. **Commit and push** to main branch:
   ```bash
   git add .
   git commit -m "Update service configuration"
   git push origin main
   ```
3. **GitHub Actions** automatically:
   - Validates all configuration
   - Creates/updates Hetzner infrastructure
   - Deploys services via Ansible
   - Verifies health checks
4. **Monitor progress** in Actions tab
5. **Services updated** without downtime

### **Manual Deployment**

If you need to trigger deployment without code changes:

1. Go to **Actions** tab in GitHub
2. Select **"Deploy Infrastructure"** workflow
3. Click **"Run workflow"** → **"Run workflow"**
4. Monitor progress in the workflow run

### **Pull Request Validation**

For safe changes:

1. **Create a branch**:
   ```bash
   git checkout -b feature/update-config
   ```
2. **Make changes and push**:
   ```bash
   git add .
   git commit -m "Update configuration"
   git push origin feature/update-config
   ```
3. **Open Pull Request** on GitHub
4. **Review the plan** posted as PR comment
5. **Merge** if changes look correct
6. **Automatic deployment** triggers on merge

## 📊 Deployment Flow Diagram

```
Developer Push
     │
     ▼
┌─────────────────┐
│ GitHub Actions  │
│   Triggered     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Validate      │
│  - Format check │
│  - Lint config  │
└────────┬────────┘
         │
         ├─────► [Pull Request] ──► Plan & Comment ──► Stop
         │
         ▼
┌─────────────────┐
│  OpenTofu Apply │
│  - Create server│
│  - Setup network│
│  - Attach vol.  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Ansible      │
│  - Install Docker
│  - Setup Nginx  │
│  - SSL certs    │
│  - Deploy apps  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update Services│
│  - Pull images  │
│  - Restart      │
│  - Health check │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Complete!    │
│  Services Live  │
└─────────────────┘
```

## 🔍 Monitoring Deployments

### **View Deployment Status**

1. Go to **Actions** tab
2. Click on latest workflow run
3. View real-time logs for each job
4. Check health check results

### **Deployment History**

- All deployments are logged in Actions
- Can view past deployments
- Can re-run failed deployments
- Can download logs for debugging

### **Notifications**

GitHub can notify you of deployment status:
- **Success**: Green checkmark ✅
- **Failure**: Red X ❌
- **In Progress**: Yellow circle 🟡

Configure notifications in:
**GitHub → Settings → Notifications → Actions**

## 🔧 What Does NOT Get Deployed

The workflow **does NOT touch**:

- ❌ Main website (`kwar-ai.com.br`) - stays on GitHub Pages
- ❌ DNS configuration - managed separately
- ❌ GitHub Pages deployment - separate workflow
- ❌ Other subdomains not defined in this infrastructure

## 🔄 Rollback Process

### **Automatic Rollback**

If health checks fail after deployment:

1. Check logs in Actions
2. SSH into server and investigate:
   ```bash
   ssh root@204.168.149.153
   docker ps
   docker logs <container>
   ```
3. Fix issue and push new commit
4. Deployment triggers automatically

### **Manual Rollback**

To rollback to previous version:

1. Find previous successful deployment in Actions
2. Click **"Re-run all jobs"**
3. Or revert commit:
   ```bash
   git revert HEAD
   git push origin main
   ```

## 🛡️ Security Best Practices

### **Secrets Management**

- ✅ Secrets stored in GitHub (encrypted at rest)
- ✅ Never logged or exposed in workflow output
- ✅ Only accessible to workflow jobs
- ✅ Can be rotated without code changes

### **SSH Key Management**

- ✅ SSH key generated by OpenTofu
- ✅ Private key stored as GitHub secret
- ✅ Public key deployed to server automatically
- ✅ Can rotate keys by re-deploying infrastructure

### **Access Control**

- ✅ Only repository collaborators can trigger workflows
- ✅ Branch protection rules prevent direct pushes to main
- ✅ PR reviews required before merging
- ✅ Environment protection rules for production

## 📝 Common Deployment Scenarios

### **Scenario 1: Update Application Code**

```bash
# In Libby or EpidBot repository
git add .
git commit -m "Add new feature"
git push origin main

# Docker images are built and pushed
# Then this workflow pulls and deploys them
```

### **Scenario 2: Update Infrastructure**

```bash
# In this repository
vim main.tf  # Change server type, add resources, etc.
git add main.tf
git commit -m "Upgrade server resources"
git push origin main

# OpenTofu plans and applies changes
# Ansible reconfigures services if needed
```

### **Scenario 3: Update Configuration**

```bash
# In this repository
vim terraform.tfvars  # Update variables
git add terraform.tfvars
git commit -m "Update API keys"
git push origin main

# Services redeployed with new configuration
```

### **Scenario 4: Add New Service**

```bash
# 1. Update OpenTofu configuration
# 2. Add Ansible role for new service
# 3. Update Nginx configuration
# 4. Push changes
# 5. Deployment includes new service automatically
```

## 🚨 Troubleshooting

### **Deployment Fails**

1. **Check Actions logs** for error details
2. **Common issues**:
   - Invalid secrets (check all required secrets are set)
   - DNS not propagated (wait 5-30 minutes)
   - Hetzner API limits (wait and retry)
   - Server resource limits (upgrade server type)

### **Services Not Responding**

1. **SSH into server**:
   ```bash
   ssh -i ./ssh_keys/kwar-ai-ssh-key root@204.168.149.153
   ```
2. **Check container status**:
   ```bash
   docker ps
   docker logs <container-name>
   ```
3. **Check Nginx**:
   ```bash
   docker logs nginx-proxy
   nginx -t
   ```

### **SSL Certificate Issues**

1. **Check certbot logs**:
   ```bash
   journalctl -u certbot --since "1 hour ago"
   ```
2. **Verify DNS**: `dig epidbot.kwar-ai.com.br`
3. **Renew manually**: `certbot renew --force-renewal`

## 📚 Related Documentation

- [README.md](README.md) - Main documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick deployment guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🎯 Best Practices

1. **Always use Pull Requests** for changes
2. **Review plans** before merging
3. **Monitor deployments** in Actions tab
4. **Keep secrets updated** and rotate regularly
5. **Test changes** in development environment first
6. **Document changes** in commit messages
7. **Use semantic versioning** for releases

---

**Last Updated**: March 2026  
**Maintained By**: Kwar-AI Infrastructure Team
