---
id: TD-Talks-001
title: List reads a mock catalog (8 talks)
title_vi: Danh sách đọc catalog mock (8 bài)
feature: Talks
level: Medium
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Talks/ILTalksUseCase.swift:22
---

## Description / Mô tả
EN: `ILTalksUseCaseImpl` returns a hardcoded 8-talk catalog (incl. the sample listen progress 28%) copied from the design handoff.
VI: `ILTalksUseCaseImpl` trả về catalog cố định 8 bài (kèm tiến độ nghe mẫu 28%) lấy từ design handoff.

## Why it was taken on / Lý do chấp nhận nợ
EN: No talks list API contract exists yet.
VI: Chưa có hợp đồng API danh sách pháp thoại.

## Impact / Ảnh hưởng
EN: Data is static; resume progress is not read from a saved listen position.
VI: Dữ liệu tĩnh; tiến độ nghe dở không đọc từ vị trí nghe đã lưu.

## Proposed fix / Hướng xử lý
EN: Add `ILTalksRepository` (+ DTO/Mapper) once the API is confirmed; keep the use case signature.
VI: Thêm `ILTalksRepository` (+ DTO/Mapper) khi API được xác nhận; giữ nguyên signature use case.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
