---
id: AS-FamilyTreeMember-003
title: The back chip acts as "Hủy" in edit mode
title_vi: Nút quay lại đóng vai trò "Hủy" ở chế độ sửa
feature: FamilyTreeMember
level: Low
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeMember/ILFamilyTreeMemberViewController.swift
owner: Product / BA
---

## Assumption / Giả định
EN: The design shows a text "Hủy" on the left of the edit header; the screen reuses `ILNavBar`, which only has a back chip on the left, so the chip discards the edit.
VI: Thiết kế có chữ "Hủy" bên trái header khi sửa; màn hình dùng lại `ILNavBar` chỉ có nút quay lại bên trái, nên nút này hủy bản sửa.

## Rationale / Cơ sở giả định
EN: Reusing the shared nav bar keeps the header consistent; the position and meaning match the design.
VI: Dùng lại nav bar chung giữ header nhất quán; vị trí và ý nghĩa khớp thiết kế.

## Implications if wrong / Hệ quả nếu sai
EN: Users may expect the chip to leave the screen; a text "Hủy" button would be added to `ILNavBar`.
VI: Người dùng có thể mong nút này thoát màn hình; khi đó cần thêm nút chữ "Hủy" vào `ILNavBar`.

## Validation / Cách xác nhận
EN: Check with Design whether an icon chip is acceptable for "Hủy".
VI: Hỏi Design xem dùng chip biểu tượng cho "Hủy" có chấp nhận được không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
