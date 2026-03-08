resource "hcloud_firewall" "main" {
  name   = var.firewall_name
  labels = var.labels

  # SSH access (port 22)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = length(var.allowed_ssh_ips) > 0 ? var.allowed_ssh_ips : ["0.0.0.0/0", "::/0"]
    description = "SSH access"
  }

  # HTTP access (port 80)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = length(var.allowed_http_ips) > 0 ? var.allowed_http_ips : ["0.0.0.0/0", "::/0"]
    description = "HTTP access"
  }

  # HTTPS access (port 443)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = length(var.allowed_http_ips) > 0 ? var.allowed_http_ips : ["0.0.0.0/0", "::/0"]
    description = "HTTPS access"
  }

  # Allow all outbound traffic
  rule {
    direction   = "out"
    protocol    = "tcp"
    port        = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description = "Allow all outbound TCP traffic"
  }

  rule {
    direction   = "out"
    protocol    = "udp"
    port        = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description = "Allow all outbound UDP traffic"
  }

  rule {
    direction   = "out"
    protocol    = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description = "Allow all outbound ICMP traffic"
  }

  # ICMP for ping and diagnostics
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
    description = "ICMP for diagnostics"
  }
}
