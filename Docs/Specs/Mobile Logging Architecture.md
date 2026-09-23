
---

# Mobile Logging Architecture — Bankaool iOS/Android

## Overview

Tài liệu này định nghĩa kiến trúc thu thập và xử lý log/metrics cho ứng dụng mobile Bankaool. Hệ thống được chia thành **4 nhóm độc lập**, mỗi nhóm phục vụ một mục đích khác nhau, dùng infrastructure khác nhau, và không thay thế cho nhau.

```
Nhóm 1 — Crash Reports   →  Sentry / Crashlytics
Nhóm 2 — Security Alerts →  Internal Risk Server (real-time)
Nhóm 3 — Metrics         →  Performance, feature adoption, app health
Nhóm 4 — Flow Tracking   →  Hành trình nghiệp vụ nhiều bước
```

---

## Nhóm 1 — Crash Reports

### Mục đích

Ghi nhận và phân tích các trường hợp ứng dụng bị crash. Phục vụ engineering team trong việc debug và fix lỗi.

### Cơ chế hoạt động

Khi app crash, iOS terminate process ngay lập tức — không còn cơ hội chạy bất kỳ dòng code nào. Sentry/Crashlytics đăng ký sẵn **Mach exception handler** và **Unix signal handler** ở tầng rất thấp (gần kernel). Khi crash xảy ra, OS gọi các handler này trước khi terminate. SDK ghi stack trace xuống file trong Sandbox. Lần mở app tiếp theo, SDK đọc file đó và upload lên server.

### Breadcrumb — Context cho crash report

Mỗi crash report cần đi kèm chuỗi hành động của user trước khi crash xảy ra. Sentry có built-in breadcrumb system, giữ tối đa 50 actions gần nhất trên RAM. Khi crash xảy ra, buffer này tự động được đính kèm vào crash report.

**Không cần tự implement circular buffer** — SDK quản lý hoàn toàn.

**Những gì SDK tự động capture:**

- HTTP request/response
- UI lifecycle (ViewDidAppear, ViewDidDisappear)
- Console logs

**Những gì phải tự gọi** (business logic SDK không biết):

```swift
// Gọi tại các điểm quan trọng trong business flow
SentrySDK.addBreadcrumb({
    let crumb = Breadcrumb()
    crumb.category = "transfer"
    crumb.message  = "User initiated transfer"
    crumb.data     = [
        "amount_tier": "tier_3_medium",  // Không log số tiền thật
        "has_recipient": true
    ]
    crumb.level = .info
    return crumb
}())
```

### Setup

```swift
SentrySDK.start { options in
    options.dsn                  = Config.sentryDSN
    options.environment          = "production"
    options.maxBreadcrumbs       = 50
    options.enableAutoBreadcrumbTracking = true

    // Bắt buộc tắt với banking app —
    // màn hình tại thời điểm crash có thể đang hiển thị số tài khoản
    options.attachScreenshot     = false
    options.attachViewHierarchy  = false
}
```

### Lưu ý bảo mật

Khi thêm `data` vào breadcrumb, không được log số tài khoản, số tiền thật, token. Log dạng categorical thay vì raw value:

```swift
// ❌ Sai
crumb.data = ["amount": 5_000_000, "clabe": "002010077777777771"]

// ✅ Đúng
crumb.data = ["amount_tier": "tier_3_medium", "has_destination": true]
```

### Destination

Sentry server (external). **Crash report không chứa PII — đây là điều kiện bắt buộc** vì Sentry là third-party service nằm ngoài perimeter của ngân hàng.

---

## Nhóm 2 — Security Alerts

### Mục đích

Phát hiện và báo cáo các hành vi tấn công trong thời gian thực. Phục vụ security team và hệ thống fraud detection.

### Các tín hiệu cần phát hiện

- Thiết bị bị jailbreak/root
- Debugger đang attach vào process
- Frida hoặc công cụ hook khác đang chạy
- Môi trường giả lập (emulator) không hợp lệ
- Chứng chỉ SSL bị thay thế (certificate pinning violation)

### Tại sao phải real-time, không được batch

Khi kẻ tấn công đã jailbreak thiết bị, họ có quyền truy cập file system của app. Nếu alert được lưu local để đợi batch push, họ có thể xóa file đó và kill app trước khi kịp gửi đi. Bằng chứng biến mất.

