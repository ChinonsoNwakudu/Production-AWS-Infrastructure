variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "web_sg_id" { type = string }
variable "project_tags" { type = map(string) }