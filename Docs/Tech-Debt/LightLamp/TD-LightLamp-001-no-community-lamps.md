---
id: TD-LightLamp-001
title: Garden has no community lamps / lamp API
title_vi: Vườn đèn chưa có đèn cộng đồng / API đèn
feature: LightLamp
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLampGardenViewModel.swift:127
---

## Description / Mô tả
EN: The garden is fed only by the local lamp repository; there is no remote data source, no DTO/endpoint and no community lamps.
VI: Vườn đèn chỉ lấy dữ liệu từ repository cục bộ; chưa có remote data source, DTO/endpoint và đèn cộng đồng.

## Why it was taken on / Lý do chấp nhận nợ
EN: No backend contract exists (AS-LightLamp-001, AS-LightLamp-002).
VI: Chưa có hợp đồng backend (AS-LightLamp-001, AS-LightLamp-002).

## Impact / Ảnh hưởng
EN: The garden looks personal-only and lamps are lost with the app.
VI: Vườn đèn chỉ mang tính cá nhân và đèn mất theo app.

## Proposed fix / Hướng xử lý
EN: Add a remote data source behind `ILLampRepository` once the API is confirmed; keep Core Data as an offline cache.
VI: Thêm remote data source sau `ILLampRepository` khi API được xác nhận; giữ Core Data làm cache offline.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