Ngược lại, nếu push lên server ngay khi phát hiện, dù họ kill app ngay sau đó, server đã nhận được alert rồi.

### Destination

**Internal Risk Event Collector** — server nội bộ của ngân hàng. **Không được gửi security alert lên Sentry hay bất kỳ third-party service nào.**

```swift
// SecurityAlertReporter.swift
public final class SecurityAlertReporter {

    public static func send(event: SecurityEvent, metadata: [String: String] = [:]) {
        // Gọi thẳng, không qua buffer, không qua queue
        RiskEventCollector.shared.sendImmediate(
            event: event.rawValue,
            metadata: metadata,
            timestamp: Date().timeIntervalSince1970
        )
    }
}

public enum SecurityEvent: String {
    case jailbreakDetected        = "jailbreak_detected"
    case debuggerAttached         = "debugger_attached"
    case fridaDetected            = "frida_detected"
    case certificatePinningFailed = "cert_pinning_failed"
    case emulatorDetected         = "emulator_detected"
}
```

---

## Nhóm 3 — Metrics

### Mục đích

Đo lường sức khỏe của ứng dụng và hành vi sử dụng ở cấp độ tổng thể. Phục vụ product team và engineering team.

> **Lưu ý quan trọng:** Nhóm này thu thập **Metrics** (số đo theo thời gian), không phải Logs (event narrative). Sự khác biệt cốt lõi:
> 
> - **Logs** → "Điều gì đó đã xảy ra" — có context, có message
> - **Metrics** → "Một con số tại một thời điểm" — value, unit, tags

### Những gì cần đo

**Performance metrics** — engineering team dùng để phát hiện regression:

```swift
// Thời gian load màn hình
MetricsCollector.record("screen.load_time", value: 1240, unit: "ms", tags: [
    "screen": "transfer_home",
    "device_tier": "mid"
])

// Thời gian response của API
MetricsCollector.record("api.response_time", value: 890, unit: "ms", tags: [
    "endpoint": "/v1/accounts",   // Path thôi, không có query params hay user data
    "status_code": "200"
])

// Cold start time
MetricsCollector.record("app.cold_start_time", value: 2100, unit: "ms", tags: [
    "device_tier": "low"
])
```

**Feature adoption** — product team dùng để biết feature nào được dùng nhiều:

```swift
MetricsCollector.count("feature.opened", tags: [
    "feature": "scheduled_transfer",
    "entry_point": "home_shortcut"
])
```

**App health** — lỗi không đủ nghiêm trọng để crash nhưng cần theo dõi:

```swift
MetricsCollector.count("api.non_fatal_error", tags: [
    "endpoint": "/v1/notifications",
    "status_code": "503"
])
```

**Session context** — log một lần mỗi session:

```swift
MetricsCollector.record("session.started", tags: [
    "os_version": "17.4",
    "device_tier": "mid",
    "network_type": "wifi",
    "app_version": "2.4.1"
])
```

### Những gì không thuộc nhóm này

```
FlowTracker     →  Chuyển tiền thất bại ở bước face verify
Sentry          →  App crash khi đang ở màn hình transfer
Security Alert  →  Phát hiện Frida đang hook vào process

Nhóm 3          →  Màn hình transfer load mất 3 giây         ✓
                    API balance call timeout                   ✓
                    User mở tab "Lịch sử giao dịch"           ✓
```

### Cơ chế đẩy

Batch push — tích lũy trong local buffer, đẩy lên server khi đạt một trong các điều kiện:

|Trigger|Điều kiện|
|---|---|
|Queue size|50 records|
|Time interval|Mỗi 5 phút|
|App background|`sceneDidEnterBackground`|
|Hardware|Chỉ đẩy khi Wi-Fi + không Low Power Mode|

### Destination

Metrics server nội bộ hoặc Prometheus/Datadog Metrics. Firebase Performance Monitoring là lựa chọn phù hợp vì tự động đo HTTP response time và screen render time mà không cần tự viết.

---

## Nhóm 4 — Flow Tracking

### Mục đích

Ghi nhận hành trình của user qua các bước trong một luồng nghiệp vụ có nhiều bước. Phục vụ product team trong việc phân tích drop-off và engineering team trong việc debug lỗi nghiệp vụ.

