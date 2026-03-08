locals {
  common_tags = {
    Project     = "kwar-ai"
    Environment = "production"
    ManagedBy   = "opentofu"
    Domain      = var.domain_name
  }
}

module "network" {
  source = "./modules/network"

  firewall_name = "${var.server_name}-firewall"
  labels        = local.common_tags
}

module "volumes" {
  source = "./modules/volumes"

  location        = var.location
  server_name     = var.server_name
  labels          = local.common_tags
  enable_backups  = true
}

module "server" {
  source = "./modules/server"

  server_name    = var.server_name
  server_type    = var.server_type
  location       = var.location
  image          = var.image
  ssh_key_name   = var.ssh_key_name
  ssh_public_key = var.ssh_public_key
  firewall_ids   = [module.network.firewall_id]
  volume_ids     = module.volumes.volume_ids
  labels         = local.common_tags

  domain_name            = var.domain_name
  epidbot_subdomain      = var.epidbot_subdomain
  libby_subdomain        = var.libby_subdomain
  grafana_subdomain      = var.grafana_subdomain
  admin_email            = var.admin_email
  timezone               = var.timezone
  enable_monitoring      = var.enable_monitoring
  postgres_password      = var.postgres_password
  postgres_db            = var.postgres_db
  postgres_user          = var.postgres_user
  openai_api_key         = var.openai_api_key
  gemini_api_key         = var.gemini_api_key
  zhipu_api_key          = var.zhipu_api_key
  deepseek_api_key       = var.deepseek_api_key
  secret_key             = var.secret_key
  backup_retention_days  = var.backup_retention_days
  grafana_admin_password = var.grafana_admin_password
  github_client_id       = var.github_client_id
  github_client_secret   = var.github_client_secret
  embedding_model        = var.embedding_model
  ollama_model           = var.ollama_model
}

module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  server_id     = module.server.server_id
  server_ip     = module.server.server_ip
  grafana_url   = "https://${var.grafana_subdomain}"
  admin_email   = var.admin_email
  labels        = local.common_tags
}
