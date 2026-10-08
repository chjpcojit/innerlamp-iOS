---
id: TD-SutraDetail-001
title: Mock sutra catalog duplicated between SutraDetail and Sutras
title_vi: Catalog kinh mẫu bị lặp giữa SutraDetail và Sutras
feature: SutraDetail
level: Low
status: Resolved
created: 2026-10-03
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/SutraDetail/ILSutraDetailUseCase.swift
  - InnerLamp/Domain/UseCases/Sutras/ILSutrasUseCase.swift
---

## Description / Mô tả
EN: `ILSutraDetailUseCaseImpl.makeSutraCatalog()` repeats the 11 sutra ids, durations, purposes, sect, audio and downloaded flags that `ILSutrasUseCaseImpl.makeCatalog()` already holds. Non-Pháp-Cú sutras also share 2 placeholder parts, as in the design prototype.
VI: `ILSutraDetailUseCaseImpl.makeSutraCatalog()` lặp lại id, thời lượng, mục đích, tông phái, cờ audio/đã tải của 11 bộ kinh đã có trong `ILSutrasUseCaseImpl.makeCatalog()`. Các bộ kinh ngoài Pháp Cú cũng dùng chung 2 phần giữ chỗ như prototype.

## Why it was taken on / Lý do chấp nhận nợ
EN: No sutra API exists yet; both catalogs are mocks and will be replaced together.
VI: Chưa có API kinh; cả hai catalog đều là mock và sẽ được thay cùng lúc.

## Impact / Ảnh hưởng
EN: Editing a sutra in one place can leave the list and the detail screen inconsistent.
VI: Sửa một bộ kinh ở một nơi có thể làm danh sách và màn chi tiết lệch nhau.

## Proposed fix / Hướng xử lý
EN: Replace both with one repository backed by the real API (`SutraDetail` tasks.md Phase 3).
VI: Thay cả hai bằng một repository dùng API thật (tasks.md Phase 3 của SutraDetail).

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-07 — both screens now read the server catalog; neither keeps a mock catalog. (Reader and Player still keep their own — see TD-SutraDetail-003.)
VI: Đã xử lý 2026-10-07 — cả hai màn đều đọc catalog từ server, không còn catalog mock. (Reader và Player vẫn còn catalog riêng — xem TD-SutraDetail-003.)
