# Azure Container Services — Quick Reference

## Quick Mapping

```
AWS                              Azure
───────────────────────────────────────────────────
ECR                          →   ACR (Azure Container Registry)
ECS Fargate (single task)    →   ACI (Azure Container Instances)
ECS Fargate (full)           →   Azure Container Apps
App Runner                   →   Azure Container Apps
EKS                          →   AKS (Azure Kubernetes Service)
```

## Phân biệt 3 services

| Service | Là gì | Khi nào dùng |
|---------|-------|--------------|
| **ACI** | Chạy 1 container nhanh, không cluster | Dev/test, batch jobs, CI/CD runners |
| **Container Apps** | Serverless containers có scaling, ingress | Production apps, microservices |
| **AKS** | Full Kubernetes | Cần toàn quyền K8s, phức tạp |

```
Simple ←─────────────────────────→ Complex
  ACI      Container Apps      AKS
```

## So với AWS

| Use case | AWS | Azure |
|----------|-----|-------|
| Run 1 container nhanh | Fargate task / App Runner | ACI |
| Serverless + auto-scale | App Runner / ECS Fargate | Container Apps |
| Full Kubernetes | EKS | AKS |
| Container registry | ECR | ACR |

## Container Scaling vs VM Scaling

| Aspect | VM (VMSS) | Container (Container Apps) |
|--------|-----------|---------------------------|
| Tốc độ | Chậm (1-3 phút) | Nhanh (seconds) |
| Đơn vị | Cả VM | 1 container |
| Min replicas | Thường ≥1 | Có thể = 0 |
| Metrics | CPU, Memory | CPU, Memory, HTTP, Queue, custom |

**Scale to Zero:** Container Apps có thể về 0 replicas — không traffic = không tiền.

**Verdict:** Container Apps đáng chú ý nhất — giống App Runner nhưng mạnh hơn (KEDA scaling, Dapr).
