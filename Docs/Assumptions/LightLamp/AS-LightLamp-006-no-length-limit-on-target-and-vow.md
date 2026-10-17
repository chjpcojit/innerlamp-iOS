---
id: AS-LightLamp-006
title: No maximum length on the dedication target and the vow
title_vi: Chưa giới hạn độ dài của "Dành cho" và lời nguyện
feature: LightLamp
level: Low
status: Invalidated
created: 2026-10-11
updated: 2026-10-17
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
EN: Invalidated by product decision of 2026-10-16: the recipient is capped at 100 and the prayer at 300 characters (BR-LMP-06, BR-LMP-07).
VI: Bị bác bỏ bởi quyết định product 2026-10-16: người nhận tối đa 100, lời nguyện tối đa 300 ký tự (BR-LMP-06, BR-LMP-07).
