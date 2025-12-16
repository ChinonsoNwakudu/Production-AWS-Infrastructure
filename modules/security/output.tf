output "web_sg_id" {
  value = aws_security_group.web.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "ec2_instance_profile_name" {
  description = "EC2 IAM instance profile NAME"
  value       = aws_iam_instance_profile.ec2_profile.name

}