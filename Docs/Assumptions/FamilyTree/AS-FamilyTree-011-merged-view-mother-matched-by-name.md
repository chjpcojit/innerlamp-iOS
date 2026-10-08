---
id: AS-FamilyTree-011
title: In the merged view the mother's own family is found in the maternal book by name
title_vi: Ở view gộp, gia đình gốc của mẹ được tìm trong gia phả bên ngoại theo tên
feature: FamilyTree
level: Medium
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTree/ILFamilyTreePedigree.swift:91
source: Docs/Specs/FamilyTree/requirements.md (v2.2, clan switcher)
owner: Product / BA
---

## Assumption / Giả định
EN: The viewer's mother is a married-in spouse in the paternal book. Her family is the woman of the maternal book with the same name (diacritics and case ignored) who was born into it. No match means the mother is shown without ancestors; two matches pick the first. Other married-in women (grandmothers) are never looked up.
VI: Mẹ của người dùng là người vợ về nhà chồng trong gia phả bên nội. Gia đình bà là người phụ nữ trong gia phả bên ngoại cùng tên (bỏ dấu, không phân biệt hoa thường) và là con ruột của dòng họ đó. Không khớp thì hiện mẹ không có tổ tiên; khớp hai người thì lấy người đầu. Các bà khác về làm dâu (bà nội…) không bao giờ được tra.

## Rationale / Cơ sở giả định
EN: The prototype links the two books by sharing one record id; the app has no cross-book link in its data model yet and ids are generated per book.
VI: Prototype nối hai gia phả bằng cách dùng chung một id; app chưa có liên kết giữa các gia phả trong mô hình dữ liệu và id được sinh theo từng gia phả.

## Implications if wrong / Hệ quả nếu sai
EN: Two women with the same name in the maternal book give the wrong grandparents; a renamed mother breaks the link silently.
VI: Hai người phụ nữ trùng tên trong gia phả bên ngoại sẽ ra nhầm ông bà; đổi tên mẹ làm mất liên kết mà không báo.

## Validation / Cách xác nhận
EN: Replace with an explicit link (member id in the other book) once the data model/API has one, and let the user pick the match when several exist.
VI: Thay bằng liên kết tường minh (id thành viên ở gia phả kia) khi mô hình dữ liệu/API có, và cho người dùng chọn khi có nhiều kết quả khớp.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
