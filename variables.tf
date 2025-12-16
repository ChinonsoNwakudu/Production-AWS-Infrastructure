variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "project_tags" {
  type = map(string)
  default = {
    Project = "ProdAWSInfra"
    Env     = "Production"
  }
  description = "Common tags for resources"
}

// Add more as needed per module