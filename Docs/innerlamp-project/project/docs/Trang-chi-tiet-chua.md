# Trang chi tiết chùa — đặc tả cho bản Web

Nguồn: `InnerLamp Prototype.dc.html`, màn hình "Trang chùa". Bản web cần hiển thị đủ các khối dưới đây, theo đúng thứ tự.

## Bố cục (từ trên xuống)

1. **Thanh điều hướng dính** — nút Quay lại + tên chùa (tên hiện khi cuộn qua hero). Nền trong suốt → đặc dần khi cuộn.
2. **Hero ảnh** (cao ~400px trên mobile; web nên 420–520px, full-bleed)
   - Ảnh toàn cảnh chùa phủ nền, gradient tối ở mép trên (cho thanh điều hướng) và chuyển về màu nền ở đáy.
   - Chip: Cấp di tích · Hệ phái
   - Tên chùa (Cormorant Garamond 28px)
   - "Còn gọi: …" (tên khác, nối bằng " · "), chỉ hiện khi có
   - Quận/huyện, Tỉnh/thành
3. **3 nút hành động** (đè lên mép dưới hero −20px): Theo dõi / Đang theo dõi (nút chính) · Chỉ đường · Cúng dường
4. **Thẻ giờ mở cửa**
   - Trạng thái: chấm xanh "Đang mở cửa · đóng lúc HH:MM" hoặc chấm xám "Đã đóng cửa · mở lại HH:MM"
   - Khoảng cách: "Cách bạn X km"
   - 2 dòng giờ: Ngày thường / Rằm & Mùng Một; dòng áp dụng hôm nay có nhãn "Hôm nay" (tính theo âm lịch: mùng 1 và 15)
5. **Lưới 4 ô thông tin** (2 cột): Niên đại · Cấp di tích · Hệ phái · Vùng miền
6. **GIỚI THIỆU** — đoạn tiểu sử (Literata 16px/1.8), thu gọn có nút "Xem thêm / Thu gọn"
7. **HÌNH ẢNH** — dải ảnh cuộn ngang, 5 ảnh: Toàn cảnh chùa (rộng hơn), Chánh điện, Tượng Phật, Cổng tam quan, Khuôn viên. Bo góc 18px, cao 180px. Web: có thể chuyển thành lưới 3–5 cột, bấm mở lightbox.
8. **TỔ CHỨC & TRUYỀN THỪA** — thẻ dạng nhãn/giá trị: Trụ trì · Tổ khai sơn · Giáo hội. Thiếu dữ liệu → "Đang cập nhật" (màu nhạt).
9. **KIẾN TRÚC & DI SẢN**
   - Thẻ nhãn/giá trị: Kiểu kiến trúc · Vật liệu (cùng kiểu với khối Tổ chức)
   - Danh sách điểm nổi bật: mỗi mục một thẻ, chấm vàng #D9963C bên trái
10. **TIỆN ÍCH** — lưới 2 cột: Bãi đỗ ô tô · Giữ xe máy · Cơm chay · Kinh sách · Khóa tu. Có → dấu ✓ xanh, nền thẻ; không có → vòng tròn rỗng, nền trong suốt, giá trị "Không có".
11. **LƯU Ý KHI VIẾNG THĂM** — thẻ nền nổi bật (feat-bg), danh sách đánh số 01, 02, 03…
12. **SỰ KIỆN & KHÓA HỌC** + "Xem tất cả"
    - Có lịch: danh sách hàng sự kiện (tiêu đề, ngày · giờ · địa điểm, trạng thái Ghi danh / Đã ghi danh)
    - Không có: ô viền đứt "Chùa chưa đăng sự kiện nào. Theo dõi để nhận thông báo khi có khóa tu mới."
13. **VỊ TRÍ & LIÊN HỆ**
    - Thẻ bản đồ (ảnh map 130px) + địa chỉ đầy đủ (đường, phường, quận, tỉnh) + vùng miền + tọa độ + 2 nút Google Maps / Apple Maps
    - Thẻ liên hệ: Hotline (tel:) · Fanpage · Website · Email (mailto:). Thiếu → "Đang cập nhật".
14. **Chân trang** — "Cập nhật MM/YYYY · Báo thông tin sai"

## Trạng thái phụ
- **Lỗi tải**: màn riêng "Trang chùa" với thông báo lỗi + nút thử lại.

## Trường dữ liệu mỗi chùa
`name, aliases[], sect, founder, abbot, sangha, era, rank, archStyle, materials, highlights[], bio, hours[open,close], holHours[open,close], lat, lng, street, ward, district, province, region, subRegion, car, bike, veg, books, retreat, rules[], sched, phone, fanpage, web, email, updated`
Ảnh: `hero-{id}` (ảnh hero), `gal-{id}-1…5` (bộ ảnh), `map-{id}` (bản đồ).

## Kiểu chữ & màu
- Tiêu đề: Cormorant Garamond 500 · Nội dung: Be Vietnam Pro · Văn bản dài/trích dẫn: Literata
- Nhãn mục: Be Vietnam Pro 600 10.5px, chữ hoa, letter-spacing .16em, màu ink-45
- Thẻ: nền card, viền 1px ink-08, bo 16–20px
- Hỗ trợ sáng/tối qua biến màu `--il-*` như app.

## Gợi ý cho web (≥1024px)
Hai cột: cột trái (Giới thiệu, Hình ảnh, Kiến trúc, Lưu ý, Sự kiện), cột phải dính (giờ mở cửa, 3 nút hành động, 4 ô thông tin, Vị trí & liên hệ, Tiện ích).
