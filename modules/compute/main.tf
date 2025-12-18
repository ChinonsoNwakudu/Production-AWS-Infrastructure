resource "aws_launch_template" "web" {
  name_prefix            = "web-"
  image_id               = data.aws_ami.amazon_linux.id # Latest Amazon Linux
  instance_type          = "t3.micro"
  vpc_security_group_ids = [var.web_sg_id]
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              EOF
  ) # Simple web server bootstrap
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.project_tags, {
      Backup = "Daily"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.project_tags, {
      Backup = "Daily"
    })
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_autoscaling_group" "web_asg" {
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = var.project_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  name = "web-asg-prod"
}

resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "13"
  instance_class         = "db.t3.micro"
  db_name                = "proddb"
  username               = "dbmaster"
  password               = "securepassword" # Use secrets manager in prod!
  multi_az               = true
  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  tags = merge(var.project_tags, {
    Backup = "Daily"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = var.private_subnet_ids
  tags       = var.project_tags
}

resource "aws_s3_bucket" "static" {
  bucket = "prod-static-bucket-${random_id.bucket.hex}"
  tags   = var.project_tags
}

resource "aws_s3_bucket_versioning" "static_versioning" {
  bucket = aws_s3_bucket.static.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "bucket" {
  byte_length = 4
}

# resource "aws_cloudfront_distribution" "cdn" {
#   origin {
#     domain_name = aws_s3_bucket.static.bucket_regional_domain_name
#     origin_id   = "s3-origin"
#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
#     }
#   }
#   enabled = true
#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "s3-origin"
#     forwarded_values {
#       query_string = false
#       cookies { forward = "none" }
#     }
#     viewer_protocol_policy = "redirect-to-https"
#   }
#   restrictions {
#     geo_restriction { restriction_type = "none" }
#   }
#   viewer_certificate { cloudfront_default_certificate = true }
#   tags = var.project_tags
# }

#resource "aws_cloudfront_origin_access_identity" "oai" {}

