---
id: AS-Sangha-001
title: The "practice temple" is chosen in-app and stored locally
title_vi: "Chùa tu tập" do người dùng chọn trong app và lưu cục bộ
feature: Sangha
level: Medium
status: Unvalidated
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Sangha/ILSanghaUseCase.swift:42
source: Docs/innerlamp-project (prototype screen `sangha`, state `myTp`; no API contract for it)
owner: Product / BA
---

## Assumption / Giả định
EN: The temple shown in the Chùa tab ("Chùa tu tập của tôi") is picked by the user ("Chọn" in the "Chùa gần bạn" list, or in the "Chọn chùa tu tập" screen opened by "Đổi chùa") and its id is kept in `UserDefaults` (`sangha.myTempleID`; temples picked from the directory also keep a name/address snapshot, `sangha.myTempleSnapshot`). "Đổi chùa" no longer clears the choice — it only opens the picker.
VI: Chùa hiển thị ở tab Chùa ("Chùa tu tập của tôi") do người dùng chọn (nút "Chọn" ở danh sách "Chùa gần bạn", hoặc ở màn "Chọn chùa tu tập" mở từ "Đổi chùa") và id được lưu trong `UserDefaults` (`sangha.myTempleID`; chùa chọn từ danh bạ còn lưu bản chụp tên/địa chỉ, `sangha.myTempleSnapshot`). "Đổi chùa" không còn xóa lựa chọn — chỉ mở màn chọn.

## Rationale / Cơ sở giả định
EN: The prototype has a chosen temple (`myTp`) but no API exists for saving a practice temple on the account.
VI: Prototype có chùa đã chọn (`myTp`) nhưng chưa có API lưu chùa tu tập vào tài khoản.

## Implications if wrong / Hệ quả nếu sai
EN: If the practice temple must live on the account (sync across devices / survive reinstall) the storage must move to the backend.
VI: Nếu chùa tu tập phải gắn với tài khoản (đồng bộ nhiều thiết bị / không mất khi cài lại) thì phải chuyển nơi lưu lên backend.

## Validation / Cách xác nhận
EN: Ask Product/BA whether the practice temple is an account field.
VI: Hỏi Product/BA chùa tu tập có phải trường của tài khoản không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
