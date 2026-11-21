# Lab 2.3: Compliant S3 Bucket

This Terraform primitive provisions a primary S3 bucket and a dedicated log bucket that together enforce five NIST 800-53 controls (SC-28, AU-3, AU-6, CM-6, AC-3) on a single bucket. Every control is defined in code and proven with machine-readable evidence (Terraform plan and state exported as JSON), not screenshots.

## Control-to-code mapping

| Control | What it requires | How this code meets it | Where |
|---|---|---|---|
| SC-28 | Protect information at rest | AES256 server-side encryption on both buckets | `main.tf`: `aws_s3_bucket_server_side_encryption_configuration` |
| AU-3 | Audit records capture who, what, when, where, outcome | Server access logging from the primary bucket to the log bucket (`access-logs/`) | `main.tf`: `aws_s3_bucket_logging` |
| AU-6 | Audit records available for review | Dedicated, encrypted, access-blocked log bucket, separate from the data | `main.tf`: `log_bucket` resources |
| CM-6 | Enforced configuration settings | Provider `default_tags` on every resource; versioning enabled | `main.tf`: `provider "aws"`, `aws_s3_bucket_versioning` |
| AC-3 | Access enforcement | All four S3 public access block settings enabled on both buckets | `main.tf`: `aws_s3_bucket_public_access_block` |

Related frameworks: SOC 2 CC6.1 (SC-28, AC-3), PCI DSS Requirement 3 (protect stored data), HIPAA encryption safeguard for PHI at rest.

## Evidence

- `evidence/lab-2-3/plan.json`: the approved plan (design evidence)
- `evidence/lab-2-3/state.json`: what was actually built (implementation evidence)

Verified against the live AWS account with the AWS CLI (`get-bucket-encryption`, `get-public-access-block`, `get-bucket-versioning`, `get-bucket-logging`). All five controls confirmed in effect.

## Usage

    terraform init
    terraform plan -var="project_name=grclab" -var="environment=dev" -out=tfplan
    terraform show -json tfplan > ../../../evidence/lab-2-3/plan.json
    terraform apply tfplan
    terraform show -json > ../../../evidence/lab-2-3/state.json

Resources are destroyed after each lab session (`terraform destroy`), so the evidence is a point-in-time record.
