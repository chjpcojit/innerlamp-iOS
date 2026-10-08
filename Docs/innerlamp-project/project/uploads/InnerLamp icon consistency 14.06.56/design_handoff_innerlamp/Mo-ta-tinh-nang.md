# InnerLamp — Mô tả tính năng & thành phần từng trang

Tài liệu đi kèm `InnerLamp Prototype.dc.html`. Mỗi trang gồm:
- **Mục đích** — trang dùng để làm gì.
- **Thành phần** — các khối trên trang, theo thứ tự từ trên xuống.
- **Hoạt động** — tương tác, trạng thái, quy tắc hiển thị, điều hướng (→).

---

## 0. Quy tắc chung

### Khung trang
- **Header (IL-NavBar):** nút Back trái · tiêu đề + dòng phụ giữa · nút hành động phải (tùy trang). Luôn ghim trên cùng, là lớp trên cùng; nội dung cuộn chui xuống dưới header.
- **Header trong suốt:** Pháp thoại, Trang chùa, Chi tiết ngày âm — header nằm trên ảnh bìa, khi cuộn quá 110px thì chuyển nền đặc (màu nền trang), chuyển màu 0.2s.
- **Thanh hành động đáy:** các nút chính / ô nhập ở đáy nằm ngoài vùng cuộn, không cuộn theo nội dung, chừa safe area 34px, có đường kẻ mảnh phía trên.
- **Bottom nav (IL-BottomNav):** 5 tab Trang chủ · Thư viện · Thắp đèn (nút nổi giữa → Chuẩn bị thiền) · Đạo tràng · Tôi. Chỉ ở 4 trang gốc. Khi cuộn xuống quá 48px thì trượt ẩn; cuộn lên (≥6px) thì hiện lại; nếu nội dung ngắn (không cuộn được) luôn hiện.

### Điều hướng
- Mỗi lần mở trang mới được đẩy vào ngăn xếp; Back lấy trang trước ra. Ngăn xếp rỗng → về Trang chủ.
- "Về trang chủ" và tab Trang chủ xóa toàn bộ ngăn xếp.
- Chuyển trang: mờ dần (crossfade) 200ms; vùng cuộn tự trở về đầu trang; bottom nav hiện lại.
- Mở trang mới sẽ tự đóng popup lỗi đang hiện.

### Danh sách màn hình (prototype)
- Thanh chọn màn hình bên dưới prototype cho phép mở thẳng từng trang, gồm cả Tất cả bài viết và Lịch lễ Phật giáo.

### Giao diện
- Sáng / Tối / Theo hệ thống (theo cài đặt máy, cập nhật ngay khi máy đổi chế độ).
- Mọi màu dùng biến theo theme; các thẻ nổi bật (thẻ vàng/đêm) có bản sáng và bản tối.

### Trang toàn màn hình (không cuộn)
Niệm Phật, Chuông mõ, Phiên thiền, Trình phát, Hoàn thành — mọi thứ vừa một màn hình.

### Bộ component dùng lại
| Component | Dùng cho |
|---|---|
| IL-NavBar | Header các trang con (back, close, tiêu đề, dòng phụ, nút phải, bản tối) |
| IL-BottomNav | Thanh tab 4 trang gốc |
| IL-Btn | Nút: primary (mực), gold, ghost, light, onDark, danger |
| IL-Chip | Chip chọn một / chọn nhiều |
| IL-Field | Ô nhập có nhãn |
| IL-Row | Hàng danh sách: icon tròn màu + tiêu đề + mô tả + chữ phải |
| IL-SettingRow | Hàng cài đặt: mũi tên / công tắc / giá trị |
| IL-Avatar | Ảnh đại diện 4 tông màu, 28–96px |
| IL-State | Trạng thái rỗng / lỗi / ngoại tuyến / hoàn thành |

---

## 1. Khởi động & tài khoản

### Màn hình chờ (Splash)
**Mục đích:** nhận diện thương hiệu trong lúc app khởi động.
**Thành phần:** ngọn đèn phát sáng (hiệu ứng thở), chữ INNERLAMP, slogan "Tự thắp đèn tâm, tự soi lối về" (Lora nghiêng).
**Hoạt động:** sau 3,2 giây tự mờ dần sang Onboarding.

### Onboarding
**Mục đích:** giới thiệu app và thu thập nhu cầu trước khi tạo tài khoản.
**Thành phần:**
- Thanh tiến độ 3 đoạn (đoạn đã qua tô vàng), nút "Bỏ qua".
- Bước 1: "Thắp ngọn đèn trong tâm" + dòng tiếng Anh "Light the lamp within".
- Bước 2: "Bạn mong cầu điều gì?" — 6 chip: Tĩnh tâm giảm lo âu, Ngủ ngon, Niệm Phật hằng ngày, Học Phật pháp, Tụng kinh, Chánh niệm khi làm việc.
- Bước 3: "Chuông tỉnh thức" — 3 hàng chuông có công tắc: Sáng sớm 05:30, Giữa trưa 12:00, Trước khi ngủ 21:30.
- Nút chính + nút phụ ở đáy.
**Hoạt động:**
- Chip chọn nhiều; chip đã chọn nền mực, chữ sáng.
- Công tắc chuông: bật thì viền và icon chuyển vàng, núm trượt phải.
- Nút chính: "Bắt đầu" → "Tiếp tục" → "Tạo tài khoản" (→ Đăng ký). Nút phụ: bước 1 là "Tôi đã có tài khoản" (→ Đăng nhập), các bước sau là "Quay lại".
- Đổi bước bằng crossfade 170ms.

### Đăng nhập
**Mục đích:** đăng nhập bằng số điện thoại.
**Thành phần:** header "Đăng nhập"; lời chào "Kính chào bạn"; ô Số điện thoại (nút cờ + mã quốc gia bên trái); ô Mật khẩu + link "Quên?"; nút Đăng nhập; nút "Gửi mã một lần qua SMS"; vạch "hoặc"; "Tạo tài khoản mới"; "Vào xem trước, chưa đăng nhập".
**Hoạt động:**
- **Chọn quốc gia:** bấm cờ → bottom sheet trượt lên, có ô tìm (không phân biệt dấu, tìm theo tên / mã ISO / mã quay số), danh sách 12 quốc gia (quốc gia đang chọn có nền nhạt + dấu tick). Không có kết quả → "Không tìm thấy quốc gia phù hợp". Chọn xong sheet đóng.
- **Chuẩn hóa số:** chấp nhận 0949…, 949…, 84949…, 0084…; tự bỏ số 0 đầu và mã vùng, giới hạn độ dài theo quốc gia.
- Số chưa đủ độ dài → viền vàng + gợi ý "Nhập 0949… hoặc 949… — chúng tôi tự thêm +84". Đủ → gợi ý "Mã xác thực sẽ gửi tới +84 949 …".
- Đăng nhập → Trang chủ; SMS → OTP; Quên? → Quên mật khẩu; Tạo tài khoản → Đăng ký; Xem trước → Trang chủ (khách).

