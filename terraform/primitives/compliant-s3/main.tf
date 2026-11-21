# ---------------------------------------------------------------
# Tools: which providers this code needs, and which versions
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

# ---------------------------------------------------------------
# AWS connection + default tags
# CM-6 (configuration settings): every resource is labeled
# automatically, so ownership and compliance scope are never missing.
# ---------------------------------------------------------------
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project         = var.project_name
      Environment     = var.environment
      ManagedBy       = "terraform"
      ComplianceScope = "nist-800-53"
    }
  }
}

# ---------------------------------------------------------------
# Naming: S3 bucket names must be globally unique, so add a suffix
# ---------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  suffix              = var.bucket_suffix != "" ? var.bucket_suffix : random_id.suffix.hex
  primary_bucket_name = "${var.project_name}-${var.environment}-${local.suffix}"
  log_bucket_name     = "${var.project_name}-${var.environment}-logs-${local.suffix}"
}

# ---------------------------------------------------------------
# Primary bucket (controls are added as separate blocks below)
# ---------------------------------------------------------------
resource "aws_s3_bucket" "primary" {
  bucket = local.primary_bucket_name
}

# SC-28 (protection at rest): encrypt everything in the bucket with AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CM-6 (configuration settings): keep every version of every object
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# AC-3 (access enforcement): block every path to public access
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------
# Log bucket: a separate, locked-down home for access logs
# AU-6 (audit review): logs are kept apart from the data they describe
# ---------------------------------------------------------------
resource "aws_s3_bucket" "log_bucket" {
  bucket = local.log_bucket_name
}

# Turn on ACLs for this bucket only, so the log-delivery service can be granted write access
resource "aws_s3_bucket_ownership_controls" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Allow AWS's log-delivery service to write logs here (nothing else)
resource "aws_s3_bucket_acl" "log_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

# SC-28: logs are encrypted too
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# AC-3: logs can never be made public
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------
# AU-3 (audit record content): record every request to the primary
# bucket and deliver the records to the log bucket
# ---------------------------------------------------------------
resource "aws_s3_bucket_logging" "primary" {
  bucket = aws_s3_bucket.primary.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}
