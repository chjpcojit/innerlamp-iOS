# Client Contract — Sổ giỗ (memorial) v1

Version: 1.0 · Last updated: 2026-11-16 · Owner: ⚔ Đạo Sư ⚔ (Tech Lead)
Pinned for InnerLamp iOS P4: 2026-11-16 · source `client-contract-memorial-v1.md`
Status: **SPEC — chưa code, chưa commit.**
Nguồn: `innerlamp-memorial/docs/specs/api/openapi.yaml` **working tree ngày 2026-11-16** (info.version `3.1.0`, **chưa commit**; HEAD `e5d4c9c` vẫn là `3.0.0` với 5 route), product spec `docs/product/memorial/product.md` v2.1.
Đích: website SvelteKit, iOS SwiftUI, Android Kotlin.

> Đây là contract **client dùng để tích hợp với bản BE đang chạy**. Bản deploy hiện có 5 route CRUD; 2 route ảnh có trong code/OpenAPI nhưng **chưa deploy** (đã kiểm 2026-11-16: `PUT/DELETE /v1/memorials/1/photo` → 404, `GET /v1/memorials` → 401). Xem §9.

---

## 0. Bảy quy tắc bắt buộc cho Dev

1. **Chỉ gửi 5 field nhắc tối thiểu**: `reminder = {days_before, time}`. **Không gửi `timezone`, không gửi `add_to_os_reminder`.** Hai field này có trong bản deploy v1 nhưng sẽ bị **từ chối 400** ở contract v4.0 (Phase 8). Kiểu gửi tối thiểu hợp lệ ở **cả hai** phiên bản.
2. **Bỏ qua field lạ khi decode response.** v1 trả thêm `reminder.timezone` và `add_to_os_reminder`; client không được fail decode, không được lưu/ghi đè hai field này.
3. **Ngày gửi lên luôn là ngày dương `YYYY-MM-DD`** khi biết năm. Âm lịch do client quy đổi trước khi gửi; `death_calendar` chỉ nói **người dùng đã nhập lịch nào**, không phải lịch của `death_date`.
4. **Không gửi đồng thời hai dạng ngày.** Hoặc `death_date`, hoặc `death_day` + `death_month` (+ `death_leap_month`). Gửi cả hai = 400.
5. **PUT là thay thế toàn bộ.** Field không gửi bị xoá (`note` → null, `reminder` → tắt). Luôn dựng body đầy đủ từ form hiện tại, không PATCH từng phần.
6. **Phân nhánh theo `error.code`, không theo `message`.** `message` là tiếng Anh, có thể đổi.
7. **`photo_url` là signed URL sống 15 phút.** Không lưu vào DB/local cache; mỗi lần mở sổ/chi tiết lấy lại từ `GET`, hoặc chấp nhận ảnh có thể 403 sau 15 phút.

---

## 1. Kết nối & xác thực

### 1.1 Base URL

| Client | Giá trị hiện tại | Việc phải làm ở P4 |
|---|---|---|
| Website | `API_BASE_URL=https://innerlamp-app-3f53tei42a-as.a.run.app` (`.env:2`) | không đổi; `.env.example` vẫn là localhost |
| iOS | `APIConfig.serverBaseURL` = `http://WeeDigitals-MacBook-Pro.local:8080` (`InnerLamp/Core/Networking/APIConfig.swift:38-45`) | đổi `.dev` sang `https://innerlamp-app-3f53tei42a-as.a.run.app`; HTTPS nên bỏ ngoại lệ ATS HTTP nếu không còn dùng |
| Android | `BuildConfig.BASE_URL` dev = `https://dev-api.innerlamp.vn/` (`app/build.gradle.kts:81`) — URL giả, chưa có backend | đổi flavor `dev` sang `https://innerlamp-app-3f53tei42a-as.a.run.app/` (giữ `/` cuối theo Retrofit) |

Chỉ dùng **một** base URL cho cả 7 route. Không hardcode URL trong feature.

### 1.2 Header

```
Authorization: Bearer <access_token>      # bắt buộc, mọi route
Accept: application/json
Content-Type: application/json            # trừ PUT ảnh: multipart/form-data
```

- Access token lấy từ `POST /v1/auth/login` hoặc `register/verify-otp`. **Refresh token không dùng được** (401).
- Route Bearer còn kiểm session (`sid`): đăng xuất/thu hồi → 401 ngay, không đợi token hết hạn.
- Website gửi thêm `X-API-Key` trên mọi call qua `apiCall`; với route memorial header này **không bắt buộc** và không thay thế Bearer.
- Không gửi token qua query string, không log token/`photo_url`.

