---
id: AS-FamilyTreeMember-002
title: Validation rules of the member edit form
title_vi: Quy tắc kiểm tra của form sửa thành viên
feature: FamilyTreeMember
level: Low
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTreeMember/ILFamilyTreeMemberUseCase.swift:75
source: Docs/Specs/FamilyTreeMember/requirements.md (FTM-6, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Name is required; birth year is optional but, when typed, must be 1700–current year; a deceased member must have a death year (≥ birth year, ≤ current year); the lunar anniversary is optional and must be readable; the residence is optional; gender can be changed freely.
VI: Họ tên bắt buộc; năm sinh không bắt buộc nhưng nếu nhập phải trong 1700–năm hiện tại; người đã mất bắt buộc có năm mất (≥ năm sinh, ≤ năm hiện tại); ngày giỗ âm lịch không bắt buộc nhưng phải đọc được; nơi sống không bắt buộc; giới tính đổi tự do.

## Rationale / Cơ sở giả định
EN: Reuses the add-member limits (AS-FamilyTreeAddMember-001). The birth year and residence are relaxed versus add-member because existing members may lack them, and the prototype edit form does not require them.
VI: Dùng lại giới hạn của form thêm người (AS-FamilyTreeAddMember-001). Năm sinh và nơi sống được nới lỏng so với form thêm vì thành viên cũ có thể thiếu và form sửa trong prototype không bắt buộc.

## Implications if wrong / Hệ quả nếu sai
EN: Wrong limits reject valid edits or accept bad data; changing a married person's gender could leave a same-sex couple in the tree.
VI: Giới hạn sai sẽ từ chối bản sửa hợp lệ hoặc nhận dữ liệu xấu; đổi giới tính người đã có vợ/chồng có thể tạo cặp cùng giới trong cây.

## Validation / Cách xác nhận
EN: Confirm the limits and whether gender may change for people with a spouse or children.
VI: Xác nhận giới hạn và việc có cho đổi giới tính với người đã có vợ/chồng hoặc con hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