### Đăng ký
**Mục đích:** tạo tài khoản mới.
**Thành phần:** tiêu đề "Kết duyên cùng InnerLamp"; các ô: Pháp danh/tên gọi (nút xúc xắc "Gợi ý"), Nơi xuất gia (không bắt buộc), Số điện thoại (có chọn quốc gia), Email, Mật khẩu (nút Hiện + thanh độ mạnh "Khá tốt"); checkbox đồng ý Điều khoản & Chính sách; nút "Gửi mã xác thực"; "Tôi đã có tài khoản".
**Hoạt động:**
- **Gợi ý pháp danh:** mỗi lần bấm, icon xoay 180° và đổi sang tên kế trong danh sách 10 tên (Diệu Tâm, Tịnh An, Minh Đăng…).
- **Nơi xuất gia:** bấm mở danh sách thả xuống (mũi tên xoay) gồm 6 lựa chọn có radio: Chưa xuất gia, Chùa Từ Quang, Thiền viện Trúc Lâm, Chùa Vĩnh Nghiêm, Chùa Trấn Quốc, Nơi khác. Chọn xong tự đóng.
- **Email:** kiểm tra định dạng khi gõ; sai → viền đỏ; đúng → dấu tick.
- **Số điện thoại:** như trang Đăng nhập.
- **Nút Gửi mã:** mờ và không bấm được cho tới khi tick đồng ý điều khoản; tick rồi → nền mực, có bóng → OTP.

### Xác thực OTP
**Mục đích:** xác nhận số điện thoại.
**Thành phần:** "Nhập mã sáu số"; dòng "Đã gửi tới +84 …" + "Đổi số"; 6 ô số (ô đã nhập viền vàng); "Gửi lại mã sau 00:47" / "Gửi lại"; gợi ý nhận mã qua cuộc gọi thoại; nút Xác nhận; ghi chú "Mã có hiệu lực trong 10 phút".
**Hoạt động:** Đổi số → Đăng nhập; Gửi lại → gửi mã mới; Xác nhận → Trang chủ.

### Quên mật khẩu
**Thành phần:** "Không sao cả" + giải thích; ô số điện thoại đã đăng ký; nút "Gửi hướng dẫn"; "Trở lại đăng nhập".
**Hoạt động:** Gửi hướng dẫn → OTP; Trở lại → Đăng nhập.

---

## 2. Trang gốc (có bottom nav)

### Trang chủ
**Mục đích:** bảng điều khiển hằng ngày — ngày âm, thời khóa, lối tắt thực hành, nội dung đọc.
**Thành phần (trên xuống):**
1. **Header ghim:** lời chào theo giờ ("Chào buổi sáng / trưa / chiều / tối, [pháp danh]" — chưa có pháp danh thì "quý Phật tử"); dòng ngày "Thứ …, ngày · tháng — ngày âm"; chuông thông báo; avatar.
2. **Lịch âm tuần:** tiêu đề tháng + link "Lịch âm"; 7 ô ngày (thứ, ngày dương, ngày âm, chấm màu); chú thích Hoàng đạo / Hắc đạo / Rằm · Mùng Một.
3. **Thẻ ngày đã chọn:** ngày âm lớn, tháng âm (có "nhuận"), năm can chi, ngày dương đầy đủ, lời khuyên trong ngày, câu kinh theo ngày → Chi tiết ngày âm.
4. **Sự kiện Phật giáo:** carousel 6 tháng tới, mỗi thẻ 3 sự kiện + "+N sự kiện khác", chấm phân trang; link "Tất cả".
5. **Ảnh chùa đẹp:** 3 ảnh + ô "+N ảnh"; "Xem tất cả".
6. **Chùa Việt Nam:** carousel ngang 8 chùa (tên, nơi, ghi chú); "Tìm chùa".
7. **Thời khóa hôm nay:** tiến độ "12 / 20 phút"; **Chuỗi ngày tinh tấn** "42 ngày".
8. **Tràng hạt mini:** vòng tròn tiến độ, số đếm / 108, "Nam mô A Di Đà Phật", nút "Bắt đầu lại", link "Toàn màn hình".
9. **Chuông mõ:** thẻ lối tắt.
10. **Thời khóa gợi ý:** 3 hàng cố định — Thiền hơi thở buổi sáng (→ Chuẩn bị thiền), Kinh Vu Lan Báo Hiếu (→ Tụng kinh), Cúng dường đèn Vu Lan (→ Cúng dường). Hiện chưa có logic gợi ý theo giờ / lịch âm / thói quen.
11. **Bài viết Phật pháp hay:** 5 thẻ (ảnh vuông, thể loại, tiêu đề 2 dòng, tác giả · thời gian đọc) + link "Xem tất cả".
**Hoạt động:**
- **Lịch tuần:** kéo/vuốt ngang theo từng trang tuần (5 tuần: 2 trước, hiện tại, 2 sau; mở ra ở tuần hiện tại); kéo quá 40px thì sang tuần, chưa tới thì bật về. Tiêu đề đổi theo tuần ("Tháng 9 – Tháng 10, 2026").
- Chấm dưới ngày: vàng = Rằm/Mùng Một; xanh = hoàng đạo; đỏ = hắc đạo. Hôm nay có viền; ngày chọn nền mực.
- Bấm ngày → thẻ ngày cập nhật (ngày âm, can chi, lời khuyên, câu kinh). Lời khuyên: Mùng Một / Rằm = ngày trai giới; mùng 8, 14, 23, 30 = ngày trai; còn lại = ngày thường.
- **Sự kiện Phật giáo (lịch chung):** tự tính từ lịch âm — lễ lớn (vía, Vu Lan, Phật đản…) tô màu nhấn; Rằm và Mùng Một ghi "ngày trai giới". Kéo ngang hoặc bấm chấm để chuyển tháng. "Tất cả", bấm một lễ, hoặc "+N sự kiện khác" → Lịch lễ Phật giáo.
- **Chùa Việt Nam:** mỗi thẻ mở đúng Trang chùa của chùa đó.
- **Tràng hạt mini:** mỗi lần chạm +1 hạt (hạt co nhẹ), vòng tiến độ tô theo %; đủ 108 thì quay về 1. "Bắt đầu lại" về 0.
- Chuông → Thông báo; avatar → Hồ sơ; "Lịch âm" → Lịch âm; thẻ ngày → Chi tiết ngày âm; "Tất cả" sự kiện → Lịch lễ Phật giáo; Ảnh → Ảnh chùa đẹp; thẻ chùa → Trang chùa (đúng chùa); Tìm chùa → Đạo tràng; thời khóa / chuỗi ngày → Nhật ký / Thống kê; Toàn màn hình → Niệm Phật; Chuông mõ → Chuông mõ; thời khóa gợi ý → Chuẩn bị thiền / Tụng kinh / Cúng dường; bài viết → Bài viết; "Xem tất cả" → Tất cả bài viết.
- Header ghim có đường kẻ dưới; bottom nav tự ẩn/hiện.