### Bài toán điển hình

User thực hiện chuyển tiền: mở tính năng → chọn tài khoản nguồn → chọn tài khoản đích → nhập số tiền → verify face → nhập OTP → xác nhận. Nếu thất bại ở bước face verify, cần biết user đã mất bao lâu, thử bao nhiêu lần, lý do thất bại là gì.

### Tại sao không dùng Nhóm 3 hay Sentry breadcrumb

- **Sentry breadcrumb** — không biết đâu là đầu, đâu là đuôi của một hành trình. Chỉ phục vụ crash context.
- **Nhóm 3 Metrics** — từng event lẻ, không có khái niệm "flow", không biết các bước liên quan đến nhau.
- **Flow Tracking** — biết rõ điểm bắt đầu và kết thúc, chờ flow đóng lại mới gửi một payload hoàn chỉnh có cấu trúc.

### Cơ chế hoạt động

Không stream từng event lên server. Tích lũy toàn bộ các bước trong memory, khi flow kết thúc — dù thành công hay thất bại — mới gửi **một payload duy nhất** lên server.

```
User mở Transfer → [tích lũy steps trong memory] → Flow kết thúc → Gửi 1 payload hoàn chỉnh
```

### Data model

```swift
public enum FlowType: String, Codable {
    case transfer       = "transfer"
    case billPayment    = "bill_payment"
    case cardActivation = "card_activation"
    case limitChange    = "limit_change"
}

public enum FlowStep: String, Codable {
    case openScreen        = "open_screen"
    case selectSource      = "select_source_account"
    case selectDestination = "select_destination"
    case enterAmount       = "enter_amount"
    case reviewSummary     = "review_summary"
    case faceVerification  = "face_verification"
    case otpVerification   = "otp_verification"
    case confirmation      = "confirmation"
}

public enum StepStatus: String, Codable {
    case entered   = "entered"    // User vào bước này
    case completed = "completed"  // Hoàn thành, sang bước tiếp
    case failed    = "failed"     // Thất bại tại bước này
    case abandoned = "abandoned"  // User tự thoát ra
}

public enum FlowOutcome: String, Codable {
    case success   = "success"
    case failed    = "failed"
    case abandoned = "abandoned"  // User tự bỏ giữa chừng
    case timeout   = "timeout"
}
```

### FlowTracker API

```swift
// Bắt đầu một flow mới
FlowTracker.shared.startFlow(.transfer)

// Ghi nhận user vào một bước
FlowTracker.shared.enterStep(.faceVerification)

// Bước thành công
FlowTracker.shared.completeStep(.faceVerification)

// Bước thất bại — ghi rõ lý do
FlowTracker.shared.failStep(
    .faceVerification,
    reason: "liveness_check_failed",
    metadata: ["attempt": "3"]
)

// Kết thúc flow
FlowTracker.shared.endFlow(outcome: .failed)
```

### Cách gọi trong feature code

```swift
// TransferCoordinator.swift
final class TransferCoordinator {

    func start() {
        FlowTracker.shared.startFlow(.transfer)
        showSelectSourceScreen()
    }

    func userSelectedSource(_ accountId: String) {
        FlowTracker.shared.completeStep(.selectSource, metadata: [
            "account_type": "checking"  // Type thôi, không log accountId
        ])
        showSelectDestinationScreen()
    }

    func userEnteredAmount(_ amount: Decimal) {
        FlowTracker.shared.completeStep(.enterAmount, metadata: [
            "amount_tier": PIIMasker.categorizeAmount(amount)
        ])
        showFaceVerification()
    }

    func faceVerificationFailed(reason: FaceVerificationError) {
        FlowTracker.shared.failStep(
            .faceVerification,
            reason: reason.loggableDescription,
            metadata: ["attempt": "\(reason.attemptCount)"]
        )
        if reason.isFinal {
            FlowTracker.shared.endFlow(outcome: .failed)
        }
    }

    func userAbandonedFlow() {
        FlowTracker.shared.endFlow(outcome: .abandoned)
    }

    func transferCompleted() {
        FlowTracker.shared.completeStep(.confirmation)
        FlowTracker.shared.endFlow(outcome: .success)
    }
}
```

### Payload gửi lên server

