---
id: AS-FamilyTree-008
title: Header keeps a back chevron and hides search/+ in the empty state
title_vi: Header giữ nút quay lại và ẩn tìm/+ ở màn trống
feature: FamilyTree
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeHeaderView.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewController.swift
source: Docs/InnerLamp project/IL-GiaPha.dc.html (header)
owner: Product / BA
---

## Assumption / Giả định
EN: The header keeps the design's back chevron (the screen is pushed) before the seal, and the search and "+" buttons are hidden while the tree is empty. The legend omits the BẠN item until Phase 4.
VI: Header giữ nút quay lại của design (màn được push) trước con dấu, và các nút tìm và "+" bị ẩn khi cây trống. Legend chưa có mục BẠN cho tới Phase 4.

## Rationale / Cơ sở giả định
EN: The design shows no empty-tree header; searching or adding to an empty tree makes no sense, and the pushed screen needs a way back.
VI: Design không có header cho cây trống; tìm hoặc thêm vào cây trống không có nghĩa, và màn push cần lối quay lại.

## Implications if wrong / Hệ quả nếu sai
EN: The header would be adjusted in design review.
VI: Header sẽ được chỉnh lại sau design review.

## Validation / Cách xác nhận
EN: Design review of the built screen on a device.
VI: Design review màn đã build trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
