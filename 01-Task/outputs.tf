output "monitoring_server_public_ip" {
  description = "Public IP of the monitoring EC2 instance"
  value       = aws_instance.monitoring.public_ip
}

output "prometheus_url" {
  description = "Prometheus dashboard URL"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "grafana_login_hint" {
  description = "Reminder for the Grafana admin login"
  value       = "username: admin | password: value of var.grafana_admin_password"
}

output "app_server_private_ips" {
  description = "Private IPs of the sample app servers (these are what Prometheus scrapes)"
  value       = [for instance in aws_instance.app : instance.private_ip]
}

output "app_server_public_ips" {
  description = "Public IPs of the sample app servers (for SSH access)"
  value       = [for instance in aws_instance.app : instance.public_ip]
}

output "ssh_private_key_path" {
  description = "Path to the auto-generated SSH private key - use this to SSH into any instance as 'ubuntu'"
  value       = local_file.private_key.filename
}
