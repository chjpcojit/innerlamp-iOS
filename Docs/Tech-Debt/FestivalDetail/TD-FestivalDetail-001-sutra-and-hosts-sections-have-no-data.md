---
id: TD-FestivalDetail-001
title: "Kinh nên tụng" and "Chùa tổ chức" sections have no data source
title_vi: Mục "Kinh nên tụng" và "Chùa tổ chức" chưa có nguồn dữ liệu
feature: FestivalDetail
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/FestivalDetail/ILFestivalDetailViewModel.swift
  - InnerLamp/Presentation/Scenes/FestivalDetail/ILFestivalDetailViewController.swift
---

## Description / Mô tả
EN: Both sections always render their "no data" text because `GET /v1/calendar/events` returns neither a recommended sutra nor hosting temples.
VI: Cả hai mục luôn hiện câu "chưa có" vì `GET /v1/calendar/events` không trả kinh nên tụng hay chùa tổ chức.

## Why it was taken on / Lý do chấp nhận nợ
EN: Product decision: show the section with "not available" text rather than hide it or invent data.
VI: Quyết định sản phẩm: hiện mục với câu "chưa có" thay vì ẩn hoặc dùng dữ liệu bịa.

## Impact / Ảnh hưởng
EN: Two of the prototype's sections carry no information yet.
VI: Hai mục của prototype chưa có thông tin.

## Proposed fix / Hướng xử lý
EN: When the backend exposes related sutras (link to SutraDetail) and hosting temples (link to Temple), extend `ILCalendarEventDTO`/entities and render rows with navigation.
VI: Khi backend có kinh liên quan (mở SutraDetail) và chùa tổ chức (mở Trang chùa), mở rộng DTO/entity và hiện hàng có điều hướng.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
