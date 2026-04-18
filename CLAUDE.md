# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Multi-cloud learning path: Azure → AWS → GCP. Documentation-focused repo with hands-on projects.

## Documentation Structure

All docs are bilingual:
- English: `filename.md`
- Vietnamese: `filename.vi.md`

When creating or updating docs, always maintain both versions.

### Docs Organization

```
docs/
├── concepts/     # Cloud-agnostic concepts (serverless, IAM patterns, etc.)
├── azure/        # Azure-specific (CLI, services)
├── en/           # Reference docs (English)
└── vi/           # Reference docs (Vietnamese)
```

## Projects

Projects deploy the same app to multiple clouds using Terraform.

```
projects/01-fullstack-app/
├── app/                    # Shared application code (Dockerfile, nginx)
├── azure/terraform/        # Azure IaC
├── aws/terraform/          # AWS IaC (planned)
└── gcp/terraform/          # GCP IaC (planned)
```

### Terraform Commands (Azure)

```bash
cd projects/01-fullstack-app/azure/terraform
cp terraform.tfvars.example terraform.tfvars  # fill subscription_id
terraform init
terraform plan
terraform apply
```

## Writing Style

- Keep docs concise and practical
- Include CLI examples with comments
- Add multi-cloud comparison tables when relevant
- Focus on "when to use what" guidance
