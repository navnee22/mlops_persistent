provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "model_storage" {
  bucket        = "model-training-inference-bucket"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.model_key.arn
      }
    }
  }
}

# Create a Customer Managed KMS Key
resource "aws_kms_key" "model_key" {
  description         = "KMS key for encrypting S3 bucket and other resources"
  key_usage           = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "model_key_alias" {
  name          = "alias/model-key"
  target_key_id = aws_kms_key.model_key.id
}

# Create IAM Role for model training and inference
resource "aws_iam_role" "model_role" {
  name = "model-training-inference-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the IAM Role
resource "aws_iam_policy" "model_policy" {
  name        = "model-training-inference-policy"
  description = "Policy for model training and inference access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
          "kms:*",
          "ecr:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "model_policy_attach" {
  role       = aws_iam_role.model_role.name
  policy_arn = aws_iam_policy.model_policy.arn
}

# Create an ECR Repository
resource "aws_ecr_repository" "model_repository" {
  name                 = "model-training-inference-repo"
  image_tag_mutability = "IMMUTABLE"
}

output "s3_bucket" {
  value = aws_s3_bucket.model_storage.id
}

output "kms_key_id" {
  value = aws_kms_key.model_key.id
}

output "iam_role" {
  value = aws_iam_role.model_role.name
}

output "ecr_repository" {
  value = aws_ecr_repository.model_repository.repository_url
}
