# cgep-labs

Hands-on labs for the **Certified GRC Engineer – Practitioner (CGE-P)** certification from the GRC Engineering Club.

The goal: compliance controls defined in code, enforced automatically, and proven with machine-readable evidence instead of screenshots.

## What's here

| Lab | What it shows | Controls | Folder |
|---|---|---|---|
| 2.3 | Compliant S3 bucket in Terraform | SC-28, AU-3, AU-6, CM-6, AC-3 | [`terraform/primitives/compliant-s3`](terraform/primitives/compliant-s3) |
| 2.5 | Tamper-resistant evidence vault (S3 Object Lock) and evidence capture script | AU-9, AU-11, SC-28, AC-3 | [`terraform/primitives/evidence-vault`](terraform/primitives/evidence-vault), [`scripts/capture-evidence.sh`](scripts/capture-evidence.sh) |
| Pipeline | Every pull request runs Terraform format/validate and a Checkov policy scan; `main` is protected and only accepts changes that pass. Risk-accepted findings are documented inline with justifications | CM-3, CM-6, SA-11 | [`.github/workflows/compliance.yml`](.github/workflows/compliance.yml) |

## Layout

- `terraform/primitives/`: standalone infrastructure units
- `terraform/modules/`: reusable modules
- `scripts/`: helper and evidence scripts
- `evidence/`: machine-readable evidence, one folder per lab

All data in this repo is synthetic. No secrets, state files, or real personal data are committed (see `.gitignore`).
