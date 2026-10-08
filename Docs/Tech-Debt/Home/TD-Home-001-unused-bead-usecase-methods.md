---
id: TD-Home-001
title: ILHomeUseCase bead methods are no longer wired
title_vi: Các hàm đếm hạt của ILHomeUseCase không còn được dùng
feature: Home
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift:13
---

## Description / Mô tả
EN: `incrementBead` / `resetBeads` (and their use-case tests / mock flags) have no caller since the Home bead card only opens Mala.
VI: `incrementBead` / `resetBeads` (cùng test và cờ mock) không còn nơi gọi vì thẻ tràng hạt ở Trang chủ chỉ mở màn Niệm Phật.

## Why it was taken on / Lý do chấp nhận nợ
EN: Kept to keep this change surgical (Domain left untouched).
VI: Giữ lại để thay đổi gọn, không đụng Domain.

## Impact / Ảnh hưởng
EN: Dead code only.
VI: Chỉ là code thừa.

## Proposed fix / Hướng xử lý
EN: Delete both methods and their tests once AS-Home-001 is confirmed.
VI: Xoá hai hàm và test khi AS-Home-001 được xác nhận.

## Resolution / Kết quả xử lý
EN: _(open)_
VI: _(chưa xử lý)_
