---
id: AS-SignUp-001
title: Legal sheet copy comes from the prototype
title_vi: Nội dung sheet pháp lý lấy từ prototype
feature: SignUp
level: High
status: Unvalidated
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Resources/Localization/vi.json
  - InnerLamp/Presentation/Scenes/SignUp/Views/ILSignUpLegalSheetViewController.swift
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (Component.LEGAL, ⚠️ Not confirmed by legal)
owner: Product / Legal
---

## Assumption / Giả định
EN: The Terms of Use / Privacy Policy text, the effective date "01/09/2026" and the support address hotro@innerlamp.vn shown in the sign-up legal sheet are the final copy.
VI: Nội dung Điều khoản sử dụng / Chính sách quyền riêng tư, ngày hiệu lực "01/09/2026" và địa chỉ hotro@innerlamp.vn trong sheet pháp lý màn Đăng ký là bản chính thức.

## Rationale / Cơ sở giả định
EN: The prototype ships this copy verbatim; no legal-approved document or URL was provided.
VI: Prototype có sẵn nội dung này; chưa có tài liệu/URL đã được pháp chế duyệt.

## Implications if wrong / Hệ quả nếu sai
EN: Wrong legal text shown at sign-up with an "I agree" action (compliance risk); copy must be replaced before release.
VI: Hiển thị sai nội dung pháp lý kèm hành động "Tôi đồng ý" (rủi ro tuân thủ); phải thay nội dung trước khi phát hành.

## Validation / Cách xác nhận
EN: Ask Product/Legal for the approved text (or a hosted URL) and update the `legal.*` keys.
VI: Xin Product/Pháp chế bản đã duyệt (hoặc URL) và cập nhật các key `legal.*`.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
