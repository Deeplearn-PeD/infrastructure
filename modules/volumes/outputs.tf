output "volume_ids" {
  description = "List of created volume IDs"
  value       = hcloud_volume.main[*].id
}

output "volume_names" {
  description = "List of created volume names"
  value       = hcloud_volume.main[*].name
}

output "volume_details" {
  description = "Details of all created volumes"
  value = {
    for vol in hcloud_volume.main :
    vol.name => {
      id       = vol.id
      size     = vol.size
      location = vol.location
      linux_device = vol.linux_device
    }
  }
}