### Thư viện
**Mục đích:** kho kinh, pháp thoại, thiền dẫn.
**Thành phần:** header ghim "Thư viện"; ô tìm kiếm giả; 4 chip lọc (Tất cả, Kinh văn, Thiền dẫn, Pháp thoại); thẻ nổi bật "Pháp thoại mùa Vu Lan" (nút "Nghe · 46 phút"); "Kinh thường tụng" — 4 hàng: Kinh Pháp Cú, Kinh Vu Lan, Kinh A Di Đà, Chú Đại Bi (mô tả + thời lượng).
**Hoạt động:** ô tìm → Tìm kiếm; thẻ nổi bật → Pháp thoại; hàng kinh → Chi tiết bài kinh.

### Đạo tràng
**Mục đích:** cộng đồng tu tập.
**Thành phần:** header ghim "Đạo tràng" + "Tìm đạo tràng"; thẻ "Đang cùng ngồi thiền · 312 người trên khắp Việt Nam · phiên 20 phút" + nút "Ngồi cùng"; "Đạo tràng của tôi" (Từ Quang, 184 thành viên, địa chỉ, thông báo mới nhất); "Chia sẻ của bạn đồng tu" — thẻ bài (avatar, tên, thời gian, chuỗi ngày, nội dung, Tùy hỷ, Hồi âm).
**Hoạt động:** Ngồi cùng → Chuẩn bị thiền; đạo tràng → Trang chùa; thông báo sự kiện → Sự kiện; bài → Bài đăng; nút viết → Viết bài.

### Hồ sơ (Tôi)
**Mục đích:** thông tin cá nhân và tổng quan tu tập.
**Thành phần:** header ghim (avatar 72px, tên, pháp danh, "Phật tử tại gia", "Sửa hồ sơ"); 3 chỉ số: 168 giờ tu tập · 42 ngày liên tục · 9.7k câu niệm Phật; bản đồ nhiệt "Nhật ký 12 tuần qua" (84 ô, đậm nhạt theo mức tu tập); "Dấu ấn tu tập" (3 huy hiệu + "Xem cả 18 dấu ấn"); thẻ "Công đức đã hồi hướng" (7 lần cúng dường, 3 ngọn đèn Vu Lan); banner Sen Vàng "Dùng thử 7 ngày miễn phí"; danh sách lối tắt (Chuông nhắc, Cài đặt, Thông báo, Chùa của tôi).
**Hoạt động:** Sửa hồ sơ → Chỉnh sửa hồ sơ; chỉ số / nhật ký → Thống kê; dấu ấn → Thành tựu; công đức → Cúng dường; Sen Vàng → Gói Sen Vàng; các hàng → trang tương ứng.

---

## 3. Kinh, pháp thoại & nội dung

### Chi tiết bài kinh
**Mục đích:** giới thiệu một bộ kinh và chọn phẩm để tụng.
**Thành phần:** header ghim (Back + "Tải về máy") cùng màu với đỉnh khối bìa để liền mạch; bìa: "KINH VĂN · SONG NGỮ", tên kinh, "26 phẩm · 423 kệ · người tụng · thời lượng", thẻ "Tụng hằng ngày", "Có phiên âm"; thẻ tiến độ + thanh 34%; đoạn giới thiệu; "Mục lục · 26 phẩm"; nút "Tụng theo".
**Hoạt động:** header không có đường kẻ khi ở đầu trang; cuộn >110px hiện đường kẻ mảnh để tách nội dung. Quầng sáng bìa là elip nằm trọn trong khối (không bị cắt mép). Phẩm đang tụng tô nền vàng nhạt; bấm phẩm → Tụng kinh; Tải về máy → Ngoại tuyến; Tụng theo → Trình phát.

### Tụng kinh (Reader)
**Mục đích:** đọc/tụng kinh văn.
**Thành phần:** header ghim "Kinh Pháp Cú · Phẩm Song Yếu · kệ 1–2" + nút "Aa"; kinh văn tiếng Việt (câu đang tụng tô đậm, câu sau mờ), bản tiếng Anh in nghiêng; nút Chia sẻ, Tải về; mini player ở đáy (trạng thái "Đang tụng / Tạm dừng", thời gian 12:04, tốc độ 1.0×, nút phát).
**Hoạt động:** Aa → Cài đặt; chia sẻ → Chia sẻ câu kinh; tải → Tải về; nút phát bật/tắt; bấm mini player → Trình phát.

### Trình phát
**Mục đích:** nghe tụng theo toàn màn hình.
**Thành phần:** header "Đang nghe" + "Mục lục"; bìa; tên phẩm, tên kinh, người tụng; thanh thời gian (14:22 / -23:18); nút tua lùi 15s, phát/dừng, tua tới 30s; "Tốc độ đọc" 4 chip (0.75×, 1.0×, 1.25×, 1.5×); "Hẹn giờ tắt" 4 chip (Tắt, 15p, 30p, Hết bài) + dòng giải thích.
**Hoạt động:** chọn tốc độ / hẹn giờ (chip chọn một). Ghi chú hẹn giờ đổi theo lựa chọn: Tắt → "nghe đến hết"; 15/30p → "Nhạc sẽ lịm dần và tắt sau …"; Hết bài → "Tiếng chuông nhẹ khi bài kết thúc". Mục lục → Chi tiết bài kinh.

### Pháp thoại
**Mục đích:** nghe bài giảng.
**Thành phần:** header trong suốt "Pháp thoại"; bìa tối "PHÁP THOẠI · MÙA VU LAN", tiêu đề, giảng sư · 46 phút · 2.4k lượt nghe; player (12:48 / -33:12, tua 15s/30s); "Các phần" — 3 mốc: 00:00 Vì sao nói hiếu là gốc, 11:20 Câu chuyện Mục Kiền Liên, 38:40 Hồi hướng & hỏi đáp; thẻ "Nghe xong, ngồi thiền 10 phút · Quán niệm ân cha mẹ".
**Hoạt động:** header chuyển nền đặc khi cuộn >110px; phát/dừng; thẻ thiền → Chuẩn bị thiền.

