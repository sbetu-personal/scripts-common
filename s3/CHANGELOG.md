# Changelog

## [Unreleased]

### Added
- Strongly typed `server_side_encryption_configuration` variable.
- Validation to ensure a valid `sse_algorithm` is always provided (`AES256`, `aws:kms`, or `aws:kms:dsse`).
- `expected_bucket_owner` argument to the `aws_s3_bucket_server_side_encryption_configuration` resource for stricter access control.

### Changed
- Simplified the encryption configuration to a single rule block instead of a list of rules.
- Removed dynamic blocks and any extraneous complexity now that only a single encryption rule is allowed.

### Fixed
- Closed loopholes that previously could allow deploying a bucket without encryption.
- Ensured that malformed configurations fail at plan time rather than resulting in partially configured or unencrypted buckets.



# S3 Bucket Secure Module

This module creates an S3 bucket with mandatory server-side encryption enabled by default. It enforces correct configuration of the encryption rule and prevents the creation of unencrypted buckets.

## Features

- **Mandatory Encryption:** Ensures every deployed bucket has a valid encryption rule.
- **Strict Typing & Validation:** Strongly typed variables and validations prevent malformed input.
- **Single Encryption Rule:** Simplified configuration requires only one encryption rule, reducing complexity.
- **Optional KMS Integration:** Easily switch from SSE-S3 (`AES256`) to SSE-KMS (`aws:kms` or `aws:kms:dsse`) with your own KMS key.

## Usage

```hcl
module "my_secure_bucket" {
  source = "./modules/s3_bucket_secure"

  bucket         = "my-unique-encrypted-bucket"
  create_bucket  = true

  # Optional: Owner validation if desired
  # expected_bucket_owner = "123456789012"

  # Optional: Override default encryption configuration (default is AES256)
  # server_side_encryption_configuration = {
  #   apply_server_side_encryption_by_default = {
  #     sse_algorithm     = "aws:kms"
  #     kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/your-kms-key-id"
  #   }
  #   # bucket_key_enabled = true
  # }
}
