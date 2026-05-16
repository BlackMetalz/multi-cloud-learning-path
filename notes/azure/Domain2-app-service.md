# Domain 2 — App Service & Deployment Slots

## App Service Plan Tiers

| Tier | SKU | Slots | Auto-scale | Custom domain | VNet |
|---|---|---|---|---|---|
| Free | F1 | ✗ | ✗ | ✗ | ✗ |
| Basic | B1/B2/B3 | ✗ | ✗ | ✓ | ✗ |
| Standard | S1/S2/S3 | ✓ (5) | ✓ | ✓ | ✗ |
| Premium v3 | P1v3/P2v3 | ✓ (20) | ✓ | ✓ | ✓ |
| Isolated v2 | I1v2 | ✓ (20) | ✓ | ✓ | ✓ (dedicated) |

**Rule nhớ nhanh:**
- Cần deployment slot → ít nhất **Standard**
- Cần VNet integration → ít nhất **Premium v3**
- Isolated = App Service Environment (ASE), fully dedicated, đắt tiền

## Deployment Slots

Staging environment riêng biệt trong cùng App Service.

```
code push → [staging slot] → smoke test → swap → [production slot]
                                            ↑
                                      (rollback nếu lỗi: swap ngược)
```

**Key points:**
- Mỗi slot có URL riêng: `app-staging.azurewebsites.net`
- Swap = đổi routing, **không copy code** → zero downtime
- App settings có thể **sticky** (không swap) hoặc swap cùng slot

**Sticky settings** = settings không bị swap:
- Tick "Deployment slot setting" trong App Settings → setting đó gắn với slot, không theo code
- Ví dụ: `ASPNETCORE_ENVIRONMENT=Production` sticky ở production slot → sau swap vẫn là Production

## Scaling

| Type | Mô tả |
|---|---|
| Scale Up | Đổi tier (B1 → S1), nhiều CPU/RAM hơn |
| Scale Out (manual) | Tăng số instance |
| Scale Out (auto) | Dựa trên metric (CPU %, request count) — cần Standard+ |

## Exam Gotchas

- **Deployment Slots** không có ở Free/Basic → câu hỏi "staging environment" = chọn Standard+
- Sau swap, cả 2 slot vẫn running (staging giờ chứa code cũ) → rollback chỉ cần swap lại
- **Always On** setting: cần bật ở Basic+ để app không bị cold start
- App Service Plan = compute resource. Nhiều app có thể share 1 plan (cùng billing, cùng scale)
- **WebJobs** chạy trong cùng App Service plan — không cần tạo resource riêng
