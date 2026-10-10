---
id: AS-AddTemple-001
title: Proposed temples are matched and named by local rules
title_vi: Chùa đề xuất được so khớp và đặt tên theo quy tắc cục bộ
feature: AddTemple
level: Medium
status: Unvalidated
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Domain/UseCases/AddTemple/ILAddTempleUseCase.swift
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (addTpVals, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: A proposal is a duplicate when its core name (without "Chùa/Thiền viện/Tịnh xá/Niệm Phật đường", ignoring case and diacritics) equals a catalog temple's and the typed province is contained in that temple's address; a name without a temple prefix gets "Chùa " prepended. Both rules are copied from the prototype's JavaScript.
VI: Đề xuất bị coi là trùng khi tên gốc (bỏ tiền tố "Chùa/Thiền viện/Tịnh xá/Niệm Phật đường", không phân biệt hoa thường và dấu) bằng tên một chùa trong danh bạ và tỉnh/thành đã nhập nằm trong địa chỉ chùa đó; tên không có tiền tố loại hình sẽ được thêm "Chùa ". Cả hai quy tắc lấy từ JavaScript của prototype.

## Rationale / Cơ sở giả định
EN: The catalog summary has no separate province field, only an address string, so the province is matched by containment.
VI: Danh bạ chỉ có chuỗi địa chỉ, không có trường tỉnh/thành riêng nên so khớp bằng "chứa".

## Implications if wrong / Hệ quả nếu sai
EN: Real temples may be rejected as duplicates (or duplicates accepted) when addresses are written differently; the user can still pick the catalog entry.
VI: Có thể chặn nhầm chùa thật là trùng (hoặc để lọt trùng) khi địa chỉ viết khác nhau; người dùng vẫn chọn được chùa trong danh bạ.

## Validation / Cách xác nhận
EN: Check with Product and the catalog owner whether the server will deduplicate and how names should be normalised.
VI: Xác nhận với Product và chủ danh bạ việc server có tự loại trùng không và chuẩn hoá tên thế nào.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