### 1.3 Envelope

Thành công:
```json
{ "success": true, "data": { } }
```
Danh sách:
```json
{ "success": true, "data": { "items": [], "total": 0 } }
```
Xoá mục (không có `data`):
```json
{ "success": true }
```
Lỗi:
```json
{ "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "…", "type": "validation" },
  "details": { "field": "reminder.time" } }
```
`ApiError`/`NetworkError` của từng client đã bám envelope này; chỉ cần đọc thêm `details.field`.

### 1.4 Kiểu ID

`id` là **số nguyên dương** (`integer`, min 1). Web đang dùng `id: string` trong view model → đổi sang `number` ở DTO và `String(id)` chỉ khi cần làm route param. iOS `Int64`, Android `Long`. Không parse id từ chuỗi có ký tự lạ; id sai → server trả 404, không phải 400.

---

## 2. Model `Memorial`

### 2.1 Field

| Field | Kiểu | Null | Ghi khi tạo/sửa | Đọc | Ghi chú |
|---|---|---|---|---|---|
| `id` | integer | không | — | ✓ | > 0 |
| `full_name` | string | không | ✓ | ✓ | trim; 1–100 ký tự sau trim |
| `relationship` | enum 10 giá trị | không | ✓ | ✓ | §2.2 |
| `death_calendar` | `"solar"`/`"lunar"` | không | ✓ | ✓ | lịch **người dùng nhập** |
| `death_date` | string `YYYY-MM-DD` | ✓ | ✓ (một trong hai dạng) | ✓ | **luôn là dương lịch** |
| `death_day` | integer 1–31 | ✓ | ✓ (dạng không năm) | ✓ | theo `death_calendar` |
| `death_month` | integer 1–12 | ✓ | ✓ (dạng không năm) | ✓ | theo `death_calendar` |
| `death_leap_month` | boolean | ✓ | ✓ (chỉ lunar) | ✓ | `null` khi có `death_date` |
| `note` | string | ✓ | ✓ | ✓ | ≤ 1000; rỗng/toàn space → `null` |
| `photo_url` | string | ✓ | — | ✓ | signed URL 15 phút; `null` nếu chưa có ảnh |
| `reminder` | object | ✓ | ✓ | ✓ | `null` = tắt nhắc |
| `reminder.days_before` | integer 0–30 | không (trong object) | ✓ | ✓ | UI chỉ cho 0/1/3/7 |
| `reminder.time` | string `HH:mm` | không | ✓ | ✓ | 24h; UI chỉ cho 06:00/07:00/12:00/19:00 |
| `reminder.timezone` | string IANA | không (v1) | **KHÔNG gửi** | bỏ qua | v1 luôn trả `Asia/Ho_Chi_Minh`; v4.0 bỏ field |
| `add_to_os_reminder` | boolean | không (v1) | **KHÔNG gửi** | bỏ qua | v1 default `false`; v4.0 bỏ field |
| `created_at` | string RFC3339 | không | — | ✓ | server |
| `updated_at` | string RFC3339 | không | — | ✓ | server |

**Field lạ bị từ chối 400**, kể cả `id`, `user_id`, `photo_url`, `created_at`. Decoder client phải cấu hình **bỏ qua unknown field** (Swift `JSONDecoder` mặc định bỏ qua; Kotlin `Json { ignoreUnknownKeys = true }`; web không cần).

### 2.2 Enum `relationship` (10 giá trị)

| Contract | Nghĩa | Web (internal key) | iOS | Android |
|---|---|---|---|---|
| `GRANDFATHER_PATERNAL` | ông nội | `paternal_grandfather` | `.paternalGrandfather` | `PaternalGrandfather` |
| `GRANDFATHER_MATERNAL` | ông ngoại | `maternal_grandfather` | `.maternalGrandfather` | `MaternalGrandfather` |
| `GRANDMOTHER_PATERNAL` | bà nội | `paternal_grandmother` | `.paternalGrandmother` | `PaternalGrandmother` |
| `GRANDMOTHER_MATERNAL` | bà ngoại | `maternal_grandmother` | `.maternalGrandmother` | `MaternalGrandmother` |
| `FATHER` | cha | `father` | `.father` | `Father` |
| `MOTHER` | mẹ | `mother` | `.mother` | `Mother` |
| `SPOUSE` | vợ/chồng | `spouse` | `.spouse` | `Spouse` |
| `SIBLING` | anh chị em | `sibling` | `.sibling` | `Sibling` |
| `CHILD` | con | `child` | `.child` | `Child` |
| `OTHER` | khác | `other` | `.other` | `Other` |

