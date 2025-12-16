variable "web_sg_id" { type = string }
variable "db_sg_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "project_tags" { type = map(string) }

variable "ec2_instance_profile_name" {
  description = "EC2 IAM instance profile NAME (not ARN)"
  type        = string
}

