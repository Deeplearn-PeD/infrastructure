resource "tls_private_key" "main" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.main[0].private_key_openssh
  filename        = "${path.module}/../../ssh_keys/${var.ssh_key_name}"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  count           = var.ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.main[0].public_key_openssh
  filename        = "${path.module}/../../ssh_keys/${var.ssh_key_name}.pub"
  file_permission = "0644"
}

resource "hcloud_ssh_key" "main" {
  count      = var.ssh_public_key == "" ? 1 : 0
  name       = var.ssh_key_name
  public_key = tls_private_key.main[0].public_key_openssh
  labels     = var.labels
}

data "hcloud_ssh_keys" "existing_keys" {
  count = var.ssh_public_key != "" ? 1 : 0
}

locals {
  ssh_key_id = var.ssh_public_key != "" ? (
    length(data.hcloud_ssh_keys.existing_keys[0].ssh_keys) > 0 ? 
    [for key in data.hcloud_ssh_keys.existing_keys[0].ssh_keys : key.id if key.name == var.ssh_key_name][0] : 
    null
  ) : hcloud_ssh_key.main[0].id
  
  ssh_public_key_final = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.main[0].public_key_openssh
}

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")

  vars = {
    domain_name            = var.domain_name
    epidbot_subdomain      = var.epidbot_subdomain
    libby_subdomain        = var.libby_subdomain
    grafana_subdomain      = var.grafana_subdomain
    admin_email            = var.admin_email
    timezone               = var.timezone
    postgres_db            = var.postgres_db
    postgres_user          = var.postgres_user
    postgres_password      = var.postgres_password
    secret_key             = var.secret_key
    backup_retention_days  = var.backup_retention_days
    openai_api_key         = var.openai_api_key
    gemini_api_key         = var.gemini_api_key
    zhipu_api_key          = var.zhipu_api_key
    deepseek_api_key       = var.deepseek_api_key
    github_client_id       = var.github_client_id
    github_client_secret   = var.github_client_secret
    embedding_model        = var.embedding_model
    ollama_model           = var.ollama_model
  }
}

resource "hcloud_server" "main" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.location
  image       = var.image
  ssh_keys    = [local.ssh_key_id]
  firewall_ids = var.firewall_ids
  
  user_data = data.template_file.cloud_init.rendered
  
  labels = var.labels

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_volume_attachment" "main" {
  count     = length(var.volume_ids)
  volume_id = var.volume_ids[count.index]
  server_id = hcloud_server.main.id
  automount = true
}
