# Multi-Cloud Service Mapping

Bảng mapping các dịch vụ tương đương giữa Azure, AWS và GCP.

## Compute

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Virtual Machine | Virtual Machines | EC2 | Compute Engine |
| Managed K8s | AKS | EKS | GKE |
| Serverless Function | Azure Functions | Lambda | Cloud Functions |
| Serverless Container | Container Apps | Fargate / App Runner | Cloud Run |

## Storage

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Object Storage | Blob Storage | S3 | Cloud Storage |
| Block Storage | Managed Disks | EBS | Persistent Disk |
| File Storage | Azure Files | EFS | Filestore |

## Database

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Managed SQL | Azure SQL / PostgreSQL | RDS / Aurora | Cloud SQL / AlloyDB |
| NoSQL | Cosmos DB | DynamoDB | Firestore / Bigtable |
| Cache | Azure Cache (Redis) | ElastiCache | Memorystore |

## Networking

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Virtual Network | VNet | VPC | VPC |
| Load Balancer | Azure LB / App Gateway | ALB / NLB | Cloud Load Balancing |
| DNS | Azure DNS | Route 53 | Cloud DNS |
| CDN | Azure CDN / Front Door | CloudFront | Cloud CDN |

## Security & Identity

| Category | Azure | AWS | GCP |
|---|---|---|---|
| IAM | Entra ID (AAD) + RBAC | IAM | IAM + Workspace |
| Secret Management | Key Vault | Secrets Manager | Secret Manager |

## Observability

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Monitoring | Azure Monitor | CloudWatch | Cloud Monitoring |
| Logging | Log Analytics | CloudWatch Logs | Cloud Logging |

## DevOps & IaC

| Category | Azure | AWS | GCP |
|---|---|---|---|
| IaC (native) | ARM / Bicep | CloudFormation | Deployment Manager |
| CI/CD | Azure DevOps / GitHub Actions | CodePipeline | Cloud Build |

## Messaging & Streaming

| Category | Azure | AWS | GCP |
|---|---|---|---|
| Message Queue | Service Bus | SQS / SNS | Pub/Sub |
| Event Streaming | Event Hubs | Kinesis / MSK | Pub/Sub / Dataflow |

## Notes

- **Azure → AWS**: concept tương đồng ~80%, chỉ khác tên gọi.
- **Azure → GCP**: networking model khác biệt (GCP dùng global VPC vs regional), nhưng overall đơn giản hơn.
- **IaC cross-cloud**: Dùng **Terraform** hoặc **Pulumi** để quản lý cả 3 cloud bằng 1 tool duy nhất.

## Resources

- **Azure**: https://azure.microsoft.com/en-us/products/
- **AWS**: https://aws.amazon.com/products/
- **GCP**: https://cloud.google.com/products
