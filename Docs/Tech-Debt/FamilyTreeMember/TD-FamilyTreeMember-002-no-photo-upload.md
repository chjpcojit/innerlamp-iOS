---
id: TD-FamilyTreeMember-002
title: No portrait photo on the profile or in the edit form
title_vi: Chưa có ảnh chân dung ở hồ sơ và form sửa
feature: FamilyTreeMember
level: Low
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeMember/Views/ILFamilyTreeMemberHeroView.swift
---

## Description / Mô tả
EN: The design shows a circular portrait with an image drop slot ("Kéo ảnh chân dung vào khung"). The screen shows the hexagon medallion instead and the form has no photo field.
VI: Thiết kế có ảnh chân dung tròn kèm ô thả ảnh ("Kéo ảnh chân dung vào khung"). Màn hình dùng huy hiệu lục giác thay thế và form không có trường ảnh.

## Why it was taken on / Lý do chấp nhận nợ
EN: No photo storage / upload API and no picker flow exist; the entity has no photo field.
VI: Chưa có kho ảnh / API tải ảnh, cũng chưa có luồng chọn ảnh; entity không có trường ảnh.

## Impact / Ảnh hưởng
EN: Users cannot attach a portrait to a family member.
VI: Người dùng chưa thể gắn ảnh chân dung cho thành viên.

## Proposed fix / Hướng xử lý
EN: When storage is confirmed: add a photo field to the entity, a picker (PhotoKit) in edit mode, and the circular frame in the hero.
VI: Khi chốt phương án lưu trữ: thêm trường ảnh vào entity, bộ chọn ảnh (PhotoKit) ở chế độ sửa và khung tròn ở phần đầu hồ sơ.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
