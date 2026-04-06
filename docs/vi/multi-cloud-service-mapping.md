# Multi-Cloud Service Mapping

Bảng mapping các dịch vụ tương đương giữa Azure, AWS và GCP. Cột **Self-Hosted** là phần mềm open-source tương đương, giúp hiểu bản chất service managed thực sự là gì.

## Compute

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Virtual Machine | Virtual Machines | EC2 | Compute Engine | KVM / Proxmox |
| Managed K8s | AKS | EKS | GKE | Kubernetes |
| Serverless Function | Azure Functions | Lambda | Cloud Functions | OpenFaaS / Knative |
| Serverless Container | Container Apps | Fargate / App Runner | Cloud Run | Knative |

## Storage

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Object Storage | Blob Storage | S3 | Cloud Storage | MinIO |
| Block Storage | Managed Disks | EBS | Persistent Disk | — |
| File Storage | Azure Files | EFS | Filestore | NFS |

## Database

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Managed SQL | Azure SQL / PostgreSQL | RDS / Aurora | Cloud SQL / AlloyDB | PostgreSQL / MySQL |
| NoSQL (Document) | Cosmos DB | DynamoDB | Firestore / Bigtable | MongoDB / CouchDB |
| Cache | Azure Cache (Redis) | ElastiCache | Memorystore | Redis / Valkey |

## Networking

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Virtual Network | VNet | VPC | VPC | — |
| Load Balancer | Azure LB / App Gateway | ALB / NLB | Cloud Load Balancing | Nginx / HAProxy |
| DNS | Azure DNS | Route 53 | Cloud DNS | CoreDNS / BIND |
| CDN | Azure CDN / Front Door | CloudFront | Cloud CDN | Varnish |

## Security & Identity

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| IAM | Entra ID (AAD) + RBAC | IAM | IAM + Workspace | Keycloak |
| Secret Management | Key Vault | Secrets Manager | Secret Manager | HashiCorp Vault |

## Observability

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Monitoring | Azure Monitor | CloudWatch | Cloud Monitoring | Prometheus + Grafana |
| Logging | Log Analytics | CloudWatch Logs | Cloud Logging | ELK Stack / Loki |

## DevOps & IaC

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| IaC (native) | ARM / Bicep | CloudFormation | Deployment Manager | Terraform / Pulumi |
| CI/CD | Azure DevOps / GitHub Actions | CodePipeline | Cloud Build | Jenkins / GitLab CI |

## Messaging & Streaming

| Category | Azure | AWS | GCP | Self-Hosted |
|---|---|---|---|---|
| Message Queue | Service Bus | SQS / SNS | Pub/Sub | RabbitMQ |
| Event Streaming | Event Hubs | Kinesis / MSK | Pub/Sub / Dataflow | Apache Kafka |

## Notes

- **Azure → AWS**: concept tương đồng ~80%, chỉ khác tên gọi.
- **Azure → GCP**: networking model khác biệt (GCP dùng global VPC vs regional), nhưng overall đơn giản hơn.
- **IaC cross-cloud**: Dùng **Terraform** hoặc **Pulumi** để quản lý cả 3 cloud bằng 1 tool duy nhất.

## Resources

- **Azure**: https://azure.microsoft.com/en-us/products/
- **AWS**: https://aws.amazon.com/products/
- **GCP**: https://cloud.google.com/products
