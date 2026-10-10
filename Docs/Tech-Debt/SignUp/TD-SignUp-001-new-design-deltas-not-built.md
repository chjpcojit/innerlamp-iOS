---
id: TD-SignUp-001
title: Remaining new-design deltas on SignUp not built (dharma name input, shared label sizes)
title_vi: Các thay đổi design mới của Đăng ký chưa làm
feature: SignUp
level: Medium
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewController.swift
  - InnerLamp/Presentation/Scenes/SignUp/Views/ILDharmaNameSuggestionField.swift
---

## Description / Mô tả
EN: Not implemented from the new prototype: (1) dharma name as a free text input (`setDharmaName`) — the suggestion-field behaviour is kept; (2) shared field label/button sizes (11→12px labels, 14→13px secondary buttons) inside `ILField`/`ILPhoneField`/`ILButton`. The ordination-place picker and the add-temple sheet are now built (see TD-SignUp-002).
VI: Chưa làm từ prototype mới: (1) pháp danh là ô nhập tự do (`setDharmaName`) — vẫn giữ hành vi ô gợi ý; (2) cỡ chữ nhãn/nút dùng chung (nhãn 11→12px, nút phụ 14→13px) trong `ILField`/`ILPhoneField`/`ILButton`. Bộ chọn nơi xuất gia và sheet thêm chùa đã làm (xem TD-SignUp-002).

## Why it was taken on / Lý do chấp nhận nợ
EN: Scope of the first task was visual + legal sheet; the picker was added in a follow-up task. Dharma name input and shared component sizes were not requested yet.
VI: Phạm vi lần đầu chỉ gồm visual + sheet pháp lý; bộ chọn chùa được làm ở lần sau. Ô nhập pháp danh và cỡ chữ component dùng chung chưa được yêu cầu.

## Impact / Ảnh hưởng
EN: SignUp differs from the prototype in these interactions and minor label sizes.
VI: Đăng ký còn khác prototype ở các tương tác này và cỡ chữ nhãn nhỏ.

## Proposed fix / Hướng xử lý
EN: Make the dharma name a free input if confirmed; update shared components for label sizes separately.
VI: Làm pháp danh thành ô nhập tự do nếu được xác nhận; cập nhật cỡ chữ ở component dùng chung riêng.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