### Tất cả bài viết
**Mục đích:** duyệt toàn bộ bài viết Phật pháp. **Mở từ:** "Xem tất cả" ở mục Bài viết Phật pháp hay (Trang chủ).
**Thành phần:** header ghim "Bài viết Phật pháp hay" + dòng phụ "20 / 60 bài"; danh sách thẻ bài (giống Trang chủ); dòng trạng thái cuối danh sách.
**Hoạt động:**
- Mở trang: luôn bắt đầu với 20 bài.
- Cuộn gần đáy (<120px) → hiện "Đang tải thêm bài viết…" → sau ~0,9 giây thêm 20 bài; dòng phụ cập nhật số đã tải.
- Không gọi tải trùng khi đang tải. Đủ 60 bài → "Bạn đã xem hết bài viết".
- Bấm bài → Bài viết.

### Bài viết Phật pháp
**Thành phần:** header ghim (thể loại · thời gian đọc); ảnh bìa; tiêu đề; tác giả (avatar chữ viết tắt) · ngày; các đoạn nội dung; khối trích dẫn kinh + nguồn; nút "Lưu bài" và "Chia sẻ"; "Đọc tiếp" — 2 bài kế.
**Hoạt động:** Lưu bài ↔ Đã lưu (nhớ riêng từng bài); Chia sẻ → Chia sẻ câu kinh; bài kế → mở bài đó và cuộn về đầu.

### Tìm kiếm
**Mở từ:** ô tìm kiếm ở Thư viện, ô tìm câu hỏi ở Trợ giúp.
**Thành phần:** header ghim (Back · "Tìm kiếm"); ô tìm có từ khóa ("vu lan") và nút × xóa nhanh, dính theo header; tab kết quả kèm số (Tất cả 18 · Kinh 4 · Pháp thoại 9); "Kết quả nổi bật" (Kinh Vu Lan Báo Hiếu, song ngữ, có audio, 38 phút — có bản sáng/tối); "Trong thư viện" — danh sách IL-Row; link "Xem trạng thái không có kết quả →".
**Hoạt động:** Back → trang trước; kết quả → Tụng kinh / Pháp thoại / Chuẩn bị thiền; link → Không có kết quả. (Nút × hiện chỉ minh họa.)

### Không có kết quả
**Thành phần:** header (Back · "Tìm kiếm"); ô tìm với từ khóa dài + nút ×; IL-State "Chưa tìm thấy bản kinh này"; nút "Gửi yêu cầu bản kinh"; "Có thể bạn đang tìm" — gợi ý.
**Hoạt động:** gợi ý → Tụng kinh / Pháp thoại; Back → trang trước.

### Chia sẻ câu kinh
**Thành phần:** thiệp xem trước (câu kinh, "KINH PHÁP CÚ · KỆ 1", họa tiết đèn); "Nền thiệp" 3 lựa chọn: Ánh đèn, Giấy mộc, Sen hồng; 4 nơi chia sẻ: Zalo, Facebook, Đạo tràng, Sao chép.
**Hoạt động:** đổi nền → thiệp đổi ngay nền, màu chữ, viền, quầng sáng, chấm nhấn. Nền "Ánh đèn" tự theo giao diện (sáng: vàng kem · tối: nền đêm).

### Ảnh chùa đẹp
**Thành phần:** header "Ảnh chùa đẹp" + dòng phụ số ảnh; chip danh mục: Tất cả, Chùa, Tượng Phật, Cảnh thiền, Lễ hội; lưới 2 cột so le (masonry) 12 ảnh, mỗi ảnh có tiêu đề + nơi chụp.
**Hoạt động:** chọn chip → lọc ảnh; dòng phụ thành "N ảnh · [danh mục]". Ảnh là ô kéo-thả để thay ảnh thật.

---

## 4. Thực hành

### Chuẩn bị thiền
**Thành phần:** header "TRƯỚC KHI NGỒI"; tên bài "Thiền hơi thở buổi sáng", giảng sư, giọng Nam, có nhạc nền; "Thời lượng" 5 lựa chọn: 5 · 12 · 20 · 30 · 45 phút + gợi ý "bạn thường ngồi 20 phút vào buổi sáng"; "Chuông"; lời dặn tư thế; tùy chọn "Ngồi im lặng, không hướng dẫn"; nút Bắt đầu.
**Hoạt động:** chọn thời lượng (mặc định 20); thời lượng hiện ở header Phiên thiền. Bắt đầu → Phiên thiền.

### Phiên thiền
**Thành phần:** header "Thiền hơi thở · [thời lượng]"; vòng thở phát sáng; đồng hồ 11:24; câu dẫn "Thở vào… biết mình đang thở vào" + bản tiếng Anh; nút phát/dừng; "Kết thúc sớm"; ghi chú "chuông 3 tiếng khánh".
**Hoạt động:** phát/dừng; Kết thúc sớm → Hoàn thành.

### Hoàn thành
**Thành phần:** "Một thời khóa đã tròn đầy"; 3 chỉ số: 43 ngày liên tục · 168.3 giờ tu tập · 312 người cùng ngồi; "Tâm bạn lúc này thế nào?" — 4 chip: Tĩnh lặng, Nhẹ nhàng, Còn tán loạn, Buồn ngủ; "Hồi hướng công đức cho · Cha mẹ hiện tiền"; nút "Ghi vào nhật ký"; "Để sau".
**Hoạt động:** chọn tâm trạng (chọn một, chip chọn tô vàng); Ghi vào nhật ký → Viết nhật ký; Để sau → Trang chủ.

### Niệm Phật (tràng hạt toàn màn hình)
**Thành phần:** header "Niệm Phật · N tràng"; chuỗi hạt dọc với vạch ngang ở giữa; số đếm lớn / 108; "Nam mô A Di Đà Phật"; hướng dẫn "Kéo lên hoặc xuống một lần — đúng một hạt về giữa vạch"; nút "Bắt đầu lại", "Xong"; ghi chú "Rung nhẹ mỗi 27 hạt · chuông ở hạt 108".
**Hoạt động:**
- **Kéo:** kéo lên/xuống, chuỗi dịch theo tay; kéo đủ 22px thì một hạt trượt về vạch (hoạt ảnh 230ms) và đếm +1. Kéo chưa đủ mà thả → chuỗi bật về.
- **Chạm** (không kéo) cũng +1 hạt.
- Hạt ở giữa to nhất, xa vạch thì nhỏ và mờ dần. Mỗi hạt thứ 27 là **hạt mẫu** màu vàng.
- Mỗi lần đếm: vạch sáng lên và phóng nhẹ. Qua 108 → quay về 1, số tràng tăng.
- Bắt đầu lại → 0; Xong → Trang chủ.