Quy tắc: map **hai chiều bằng bảng tường minh**, không suy ra từ chuỗi hiển thị; giá trị lạ khi decode → lỗi decode có kiểm soát (không crash, không đoán `OTHER`). Trong push/notification sau này `OTHER` phải hiện "người thân", không hiện tên (NFR-MEM-02).

### 2.3 Ngày mất — hai dạng, một nguồn quy đổi

**Dạng A — biết năm** (`death_date`):
- Gửi `death_date = YYYY-MM-DD` **dương lịch**, từ `1900-01-01` đến **hôm nay theo Asia/Ho_Chi_Minh**.
- Nếu người dùng nhập **âm lịch**: client quy đổi `(day, month, year, leap)` → dương **chính xác** trước khi gửi. Năm không có tháng nhuận đó → chặn tại form (`mem_f_date_not_exist` / `ILMemorialError.invalidInput` / lỗi field ngày), **không** gửi lên.
- Khi đọc về: `death_calendar` cho biết hiển thị lại theo lịch nào. Nếu `lunar`, client `solarToLunar(death_date)` để lấy `day/month/year/leap` — đây là cách **khôi phục cờ nhuận** cho mục biết năm (product Appendix B.1).
- Không parse `death_date` thành `Date` theo UTC rồi hiển thị theo timezone máy: lệch 1 ngày. Dùng plain date (Swift `DateComponents`/`LocalDate`, web `new Date(y, m-1, d)` local, Kotlin `LocalDate`).

**Dạng B — không biết năm** (`death_day` + `death_month` + `death_leap_month`, **không gửi `death_date`**):
- `solar`: ngày hợp lệ của tháng, tháng 2 cho phép 29; `death_leap_month` phải `false`/không gửi.
- `lunar`: ngày 1–30, tháng 1–12; `death_leap_month` cho tháng nhuận, mặc định `false`.
- Khi đọc: dùng đúng `day/month/leap` server trả, **không** quy đổi sang dương để lưu (sẽ mất tháng nhuận).

**Quy đổi âm↔dương dùng chung vector**: `docs/product/memorial/rules/death-date-conversion.json` và `next-anniversary.json`. Mỗi client chạy **nguyên file**, không chép case. Đây là điều kiện gate của P4, không phải test tuỳ chọn.

**Tính kỳ giỗ**: làm ở client (product §3.6, BR-MEM-05…10). Backend hiện **không** trả `next_anniversary` (v4.0 Phase 9 mới có kế hoạch nhắc, và response vẫn không trả `next_*` — AC17b). Vì vậy danh sách sắp theo số ngày còn lại là việc của client.

### 2.4 Nhắc — payload v1 tương thích v4.0

Gửi:
```json
"reminder": { "days_before": 3, "time": "07:30" }
```
hoặc `"reminder": null` / bỏ field = tắt.

- `days_before` **0–30** theo schema; UI chỉ cho **0, 1, 3, 7**. `time` **HH:mm**; UI chỉ cho **06:00, 07:00, 12:00, 19:00**.
- Giá trị cũ ngoài lựa chọn (tạo trước v2.0): đọc lên hiển thị **lựa chọn gần nhất** (product FR-MEM-007): lead gần nhất, hoà → mốc sớm hơn (2→3, 5→7); giờ gần nhất, hoà → sớm hơn (09:30→07:00), trước 06:00→06:00, sau 19:00→19:00. **Không tự ghi đè** giá trị đã lưu cho tới khi người dùng bấm lưu.
- **Không gửi `timezone`**: bản v1 mặc định `Asia/Ho_Chi_Minh`; v4.0 bỏ field. Nhắc local chạy theo **giờ địa phương thiết bị** (xem technical decision D1) — khớp với ý "07:00 theo múi giờ tài khoản" khi tài khoản ở cùng thiết bị.
- **Không gửi `add_to_os_reminder`**: FR-MEM-009 đã bỏ từ product v2.0. Bản v1 mặc định `false`; v4.0 bỏ field.

