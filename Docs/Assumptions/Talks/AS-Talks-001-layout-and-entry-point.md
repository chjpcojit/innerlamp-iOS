---
id: AS-Talks-001
title: Entry point from the Library tile (design confirms the list screen)
title_vi: Điểm vào từ ô Thư viện (design đã có màn danh sách)
feature: Talks
level: Low
status: Validated
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Presentation/Scenes/Talks/ILTalksViewController.swift:1
  - InnerLamp/Presentation/Scenes/Library/ILLibraryCoordinator.swift:62
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (`libTiles`, `talksVals`)
owner: Product / BA
---

## Assumption / Giả định
EN: The "all talks" list opens from Library's "Pháp thoại" quick-access tile.
VI: Danh sách "tất cả pháp thoại" mở từ ô "Pháp thoại" ở Thư viện.

## Rationale / Cơ sở giả định
EN: The Library tile already had a TODO for a dedicated list screen; the handoff describes no such screen.
VI: Ô ở Thư viện đã có TODO chờ màn danh sách riêng; handoff không mô tả màn này.

## Implications if wrong / Hệ quả nếu sai
EN: Rework of one screen's layout/entry points.
VI: Làm lại bố cục/điểm vào của một màn.

## Validation / Cách xác nhận
EN: Product/Design to supply a mock for the list screen.
VI: Product/Design cung cấp thiết kế cho màn danh sách.

## Outcome / Kết luận
EN: Validated 2026-10-05 against the updated design: `libTiles` "Pháp thoại" → `go('talks')`.
VI: Xác nhận 2026-10-05 theo design mới: ô "Pháp thoại" → `go('talks')`.