```json
{
  "flow_id": "550e8400-e29b-41d4-a716",
  "flow_type": "transfer",
  "session_id": "abc-123",
  "outcome": "failed",
  "total_duration_ms": 187000,
  "steps": [
    { "step": "open_screen",           "status": "completed", "duration_ms": 1200  },
    { "step": "select_source_account", "status": "completed", "duration_ms": 4500  },
    { "step": "select_destination",    "status": "completed", "duration_ms": 12000 },
    { "step": "enter_amount",          "status": "completed", "duration_ms": 8000,
      "metadata": { "amount_tier": "tier_3_medium" } },
    { "step": "face_verification",     "status": "failed",    "duration_ms": 45000,
      "failure_reason": "liveness_check_failed",
      "metadata": { "attempt": "3" } }
  ]
}
```

### Destination

Internal Analytics server. Dữ liệu này không ra ngoài perimeter ngân hàng.

---

## Correlation ID — Liên kết mobile log với backend log

### Vấn đề

Không có Correlation ID, mobile log và backend log là hai hòn đảo riêng biệt. Khi một giao dịch fail, FlowTracker ghi nhận `face_verification failed` ở phía mobile, nhưng backend cũng có log riêng của nó. Không có cách nào liên kết hai bên ngoài việc dò bằng timestamp — mất rất nhiều thời gian khi debug incident thực tế.

### Cơ chế

Một `correlationId` được sinh ra từ mobile ngay khi bắt đầu một flow, truyền theo mọi HTTP request dưới dạng header, và backend ghi ID này vào log của nó. Khi có sự cố, query một ID duy nhất sẽ thấy toàn bộ hành trình từ mobile xuống backend.

```
Mobile FlowPayload  ─┐
                     ├── correlationId: "550e8400-e29b-41d4-a716"
Backend logs        ─┘
```

### Implementation

**Sinh ID và gắn vào flow:**

```swift
// FlowTracker.swift — sinh correlationId khi startFlow
public func startFlow(_ type: FlowType) {
    queue.async {
        if self.activeFlow != nil {
            self.endCurrentFlow(outcome: .abandoned)
        }
        self.activeFlow = ActiveFlow(type: type)
        // correlationId được sinh tự động trong ActiveFlow.init
    }
}

// ActiveFlow.swift
private final class ActiveFlow {
    let correlationId = UUID().uuidString  // Sinh một lần, dùng xuyên suốt flow
    let flowId        = UUID().uuidString
    // ...
}
```

**Truyền vào mọi HTTP request trong flow:**

```swift
// NetworkInterceptor.swift — interceptor tự động inject header
final class CorrelationIDInterceptor: RequestInterceptor {

    func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void) {

        var request = urlRequest

        // Lấy correlationId từ flow đang active nếu có
        if let correlationId = FlowTracker.shared.currentCorrelationId {
            request.setValue(correlationId, forHTTPHeaderField: "X-Correlation-ID")
        }

        // sessionId luôn có, kể cả ngoài flow
        request.setValue(
            SessionManager.shared.currentSessionId,
            forHTTPHeaderField: "X-Session-ID"
        )

        completion(.success(request))
    }
}
```

**Gắn vào FlowPayload khi gửi lên server:**

```swift
// FlowPayload bổ sung field correlationId
public struct FlowPayload: Codable {
    let flowId:        String
    let correlationId: String   // Backend dùng field này để join log
    let sessionId:     String
    // ... các field khác
}
```

**Payload mẫu sau khi bổ sung:**

```json
{
  "flow_id":        "7f3a9c1e-4b2d-48f0-a112",
  "correlation_id": "550e8400-e29b-41d4-a716",
  "session_id":     "abc-123",
  "flow_type":      "transfer",
  "outcome":        "failed",
  "steps": [...]
}
```

### Quy tắc sử dụng

|Header|Phạm vi|Mục đích|
|---|---|---|
|`X-Correlation-ID`|Trong một flow cụ thể|Join mobile log ↔ backend log cho một giao dịch|
|`X-Session-ID`|Toàn bộ session đăng nhập|Trace mọi request trong một phiên làm việc|

`X-Correlation-ID` chỉ tồn tại khi đang có flow active. Các request ngoài flow (load danh sách tài khoản, notification) chỉ mang `X-Session-ID`.

