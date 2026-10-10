---
id: TD-Sangha-001
title: Sangha tab content is mock; spec not rewritten; Post scene has no entry point
title_vi: Nội dung tab Chùa còn là dữ liệu mẫu; spec chưa viết lại; màn Post không còn lối vào
feature: Sangha
level: Medium
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Sangha/ILSanghaUseCase.swift:76
  - InnerLamp/Presentation/Scenes/Sangha/ILSanghaCoordinator.swift:42
  - Docs/Specs/Sangha/requirements.md
  - InnerLamp/Presentation/Scenes/Post/ILPostCoordinator.swift
---

## Description / Mô tả
EN: (1) The whole tab is mock data, UI only: temples, announcements, events/retreats, talks, practitioner counts, online sessions and festival days (no API / Core Data; no loading or error state). (2) The "Nhắc tôi" / "Giữ chỗ" pills are display-only toggles (not persisted, no real reminder). (3) "Công đức · cúng dường" and online sessions have no destination screen (TODO in the coordinator). (4) `Docs/Specs/Sangha/*` still describes the removed community feed. (5) The Post scene was only reachable from that feed, so it is unreachable now. (6) "Đổi chùa" has no swap icon (design shows one) — icons must come from `ILIcons`.
VI: (1) Cả tab là dữ liệu mẫu, chỉ có UI: chùa, thông báo, khóa tu/lễ, pháp thoại, số Phật tử, buổi tu trực tuyến và ngày lễ (không gọi API / Core Data; chưa có trạng thái loading / lỗi). (2) Các nút "Nhắc tôi" / "Giữ chỗ" chỉ bật/tắt hiển thị (không lưu, không nhắc thật). (3) "Công đức · cúng dường" và buổi tu trực tuyến chưa có màn đích (TODO trong coordinator). (4) `Docs/Specs/Sangha/*` vẫn mô tả feed cộng đồng đã bỏ. (5) Màn Post chỉ vào được từ feed đó nên nay không còn lối vào. (6) "Đổi chùa" chưa có icon đổi chiều như thiết kế — icon phải lấy từ `ILIcons`.

## Why it was taken on / Lý do chấp nhận nợ
EN: Redesign of the tab UI was the scope; backend contracts, reminders and the offering screen do not exist yet.
VI: Phạm vi là dựng lại UI tab; chưa có contract backend, nhắc lịch và màn cúng dường.

## Impact / Ảnh hưởng
EN: The tab looks complete but shows static content; spec drifts from code; Post code is dead.
VI: Tab trông đầy đủ nhưng nội dung tĩnh; spec lệch code; code màn Post thành code chết.

## Proposed fix / Hướng xử lý
EN: Get API contracts and build the repository (data-builder); rewrite `Docs/Specs/Sangha/` (spec-writer); add the swap icon to `ILIcons`; wire Offer / online sessions; decide the fate of Post.
VI: Lấy contract API và dựng repository (data-builder); viết lại `Docs/Specs/Sangha/` (spec-writer); thêm icon đổi chiều vào `ILIcons`; nối Cúng dường / buổi tu trực tuyến; quyết định số phận màn Post.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
