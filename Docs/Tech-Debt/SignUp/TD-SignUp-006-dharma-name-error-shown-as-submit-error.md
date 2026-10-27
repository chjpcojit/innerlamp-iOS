---
id: TD-SignUp-006
title: Dharma name error is shown as the submit error
title_vi: Lỗi pháp danh hiện ở dòng lỗi chung khi gửi
feature: SignUp
level: Low
status: Open
created: 2026-10-27
updated: 2026-10-27
files:
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift:371
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift:437
---

## Description / Mô tả
EN: The dharma name field has no error line of its own, so a too-long dharma name (> 255 characters) or `INVALID_DHARMA_NAME` is shown in the form's submit error, not under the field.
VI: Ô pháp danh chưa có dòng lỗi riêng, nên pháp danh quá dài (> 255 ký tự) hoặc `INVALID_DHARMA_NAME` hiện ở dòng lỗi chung của form, không nằm dưới ô.

## Why it was taken on / Lý do chấp nhận nợ
EN: Adding an error line is a UI change that goes through `ui-builder`; the case is rare (255 characters) and the message still reaches the user.
VI: Thêm dòng lỗi là thay đổi UI phải qua `ui-builder`; trường hợp hiếm (255 ký tự) và thông báo vẫn đến người dùng.

## Impact / Ảnh hưởng
EN: The user has to infer which field is wrong from the message text.
VI: Người dùng phải đoán ô nào sai qua nội dung thông báo.

## Proposed fix / Hướng xử lý
EN: Give the dharma name field an error line like the other fields and route `displayNameError` to it.
VI: Thêm dòng lỗi cho ô pháp danh như các ô khác và đưa `displayNameError` vào đó.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
