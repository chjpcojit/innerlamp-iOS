---
id: AS-SutraDetail-002
title: Extra sutra-detail API fields are shown with default labels and tolerant decoding
title_vi: Các field bổ sung của API chi tiết kinh hiển thị với nhãn mặc định và decode khoan dung
feature: SutraDetail
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DTOs/ILSutraDTO.swift
  - InnerLamp/Data/DTOs/Mappers/ILSutraMapper.swift
  - InnerLamp/Presentation/Scenes/SutraDetail/ILSutraDetailViewModel.swift
source: Docs/Specs/SutraDetail/requirements.md (v1.4, ⚠️ Not confirmed); BE confirmation 2026-10-11
owner: Product / BA
---

## Assumption / Giả định
EN: Product decided (2026-10-11) to show every field the API returns. The shapes are confirmed by the backend (2026-10-11); the app still decodes the newer fields as optional so a missing or differently shaped value hides its row instead of failing the page. Unconfirmed: row labels are our own default Vietnamese copy ("Tác giả", "Dịch giả Hán", "Ghi chú tham chiếu"...); deity rows are plain text without the thumbnail; the "unreviewed" notice (our wording) is shown for any non-empty `review_status`, because no "reviewed" value is defined; `summary` is hidden while empty.
VI: Product quyết định (2026-10-11) hiển thị mọi field API trả về. Cấu trúc đã được backend xác nhận (2026-10-11); app vẫn decode các field mới ở dạng optional để thiếu hoặc sai cấu trúc thì ẩn dòng chứ không làm hỏng cả trang. Chưa xác nhận: nhãn dòng là copy tiếng Việt mặc định của ta ("Tác giả", "Dịch giả Hán", "Ghi chú tham chiếu"...); dòng deity chỉ là chữ thường, không có thumbnail; thông báo "chưa duyệt" (nội dung do ta soạn) hiện với mọi `review_status` không rỗng vì chưa có giá trị "đã duyệt"; `summary` bị ẩn khi trống.

## Rationale / Cơ sở giả định
EN: The owner asked for full display now; no design or copy exists yet, so defaults keep the screen safe if the backend data is sparse.
VI: Chủ sản phẩm yêu cầu hiển thị đầy đủ ngay; chưa có thiết kế / copy nên dùng mặc định để màn hình an toàn khi dữ liệu backend còn thưa.

## Implications if wrong / Hệ quả nếu sai
EN: Labels, order, deity-row behavior or the notice wording may need rework.
VI: Nhãn, thứ tự, hành vi dòng deity hoặc nội dung thông báo có thể phải làm lại.

## Validation / Cách xác nhận
EN: Product / design confirm labels, order, deity-row tap, the notice wording and the "reviewed" status value.
VI: Product / design xác nhận nhãn, thứ tự, hành vi bấm dòng deity, nội dung thông báo và giá trị trạng thái "đã duyệt".

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
