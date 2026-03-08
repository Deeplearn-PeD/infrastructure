variable "firewall_name" {
  description = "Name of the firewall"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "allowed_ssh_ips" {
  description = "List of IPs allowed to access SSH (empty = all)"
  type        = list(string)
  default     = []
}

variable "allowed_http_ips" {
  description = "List of IPs allowed to access HTTP/HTTPS (empty = all)"
  type        = list(string)
  default     = []
}
