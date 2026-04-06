# Serverless Functions — The Concept Behind Lambda, Azure Functions & Cloud Functions

## What is a Serverless Function?

A serverless function is the simplest unit of cloud compute:

```
Event → Function → Response
```

You write a function. The platform runs it. You don't manage servers.

That's it. Lambda, Azure Functions, Cloud Functions, OpenFaaS — all just implementations of this one idea.

## Core Properties

| Property | What it means |
|---|---|
| **Event-driven** | Function runs in response to a trigger (HTTP request, queue message, file upload, cron schedule...) |
| **Stateless** | Each invocation is independent. No local state survives between calls. Store state in DB/Storage. |
| **Short-lived** | Functions have a timeout (Lambda: 15 min, Azure Functions: 10 min). Not for long-running jobs. |
| **Scale to zero** | No requests = no running instances = no cost (cloud) or no resource usage (self-hosted). |
| **Auto-scale** | Platform handles scaling up/down based on traffic. You don't configure instance count. |

## How It Actually Works

```
1. You write a function:
   ┌──────────────────────────────┐
   │ function handler(event) {    │
   │   // your logic here         │
   │   return { status: "ok" }    │
   │ }                            │
   └──────────────────────────────┘

2. You deploy it to a platform:
   - Cloud: Lambda / Azure Functions / Cloud Functions
   - Self-hosted: OpenFaaS / Knative

3. Platform gives you an HTTP endpoint:
   https://my-function.azurewebsites.net/api/handler

4. When a request comes in:
   Event ──→ Platform spins up container ──→ Runs your function ──→ Returns response
                                                                  ──→ Container stays warm or shuts down
```

## Trigger Types

Functions don't just respond to HTTP. Common triggers:

| Trigger | Example |
|---|---|
| HTTP | REST API endpoint |
| Queue | Process message from Service Bus / SQS / Pub/Sub |
| Storage | File uploaded to Blob Storage / S3 |
| Timer/Cron | Run every 5 minutes |
| Database | Row inserted/updated |
| Event Stream | Message from Event Hubs / Kinesis |

## The Cold Start Problem

When a function hasn't been called for a while, the platform shuts down its container. The next request has to:

1. Start a new container
2. Load your code
3. Initialize runtime
4. Then execute your function

This delay (100ms to several seconds) is called **cold start**. It matters for latency-sensitive APIs, less so for background jobs.

**Mitigation strategies:**
- Provisioned concurrency (Lambda) / Always Ready instances (Azure) — keeps containers warm
- Smaller function packages — faster startup
- Use compiled languages (Go, Rust) over interpreted (Python, Node) for faster init

## When to Use Serverless Functions

**Good fit:**
- Webhook handlers
- API backends with variable/bursty traffic
- Image/video processing triggered by uploads
- Cron jobs / scheduled tasks
- Event processing (queue consumers, stream processors)
- Glue code between services

**Bad fit:**
- Long-running processes (>15 min)
- Stateful applications (websockets, game servers)
- High-throughput, consistent traffic (cheaper to run a container 24/7)
- Requires low, predictable latency (cold starts hurt)

## Cloud Implementations Compared

| | Azure Functions | AWS Lambda | GCP Cloud Functions | OpenFaaS |
|---|---|---|---|---|
| **Max timeout** | 10 min (Consumption) | 15 min | 9 min (1st gen) / 60 min (2nd gen) | Configurable |
| **Languages** | C#, JS, Python, Java, Go, PowerShell | JS, Python, Go, Java, Rust, .NET | JS, Python, Go, Java, .NET, Ruby, PHP | Any (Docker) |
| **Trigger sources** | Azure services, HTTP, Timer | AWS services, HTTP, Cron | GCP services, HTTP, Cron | HTTP, Cron, Connectors |
| **Pricing model** | Per execution + duration | Per execution + duration | Per execution + duration | Your infra cost |
| **Vendor lock-in** | High (Azure SDK, bindings) | High (AWS SDK, event format) | High (GCP SDK) | None |
| **Cold start** | ~1-3s (Consumption) | ~100ms-1s | ~100ms-2s | Depends on setup |

## The Key Insight

> All serverless function platforms solve the same problem: **run this code when this event happens, and I don't want to think about servers.**
>
> The differences are in pricing, timeout limits, trigger integrations, and ecosystem lock-in — not in the fundamental concept.

Learn the pattern once. The rest is just configuration.
