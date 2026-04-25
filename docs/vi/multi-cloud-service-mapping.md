# Multi-Cloud Service Mapping

Bảng mapping các dịch vụ tương đương giữa Azure, AWS và GCP.

- **Self-Hosted**: phần mềm open-source có thể tự chạy trên infrastructure của mình
- **SaaS**: dịch vụ bên thứ 3, dùng được với mọi cloud (không self-host được)

## Compute

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Virtual Machine | Virtual Machines | EC2 | Compute Engine | KVM / Proxmox | — |
| Managed K8s | AKS | EKS | GKE | Kubernetes | — |
| Serverless Function | Azure Functions | Lambda | Cloud Functions | OpenFaaS / Knative | — |
| Serverless Container | Container Apps | Fargate / App Runner | Cloud Run | Knative | — |

## Storage

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Object Storage | Blob Storage | S3 | Cloud Storage | MinIO | — |
| Block Storage | Managed Disks | EBS | Persistent Disk | — | — |
| File Storage | Azure Files | EFS | Filestore | NFS | — |

### Phân cấp Object Storage

Azure có thêm 1 cấp so với AWS/GCP — `Storage Account` không có khái niệm tương đương trực tiếp.

| Cấp | Azure | AWS | GCP |
|---|---|---|---|
| Account / Project | Storage Account | (AWS account) | (GCP project) |
| Nhóm ("bucket") | Container | Bucket | Bucket |
| File | Blob | Object | Object |

1 Azure Storage Account chứa nhiều Blob Container (và File share, Queue, Table). AWS/GCP thì bucket nằm thẳng dưới account/project.

## Database

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Managed SQL | Azure SQL / PostgreSQL | RDS / Aurora | Cloud SQL / AlloyDB | PostgreSQL / MySQL | PlanetScale / Neon |
| NoSQL (Document) | Cosmos DB | DynamoDB | Firestore / Bigtable | MongoDB / CouchDB | MongoDB Atlas |
| Cache | Azure Cache (Redis) | ElastiCache | Memorystore | Redis / Valkey | Upstash |

## Networking

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Virtual Network | VNet | VPC | VPC | — | — |
| Load Balancer | Azure LB / App Gateway | ALB / NLB | Cloud Load Balancing | Nginx / HAProxy | — |
| DNS | Azure DNS | Route 53 | Cloud DNS | CoreDNS / BIND | Cloudflare DNS |
| CDN | Azure CDN / Front Door | CloudFront | Cloud CDN | Varnish | Cloudflare CDN |
| API Gateway | API Management | API Gateway | Apigee / API Gateway | Kong / APISIX | — |
| Service Mesh | Open Service Mesh | App Mesh | Anthos Service Mesh | Istio / Linkerd | — |

## Security & Identity

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| IAM | Entra ID (AAD) + RBAC | IAM | IAM + Workspace | Keycloak | Auth0 / Okta |
| Workload Identity | Managed Identity (SAMI / UAMI) | IAM Role (cho EC2/Lambda) | Service Account | — | — |
| Secret Management | Key Vault | Secrets Manager | Secret Manager | HashiCorp Vault | Doppler |

## Observability

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Monitoring | Azure Monitor | CloudWatch | Cloud Monitoring | Prometheus + Grafana | Datadog / New Relic |
| Logging | Log Analytics | CloudWatch Logs | Cloud Logging | ELK Stack / Loki | Datadog / Splunk |

## DevOps & IaC

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| IaC (native) | ARM / Bicep | CloudFormation | Deployment Manager | Ansible | Terraform Cloud / Pulumi Cloud |
| CI/CD | Azure DevOps | CodePipeline | Cloud Build | Jenkins / GitLab CI | GitHub Actions / CircleCI |

## Messaging & Streaming

| Category | Azure | AWS | GCP | Self-Hosted | SaaS |
|---|---|---|---|---|---|
| Message Queue | Service Bus | SQS / SNS | Pub/Sub | RabbitMQ | — |
| Event Streaming | Event Hubs | Kinesis / MSK | Pub/Sub / Dataflow | Apache Kafka | Confluent Cloud |

## Notes

- **Azure → AWS**: concept tương đồng ~80%, chỉ khác tên gọi.
- **Azure → GCP**: networking model khác biệt (GCP dùng global VPC vs regional), nhưng overall đơn giản hơn.
- **IaC cross-cloud**: Dùng **Terraform** hoặc **Pulumi** để quản lý cả 3 cloud bằng 1 tool duy nhất.

## Resources

- **Azure**: https://azure.microsoft.com/en-us/products/
- **AWS**: https://aws.amazon.com/products/
- **GCP**: https://cloud.google.com/products
