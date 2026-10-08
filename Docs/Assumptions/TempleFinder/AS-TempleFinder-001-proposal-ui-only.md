---
id: AS-TempleFinder-001
title: A proposed temple is only validated and acknowledged — never stored, sent, or selected
title_vi: Chùa đề xuất chỉ được kiểm tra và báo "đã gửi" — không lưu, không gửi, không được chọn
feature: TempleFinder
level: Medium
status: Unvalidated
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Presentation/Scenes/TempleFinder/ILTempleFinderViewModel.swift:202
source: Docs/innerlamp-project (prototype `findtp` / `chAddSubmit`; user decision "Chỉ UI, chưa lưu" on 2026-10-05)
owner: Product / BA
---

## Assumption / Giả định
EN: Submitting the "Đề xuất thêm chùa" form only validates the input (name and province required, duplicates of a listed temple rejected) and shows "Đã gửi đề xuất …". Nothing is persisted or sent, and the proposed temple is NOT set as the practice temple (the prototype's "Gửi và chọn chùa này" + "Chờ xác minh" state is not built).
VI: Gửi form "Đề xuất thêm chùa" chỉ kiểm tra dữ liệu (bắt buộc tên và tỉnh, từ chối chùa đã có trong danh bạ) rồi hiện "Đã gửi đề xuất …". Không lưu, không gửi đi đâu, và chùa đề xuất KHÔNG được đặt làm chùa tu tập (nút "Gửi và chọn chùa này" + trạng thái "Chờ xác minh" của prototype chưa làm).

## Rationale / Cơ sở giả định
EN: The user asked for UI only; the backend has no endpoint for temple proposals. Selecting an unstored temple would need local persistence the user declined.
VI: Người dùng yêu cầu chỉ làm UI; backend chưa có endpoint đề xuất chùa. Chọn 1 chùa chưa lưu cần lưu cục bộ mà người dùng đã từ chối.

## Implications if wrong / Hệ quả nếu sai
EN: Users believe their proposal was received while it is lost. If Product wants "propose and select now", a proposal store and the "Chờ xác minh" Chùa-tab state are needed.
VI: Người dùng tưởng đề xuất đã được tiếp nhận nhưng thực tế bị mất. Nếu Product muốn "đề xuất và chọn ngay" thì cần nơi lưu đề xuất và trạng thái "Chờ xác minh" ở tab Chùa.

## Validation / Cách xác nhận
EN: Confirm with Product/BA and the backend team the proposal contract and whether it is selectable before verification.
VI: Xác nhận với Product/BA và backend về contract đề xuất chùa và việc có được chọn trước khi xác minh hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
