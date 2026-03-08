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
  description = "Hetzner server type (CX43 recommended)"
  type        = string
  default     = "cx43"  # 8 vCPU, 16GB RAM (Intel Ice Lake)
}

variable "location" {
  description = "Hetzner data center location"
  type        = string
  default     = "hel1"
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
