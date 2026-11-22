output "vault_name" {
  description = "S3 bucket name of the evidence vault. Feed this to capture-evidence.sh --vault."
  value       = aws_s3_bucket.vault.id
}
