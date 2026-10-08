---
id: TD-FamilyTree-002
title: Add-member and profile/CTA buttons from the design are not built
title_vi: Các nút thêm thành viên và hồ sơ/CTA trong design chưa làm
feature: FamilyTree
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeEmptyView.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewController.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
---

## Description / Mô tả
EN: The prototype has a "+" in the header and two buttons at the bottom of the sheet ("Hồ sơ đầy đủ" and "Thêm con cháu" / "Nhắc ngày giỗ"). They are omitted rather than shipped as dead controls, because no add-member form, member profile or reminder hook exists.
VI: Prototype có nút "+" ở header và hai nút cuối sheet ("Hồ sơ đầy đủ" và "Thêm con cháu" / "Nhắc ngày giỗ"). Các nút này được bỏ thay vì đưa vào dưới dạng nút không hoạt động, vì chưa có form thêm thành viên, hồ sơ thành viên hay móc nhắc giỗ.

EN: The empty state's "Tạo gia phả mới" now opens the create screen (`FamilyTreeCreate`, 2026-10-03). "Tham gia bằng mã mời" is built and sends `joinTapped`, but its ViewModel handler is still a one-line `print("TODO: ...")` stub — no invite-code screen or API exists.
VI: Nút "Tạo gia phả mới" ở màn trống giờ mở màn tạo gia phả (`FamilyTreeCreate`, 2026-10-03). "Tham gia bằng mã mời" đã có và phát `joinTapped`, nhưng handler trong ViewModel vẫn chỉ là stub `print("TODO: ...")` — chưa có màn nhập mã mời hay API.

EN: Update (v2.0, 2026-10-03): the header "+" and the sheet's bottom buttons are now built as UI and wired to TODO stubs — see TD-FamilyTree-004 to 008. Only the join-by-invite-code stub remains tracked here.
VI: Cập nhật (v2.0, 2026-10-03): nút "+" ở header và các nút cuối sheet đã được làm ở mức UI và nối tới stub TODO — xem TD-FamilyTree-004 đến 008. Mục này chỉ còn theo dõi stub "Tham gia bằng mã mời".

## Why it was taken on / Lý do chấp nhận nợ
EN: Out of scope for this screen; each needs its own screen/spec (and the Memorial spec lists "add an entry to the book from the tree" as separate work).
VI: Ngoài phạm vi màn này; mỗi nút cần màn/spec riêng (và spec Memorial ghi "thêm vào sổ giỗ từ cây gia phả" là việc riêng).

## Impact / Ảnh hưởng
EN: Users can browse the tree but not edit it.
VI: Người dùng chỉ xem được cây, chưa sửa được.

## Proposed fix / Hướng xử lý
EN: Spec the member form/profile; add `NavEvent` cases (`.addMember`, `.openProfile(id)`, ...) and the matching `Input` triggers, then the buttons.
VI: Viết spec cho form/hồ sơ thành viên; thêm các case `NavEvent` (`.addMember`, `.openProfile(id)`, ...) cùng `Input` tương ứng, rồi thêm nút.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
