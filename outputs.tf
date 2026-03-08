output "server_ip" {
  description = "Public IP address of the server"
  value       = module.server.server_ip
}

output "server_name" {
  description = "Name of the server"
  value       = module.server.server_name
}

output "server_status" {
  description = "Status of the server"
  value       = module.server.server_status
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${module.server.server_ip}"
}

output "epidbot_url" {
  description = "EpidBot application URL"
  value       = "https://${var.epidbot_subdomain}"
}

output "libby_url" {
  description = "Libby API URL"
  value       = "https://${var.libby_subdomain}"
}

output "grafana_url" {
  description = "Grafana monitoring URL"
  value       = var.enable_monitoring ? "https://${var.grafana_subdomain}" : "Monitoring disabled"
}

output "domain_name" {
  description = "Main domain name"
  value       = var.domain_name
}

output "nameservers" {
  description = "Hetzner nameservers for DNS configuration"
  value       = ["hel1-dc1.hetzner.com", "hel1-dc2.hetzner.com", "hel1-dc3.hetzner.com"]
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT
    Infrastructure has been deployed successfully!
    
    Next steps:
    1. Configure DNS records for your domain (kwar-ai.com.br):
       - A record: ${var.epidbot_subdomain} -> ${module.server.server_ip}
       - A record: ${var.libby_subdomain} -> ${module.server.server_ip}
       ${var.enable_monitoring ? "- A record: ${var.grafana_subdomain} -> ${module.server.server_ip}" : ""}
    
    2. Wait for DNS propagation (5-30 minutes)
    
    3. Run Ansible playbook to deploy services:
       cd ansible && ansible-playbook -i inventory.ini playbook.yml
    
    4. Access your services:
       - EpidBot: https://${var.epidbot_subdomain}
       - Libby API: https://${var.libby_subdomain}
       ${var.enable_monitoring ? "- Grafana: https://${var.grafana_subdomain}" : ""}
    
    5. Check service health:
       ./scripts/healthcheck.sh
  EOT
}
