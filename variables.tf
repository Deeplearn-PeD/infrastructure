variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the Hetzner server"
  type        = string
  default     = "kwar-ai-server"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx43"

  # SCALING OPTIONS (Shared vCPU - Best Value):
  # cx23  - 2 vCPU,  4 GB RAM,  40 GB SSD   - €4/mo  (dev/test)
  # cpx21 - 3 vCPU,  4 GB RAM,  80 GB SSD   - €9/mo  (small workloads)
  # cpx31 - 4 vCPU,  8 GB RAM, 160 GB SSD   - €15/mo (light production)
  # cx43  - 8 vCPU, 16 GB RAM, 160 GB SSD   - €17/mo (recommended - current)
  # cpx51 - 16 vCPU, 32 GB RAM, 360 GB SSD  - €54/mo (scale-up option)
  #
  # DEDICATED OPTIONS (Consistent Performance - Production):
  # ccx13 - 2 vCPU,  8 GB RAM,  80 GB SSD   - €15/mo
  # ccx23 - 4 vCPU, 16 GB RAM, 160 GB SSD   - €30/mo
  # ccx33 - 8 vCPU, 32 GB RAM, 240 GB SSD   - €60/mo
  # ccx43 - 16 vCPU, 64 GB RAM, 360 GB SSD  - €120/mo
  # ccx53 - 32 vCPU, 128 GB RAM, 600 GB SSD - €240/mo
  # ccx63 - 48 vCPU, 192 GB RAM, 960 GB SSD - €480/mo (max)
}

variable "location" {
  description = "Hetzner data center location"
  type        = string
  default     = "hel1"

  # LOCATION OPTIONS:
  # nbg1 - Nuremberg, Germany (EU) - 20TB free traffic
  # fsn1 - Falkenstein, Germany (EU) - 20TB free traffic
  # hel1 - Helsinki, Finland (EU) - 20TB free traffic [RECOMMENDED]
  # ash  - Ashburn, VA, USA - 1TB free traffic
  # hil  - Hillsboro, OR, USA - 1TB free traffic
  # sin  - Singapore (APAC) - 0.5TB free traffic
}

variable "image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "kwar-ai.com.br"
}

variable "epidbot_subdomain" {
  description = "Subdomain for EpidBot"
  type        = string
  default     = "epidbot.kwar-ai.com.br"
}

variable "libby_subdomain" {
  description = "Subdomain for Libby API"
  type        = string
  default     = "libby.kwar-ai.com.br"
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana"
  type        = string
  default     = "grafana.kwar-ai.com.br"
}

variable "ssh_key_name" {
  description = "Name for the SSH key in Hetzner"
  type        = string
  default     = "kwar-ai-ssh-key"
}

variable "ssh_public_key" {
  description = "SSH public key content (if not provided, will be generated)"
  type        = string
  default     = ""
}

variable "admin_email" {
  description = "Admin email for Let's Encrypt and notifications"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "libby"
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "libby"
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Google Gemini API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "zhipu_api_key" {
  description = "ZhipuAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deepseek_api_key" {
  description = "DeepSeek API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_key" {
  description = "Secret key for application security"
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Number of days to keep backups"
  type        = number
  default     = 7
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "enable_monitoring" {
  description = "Enable Prometheus/Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "github_client_id" {
  description = "GitHub OAuth client ID"
  type        = string
  default     = ""
}

variable "github_client_secret" {
  description = "GitHub OAuth client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "embedding_model" {
  description = "Embedding model for Libby"
  type        = string
  default     = "mxbai-embed-large"
}

variable "ollama_model" {
  description = "Ollama model to use"
  type        = string
  default     = "llama3"
}

variable "timezone" {
  description = "Server timezone"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "epidbot_admin_user" {
  description = "Default admin username for EpidBot"
  type        = string
  default     = "admin"
}

variable "epidbot_admin_password" {
  description = "Default admin password for EpidBot (CHANGE IMMEDIATELY!)"
  type        = string
  sensitive   = true
}

variable "epidbot_admin_email" {
  description = "Default admin email for EpidBot"
  type        = string
  default     = "admin@kwar-ai.com.br"
}

variable "postgres_volume_size" {
  description = "Size of PostgreSQL volume in GB"
  type        = number
  default     = 50
}

variable "libby_volume_size" {
  description = "Size of Libby data volume in GB"
  type        = number
  default     = 20
}

variable "epidbot_volume_size" {
  description = "Size of EpidBot data volume in GB"
  type        = number
  default     = 20
}

variable "backup_volume_size" {
  description = "Size of backup volume in GB"
  type        = number
  default     = 100
}

variable "monitoring_volume_size" {
  description = "Size of monitoring data volume in GB"
  type        = number
  default     = 10
}
