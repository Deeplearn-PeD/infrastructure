variable "server_id" {
  description = "ID of the server to monitor"
  type        = number
}

variable "server_ip" {
  description = "IP address of the server"
  type        = string
}

variable "grafana_url" {
  description = "URL for Grafana access"
  type        = string
}

variable "admin_email" {
  description = "Admin email for alerts"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