### Chuông mõ
**Mục đích:** gõ mõ giữ nhịp tụng, thỉnh chuông khi thiền. Âm thanh tạo trực tiếp trên máy (không cần file).
**Thành phần:** header "Chuông mõ · [trạng thái]"; preset (chip): Tụng kinh, Niệm Phật, Lạy sám hối, Ngồi thiền, Chỉ gõ mõ; chế độ (segmented): Mõ · Chuông · Mõ + chuông; "Thỉnh chuông sau mỗi" Tắt / 10 / 27 / 108 tiếng mõ (chỉ hiện ở Mõ + chuông); bộ chỉnh nhịp (−/+) với nhãn và giá trị; **nút gõ lớn** (nhãn MÕ/CHUÔNG, số đếm, gợi ý) có quầng sáng; 3 nút dưới: trái (Dồn mõ / Đặt lại), giữa (Phát/Dừng tự động), phải (Thỉnh chuông); bộ đếm tiếng mõ và tiếng chuông.
**Hoạt động:**
- **Preset** đặt sẵn: Tụng kinh = Mõ + chuông, 72 nhịp/phút, chuông mỗi 10 tiếng; Niệm Phật = 96 nhịp/phút, chuông mỗi 27; Lạy sám hối = chỉ chuông, 12 giây/tiếng; Ngồi thiền = chỉ chuông, 60 giây/tiếng; Chỉ gõ mõ = 60 nhịp/phút. Tự chỉnh bất cứ thông số nào → bỏ chọn preset.
- **Chạm nút lớn:** gõ một tiếng mõ (hoặc chuông ở chế độ Chuông); nút co lại, viền và quầng sáng lóe lên; số đếm +1. Ở Mõ + chuông, đủ số tiếng đã chọn thì tự thỉnh một tiếng chuông.
- **Phát tự động:** giữ nhịp liên tục; mõ: 40–160 nhịp/phút (bước 4); chuông: 5–120 giây/tiếng (bước 5). Header ghi "· đang giữ nhịp".
- **Dồn mõ:** 16 tiếng mõ nhanh dần rồi kết bằng một tiếng chuông; trong lúc dồn không nhận chạm.
- **Đặt lại** (chế độ Chuông): dừng và xóa bộ đếm.
- Đổi preset / chế độ → dừng phát tự động. Rời trang → tự dừng và đặt lại.

### Chuông nhắc (Chuông tỉnh thức)
**Thành phần:** "Nhắc bạn trở về hơi thở" + mô tả; "Giờ nhắc chính" — giờ lớn với nút ▲▼, dòng gợi ý theo buổi; 7 nút ngày T2–CN; "Thời khóa khác" (các mốc có công tắc); nút "Lưu chuông nhắc".
**Hoạt động:** ▲▼ đổi giờ vòng 0–23; gợi ý: trước 11h "Công phu khuya", 11–18h "Một phút trở về hơi thở giữa ngày", sau 18h "Buông thư trước khi ngủ". Bấm ngày để bật/tắt; tóm tắt "05:30 · mỗi ngày" hoặc "05:30 · N ngày mỗi tuần".

---

## 5. Nhật ký & tiến trình

### Nhật ký
**Thành phần:** header ghim (Back · "Nhật ký" · "Lịch âm"); thẻ "Thời lượng theo tuần · TB 22 phút/ngày" — 7 cột T2–CN; danh sách ngày đã ghi (ngày, tháng, tiêu đề, tóm tắt, thẻ màu); **nút "Ghi lại hôm nay" full-width cố định ở đáy**, chừa safe area.
**Hoạt động:** Lịch âm → Lịch âm; bấm ngày → Chi tiết nhật ký; Ghi lại → Viết nhật ký.

### Viết nhật ký
**Thành phần:** header "Nhật ký hôm nay" + "Lưu"; ngày dương (10 TH9) và ngày âm ("16 tháng Bảy âm · sau ngày rằm"); ô "Ghi lại" (đếm số chữ); "Gắn thẻ" — Thiền, Niệm Phật, Tụng kinh, + Thẻ mới; nút "Lưu vào nhật ký".
**Hoạt động:** thẻ chọn nhiều; Lưu → Nhật ký.

### Chi tiết nhật ký (một ngày)
**Thành phần:** header "09 tháng 9 · 16 tháng Bảy âm · Rằm Vu Lan" + "Sửa"; thẻ "Thời khóa đã tròn" (có bản sáng/tối); tâm trạng, hồi hướng, thẻ; nội dung đã viết; "Đã hành trong ngày" (mỗi hàng có "Mở"); **2 nút "Viết thêm", "Xem tiến trình" cố định ở đáy**.
**Hoạt động:** Sửa / Viết thêm → Viết nhật ký; hàng kinh → Chi tiết bài kinh; hàng niệm Phật → Niệm Phật; Xem tiến trình → Thống kê.

### Thống kê (Tiến trình tu tập)
**Thành phần:** header "Tiến trình tu tập · 12 tuần gần nhất"; thẻ "Chuỗi ngày tinh tấn · 42" + "Còn 6 ngày nữa là tròn dấu ấn An cư 48 ngày"; 2 ô: Tổng thời gian 168 giờ (+8 giờ so với tháng trước), Giờ ngồi quen 05:40 (68% vào buổi sáng); biểu đồ cột 12 tuần; "Phân bổ pháp hành" — thanh ngang: Thiền hơi thở 42%, Tụng kinh 28%, Niệm Phật 20%, Pháp thoại 10%; thẻ "Giữ chuỗi ngày bằng chuông nhắc".
**Hoạt động:** thẻ chuông nhắc → Chuông nhắc.

### Thành tựu (Dấu ấn tu tập)
**Thành phần:** header "Dấu ấn tu tập · 6 trong 18 dấu ấn"; thẻ "Dấu ấn gần nhất · An cư bốn mươi ngày"; lưới 3 cột 9 huy hiệu; **nút "Xem tiến trình tu tập" cố định ở đáy**.
**Hoạt động:** huy hiệu đã đạt: đầy màu, dòng phụ "Đã đạt / Mới đạt". Chưa đạt: mờ 50%, viền nét đứt, dòng phụ tiến độ ("Còn 58 ngày", "Còn 2 giờ", "Chưa mở"). Nút đáy → Thống kê.