> Vì sao không gửi `timezone`: nếu gửi, Phase 8 sẽ trả `400 VALIDATION_ERROR` đúng field đó (task Phase 8: "gửi `add_to_os_reminder` hoặc `reminder.timezone` → 400"). Payload tối thiểu ở trên chạy được trước **và** sau Phase 8 mà không phải sửa client.

---

## 3. Bảy route

`Auth` = Bearer bắt buộc. Mọi lỗi có thể tăng thêm 500.

### 3.1 `POST /v1/memorials` — tạo

| | |
|---|---|
| Auth | Bearer |
| Body | `MemorialRequest`: `full_name`*, `relationship`*, `death_calendar`*, một trong hai dạng ngày, `note?`, `reminder?` |
| 201 | `data` = Memorial (mới, `photo_url: null`) |
| 400 | `VALIDATION_ERROR` + `details.field` |
| 401 | `UNAUTHORIZED` |
| 409 | `MEMORIAL_LIMIT_REACHED` — đã đủ 100 mục |
| 413 | `PAYLOAD_TOO_LARGE` — body JSON quá lớn (phòng thủ; client chặn ở form) |
| 500 | `INTERNAL_ERROR` |

Client: 201 → đóng form, flash "Đã lưu vào sổ giỗ." (key hiện có), reload danh sách hoặc chèn bản ghi trả về. Không tự tăng `id`.

### 3.2 `GET /v1/memorials` — danh sách

| | |
|---|---|
| Auth | Bearer |
| Query | không có; **không phân trang** |
| 200 | `data = { items: Memorial[], total: number }` |
| 401 / 500 | như trên |

- Trả **toàn bộ** (tối đa 100), mới thêm trước: `created_at DESC, id DESC`. Không sắp theo ngày giỗ — client tự sắp.
- `items: []`, `total: 0` khi chưa có; không bao giờ `null`.
- Không cache response ở CDN/proxy; cache local chỉ là bản đọc (D6).

### 3.3 `GET /v1/memorials/{id}` — chi tiết

| | |
|---|---|
| Auth | Bearer |
| Path | `id` số nguyên dương |
| 200 | `data` = Memorial |
| 401 | `UNAUTHORIZED` |
| 404 | `MEMORIAL_NOT_FOUND` — không tồn tại, id sai, **hoặc của người khác** (cùng một body) |
| 500 | `INTERNAL_ERROR` |

Client không được phân biệt "không tồn tại" và "của người khác"; hiện cùng một trạng thái "mục không còn trong sổ".

### 3.4 `PUT /v1/memorials/{id}` — sửa (thay thế toàn bộ)

| | |
|---|---|
| Auth | Bearer |
| Body | như POST, **đầy đủ** |
| 200 | `data` = Memorial sau sửa |
| 400 | `VALIDATION_ERROR` + field |
| 401 | `UNAUTHORIZED` |
| 404 | `MEMORIAL_NOT_FOUND` |
| 413 | `PAYLOAD_TOO_LARGE` |
| 500 | `INTERNAL_ERROR` |

- Không đổi chủ, `created_at`, ảnh.
- **Thiếu `reminder` = tắt nhắc**; thiếu `note` = xoá ghi chú; đổi dạng ngày phải xoá dạng còn lại (không gửi `death_date` khi gửi `death_day/month` và ngược lại).
- 404 khi sửa: client coi mục đã bị xoá nơi khác → về sổ + thông báo "mục không còn", **không** giữ form như lỗi mạng.

### 3.5 `DELETE /v1/memorials/{id}` — xoá cứng

| | |
|---|---|
| Auth | Bearer |
| 200 | `{ "success": true }` — **không có `data`** |
| 401 | `UNAUTHORIZED` |
| 404 | `MEMORIAL_NOT_FOUND` (gọi lại sau khi xoá cũng 404) |
| 500 | `INTERNAL_ERROR` |

Client: 200 → xoá khỏi cache, flash "Đã xóa …". **404 = thành công về mặt UI** (mục đã không còn), không hiện lỗi. 500/mạng → giữ mục, hiện lỗi xoá.

### 3.6 `PUT /v1/memorials/{id}/photo` — tải/thay ảnh

