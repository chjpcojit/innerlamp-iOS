---
id: AS-FamilyTree-010
title: A user has at most two books: paternal (nội) first, then maternal (ngoại)
title_vi: Mỗi người dùng có tối đa hai gia phả: bên nội trước, rồi bên ngoại
feature: FamilyTree
level: Medium
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Domain/Entities/ILFamilyTreeEntity.swift:49
source: Docs/Specs/FamilyTree/requirements.md (v2.2, clan switcher)
owner: Product / BA
---

## Assumption / Giả định
EN: The first book a user creates is their father's side (`.paternal`), the second is their mother's side (`.maternal`), and "Tạo gia phả mới" disappears from the switcher menu once both exist. The side is not asked in the create form.
VI: Gia phả đầu tiên người dùng tạo là bên cha (`.paternal`), gia phả thứ hai là bên mẹ (`.maternal`), và mục "Tạo gia phả mới" biến mất khỏi menu khi đã đủ hai. Form tạo không hỏi bên nào.

## Rationale / Cơ sở giả định
EN: The prototype's switcher lists "Họ Nguyễn Hữu" (nội), "Họ Trần" (ngoại) and the merged view; no other kinds of book appear. Product answer of 2026-10-04: "Danh sách cây + gộp".
VI: Menu chọn trong prototype liệt kê "Họ Nguyễn Hữu" (nội), "Họ Trần" (ngoại) và view gộp; không có loại gia phả nào khác. Product trả lời 2026-10-04: "Danh sách cây + gộp".

## Implications if wrong / Hệ quả nếu sai
EN: A user with a third book (a spouse's side, a joined book) cannot add it; a user who creates the maternal book first gets it labelled paternal.
VI: Người dùng có gia phả thứ ba (bên vợ/chồng, gia phả tham gia) không thêm được; người tạo bên ngoại trước sẽ bị gán nhãn bên nội.

## Validation / Cách xác nhận
EN: Confirm with Product whether more than two books or an explicit side choice is needed, and how joined books (invite code) are labelled.
VI: Xác nhận với Product có cần nhiều hơn hai gia phả hoặc cho chọn bên không, và gia phả tham gia (mã mời) được gán nhãn thế nào.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
