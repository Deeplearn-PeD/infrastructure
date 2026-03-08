# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-03-08

### Added

#### Infrastructure (OpenTofu/Terraform)
- Initial infrastructure setup with OpenTofu
- Hetzner Cloud server module (CX42, Helsinki)
- Network module with firewall rules (SSH, HTTP, HTTPS)
- Volumes module for persistent storage (200GB total)
- Cloud-init configuration for automated server setup
- SSH key generation and management

#### Configuration Management (Ansible)
- Docker installation and configuration role
- Nginx reverse proxy role with SSL
- Libby server deployment role
- EpidBot deployment role
- Monitoring stack deployment role
- Automated SSL certificate management with Let's Encrypt

#### Services
- **Libby Server**: RAG document embedding and retrieval
  - PostgreSQL with pgvector extension
  - Ollama integration for embeddings
  - Automatic database backups
  - Document watcher service

- **EpidBot**: AI assistant for Brazilian public health data
  - Gradio web interface
  - Integration with Libby knowledge base
  - Multiple LLM provider support

#### Monitoring
- Prometheus metrics collection
- Grafana dashboards
- Alertmanager for notifications
- Node Exporter for system metrics
- cAdvisor for container metrics
- Pre-configured alert rules

#### Deployment
- One-command deployment script
- Automated service deployment with Ansible
- Health check scripts
- Backup automation
- SSL certificate auto-renewal

#### CI/CD
- GitHub Actions workflow for infrastructure deployment
- GitHub Actions workflow for service updates
- GitHub Actions workflow for infrastructure destruction
- Automated testing and validation

#### Documentation
- Comprehensive README with architecture diagrams
- Quick start guide
- Troubleshooting guide
- Configuration reference
- Security best practices

#### Security
- UFW firewall configuration
- Fail2ban for SSH protection
- SSH hardening (key-only authentication)
- Automatic security updates
- Rate limiting on API endpoints
- SSL/TLS with modern cipher suites
- HSTS headers

#### Backup & Recovery
- Daily automated backups
- PostgreSQL dump and restore
- Volume snapshot support
- 7-day retention policy
- Backup verification

### Features

#### High Availability
- Automatic container restart
- Health checks for all services
- Service dependency management
- Graceful shutdown handling

#### Cost Optimization
- Efficient resource utilization
- Automatic cleanup of old Docker images
- Backup rotation
- Volume management

#### Developer Experience
- Simple setup script
- Clear documentation
- Comprehensive logging
- Easy troubleshooting

### Infrastructure Specifications

- **Server**: Hetzner CX42 (8 vCPU, 16GB RAM)
- **Location**: Helsinki (hel1)
- **Storage**: 200GB distributed across 5 volumes
- **Network**: Firewall with restricted access
- **OS**: Ubuntu 24.04 LTS
- **Estimated Cost**: €20.40/month

### Services URLs

- EpidBot: https://epidbot.kwar-ai.com.br
- Libby API: https://libby.kwar-ai.com.br
- Grafana: https://grafana.kwar-ai.com.br

### Supported Providers

- OpenAI (GPT-4, GPT-4o)
- Google Gemini
- ZhipuAI (GLM)
- DeepSeek
- Ollama (local LLMs)

### Tested With

- OpenTofu 1.6.0
- Ansible 2.15+
- Docker 24.0+
- Docker Compose 2.20+
- Ubuntu 24.04 LTS

### Known Limitations

- Single server deployment (not clustered)
- No GPU support (CPU-only inference)
- Manual scaling required
- No multi-region support yet

### Future Enhancements

- [ ] Multi-environment support (dev/staging/prod)
- [ ] Kubernetes deployment option
- [ ] GPU-enabled instances
- [ ] Multi-region deployment
- [ ] Advanced monitoring with custom metrics
- [ ] Blue-green deployment strategy
- [ ] Automated disaster recovery
- [ ] Cost optimization automation

## [Unreleased]

### Planned
- Development environment configuration
- Staging environment setup
- Automated performance testing
- Enhanced security scanning
- Database migration automation

---

For more details about releases, see [GitHub Releases](https://github.com/your-org/kwarai-infra/releases).