| | |
|---|---|
| Auth | Bearer |
| Content-Type | `multipart/form-data`, đúng **một part tên `photo`** |
| Giới hạn | **≤ 5 MiB** (`5 × 1024 × 1024 = 5.242.880` byte); JPEG/PNG/WebP; server sniff **512 byte đầu**, không tin `Content-Type` của part |
| 200 | `data` = Memorial, `photo_url` = signed URL **15 phút** |
| 400 | `VALIDATION_ERROR`, `details.field = "photo"` — thiếu part, file rỗng, body không phải multipart |
| 401 | `UNAUTHORIZED` |
| 404 | `MEMORIAL_NOT_FOUND` — **kiểm quyền sở hữu trước khi đọc body**; id của người khác cũng 404, không nhận upload |
| 413 | `PHOTO_TOO_LARGE` |
| 415 | `PHOTO_UNSUPPORTED_TYPE` |
| 500 | `INTERNAL_ERROR` |

Client:
- Nén/convert ảnh về JPEG (iOS: HEIC → JPEG) **trước** khi upload; kiểm kích thước ở client để không gửi > 5 MiB (tiết kiệm pin/quota), nhưng vẫn map 413.
- Part filename bất kỳ; không gửi thêm field nào (server chỉ đọc `photo`).
- 200 → thay `photo_url` trong state; **không lưu URL**; ảnh cũ bị xoá best-effort sau khi DB nhận key mới.
- **Flag `memorial.photo.enabled = false`** cho tới khi route được deploy (D4). Khi flag tắt: ẩn nút ảnh, không gọi route.

### 3.7 `DELETE /v1/memorials/{id}/photo` — xoá ảnh

| | |
|---|---|
| Auth | Bearer |
| 200 | `data` = Memorial, `photo_url: null` — **mục chưa có ảnh vẫn 200** |
| 401 | `UNAUTHORIZED` |
| 404 | `MEMORIAL_NOT_FOUND` |
| 500 | `INTERNAL_ERROR` |

Client: 200 → về ảnh chữ cái đầu; xoá cache ảnh; không hiện lỗi nếu vốn không có ảnh.

---

## 4. Ảnh — chi tiết triển khai

| Việc | Quy định |
|---|---|
| Nguồn ảnh | iOS `PhotosPicker`/camera; Android Photo Picker/camera; web `<input type=file accept="image/jpeg,image/png,image/webp">` |
| Convert | HEIC/HEIF và định dạng khác → JPEG chất lượng ~0.8; giữ cạnh dài ≤ 2048 px để gần như chắc chắn < 5 MiB |
| Kiểm trước | `size > 5 MiB` → chặn, báo "Ảnh tối đa 5 MB" (không gọi API) |
| Hiển thị | `photo_url` signed 15 phút; dùng async image loader có cache theo URL+thời gian; khi 403/hết hạn → gọi lại `GET` mục để lấy URL mới, không loop |
| Quyền riêng tư | Không log URL/ảnh; không đưa `photo_url` vào analytics/crash; ảnh thuộc tài khoản, chỉ chủ thấy |
| Dọn object mồ côi | BE chưa làm (task Phase 6 `[ ]`); client không cần biết, nhưng đừng giả định URL cũ sống mãi |

---

## 5. Lỗi & map sang UI

### 5.1 Bảng mã