### Lịch âm
**Thành phần:** header "Tháng 9 · 2026 · Âm lịch [năm can chi] · tháng [âm]" + nút ‹ ›; carousel 6 tháng (lưới 7 cột: ngày dương + ngày âm); gợi ý "Trượt ngang để xem tháng khác"; thẻ "Hôm nay" (có bản sáng/tối) + lời nhắc; sự kiện chùa.
**Hoạt động:**
- Chuyển tháng: vuốt / kéo ngang, cuộn chuột dọc, hoặc nút ‹ ›. Header cập nhật theo tháng.
- Mùng 1 và Rằm ghi chữ; ngày chay (1, 8, 14, 15, 18, 23, 30 âm) nền vàng nhạt; hôm nay nền đậm hơn; ngày chọn nền mực.
- Sự kiện chùa → Trang chùa.

### Chi tiết ngày âm
**Thành phần:** header trong suốt; bìa: ngày âm lớn, loại ngày (Hoàng đạo / Hắc đạo / Rằm / Mùng Một, có chấm màu); bảng Ngày · Tháng · Năm (can chi) · Dương lịch; "Giờ hoàng đạo" — 6 giờ tốt (tên chi, con giáp, khung giờ); "Tuổi xung khắc" — 2 tuổi + giải thích; "Hướng xuất hành" — Hỷ thần, Tài thần (hướng, ý nghĩa, chữ Hán 喜 / 財); lời khuyên + câu kinh trong ngày.
**Hoạt động:** mọi số liệu tính từ ngày đang chọn ở Trang chủ (mặc định hôm nay). Header chuyển nền đặc khi cuộn >110px.

---

## 6. Cộng đồng & chùa

### Bài đăng đạo tràng
**Thành phần:** header ghim (tên đạo tràng + số thành viên); thẻ bài gốc (avatar, tác giả, thời gian · thẻ, nội dung, Tùy hỷ + số, số bình luận, Chia sẻ); "N lời chia sẻ · Mới nhất"; danh sách bình luận (avatar, tên, thời gian, nội dung, Tán thán N, Trả lời; trả lời lùi vào 22px); **ô "Viết lời chia sẻ…" + nút gửi cố định ở đáy**, chừa safe area.
**Hoạt động:** Tùy hỷ bật/tắt → icon và số chuyển vàng, số +1. Nội dung bài lấy theo bài được bấm ở Đạo tràng. Ô nhập đứng yên ở đáy khi cuộn.

### Viết bài chia sẻ
**Thành phần:** header (Đóng · "Chia sẻ" · "Đăng"); avatar + tên + nút người xem; ô soạn; đính kèm: Thêm ảnh, Gắn câu kinh, Gắn thời khóa; "Gắn thẻ" — Thiền, Tụng kinh, Niệm Phật, Vu Lan; nút "Đăng lên đạo tràng".
**Hoạt động:** nút người xem xoay vòng: Đạo tràng Từ Quang → Bạn đồng tu → Chỉ mình tôi. Thẻ chọn nhiều. Đăng → Bài đăng; Đóng → Back.

### Trang chùa
**Mục đích:** hồ sơ đầy đủ của một ngôi chùa — tìm kiếm, hành hương, đi lễ thực tế.
**Mở từ:** thẻ chùa ở Trang chủ (đúng chùa được chọn), Đạo tràng của tôi, Lịch âm, chip chùa ở Lịch lễ Phật giáo.
**Mô hình dữ liệu (mỗi chùa):**
| Nhóm | Trường |
|---|---|
| Định danh & vị trí | name, aliases[] (tên dân gian — dùng cho tìm kiếm), lat/lng, street, ward, district, province, region (Bắc/Trung/Nam/Tây Nguyên), subRegion (Đông Nam Bộ, Tây Nam Bộ…) |
| Phật học & tổ chức | sect (Bắc tông, Nam tông Kinh/Khmer, Khất sĩ, Thiền phái Trúc Lâm, Kim Cương Thừa…), abbot (trụ trì), founder (tổ khai sơn), sangha (GHPGVN tỉnh/huyện) |
| Lịch sử & kiến trúc | era (năm / thế kỷ), rank (Không xếp hạng · cấp Tỉnh · Quốc gia · Quốc gia đặc biệt), archStyle (chữ Đinh, Tam, Nội công ngoại quốc…), materials, highlights[], bio (100–150 từ, biên tập riêng) |
| Tiện ích & hỗ trợ | hours / holHours (phút trong ngày; ngày thường & Rằm–Mùng Một), phone, fanpage, website, email, car, bike (có/không · phí), veg (cơm chay), books (kinh sách), retreat (khóa tu), rules[] (trang phục, chụp ảnh…) |

**Thành phần (trên xuống):**
1. **Header trong suốt** (Back); khi cuộn >110px chuyển nền đặc và hiện tên chùa.
2. **Bìa:** chip cấp di tích + chip hệ phái; tên chính thức; "Còn gọi: …" (tên dân gian, ẩn nếu không có); quận, tỉnh.
3. **3 nút:** Theo dõi / Đang theo dõi · Chỉ đường · Cúng dường.
4. **Thẻ trạng thái:** "Đang mở cửa · đóng lúc 20:00" hoặc "Đã đóng cửa · mở lại 5:00"; "Cách bạn … km"; 2 dòng giờ (Ngày thường, Rằm & Mùng Một) — dòng áp dụng hôm nay có nhãn "Hôm nay".
5. **Lưới 4 ô:** Niên đại · Cấp di tích · Hệ phái · Vùng miền.
6. **Giới thiệu:** tóm tắt lịch sử, thu gọn ~5 dòng + "Đọc thêm / Thu gọn".
7. **Tổ chức & truyền thừa:** Trụ trì, Tổ khai sơn, Giáo hội.
8. **Kiến trúc & di sản:** kiểu kiến trúc · vật liệu; danh sách điểm nổi bật.
9. **Tiện ích:** lưới 5 ô — Bãi đỗ ô tô, Giữ xe máy, Cơm chay, Kinh sách, Khóa tu.
10. **Lưu ý khi viếng thăm:** danh sách đánh số trên thẻ nổi bật (sáng/tối).
11. **Sự kiện & khóa học:** "Xem tất cả" + thời khóa sắp tới; chùa chưa có sự kiện → khung nét đứt "Chùa chưa đăng sự kiện nào…".
12. **Vị trí & liên hệ:** ô bản đồ (giữ chỗ); địa chỉ chuẩn hóa đầy đủ; vùng · tiểu vùng; tọa độ; nút Google Maps / Apple Maps; danh sách Hotline, Fanpage, Website, Email.
13. **Chân trang:** "Cập nhật MM/YYYY · Báo thông tin sai".

