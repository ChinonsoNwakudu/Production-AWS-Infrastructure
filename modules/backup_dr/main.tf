resource "aws_backup_vault" "main" {
  name = "prod-vault"
  tags = var.project_tags
}

resource "aws_backup_plan" "daily" {
  name = "daily-backup"
  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 12 * * ? *)" # Daily at 12 UTC
    lifecycle {
      delete_after = 7 # Days
    }
  }
  tags = var.project_tags
}

resource "aws_backup_selection" "resources" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "tag-based-backup-selection"
  plan_id      = aws_backup_plan.daily.id

  # Select resources that have the tag Backup = "Daily"
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "Daily"
  }
}

resource "aws_iam_role" "backup_role" {
  name = "backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}


resource "aws_s3_bucket" "dr_bucket" {
  provider = aws.dr  
  bucket = "dr-static-bucket-${random_id.dr.hex}"

  tags = var.project_tags
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.dr  
  bucket = aws_s3_bucket.dr_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.main  # Main region provider (us-east-1)
  role     = aws_iam_role.s3_replication_role.arn
  bucket   = var.s3_bucket_name

  rule {
    id     = "dr-rule"
    status = "Enabled"
    priority = 1  # Required for V2 when multiple rules possible; safe to add

    delete_marker_replication {
      status = "Disabled"  # Explicitly required for V2
    }

    destination {
      bucket        = aws_s3_bucket.dr_bucket.arn
      storage_class = "STANDARD"
    }

    filter {}  # Replicates all objects (empty filter = V2 schema)
  }

  depends_on = [
    aws_s3_bucket_versioning.dr_versioning,
    # aws_s3_bucket_versioning.static_versioning  # If in compute module
  ]
}

resource "random_id" "dr" { byte_length = 4 }

resource "aws_iam_role" "s3_replication_role" {
  name = "s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "s3_replication_policy" {
  name = "s3-replication-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"  # Source bucket ARN
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"  # Source objects
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.dr_bucket.arn}/*"  # Destination objects
      }
    ]
  })
  tags = var.project_tags
}

resource "aws_iam_role_policy_attachment" "s3_replication_attach" {
  role       = aws_iam_role.s3_replication_role.name
  policy_arn = aws_iam_policy.s3_replication_policy.arn
}



