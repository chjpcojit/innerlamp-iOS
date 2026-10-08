---
id: AS-Deity-DEVA
title: DEVA deity type is labelled "Thiên Nữ" and has no filter chip
title_vi: Loại DEVA được gắn nhãn "Thiên Nữ" và không có chip lọc
feature: Deity
level: Low
status: Unvalidated
created: 2026-10-06
updated: 2026-10-06
files:
  - InnerLamp/Resources/Localization/vi.json
  - InnerLamp/Presentation/Scenes/Deities/ILDeitiesViewModel.swift
source: BE session [BE]-InnerLamp message 2026-10-06 (type enum gained DEVA; 1 item, deva_sri_mahadevi)
owner: Product / BA
---

## Assumption / Giả định
EN: `DEVA` shows the label "Thiên Nữ" (only item today is Đại Cát Tường Thiên Nữ) and appears under the "All" filter only; no dedicated filter chip.
VI: `DEVA` hiển thị nhãn "Thiên Nữ" (hiện chỉ có Đại Cát Tường Thiên Nữ) và chỉ xuất hiện ở bộ lọc "Tất cả"; không có chip lọc riêng.

## Rationale / Cơ sở giả định
EN: Backend gave no display copy; one item does not justify a new filter.
VI: Backend không cung cấp nhãn hiển thị; chỉ 1 mục nên chưa cần chip lọc.

## Implications if wrong / Hệ quả nếu sai
EN: Wrong label text or missing filter; trivially fixable.
VI: Sai nhãn hoặc thiếu bộ lọc; sửa dễ.

## Validation / Cách xác nhận
EN: Ask Product for the label and whether DEVA needs a chip.
VI: Hỏi Product về nhãn và việc có cần chip cho DEVA.

## Outcome / Kết luận
EN: _(pending)_
VI: _(chờ xác nhận)_
