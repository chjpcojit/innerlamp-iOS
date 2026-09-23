# Core/Logging

Hệ thống logging/metrics cho InnerLamp. Implement đầy đủ theo spec [`Mobile Logging Architecture.md`](../../Docs/Specs/Mobile%20Logging%20Architecture.md) — đọc file đó trước nếu cần hiểu **tại sao** kiến trúc tách thành 4 nhóm độc lập.

## 4 nhóm, 4 mục đích, 4 đích đến — không thay thế cho nhau

| Nhóm | Trả lời câu hỏi | Đích đến | Trigger đẩy | Entry point |
|---|---|---|---|---|
| 1 — Crash Reports | App crash ở đâu, tại sao? | Sentry (external, đã tích hợp SPM `sentry-cocoa`) | Lần mở app tiếp theo | `LoggingService` / `SentryLoggingService` |
| 2 — Security Alerts | Có đang bị tấn công không? | Risk server nội bộ (**mock**) | Ngay lập tức, không buffer | `SecurityAlertReporting` / `SecurityAlertReporter` |
| 3 — Metrics | App có chạy khỏe không? | Metrics server nội bộ (**mock**) | Batch: 50 record / 5 phút / vào background / có Wi-Fi | `MetricsCollecting` / `MetricsCollector` |
| 4 — Flow Tracking | User bỏ ở bước nào, vì sao? | Analytics server nội bộ (**mock**) | Khi flow kết thúc, gửi 1 payload | `FlowTracking` / `FlowTracker` |

**Mock**: chưa có backend Risk/Metrics/Analytics thật. `MockLogTransport` in payload ra console (`#if DEBUG`) thay vì gọi network. Khi có endpoint thật, chỉ cần viết implementation mới cho `LogTransport` (dùng `NetworkService` + `Endpoint` sẵn có) — không phải sửa `SecurityAlertReporter`/`MetricsCollector`/`FlowTracker`.

## File map

```
LoggingService.swift          # Protocol Nhóm 1 — business code chỉ biết protocol này, không biết Sentry
SentryLoggingService.swift    # Implementation Nhóm 1 — nơi duy nhất import Sentry
LogLevel.swift                # debug/info/warning/error/fatal, Comparable

SecurityEvent.swift           # Vocabulary cố định: jailbreak, debugger, frida, cert pinning, emulator
SecurityAlertReporting.swift  # Protocol Nhóm 2
SecurityAlertReporter.swift   # Implementation Nhóm 2 — gửi thẳng, không qua buffer

MetricsCollecting.swift       # Protocol + model Nhóm 3 (MetricRecord, MetricKind)
MetricsCollector.swift        # Implementation Nhóm 3 — buffer + NWPathMonitor + Timer

FlowModels.swift              # FlowType, FlowStep (open-ended), StepStatus, FlowOutcome, FlowPayload
FlowTracking.swift            # Protocol Nhóm 4
FlowTracker.swift             # Implementation Nhóm 4 — tích lũy step trong memory

LogTransport.swift            # Interface đẩy payload lên server nội bộ (dùng chung Nhóm 2/3/4)
MockLogTransport.swift        # Implementation mock — print JSON ra console

BreadcrumbCategory.swift      # Category cho breadcrumb Nhóm 1 (open-ended, feature tự khai thêm)
UserContext.swift             # sessionId/deviceTier/appVersion — không chứa PII
CorrelationContext.swift      # Sinh & giữ sessionId/correlationId dùng chung toàn app
DeviceTier.swift              # DeviceTier/AppVersionProvider/OSVersionProvider
LoggingConfig.swift           # DSN, base URL server (mock), environment
PIIMasker.swift                # Bắt buộc — chặn/mask PII trước khi bất kỳ log nào rời app
```

## Cách dùng

Không import `Sentry`, `SecurityAlertReporter`, `MetricsCollector`, `FlowTracker` trực tiếp trong feature code — luôn lấy qua `DIContainer` bằng protocol tương ứng (`LoggingService`, `SecurityAlertReporting`, `MetricsCollecting`, `FlowTracking`).

### Nhóm 1 — Crash breadcrumb & log

