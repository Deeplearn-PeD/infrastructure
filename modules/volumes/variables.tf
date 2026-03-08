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
