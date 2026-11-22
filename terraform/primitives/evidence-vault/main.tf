# ---------------------------------------------------------------
# Lab 2.5: Evidence vault (S3 Object Lock / WORM storage)
# Evidence stored here cannot be deleted or overwritten until its
# retention date passes: chain of custody for audit evidence.
# ---------------------------------------------------------------
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project         = var.project_name
      Environment     = "evidence"
      ManagedBy       = "terraform"
      ComplianceScope = "cge-p-lab"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  vault_name = "${var.project_name}-grc-evidence-vault-${random_id.suffix.hex}"
}

# The vault. Object Lock can only be switched on when the bucket is
# created; it can never be added to an existing bucket.
resource "aws_s3_bucket" "vault" {
  # Documented exceptions (risk accepted for this lab; reviewed 2026-11-22):
  #checkov:skip=CKV_AWS_145:AES256 (SSE-S3) meets SC-28 for this lab; customer-managed KMS keys planned for production evidence
  #checkov:skip=CKV_AWS_144:Cross-region replication is a resilience control outside this lab's scope
  #checkov:skip=CKV2_AWS_62:Event notifications not required for this lab
  #checkov:skip=CKV2_AWS_61:Retention is enforced by Object Lock default retention, not lifecycle rules
  #checkov:skip=CKV_AWS_18:Access logging for the vault planned with CloudTrail data events in the capstone; lab vault is destroyed after the session
  bucket              = local.vault_name
  object_lock_enabled = true # MUST be set at bucket creation
}

# Object Lock requires versioning: every write is kept as its own version.
resource "aws_s3_bucket_versioning" "vault" {
  bucket = aws_s3_bucket.vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# AU-9 / AU-11: every object uploaded is automatically locked for
# retention_days. GOVERNANCE for labs, COMPLIANCE for real evidence.
resource "aws_s3_bucket_object_lock_configuration" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    default_retention {
      mode = var.lock_mode
      days = var.retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.vault]
}

# SC-28: evidence is encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# AC-3: evidence can never be made public
resource "aws_s3_bucket_public_access_block" "vault" {
  bucket = aws_s3_bucket.vault.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Look up this account's ID (a "data source" reads information; it builds nothing)
data "aws_caller_identity" "current" {}

# Refuse deletion of the whole vault by anyone except the account root user
resource "aws_s3_bucket_policy" "vault" {
  bucket = aws_s3_bucket.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyBucketDeletion"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:DeleteBucket"
      Resource  = aws_s3_bucket.vault.arn
      Condition = {
        StringNotEquals = {
          "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    }]
  })
}