```swift
let logging: LoggingService = container.loggingService

logging.breadcrumb(category: .transfer, message: "User initiated transfer", data: [
    "amount_tier": PIIMasker.categorizeAmount(amount),   // không log số tiền thật
    "has_recipient": true
])

logging.log(level: .warning, message: "Non-fatal API timeout", metadata: ["endpoint": "/v1/notifications"])
```

PII masking đã được `SentryLoggingService` tự áp dụng cho mọi `message`/`data`/`metadata` — không cần tự gọi `PIIMasker` trước khi log, nhưng vẫn phải tự chọn log **categorical value** (tier, boolean) thay vì raw value như số tài khoản/số tiền, vì masker không đoán được ý nghĩa nghiệp vụ của một con số.

Set/clear user context khi login/logout:

```swift
logging.setUserContext(UserContext(sessionId: ..., deviceTier: DeviceTier.current.rawValue, appVersion: AppVersionProvider.current))
logging.clearUserContext()
```

### Nhóm 2 — Security alert

```swift
let reporter: SecurityAlertReporting = container.securityAlertReporter
reporter.send(event: .jailbreakDetected)
reporter.send(event: .certificatePinningFailed, metadata: ["host": "api.innerlamp.app"])
```

Gọi ngay tại điểm phát hiện (jailbreak check, debugger check, cert pinning validator...) — không delay, không gom batch.

### Nhóm 3 — Metrics

```swift
let metrics: MetricsCollecting = container.metricsCollector

metrics.record("screen.load_time", value: 1240, unit: "ms", tags: ["screen": "meditation_player"])
metrics.count("feature.opened", tags: ["feature": "scheduled_bell", "entry_point": "home_shortcut"])
metrics.record("session.started", tags: ["os_version": OSVersionProvider.current, "device_tier": DeviceTier.current.rawValue])
```

Không cần tự flush — buffer tự đẩy theo trigger. Gọi `metrics.flush()` chỉ khi thật sự cần ép đẩy ngay (ví dụ debug).

### Nhóm 4 — Flow Tracking

Mỗi feature tự khai `FlowType`/`FlowStep` riêng (open-ended, giống `BreadcrumbCategory`):

```swift
extension FlowType { static let onboarding: FlowType = "onboarding" }
extension FlowStep {
    static let selectIntents: FlowStep = "select_intents"
    static let selectBells: FlowStep = "select_bells"
}
```

```swift
let flow: FlowTracking = container.flowTracker

flow.startFlow(.onboarding)
flow.enterStep(.selectIntents)
flow.completeStep(.selectIntents, metadata: ["count": "\(selected.count)"])
...
flow.endFlow(outcome: .success)   // hoặc .failed / .abandoned / .timeout
```

`startFlow` tự sinh `correlationId` mới và giao cho `CorrelationContext` — mọi request qua `Endpoint` trong lúc flow đang chạy tự động mang header `X-Correlation-ID`. `endFlow` gửi 1 payload duy nhất rồi clear correlationId. Nếu `startFlow` gọi trong lúc flow cũ chưa `endFlow`, flow cũ tự đóng với outcome `.abandoned`.

## PII Masking — không tuỳ chọn

Field bị chặn hoàn toàn ở mọi nhóm: `pin`, `password`, `cvv`, `token`, `access_token`, `refresh_token`, `card_number`, `account_number`, `clabe`, `curp`, `rfc`, `email`, `phone` — xem `PIIMasker.blockedKeys`. Test suite bắt buộc: `InnerLampTests/PIIMaskerTests.swift`. Thêm format PII mới → viết test trước, rồi mới thêm regex.

## Correlation ID

`CorrelationContext.shared` là nơi duy nhất giữ `sessionId`/`correlationId`. `Endpoint.buildURLRequest()` tự inject `X-Session-ID` (luôn có) và `X-Correlation-ID` (chỉ có khi đang trong flow active) vào mọi request — không cần set thủ công ở feature code.

## Bootstrap

`AppDelegate.bootstrapLogging()` gọi `SentryLoggingService.shared.start()`, set user context, và log `session.started` lúc app launch. DSN/base URL mock nằm ở `LoggingConfig` — thay bằng giá trị production trước khi release (xem `TODO` trong file).
