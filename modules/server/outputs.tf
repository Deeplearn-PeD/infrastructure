output "server_id" {
  description = "ID of the created server"
  value       = hcloud_server.main.id
}

output "server_ip" {
  description = "Public IP address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "server_name" {
  description = "Name of the server"
  value       = hcloud_server.main.name
}

output "server_status" {
  description = "Status of the server"
  value       = hcloud_server.main.status
}

output "ssh_key_id" {
  description = "ID of the SSH key"
  value       = var.ssh_public_key != "" ? hcloud_ssh_key.main[0].id : null
}

output "ssh_private_key_path" {
  description = "Path to the generated SSH private key (if generated)"
  value       = var.ssh_public_key == "" ? local_sensitive_file.ssh_private_key[0].filename : null
}
