output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.static.bucket
}

# output "cloudfront_domain" {
#   value = aws_cloudfront_distribution.cdn.domain_name
# }