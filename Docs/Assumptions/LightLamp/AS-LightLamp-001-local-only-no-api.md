---
id: AS-LightLamp-001
title: Lit lamps are stored only on the device (Core Data), no backend
title_vi: Đèn đã thắp chỉ lưu trên thiết bị (Core Data), chưa có backend
feature: LightLamp
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILLampRepositoryImpl.swift:9
  - InnerLamp/Data/DataSources/Local/ILLampLocalDataSource.swift:17
source: Docs/Specs/LightLamp/requirements.md (Out of scope — server-side lamp API, ⚠️ Not confirmed)
owner: Product / Backend
---

## Assumption / Giả định
EN: Lamps live only in the local Core Data store (`Lamp` entity, model `InnerLamp 5`). There is no sync, no per-account scope; deleting the app deletes the lamps.
VI: Đèn chỉ nằm trong Core Data cục bộ (entity `Lamp`, model `InnerLamp 5`). Không đồng bộ, không gắn theo tài khoản; xóa app là mất đèn.

## Rationale / Cơ sở giả định
EN: The user chose local Core Data behind a repository protocol because no lamp API exists (decision 2026-10-10).
VI: Người dùng chọn Core Data cục bộ sau một repository protocol vì chưa có API đèn (quyết định 2026-10-10).

## Implications if wrong / Hệ quả nếu sai
EN: If the server should own lamps, existing local lamps need a one-time upload and a merge rule; the model needs a server id / sync state.
VI: Nếu server là nơi giữ đèn, đèn cục bộ cần tải lên một lần và có quy tắc gộp; model cần thêm server id / trạng thái đồng bộ.

## Validation / Cách xác nhận
EN: Ask backend for a lamp contract (endpoints, per-account scope, community garden rules).
VI: Hỏi backend hợp đồng API đèn (endpoint, phạm vi theo tài khoản, quy tắc vườn đèn cộng đồng).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
