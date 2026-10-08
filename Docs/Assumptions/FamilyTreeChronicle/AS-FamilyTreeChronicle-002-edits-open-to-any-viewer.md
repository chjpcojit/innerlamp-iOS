---
id: AS-FamilyTreeChronicle-002
title: Any viewer of a book can edit its chronicle and change the clan head
title_vi: Bất kỳ ai xem gia phả đều sửa được phả ký và đổi tộc trưởng
feature: FamilyTreeChronicle
level: High
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeChronicle/ILFamilyTreeChronicleViewModel.swift
source: Docs/InnerLamp project/IL-GiaPha.dc.html (footer: "Phả ký do người quản lý gia phả biên soạn. Con cháu có thể đề xuất chỉnh sửa." — ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The "Sửa" button and the "Đổi" clan-head button are shown to everyone; there is no manager / descendant distinction and no "propose an edit" flow.
VI: Nút "Sửa" và nút "Đổi" tộc trưởng hiện cho mọi người; chưa phân biệt người quản lý / con cháu và chưa có luồng "đề xuất chỉnh sửa".

## Rationale / Cơ sở giả định
EN: The prototype shows both buttons unconditionally; the footer text implies roles but no role model exists in the app.
VI: Prototype hiện cả hai nút vô điều kiện; dòng chân trang gợi ý có vai trò nhưng app chưa có mô hình vai trò.

## Implications if wrong / Hệ quả nếu sai
EN: Descendants could overwrite the manager's text or reassign the clan head (data integrity / authorization problem once data is shared).
VI: Con cháu có thể ghi đè nội dung của người quản lý hoặc đổi tộc trưởng (vấn đề toàn vẹn dữ liệu / phân quyền khi dữ liệu được chia sẻ).

## Validation / Cách xác nhận
EN: Confirm roles and permissions with Product / BA; gate edit and head change by role and add a propose-edit flow if needed.
VI: Xác nhận vai trò và quyền với Product / BA; chặn sửa và đổi tộc trưởng theo vai trò, thêm luồng đề xuất nếu cần.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
