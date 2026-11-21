output "bucket_name" {
  description = "Name of the primary compliant bucket."
  value       = aws_s3_bucket.primary.bucket
}

output "primary_bucket_arn" {
  description = "ARN of the primary compliant bucket."
  value       = aws_s3_bucket.primary.arn
}

output "log_bucket_arn" {
  description = "ARN of the access-log bucket."
  value       = aws_s3_bucket.log_bucket.arn
}

output "encryption_algorithm" {
  description = "Encryption algorithm in effect on the primary bucket (SC-28 attestation)."
  value = one([
    for rule in aws_s3_bucket_server_side_encryption_configuration.primary.rule :
    rule.apply_server_side_encryption_by_default[0].sse_algorithm
  ])
}
