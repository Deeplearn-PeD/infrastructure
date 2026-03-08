resource "hcloud_volume" "main" {
  count     = 5
  name      = "${var.server_name}-vol-${count.index + 1}"
  size      = local.volume_sizes[count.index]
  location  = var.location
  labels    = var.labels
  format    = "ext4"

  lifecycle {
    prevent_destroy = false
  }
}

locals {
  volume_sizes = [
    var.postgres_volume_size,
    var.libby_volume_size,
    var.epidbot_volume_size,
    var.backup_volume_size,
    var.monitoring_volume_size
  ]
  
  volume_names = [
    "postgres-data",
    "libby-data",
    "epidbot-data",
    "backup-data",
    "monitoring-data"
  ]
}
