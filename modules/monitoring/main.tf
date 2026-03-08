resource "local_file" "prometheus_config" {
  content  = templatefile("${path.module}/templates/prometheus.yml.tftpl", {
    server_ip = var.server_ip
  })
  filename = "${path.module}/../../ansible/files/monitoring/prometheus.yml"
}

resource "local_file" "alertmanager_config" {
  content  = templatefile("${path.module}/templates/alertmanager.yml.tftpl", {
    admin_email = var.admin_email
  })
  filename = "${path.module}/../../ansible/files/monitoring/alertmanager.yml"
}

resource "local_file" "docker_compose" {
  content  = templatefile("${path.module}/templates/docker-compose.yml.tftpl", {
    grafana_url = var.grafana_url
  })
  filename = "${path.module}/../../ansible/files/monitoring/docker-compose.yml"
}

resource "local_file" "grafana_dashboards" {
  for_each = fileset("${path.module}/dashboards", "*.json")
  content  = file("${path.module}/dashboards/${each.key}")
  filename = "${path.module}/../../ansible/files/monitoring/dashboards/${each.key}"
}

resource "local_file" "alert_rules" {
  content  = file("${path.module}/rules/alerts.yml")
  filename = "${path.module}/../../ansible/files/monitoring/rules/alerts.yml"
}
