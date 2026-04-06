# Serverless Functions — Bản chất đằng sau Lambda, Azure Functions & Cloud Functions

## Serverless Function là gì?

Serverless function là đơn vị compute đơn giản nhất trên cloud:

```
Event → Function → Response
```

Bạn viết 1 function. Platform chạy nó. Bạn không quản lý server.

Hết. Lambda, Azure Functions, Cloud Functions, OpenFaaS — tất cả chỉ là các implementation khác nhau của cùng 1 ý tưởng.

## Đặc điểm cốt lõi

| Đặc điểm | Ý nghĩa |
|---|---|
| **Event-driven** | Function chạy khi có trigger (HTTP request, message từ queue, file upload, cron schedule...) |
| **Stateless** | Mỗi lần gọi là độc lập. Không có state local nào sống sót giữa các lần gọi. Lưu state ở DB/Storage bên ngoài. |
| **Short-lived** | Function có timeout (Lambda: 15 phút, Azure Functions: 10 phút). Không dùng cho job chạy lâu. |
| **Scale to zero** | Không có request = không có instance chạy = không tốn tiền (cloud) hoặc không tốn resource (self-hosted). |
| **Auto-scale** | Platform tự lo scale up/down theo traffic. Bạn không cần config số lượng instance. |

## Cách hoạt động thực tế

```
1. Bạn viết 1 function:
   ┌──────────────────────────────┐
   │ function handler(event) {    │
   │   // logic của bạn           │
   │   return { status: "ok" }    │
   │ }                            │
   └──────────────────────────────┘

2. Deploy lên platform:
   - Cloud: Lambda / Azure Functions / Cloud Functions
   - Self-hosted: OpenFaaS / Knative

3. Platform cho bạn 1 HTTP endpoint:
   https://my-function.azurewebsites.net/api/handler

4. Khi có request đến:
   Event ──→ Platform khởi tạo container ──→ Chạy function ──→ Trả response
                                                              ──→ Container giữ warm hoặc tắt
```

## Các loại Trigger

Function không chỉ phản hồi HTTP. Các trigger phổ biến:

| Trigger | Ví dụ |
|---|---|
| HTTP | REST API endpoint |
| Queue | Xử lý message từ Service Bus / SQS / Pub/Sub |
| Storage | File được upload lên Blob Storage / S3 |
| Timer/Cron | Chạy mỗi 5 phút |
| Database | Row được insert/update |
| Event Stream | Message từ Event Hubs / Kinesis |

## Vấn đề Cold Start

Khi function không được gọi một thời gian, platform tắt container đi. Request tiếp theo phải:

1. Khởi tạo container mới
2. Load code của bạn
3. Khởi tạo runtime
4. Rồi mới chạy function

Độ trễ này (100ms đến vài giây) gọi là **cold start**. Quan trọng với API cần latency thấp, ít ảnh hưởng với background job.

**Cách giảm thiểu:**
- Provisioned concurrency (Lambda) / Always Ready instances (Azure) — giữ container luôn sẵn sàng
- Package function nhỏ gọn — khởi tạo nhanh hơn
- Dùng compiled language (Go, Rust) thay vì interpreted (Python, Node) để init nhanh hơn

## Khi nào nên dùng Serverless Functions

**Phù hợp:**
- Webhook handlers
- API backend có traffic không đều / bursty
- Xử lý ảnh/video khi có file upload
- Cron jobs / scheduled tasks
- Event processing (queue consumers, stream processors)
- Glue code giữa các services

**Không phù hợp:**
- Process chạy lâu (>15 phút)
- Ứng dụng stateful (websockets, game servers)
- Traffic cao và ổn định (chạy container 24/7 rẻ hơn)
- Cần latency thấp và dự đoán được (cold start ảnh hưởng)

## So sánh các Cloud Implementations

| | Azure Functions | AWS Lambda | GCP Cloud Functions | OpenFaaS |
|---|---|---|---|---|
| **Max timeout** | 10 phút (Consumption) | 15 phút | 9 phút (1st gen) / 60 phút (2nd gen) | Tuỳ config |
| **Ngôn ngữ** | C#, JS, Python, Java, Go, PowerShell | JS, Python, Go, Java, Rust, .NET | JS, Python, Go, Java, .NET, Ruby, PHP | Bất kỳ (Docker) |
| **Trigger sources** | Azure services, HTTP, Timer | AWS services, HTTP, Cron | GCP services, HTTP, Cron | HTTP, Cron, Connectors |
| **Pricing model** | Theo lượt gọi + thời gian chạy | Theo lượt gọi + thời gian chạy | Theo lượt gọi + thời gian chạy | Chi phí infra của bạn |
| **Vendor lock-in** | Cao (Azure SDK, bindings) | Cao (AWS SDK, event format) | Cao (GCP SDK) | Không |
| **Cold start** | ~1-3s (Consumption) | ~100ms-1s | ~100ms-2s | Tuỳ setup |

## Điểm mấu chốt

> Tất cả serverless function platform đều giải quyết cùng 1 bài toán: **chạy đoạn code này khi event này xảy ra, và tôi không muốn nghĩ về server.**
>
> Sự khác biệt nằm ở pricing, timeout limits, trigger integrations, và mức độ lock-in — không phải ở concept cơ bản.

Học pattern 1 lần. Phần còn lại chỉ là configuration.