### Yêu cầu phía backend

Backend phải ghi `X-Correlation-ID` vào structured log của mọi service nhận request. Đây là điều kiện để Correlation ID có tác dụng — nếu chỉ mobile làm mà backend không ghi thì vô nghĩa.

---

## PII Masking — Quy tắc áp dụng cho tất cả các nhóm

### Các trường bị chặn hoàn toàn

Những field sau **không được xuất hiện trong bất kỳ log nào**, dù ở nhóm nào:

|Field|Lý do|
|---|---|
|`pin`, `password`, `cvv`|Credential|
|`token`, `access_token`, `refresh_token`|Auth token|
|`card_number`, `account_number`, `clabe`|Số tài khoản/thẻ|
|`curp`, `rfc`|Định danh cá nhân tại México|
|`email`, `phone`|PII|

### Xử lý số tiền

Không log số tiền thật — chuyển sang tier:

```swift
public static func categorizeAmount(_ amount: Decimal) -> String {
    switch amount {
    case ..<500:             return "tier_1_micro"
    case 500..<5_000:        return "tier_2_low"
    case 5_000..<50_000:     return "tier_3_medium"
    default:                 return "tier_4_high"
    }
}
```

### Regex mask cho free-text fields

```swift
// Áp dụng trước khi ghi bất kỳ string nào vào log
PIIMasker.maskMessage("Transfer to CLABE 002010077777777771 amount $5,000")
// Output: "Transfer to [CLABE:****] amount $[AMOUNT:****]"
```

### Test Suite — Bắt buộc, không phải tuỳ chọn

PIIMasker là thành phần có rủi ro compliance cao nhất trong toàn bộ kiến trúc. Nếu một regex sai hoặc developer quên gọi masker trước khi log, PII đi thẳng lên Sentry — third-party server ngoài perimeter ngân hàng.

**Test phải cover toàn bộ loại PII được định nghĩa:**

```swift
// PIIMaskerTests.swift
import XCTest
@testable import BankaoolCore

final class PIIMaskerTests: XCTestCase {

    // MARK: - CLABE (18 chữ số — định dạng México)

    func test_mask_clabe_standalone() {
        let input  = "Transfer to 002010077777777771 completed"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("002010077777777771"))
        XCTAssertTrue(output.contains("[CLABE:****]"))
    }

    func test_mask_clabe_embedded_in_sentence() {
        let input  = "Recipient CLABE is 002010077777777771, please confirm"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("002010077777777771"))
    }

    // MARK: - Card Number

    func test_mask_card_with_spaces() {
        let input  = "Card 4111 1111 1111 1111 declined"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111"))
        XCTAssertTrue(output.contains("[CARD:****]"))
    }

    func test_mask_card_with_dashes() {
        let input  = "Card 4111-1111-1111-1111 declined"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111-1111"))
    }

    func test_mask_card_no_separator() {
        let input  = "Card 4111111111111111 approved"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("4111111111111111"))
    }

    // MARK: - Token

    func test_mask_bearer_token() {
        let input  = "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("eyJhbGci"))
        XCTAssertTrue(output.contains("[TOKEN:****]"))
    }

    func test_mask_token_in_json_string() {
        let input  = #"{"access_token": "eyJhbGciOiJSUzI1NiJ9.payload"}"#
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("eyJhbGci"))
    }

    // MARK: - Phone (México)

    func test_mask_mexican_phone() {
        let input  = "User phone: +52 55 1234 5678"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("1234 5678"))
        XCTAssertTrue(output.contains("[PHONE:****]"))
    }

    // MARK: - Email

    func test_mask_email() {
        let input  = "Confirmation sent to usuario@gmail.com"
        let output = PIIMasker.maskMessage(input)
        XCTAssertFalse(output.contains("usuario@gmail.com"))
        XCTAssertTrue(output.contains("[EMAIL:****]"))
    }

    // MARK: - Metadata (blocked keys)

    func test_blocked_key_pin_is_dropped() {
        let input  = ["pin": "1234", "screen": "transfer"]
        let output = PIIMasker.maskMetadata(input)
        XCTAssertNil(output["pin"])             // Bị drop hoàn toàn
        XCTAssertEqual(output["screen"] as? String, "transfer")  // Key an toàn giữ nguyên
    }

    func test_blocked_key_token_is_dropped() {
        let input  = ["access_token": "eyJhbGci...", "attempt": "1"]
        let output = PIIMasker.maskMetadata(input)
        XCTAssertNil(output["access_token"])
        XCTAssertNotNil(output["attempt"])
    }

    func test_nested_metadata_is_recursively_masked() {
        let input: [String: Any] = [
            "context": ["clabe": "002010077777777771", "type": "checking"]
        ]
        let output = PIIMasker.maskMetadata(input)
        let nested = output["context"] as? [String: Any]
        XCTAssertNil(nested?["clabe"])
        XCTAssertEqual(nested?["type"] as? String, "checking")
    }

    // MARK: - Safe content không bị ảnh hưởng

    func test_safe_string_passes_through_unchanged() {
        let input  = "User tapped confirm button on transfer screen"
        let output = PIIMasker.maskMessage(input)
        XCTAssertEqual(input, output)
    }

    func test_amount_tier_categorization() {
        XCTAssertEqual(PIIMasker.categorizeAmount(100),    "tier_1_micro")
        XCTAssertEqual(PIIMasker.categorizeAmount(1_000),  "tier_2_low")
        XCTAssertEqual(PIIMasker.categorizeAmount(10_000), "tier_3_medium")
        XCTAssertEqual(PIIMasker.categorizeAmount(100_000),"tier_4_high")
    }
}
```

