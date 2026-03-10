variable "location" {
  description = "Hetzner data center location"
  type        = string
}

variable "server_name" {
  description = "Name of the server (used for volume naming)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_backups" {
  description = "Enable automatic backups for volumes"
  type        = bool
  default     = true
}

variable "postgres_volume_size" {
  description = "Size of PostgreSQL volume in GB"
  type        = number
  default     = 50

  # SCALING GUIDE:
  # 50 GB  - Development/small production (default)
  # 100 GB - Medium production with significant data
  # 200 GB - Large production datasets
  # Max: 10 TB per volume, up to 16 volumes per server
}

variable "libby_volume_size" {
  description = "Size of Libby data volume in GB"
  type        = number
  default     = 20

  # SCALING GUIDE:
  # 20 GB  - Default (Ollama models + embeddings)
  # 50 GB  - Multiple large models
  # 100 GB - Large embedding collections
}

variable "epidbot_volume_size" {
  description = "Size of EpidBot data volume in GB"
  type        = number
  default     = 20

  # SCALING GUIDE:
  # 20 GB  - Default (chat history + pysus cache + plots)
  # 50 GB  - Extended pysus data retention
  # 100 GB - Large report archives
}

variable "backup_volume_size" {
  description = "Size of backup volume in GB"
  type        = number
  default     = 100

  # SCALING GUIDE:
  # 100 GB - Default (7 days retention)
  # 200 GB - 14-30 days retention
  # 500 GB - Long-term archives
}

variable "monitoring_volume_size" {
  description = "Size of monitoring data volume in GB"
  type        = number
  default     = 10

  # SCALING GUIDE:
  # 10 GB  - Default (30 days metrics)
  # 20 GB  - Extended retention (60-90 days)
  # 50 GB  - Long-term observability
}
