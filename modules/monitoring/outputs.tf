output "prometheus_config_path" {
  description = "Path to Prometheus configuration file"
  value       = local_file.prometheus_config.filename
}

output "alertmanager_config_path" {
  description = "Path to Alertmanager configuration file"
  value       = local_file.alertmanager_config.filename
}

output "docker_compose_path" {
  description = "Path to monitoring Docker Compose file"
  value       = local_file.docker_compose.filename
}