### CI Gate — Bắt buộc

Test suite này phải là CI gate: nếu bất kỳ test nào fail thì build fail, không được merge vào main branch. Không có ngoại lệ.

```yaml
# .github/workflows/ci.yml
- name: Run PIIMasker Tests
  run: xcodebuild test
       -scheme BankaoolCore
       -testPlan PIIMaskerTests
       -resultBundlePath TestResults/PIIMasker.xcresult
```

**Khi thêm format PII mới** (ví dụ format số điện thoại mới của Mexico), phải thêm test case trước khi thêm regex. Test-first ở đây không phải ceremony — đây là cơ chế duy nhất đảm bảo không có format nào bị bỏ sót theo thời gian.

---

## Tổng quan — Mỗi nhóm trả lời câu hỏi gì

|Nhóm|Câu hỏi|Destination|Trigger đẩy|
|---|---|---|---|
|1 — Crash Reports|App bị crash ở đâu, tại sao?|Sentry (external)|Lần mở app tiếp theo|
|2 — Security Alerts|Có đang bị tấn công không?|Risk Server (internal)|Ngay lập tức|
|3 — Metrics|App có đang chạy khỏe không?|Metrics Server (internal)|Batch theo điều kiện|
|4 — Flow Tracking|User bỏ ở bước nào, lý do gì?|Analytics Server (internal)|Khi flow kết thúc|

**Cross-cutting concerns áp dụng cho tất cả các nhóm:**

|Concern|Mục đích|Bắt buộc|
|---|---|---|
|Correlation ID|Liên kết mobile log ↔ backend log qua `X-Correlation-ID` header|Có|
|PII Masking|Chặn và mask dữ liệu nhạy cảm trước khi ghi vào bất kỳ log nào|Có|
|PIIMasker Test Suite|CI gate đảm bảo không có PII format nào bị bỏ sót|Có|

---

## Logging Wrapper — Thiết kế interface chung

Business code không được phụ thuộc trực tiếp vào Sentry, Crashlytics hay bất kỳ SDK cụ thể nào. Mọi tương tác phải qua `LoggingService` protocol.

```swift
public protocol LoggingService {
    func breadcrumb(category: BreadcrumbCategory, message: String, data: [String: Any]?)
    func log(level: LogLevel, message: String, metadata: [String: Any]?)
    func setUserContext(_ context: UserContext)
    func clearUserContext()
}

// UserContext chỉ chứa thông tin không nhạy cảm
public struct UserContext {
    let sessionId: String    // UUID random mỗi session, không phải user ID thật
    let deviceTier: String   // "high" / "mid" / "low"
    let appVersion: String
}
```

Concrete implementation (`SentryLoggingService`) ẩn hoàn toàn sau protocol. Khi cần đổi vendor hoặc thêm backend thứ hai, chỉ sửa một chỗ duy nhất.