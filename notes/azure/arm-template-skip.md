# ARM Template — Skip

- **ARM Template** = CloudFormation của Azure (JSON, verbose, khó đọc)
- **Bicep** = ARM nhưng syntax đẹp hơn (vẫn Azure-only)
- **Verdict:** Dùng Terraform. ARM/Bicep chỉ để đọc hiểu legacy hoặc export từ Portal khi cần reverse-engineer.

## Quick Mapping

```
AWS                          →   Azure
─────────────────────────────────────────────
CloudFormation Template      →   ARM Template (JSON)
CloudFormation Stack         →   Resource Group Deployment
SAM Template                 →   Bicep (syntax đẹp hơn)
EC2 Launch Template          →   VMSS Image Config (chỉ cho VM)
```                                   
