variable "server_name" {
  description = "Name of the Hetzner server"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
}

variable "location" {
  description = "Hetzner data center location"
  type        = string
}

variable "image" {
  description = "OS image for the server"
  type        = string
}

variable "ssh_key_name" {
  description = "Name for the SSH key"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = ""
}

variable "firewall_ids" {
  description = "List of firewall IDs to attach"
  type        = list(number)
  default     = []
}

variable "volume_ids" {
  description = "List of volume IDs to attach"
  type        = list(number)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
}

variable "epidbot_subdomain" {
  description = "Subdomain for EpidBot"
  type        = string
}

variable "libby_subdomain" {
  description = "Subdomain for Libby API"
  type        = string
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana"
  type        = string
}

variable "admin_email" {
  description = "Admin email address"
  type        = string
}

variable "timezone" {
  description = "Server timezone"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Gemini API key"
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
  description = "Backup retention days"
  type        = number
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
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
}

variable "ollama_model" {
  description = "Ollama model to use"
  type        = string
}
