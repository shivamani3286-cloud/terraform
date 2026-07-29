output "bastion_public_ip" {
  description = "Public IP of the bastion host - SSH here first"
  value       = aws_instance.bastion.public_ip
}

output "frontend_alb_dns_name" {
  description = "Public DNS name of the frontend ALB (CloudFront origin)"
  value       = aws_lb.frontend.dns_name
}

output "backend_alb_dns_name" {
  description = "Internal DNS name of the backend ALB (only reachable from inside the VPC)"
  value       = aws_lb.backend.dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "site_url" {
  description = "Public URL for the site once DNS propagates"
  value       = "https://${var.domain_name}"
}

output "rds_primary_endpoint" {
  description = "Primary RDS MySQL endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "rds_replica_endpoint" {
  description = "Read replica RDS MySQL endpoint"
  value       = aws_db_instance.replica.endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}
