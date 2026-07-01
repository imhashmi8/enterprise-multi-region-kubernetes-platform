# ── S3 access log bucket ──────────────────────────────────────────────────────
resource "aws_s3_bucket" "state_logs" {
  bucket        = "${var.state_bucket_name}-access-logs"
  force_destroy = false

  tags = {
    Name    = "${var.state_bucket_name}-access-logs"
    Purpose = "terraform-state-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "state_logs" {
  bucket                  = aws_s3_bucket.state_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration { days = var.log_retention_days }
  }
}

# ── Terraform remote state bucket ─────────────────────────────────────────────
resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name    = var.state_bucket_name
    Purpose = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.state_logs.id
  target_prefix = "terraform-state/"
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "manage-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

# ── DynamoDB lock table ────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }

  tags = {
    Name    = var.lock_table_name
    Purpose = "terraform-state-locking"
  }
}
