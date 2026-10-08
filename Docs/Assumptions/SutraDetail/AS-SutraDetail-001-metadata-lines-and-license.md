---
id: AS-SutraDetail-001
title: Detail meta/description lines are derived from API fields; license is shown raw
title_vi: Dòng meta/mô tả của màn chi tiết suy từ field API; giấy phép hiển thị nguyên văn
feature: SutraDetail
level: Medium
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/SutraDetail/ILSutraDetailViewModel.swift
source: BE contract for GET /v1/sutras/{id}; BE note that content is UNREVIEWED and licenses are partly unknown
owner: Product / BA
---

## Assumption / Giả định
EN: The API has no description, so the description line shows "collection · reference" (e.g. "Tiểu Bộ · Snp 1.8"). The meta line shows "N dòng · duration". The kicker is kind (kinh văn / kệ tụng / thần chú) + tradition. Each table-of-contents row shows its line count. The translator, source name and license are shown verbatim under the description (the backend asked for them to be displayed); the license text can be long. The source link (`source_url`) is validated but not shown or tappable. The UNREVIEWED status and AI-assigned tags (`daily_chant`, `purposes`, deity links) are shown without any "unreviewed" notice.
VI: API không có mô tả nên dòng mô tả hiện "bộ kinh · số hiệu" (vd. "Tiểu Bộ · Snp 1.8"). Dòng meta hiện "N dòng · thời lượng". Kicker là thể loại (kinh văn / kệ tụng / thần chú) + tông phái. Mỗi dòng Mục lục hiện số dòng. Dịch giả, nguồn và giấy phép hiển thị nguyên văn dưới mô tả (BE yêu cầu phải hiển thị); chuỗi giấy phép có thể dài. Link nguồn (`source_url`) được kiểm tra nhưng chưa hiển thị / chưa bấm được. Trạng thái UNREVIEWED và các nhãn do AI gán (`daily_chant`, `purposes`, liên kết deity) hiển thị mà không có cảnh báo "chưa duyệt".

## Rationale / Cơ sở giả định
EN: Uses only fields the API provides; the prototype has no copy or design for these lines.
VI: Chỉ dùng các field API có; prototype chưa có nội dung / thiết kế cho các dòng này.

## Implications if wrong / Hệ quả nếu sai
EN: Possible licensing / content-accuracy exposure if unreviewed text is shown to end users without a notice; copy and layout of these lines may need redesign.
VI: Có rủi ro về giấy phép / độ chính xác nội dung nếu hiển thị văn bản chưa duyệt cho người dùng cuối mà không có cảnh báo; nội dung và bố cục các dòng này có thể phải thiết kế lại.

## Validation / Cách xác nhận
EN: Product / legal to confirm the license display rule, whether an "unreviewed" notice is required, and the wanted description copy; design to confirm layout.
VI: Product / pháp lý xác nhận quy tắc hiển thị giấy phép, có cần cảnh báo "chưa duyệt" không và nội dung mô tả mong muốn; design xác nhận bố cục.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
