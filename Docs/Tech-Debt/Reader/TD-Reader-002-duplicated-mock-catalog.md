---
id: TD-Reader-002
title: Reader duplicates the sutra mock catalog
title_vi: Reader nhân đôi catalog kinh mock
feature: Reader
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Reader/ILReaderUseCase.swift:130
---

## Description / Mô tả
EN: `ILReaderUseCaseImpl.makeSutraCatalog()` repeats the 11 sutra ids, durations and audio flags already in `ILSutraDetailUseCaseImpl`/`ILSutrasUseCaseImpl`; chant text exists only for Pháp Cú and Tâm Kinh, the rest show a placeholder.
VI: `ILReaderUseCaseImpl.makeSutraCatalog()` lặp lại id, thời lượng, cờ audio của 11 bộ kinh đã có ở `ILSutraDetailUseCaseImpl`/`ILSutrasUseCaseImpl`; chỉ Pháp Cú và Tâm Kinh có kinh văn, còn lại hiện placeholder.

## Why it was taken on / Lý do chấp nhận nợ
EN: Same as TD-SutraDetail-001: no sutra API yet, and the features are independent.
VI: Giống TD-SutraDetail-001: chưa có API kinh, các feature độc lập.

## Impact / Ảnh hưởng
EN: Changing a sutra in one catalog can leave the others stale.
VI: Sửa một bộ kinh ở một catalog có thể làm các catalog khác lệch.

## Proposed fix / Hướng xử lý
EN: Replace all mock catalogs with one `ILSutraRepository` once the API contract is confirmed.
VI: Thay mọi catalog mock bằng một `ILSutraRepository` khi chốt hợp đồng API.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
