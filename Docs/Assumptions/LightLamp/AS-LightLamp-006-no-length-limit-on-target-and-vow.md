---
id: AS-LightLamp-006
title: No maximum length on the dedication target and the vow
title_vi: Chưa giới hạn độ dài của "Dành cho" và lời nguyện
feature: LightLamp
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLightLampViewController.swift:76
  - InnerLamp/Domain/UseCases/LightLamp/ILLightLampUseCase.swift:43
source: Docs/Specs/LightLamp/requirements.md (Pending — maximum length, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Neither field enforces a character limit. Long text is truncated with an ellipsis on garden cards and wraps on the completion card.
VI: Cả hai ô không giới hạn ký tự. Chữ dài bị cắt bằng dấu ba chấm trên thẻ vườn đèn và xuống dòng trên thẻ hoàn tất.

## Rationale / Cơ sở giả định
EN: No limit is specified in the prototype or doc; inventing one could silently drop user text.
VI: Prototype và tài liệu không nêu giới hạn; tự đặt giới hạn có thể làm mất chữ của người dùng.

## Implications if wrong / Hệ quả nếu sai
EN: A server API later may impose a limit, requiring input limits and a migration for long existing text.
VI: API sau này có thể đặt giới hạn, cần giới hạn khi nhập và xử lý dữ liệu dài đã có.

## Validation / Cách xác nhận
EN: Ask Product/Backend for the limits.
VI: Hỏi Product/Backend về giới hạn.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
