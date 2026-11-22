# Lab 2.5: Evidence Vault (IaC as Compliance Evidence)

An S3 bucket with Object Lock (WORM storage) that holds audit evidence so it cannot be deleted or overwritten until its retention date passes, plus a script (`scripts/capture-evidence.sh`) that captures a Terraform workspace's evidence, fingerprints it, and locks it in the vault.

## What it proves

| Property | How |
|---|---|
| Integrity | Every file in the bundle has a SHA-256 hash in `manifest.json`; Object Lock prevents changes |
| Attribution | The bundle includes the latest Git commit (author, message) |
| Reproducibility | Everything is code; anyone can re-run the capture and re-check the hashes |

## Controls

| Control | How this code meets it |
|---|---|
| AU-9 (protection of audit information) | Object Lock default retention; bucket policy denies bucket deletion except by root |
| AU-11 (audit record retention) | Every object is retained for `retention_days` automatically |
| SC-28 | AES256 encryption at rest |
| AC-3 | All four S3 public access block settings enabled |
| CM-6 | Provider default tags on every resource |

Lock mode is `GOVERNANCE` for lab work so resources can be cleaned up; production evidence would use `COMPLIANCE`, where nobody (including root) can delete until retention expires.

## Evidence

- `evidence/lab-2-5/receipt.json`: upload receipt (run ID, vault, key, `version_id`, capture time)
- Verified: retention applied automatically on upload (`get-object-retention`), and deleting the locked version as an administrator was refused with `AccessDenied ... object protected by object lock`.