**Hoạt động:**
- **Giờ mở cửa:** so giờ hiện tại với khung giờ; nếu hôm nay là Rằm hoặc Mùng Một âm lịch thì dùng khung giờ lễ.
- **Khoảng cách:** công thức haversine từ vị trí người dùng (prototype cố định ở Quận 1, TP.HCM); <10 km hiện 1 số lẻ, còn lại làm tròn.
- **Chỉ đường / Google Maps / Apple Maps:** mở app bản đồ với điểm đến là tọa độ chùa.
- **Theo dõi:** bật/tắt riêng cho từng chùa.
- **Tiện ích:** có → dấu ✓ xanh, nền thẻ; không / chưa có → vòng rỗng, nền trong, ghi "Không có".
- **Trường trống:** Trụ trì, Tổ khai sơn, liên hệ… chưa có dữ liệu hiện "Đang cập nhật" (nghiêng, mờ), không ẩn dòng.
- Liên hệ: Hotline → gọi; Fanpage/Website → trình duyệt; Email → ứng dụng mail.
- Cúng dường → Cúng dường; Xem tất cả sự kiện → Sự kiện & khóa học của chùa này.

**Dữ liệu mẫu:** 9 chùa (Từ Quang — giả lập đầy đủ; Một Cột, Trấn Quốc, Hương, Bái Đính, Thiên Mụ, Linh Ứng, Trúc Lâm Đà Lạt, Vĩnh Nghiêm). Với chùa thật: niên đại/lịch sử cần đối chiếu nguồn chính thức; giờ mở cửa, tiện ích, lưu ý là mẫu; trụ trì & liên hệ để "Đang cập nhật".

### Sự kiện & khóa học (riêng từng chùa)
**Mở từ:** Trang chùa ("Xem tất cả" ở mục Sự kiện & khóa học), Đạo tràng (chip "Sự kiện & khóa học" → Từ Quang).
**Thành phần:** header ghim "Sự kiện & khóa học" + dòng phụ tên chùa; 3 tab chip: Sắp diễn ra, Khóa học, Đã ghi danh; thẻ nổi bật "Khóa tu một ngày an lạc" (ô ngày, giờ, nơi, người hướng dẫn, nút "Ghi danh", "còn 12 chỗ" — bản sáng/tối); tiêu đề danh sách; danh sách sự kiện (ô ngày màu, tên, mô tả, trạng thái).
**Hoạt động:**
- Đổi tab → đổi tiêu đề và danh sách: Sắp diễn ra ("Trong tháng này"), Khóa học ("Khóa học nhiều buổi" — ô ngày ghi số tuần), Đã ghi danh.
- Trạng thái: Ghi danh / Còn N chỗ / Đang mở / Sắp mở / Đã ghi danh.
- **Chùa chưa có sự kiện:** trạng thái rỗng — biểu tượng đèn, "Chùa chưa đăng sự kiện nào", nút Theo dõi (dùng chung trạng thái theo dõi với Trang chùa), link "Xem lịch lễ Phật giáo chung".
- Ghi danh / bấm sự kiện → Ghi danh.
- Prototype: chỉ Từ Quang có dữ liệu sự kiện.

### Lịch lễ Phật giáo (lịch chung)
**Mục đích:** các ngày lễ chung của Phật giáo, không thuộc riêng chùa nào.
**Mở từ:** Trang chủ — "Tất cả", bấm một lễ, hoặc "+N sự kiện khác" ở mục Sự kiện Phật giáo; link trong trạng thái rỗng của Sự kiện & khóa học.
**Thành phần:** header ghim "Lịch lễ Phật giáo" + dòng phụ "12 tháng tới · N ngày"; 3 chip lọc (ghim cùng header): Tất cả · Lễ lớn · Rằm & Mùng Một; dòng giải thích; danh sách nhóm theo tháng dương — mỗi mục: ngày dương + thứ, tên lễ, đếm ngược, ngày âm · "N chùa tổ chức", chip các chùa.
**Hoạt động:**
- Tính từ hôm nay đến 12 tháng tới theo lịch âm (múi giờ +7); tháng nhuận ghi "(nhuận)".
- Lễ lớn (vía, Phật đản, Vu Lan…) tên ngày màu nhấn; Rằm & Mùng Một ghi "ngày trai giới".
- Đếm ngược: "Hôm nay" (viền vàng) / "Ngày mai" / "còn N ngày".
- Hiện tối đa 3 chip chùa + "+N chùa"; bấm chip → Trang chùa đó.
- Chùa tổ chức (mẫu): lễ lớn → cả 9 chùa; vía khác → Từ Quang + 2 chùa; Rằm & Mùng Một → Từ Quang. Bản thật lấy từ sự kiện chùa đăng ký.

### Ghi danh
**Thành phần:** header "Ghi danh"; tên khóa; bảng Thời gian · Địa điểm · Hướng dẫn; "Số người cùng đi" — Một mình, 2 người, 3 người, 4+; ghi chú "Khóa tu miễn phí. Xin đến trước 6:15…"; nút xác nhận.
**Hoạt động:** nút đổi chữ theo số người: "Ghi danh cho tôi" / "Ghi danh 2 người"…; xác nhận → Sự kiện.

### Cúng dường đèn
**Thành phần:** header "Cúng dường đèn"; thẻ "Thắp một ngọn đèn, hồi hướng cho người thương" + "Bạn đã thắp 2 / 3 ngọn mùa Vu Lan"; "Chọn tâm nguyện cúng dường" — 3 ô: 50.000đ (một ngọn), 200.000đ (bốn ngọn), Tùy tâm (tự nhập); "Hồi hướng cho"; "Chùa nhận cúng dường"; cam kết "100% chuyển thẳng đến chùa · có biên nhận công khai"; nút thanh toán.
**Hoạt động:** chọn mức (viền vàng); nút ghi số tiền đã chọn; thanh toán → Biên nhận.

### Biên nhận
**Thành phần:** "Đèn đã được thắp" + kệ hồi hướng; bảng: Số tiền, Nơi nhận, Hồi hướng cho, Thời gian, Mã biên nhận (IL-2609-4471); "Chùa đã xác nhận · biên nhận công khai trong sổ công đức"; nút "Lưu ảnh", "Về trang chủ".
**Hoạt động:** Về trang chủ → xóa ngăn xếp, về Trang chủ.

### Gói Sen Vàng
**Thành phần:** nền tối; "Mở trọn thư viện pháp bảo"; 4 quyền lợi (kinh song ngữ có phiên âm, khóa thiền 8 tuần, tải về nghe không mạng, nhật ký không giới hạn); 3 gói có radio: Tháng 79.000₫, Năm 589.000₫ (49.000₫/tháng, nhãn "TIẾT KIỆM 38%"), Trọn đời 1.890.000₫; nút + ghi chú điều khoản; "Để sau, tôi dùng bản miễn phí".
**Hoạt động:** mặc định chọn gói Năm. Nút và ghi chú đổi theo gói: Tháng/Năm → "Dùng thử 7 ngày miễn phí" + giá sau thử; Trọn đời → "Thỉnh gói trọn đời" + "Thanh toán một lần". Nút → Biên nhận; Để sau → Back.

