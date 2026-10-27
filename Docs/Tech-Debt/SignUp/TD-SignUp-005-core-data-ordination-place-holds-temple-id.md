---
id: TD-SignUp-005
title: Core Data attribute ordinationPlace now stores the temple id
title_vi: Thuộc tính Core Data ordinationPlace nay lưu id chùa
feature: SignUp
level: Low
status: Open
created: 2026-10-27
updated: 2026-10-27
files:
  - InnerLamp/Data/DataSources/Local/ILUserLocalDataSource.swift:84
---

## Description / Mô tả
EN: `ILUserEntity.ordinationTempleID` is saved into and read from the existing Core Data attribute `ordinationPlace` of the cached user. The attribute name no longer matches what it holds (a temple id, not a name).
VI: `ILUserEntity.ordinationTempleID` được lưu vào và đọc từ thuộc tính Core Data có sẵn `ordinationPlace` của user trong cache. Tên thuộc tính không còn khớp với giá trị (id chùa, không phải tên).

## Why it was taken on / Lý do chấp nhận nợ
EN: Renaming the attribute needs a new model version and a lightweight migration; the auth email change had to stay small and the value is only a cache refreshed on every sign-in.
VI: Đổi tên thuộc tính cần version model mới và lightweight migration; thay đổi auth email cần gọn và giá trị chỉ là cache được làm mới mỗi lần đăng nhập.

## Impact / Ảnh hưởng
EN: Misleading name for the next reader; any code that reads `ordinationPlace` as a display name would show an id.
VI: Tên gây hiểu nhầm cho người đọc sau; code nào đọc `ordinationPlace` như tên hiển thị sẽ hiện ra id.

## Proposed fix / Hướng xử lý
EN: Add a model version with `ordinationTempleID` (rename identifier `ordinationPlace`) the next time the user entity changes.
VI: Thêm version model với `ordinationTempleID` (renaming identifier `ordinationPlace`) ở lần đổi entity user tiếp theo.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
