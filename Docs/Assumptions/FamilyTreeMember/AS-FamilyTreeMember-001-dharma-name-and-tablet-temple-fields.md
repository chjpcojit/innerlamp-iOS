---
id: AS-FamilyTreeMember-001
title: `dharmaName` and `tabletTemple` added to the member entity without an API contract
title_vi: Thêm `dharmaName` và `tabletTemple` vào entity thành viên khi chưa có hợp đồng API
feature: FamilyTreeMember
level: Medium
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/Entities/ILFamilyTreeEntity.swift
  - InnerLamp/Domain/UseCases/FamilyTreeMember/ILFamilyTreeMemberUseCase.swift
source: Docs/Specs/FamilyTreeMember/requirements.md (FTM-9, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: A member has an optional Buddhist name (Pháp danh) and an optional name of the temple that keeps the ancestral tablet (Bài vị thờ tại), both free text, edited on the profile.
VI: Mỗi thành viên có thể có Pháp danh và tên nơi thờ bài vị (Bài vị thờ tại), đều là văn bản tự do, sửa ở màn hồ sơ.

## Rationale / Cơ sở giả định
EN: The prototype's profile edit form has both fields; the detail sheet already reserved the rows (AS-FamilyTree-006). Free text is the simplest shape.
VI: Form sửa hồ sơ trong prototype có cả hai trường; detail sheet đã chừa sẵn hai dòng (AS-FamilyTree-006). Văn bản tự do là dạng đơn giản nhất.

## Implications if wrong / Hệ quả nếu sai
EN: The real API may model the temple as a reference to a temple record (and link to the Temple scene); the entity and DTO would change.
VI: API thật có thể mô hình nơi thờ là tham chiếu tới một ngôi chùa (và liên kết sang màn Chùa); entity và DTO sẽ phải đổi.

## Validation / Cách xác nhận
EN: Ask Product/BA and the backend owner for the field contract before the data layer is built.
VI: Hỏi Product/BA và chủ API về hợp đồng trường dữ liệu trước khi dựng data layer.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