---

## 7. Cài đặt & hệ thống

### Chỉnh sửa hồ sơ
**Thành phần:** header + "Lưu"; avatar + "Đổi ảnh đại diện"; ô: Pháp danh, Số điện thoại, Chùa/đạo tràng; "Đôi dòng về bạn"; công tắc "Hiển thị trong đạo tràng"; "Vùng cẩn trọng": Đổi mật khẩu, Xóa tài khoản và toàn bộ dữ liệu (chữ đỏ).
**Hoạt động:** Lưu / Back → trang trước.

### Cài đặt
**Thành phần:** thẻ tài khoản (tên, pháp danh, số điện thoại); nhóm **Thời khóa** (các công tắc); **Hiển thị & ngôn ngữ** (Cỡ chữ kinh văn, Ngôn ngữ, Giao diện); **Nội dung & trợ giúp** (Tải về, Trợ giúp); **Riêng tư** (công tắc); phiên bản "InnerLamp 1.4", Điều khoản, Quyền riêng tư; link "Xem trạng thái ngoại tuyến →".
**Hoạt động:** 4 công tắc bật/tắt độc lập; hàng mũi tên → Ngôn ngữ & hiển thị / Tải về / Trợ giúp; link → Ngoại tuyến.

### Ngôn ngữ & hiển thị
**Thành phần:** "Ngôn ngữ" — Tiếng Việt (có phiên âm Hán – Việt), English (Pali reference), 中文 · 繁體; "Cỡ chữ kinh văn" — Nhỏ, Vừa, Lớn, Rất lớn + câu xem trước; "Giao diện" — 3 ô màu Sáng, Tối, Theo máy.
**Hoạt động:** ngôn ngữ chọn một (radio, viền vàng). Cỡ chữ đổi câu xem trước ngay: 14 / 16 / 19 / 22px. Giao diện đổi toàn app ngay lập tức.

### Tải về
**Thành phần:** header "Nghe không cần mạng · 8 mục · 412 MB"; thanh dung lượng "412 MB / 2 GB" chia màu Pháp thoại / Kinh văn / Nhạc thiền; danh sách: tên, dung lượng · thời lượng, trạng thái.
**Hoạt động:** trạng thái: "Đã tải" (xanh), "72%" (thanh tiến độ, màu nhấn), "Chờ Wi-Fi" (xám).

### Thông báo
**Thành phần:** header (nút Đóng); thẻ "SẮP DIỄN RA · 30 PHÚT NỮA · Thời khóa tối cùng đạo tràng" + nút "Ngồi ngay", "Bỏ qua tối nay"; "Hôm nay" — danh sách thông báo (icon màu, tiêu đề, nội dung, thời gian, chấm chưa đọc).
**Hoạt động:** Ngồi ngay → Chuẩn bị thiền; chấm vàng = chưa đọc.

### Ngoại tuyến
**Thành phần:** banner "Đang ngoại tuyến" + "Thử lại"; "Không có mạng, vẫn ngồi được" + giải thích; "Đã tải về máy" — các bài đã tải; thẻ "Niệm Phật không cần mạng".
**Hoạt động:** bài đã tải → Chuẩn bị thiền / Tụng kinh; thẻ niệm Phật → Niệm Phật.

### Trợ giúp
**Thành phần:** "Bạn đang cần giúp điều gì?" + ô tìm; 5 câu hỏi dạng mở/đóng (nghe không mạng, đổi điện thoại, gia hạn Sen Vàng, biên nhận cúng dường, tắt thông báo nhưng giữ chuông); "Vẫn chưa rõ? Ban hộ trì thường trả lời trong vòng một ngày".
**Hoạt động:** mỗi lúc chỉ mở một câu; bấm câu đang mở thì đóng; câu mở có viền vàng, mũi tên xoay 180°. Ô tìm → Tìm kiếm.

### Đang tải
**Thành phần:** "Đang thắp đèn…" + 4 thanh khung xương (skeleton) nhấp nháy lệch nhịp.

### Lỗi
**Thành phần:** IL-State lỗi, "Mã lỗi 503 · 09:42"; nút Thử lại; nút mở nội dung đã tải.
**Hoạt động:** Thử lại → Đang tải; nội dung đã tải → Tải về.

### Popup lỗi (bộ mẫu)
**Thành phần:** 6 hàng demo + khối "Nguyên tắc".
**Hoạt động:**
- **Toast trên:** lỗi nhẹ, không nút, tự tắt sau ~3 giây.
- **Banner trên có hành động:** nền tối, 2 nút — lỗi cần quyết định.
- **Snackbar dưới:** 1 dòng, 1 hành động, tự tắt sau ~3 giây.
- **Bottom sheet lỗi:** lỗi có ngữ cảnh dài, mã lỗi, 2 nút.
- **Dialog giữa màn hình:** chặn luồng, buộc chọn 1 trong 2.
- **Toàn màn hình:** sự cố nặng, app không tiếp tục được.
- Mọi dạng đều có cách thoát rõ ràng; mở trang khác sẽ tự đóng popup.

### Bộ component
**Thành phần:** trang tổng hợp các component (xem bảng ở mục 0) và trạng thái: IL-NavBar (mặc định, tối, có dòng phụ, có nút phải, đóng), IL-BottomNav (5 tab, active, nút đèn nổi), IL-SettingRow (mũi tên, công tắc bật/tắt, giá trị, hàng cuối, tối), IL-State (rỗng, lỗi, ngoại tuyến, hoàn thành, tối), IL-Avatar (4 tông, 28–96px), IL-Btn, IL-Chip, IL-Field, IL-Row.

---

## Ghi chú cho đội phát triển
- Dữ liệu trong prototype là mẫu (bài viết lặp lại 5 bài, số liệu thống kê cố định) — thay bằng API.
- Lịch âm, can chi, giờ hoàng đạo, hướng xuất hành, sự kiện Phật giáo được **tính thật** theo múi giờ +7.
- Âm thanh mõ/chuông hiện tổng hợp trên máy; bản chính thức nên thay bằng file ghi âm thật.
- Chùa: dữ liệu mẫu theo mô hình ở mục Trang chùa; vị trí người dùng cố định — bản thật dùng GPS (xin quyền vị trí) để tính "gần tôi".
- Sự kiện: tách 2 nguồn — lịch lễ chung (tính từ âm lịch) và sự kiện riêng do từng chùa đăng.
- Ảnh (bài viết, chùa, thư viện ảnh) là ô giữ chỗ.