| HTTP | `error.code` | Khi nào | Client coi là |
|---|---|---|---|
| 400 | `VALIDATION_ERROR` | field sai/thiếu, field lạ, JSON hỏng, sai Content-Type, thiếu part ảnh | lỗi form (field-level nếu có `details.field`) |
| 401 | `UNAUTHORIZED` | thiếu/sai/hết hạn token, refresh token, session bị thu hồi | hết phiên → đăng nhập lại |
| 404 | `MEMORIAL_NOT_FOUND` | id không tồn tại/sai/**của người khác** | mục không còn |
| 409 | `MEMORIAL_LIMIT_REACHED` | đủ 100 mục | sổ đầy |
| 413 | `PAYLOAD_TOO_LARGE` (JSON) / `PHOTO_TOO_LARGE` (ảnh) | body quá lớn / ảnh > 5 MiB | ảnh quá lớn / lỗi lưu |
| 415 | `PHOTO_UNSUPPORTED_TYPE` | không phải JPEG/PNG/WebP | ảnh sai định dạng |
| 500 | `INTERNAL_ERROR` | lỗi server | lỗi tạm, thử lại |
| 0 | `NETWORK_ERROR` (client tự sinh) | không tới được server/timeout | mất kết nối |

`details.field` các giá trị có thể gặp: `full_name`, `relationship`, `death_calendar`, `death_date`, `death_day`, `death_month`, `death_leap_month`, `note`, `reminder.days_before`, `reminder.time`, `add_to_os_reminder` (nếu client lỡ gửi), `photo`.

### 5.2 Map theo nền tảng

| Tình huống | Website (SvelteKit) | iOS | Android |
|---|---|---|---|
| 401 | `endSession()` + 303 `/login` | `ILMemorialError.unauthorized` → coordinator đăng nhập | `AppError.Unauthorized` → Login, clear cache |
| `GET` list 5xx/mạng | `loadError` → `mem_err_load` + `mem_retry` (không offline) | đọc Core Data, banner "bản offline"; không có bản → `noOfflineCopy` | đọc Room, banner offline; không có → lỗi tải |
| `GET {id}` 404 | `mem_not_found` + `mem_back` | `.notFound` → pop + thông báo | `NotFound` → pop + thông báo |
| `PUT` 404 | flash `mem_flash_gone`, 303 `/memorial` | `.notFound` → `.removed(message)` | `NotFound` → đóng form + reload |
| `DELETE` 404 | flash `mem_flash_gone`, coi như xong | coi như xong, xoá cache | coi như xong, xoá cache |
| 409 | `mem_err_full`, giữ form | `.limitReached` (copy sổ đầy) | `LimitReached`, giữ form |
| 400 `full_name` | `mem_f_name_err` / `mem_f_name_too_long` | `nameError` | lỗi ô tên |
| 400 `note` | `mem_f_note_too_long` | `noteError` | lỗi ô ghi chú |
| 400 ngày (`death_*`) | `mem_f_date_invalid` | `dateError` | lỗi khối ngày |
| 400 field khác | `mem_err_save` (log code, **không log nội dung**) | `.invalidInput` | lỗi lưu chung |
| 413 JSON | `mem_err_save` | `.invalidInput` | lỗi lưu chung |
| 413 ảnh | `mem_photo_too_large` (key mới) | `.photoTooLarge` (case mới) | lỗi ảnh quá lớn |
| 415 ảnh | `mem_photo_unsupported` (key mới) | `.photoUnsupported` (case mới) | lỗi định dạng ảnh |
| 500 | `mem_err_save` / `mem_err_delete` / `mem_err_load` | `.saveFailed`/`.deleteFailed`/`.loadFailed` | `SaveFailed`/`DeleteFailed`/`LoadFailed` |

Quy ước: lỗi **4xx do dữ liệu** giữ form và dữ liệu người dùng nhập; **401** rời form; **404 khi sửa/xoá** đóng form; **mạng/5xx** giữ form (trừ GET list).

---

## 6. Bất biến & edge case

1. **Trần 100**: đếm ở server trong transaction; hai request đồng thời vẫn không vượt. Client hiển thị 409, không tự cắt danh sách.
2. **Danh sách không phân trang**: đừng thêm `page`/`limit` (server bỏ qua/không hỗ trợ); với 100 mục vẫn nhẹ.
3. **PUT thay thế**: form sửa phải gửi cả `reminder` đang hiển thị; nếu người dùng tắt → `null`.
4. **Ngày tương lai**: server từ chối; client cũng chặn theo `Asia/Ho_Chi_Minh`, không theo UTC.
5. **Năm < 1900**: server từ chối; client giới hạn 1900…năm nay.
6. **Tên toàn khoảng trắng**: coi như rỗng, chặn ở client; server cũng từ chối.
7. **Ghi chú toàn khoảng trắng**: gửi `null`.
8. **Xoá ảnh khi không có ảnh**: 200, không phải lỗi.
9. **Signed URL hết hạn**: 403 khi tải ảnh; refresh bằng `GET`, không coi là mục bị xoá.
10. **Sửa đồng thời hai thiết bị**: last-write-wins toàn bộ document (không version/ETag trong v1). Không có conflict 409 cho sửa; chấp nhận và ghi nợ.
11. **Offline**: chỉ đọc bản cache; **không xếp hàng ghi** (D6). iOS/Android báo "cần kết nối để sửa"; web báo lỗi tải.
12. **Đăng xuất**: xoá cache local + huỷ nhắc local đã đặt; không xoá dữ liệu server.

---

## 7. Những gì client KHÔNG được làm

- Không gọi `POST/PUT` với `reminder.timezone` hoặc `add_to_os_reminder`.
- Không gọi route ảnh khi flag tắt; không tự ghép URL ảnh từ `id`.
- Không tự tính `next_anniversary` ở server/backend; không mong response có `next_*`.
- Không hiển thị `photo_url`/tên/ghi chú trong log, crash report, analytics.
- Không gửi `death_day/month` cùng `death_date`.
- Không tự chọn `OTHER` khi gặp enum lạ; báo lỗi decode.
- Không lưu `photo_url` lâu hơn phiên hiện tại.

---

## 8. Tương thích & thay đổi contract

| Mốc | Trạng thái | Client phải làm |
|---|---|---|
| **Deployed hiện tại** | 5 route CRUD; `reminder.timezone` + `add_to_os_reminder` còn; route ảnh 404 | gửi payload tối thiểu; bỏ qua field thừa; **không** gọi ảnh |
| **Working tree BE (OpenAPI 3.1.0, chưa commit)** | thêm mô tả 2 route ảnh; code handler đã có, **chưa deploy** | code ảnh sau flag, chờ deploy |
| Phase 8 (v4.0) | bỏ 2 field; `days_before`/`time` chỉ nhận lựa chọn; tăng major OpenAPI; **phá vỡ tương thích** nhưng sản phẩm chưa phát hành | **không phải sửa** nếu đã theo §0; kiểm lại test decode |
| Phase 9 | thêm kế hoạch nhắc phía server (`next_*` nội bộ, **không** trả response — AC17b); `PATCH /v1/users/me` timezone | không đổi payload; nhắc local vẫn chạy tới Phase 10 |
| Phase 10 + notification | push + inbox; client đăng ký token, tắt nhắc local | xem D1/D2 cutover |

Khi OpenAPI đổi: cập nhật file này + 3 spec client trong **cùng PR spec**, không đổi code trong PR spec. Feature tối đa **2 vòng review** (quy tắc v1.5/v1.6); quá vòng → báo Chưởng Môn kèm finding.

---

## 9. Dependency & câu hỏi

### 9.1 Chặn E2E (đã kiểm 2026-11-16)

| Hạng mục | Bằng chứng | Ảnh hưởng | Điều kiện mở |
|---|---|---|---|
| `PUT/DELETE /v1/memorials/{id}/photo` chưa deploy | `PUT /v1/memorials/1/photo` → **404**; `DELETE` → **404**; `GET /v1/memorials` → 401 | không thể E2E ảnh; 404 trùng với "mục không tồn tại" nên **không được bật UI ảnh** | deploy image có Phase 6; smoke 401 (không phải 404) trên route ảnh; sau đó bật flag |
| Server reminder job (Phase 8–10) chưa có | `docs/specs/features/memorial/tasks.md` Phase 8–10 `[ ]`; Phase 10 chặn bởi notification | nhắc chỉ chạy local; web không có nhắc | Phase 10 + notification feature; xem D1 |
| Notification list/inbox chưa có | ADR-0001, spec notification chưa có | web không có nơi hiện nhắc giỗ | feature notification |

### 9.2 Câu hỏi cho Chưởng Môn (không chặn P4, cần chốt trước P5)

1. **Nhắc local tạm thời**: chấp nhận iOS/Android nhắc local, **web không nhắc** cho tới Phase 10? `Default: có` — đúng product §3.6 (web chỉ hiện trong notification list, mà list chưa có).
2. **Múi giờ tài khoản**: trong lúc chưa có `PATCH /v1/users/me` timezone, dùng mặc định Việt Nam và giờ địa phương thiết bị? `Default: có`.
3. **Deploy route ảnh**: ai/ngày nào? `Default: Luyện Khí deploy trước P5, Đạo Sư smoke rồi bật flag` — cần Chưởng Môn xác nhận lịch.

---

## 10. Definition of Done cho contract này

- [x] Đủ 7 route, đúng method/path/auth/request/response/error.
- [x] Kiểu ngày hai dạng + quy tắc quy đổi + vector.
- [x] Enum 10 giá trị + map 3 nền tảng.
- [x] Nhắc: payload tối thiểu, lựa chọn UI, giá trị cũ, không gửi 2 field sắp bỏ.
- [x] Ảnh: multipart, part name, 5 MiB, 3 định dạng, signed URL 15 phút.
- [x] Bảng lỗi 400/401/404/409/413/415/500 + map UI từng nền tảng.
- [x] Base URL dev + việc đổi config từng client.
- [x] Ghi rõ route ảnh chưa deploy + dependency E2E.
