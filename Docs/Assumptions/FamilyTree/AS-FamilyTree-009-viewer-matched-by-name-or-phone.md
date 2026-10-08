---
id: AS-FamilyTree-009
title: The viewer will be matched to a tree member by account name or phone number
title_vi: Người xem sẽ được khớp với thành viên trong cây theo tên hoặc số điện thoại tài khoản
feature: FamilyTree
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTree/ILFamilyTreeViewerResolver.swift:14
source: Docs/Specs/FamilyTree/requirements.md (Open questions (resolved), "me" id)
owner: Product / BA
---

## Assumption / Giả định
EN: The "me" member is found by matching the signed-in account's name or phone number with the tree's members. The exact rules (diacritics, partial names, ties, members without a phone number) are not defined. Until then the clan head stands in as "me".
VI: Thành viên "tôi" được tìm bằng cách khớp tên hoặc số điện thoại của tài khoản đăng nhập với các thành viên trong cây. Chưa định nghĩa quy tắc chi tiết (dấu tiếng Việt, tên một phần, trùng tên, thành viên không có số điện thoại). Tạm thời tộc trưởng đóng vai "tôi".

## Rationale / Cơ sở giả định
EN: Product decision of 2026-10-03: link by account name/phone later; the member model has a name but no phone field yet (AS-FamilyTree-001).
VI: Quyết định của Product ngày 2026-10-03: liên kết theo tên/số điện thoại của tài khoản sau; model thành viên hiện có tên nhưng chưa có trường số điện thoại (AS-FamilyTree-001).

## Implications if wrong / Hệ quả nếu sai
EN: A wrong or missing match shows "BẠN" on the wrong person or hides it; fixing it only means replacing the resolver, but the member data may need a phone field.
VI: Khớp sai hoặc không khớp sẽ hiện "BẠN" sai người hoặc ẩn đi; chỉ cần thay resolver, nhưng dữ liệu thành viên có thể cần thêm trường số điện thoại.

## Validation / Cách xác nhận
EN: Confirm with Product/BA the matching rules and whether members get a phone number field; check against real clan data once the API exists.
VI: Xác nhận với Product/BA quy tắc khớp và việc thêm trường số điện thoại cho thành viên; kiểm tra với dữ liệu gia phả thật khi có API.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
