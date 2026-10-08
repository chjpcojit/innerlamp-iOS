---
id: AS-Temple-002
title: Stretchy header blur range and intensity
title_vi: Khoảng và cường độ làm mờ của hero co giãn
feature: Temple
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILHeaderBlurView.swift:12
  - InnerLamp/Presentation/Scenes/Temple/ILTempleViewController.swift
  - InnerLamp/Presentation/Scenes/Deity/ILDeityViewController.swift (same behavior applied to Buddha / Bodhisattva)
source: Chat request 2026-10-07 (no spec yet)
owner: Product / Design
---

## Assumption / Giả định
EN: "Scroll past 50% of the image height" means the content offset exceeds 0.5 × image height; blur grows linearly until offset = image height ("image passed the top edge"), where it stops at 0.7 of the system ultra-thin-material blur ("just enough", not fully opaque). Only a header-height strip (`ILHeaderBlurView` in the sticky header band) blurs the hero scrolling under it. With no image the header never blurs. Nav-bar glyphs are light over a photo and theme-colored otherwise.
VI: "Cuộn quá 50% chiều cao ảnh" nghĩa là offset > 0.5 × chiều cao ảnh; độ mờ tăng tuyến tính đến khi offset = chiều cao ảnh (ảnh qua mép trên) và dừng ở 0.7 của blur ultra-thin-material ("vừa đủ", không mờ hẳn). Chỉ dải cao bằng header (`ILHeaderBlurView`) bị mờ, làm mờ hero trượt dưới nó. Không có ảnh thì không mờ. Icon nav bar màu sáng khi đè lên ảnh, ngược lại theo theme.

## Rationale / Cơ sở giả định
EN: Matches the verbal description; exact numbers were not given.
VI: Khớp mô tả bằng lời; chưa có số liệu cụ thể.

## Implications if wrong / Hệ quả nếu sai
EN: Only two constants (`blurStartFraction` in `ILStretchyHeaderView`, `maxIntensity` in `ILHeaderBlurView`) change.
VI: Chỉ cần đổi hai hằng số (`blurStartFraction` in `ILStretchyHeaderView`, `maxIntensity` in `ILHeaderBlurView`).

## Validation / Cách xác nhận
EN: Review on a physical device with Design.
VI: Xem trên máy thật cùng Design.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
