//
//  APIConfig.swift
//  InnerLamp
//

import Foundation

/// Cấu hình host cho toàn bộ API nghiệp vụ (auth, signup, home, ...) — cùng convention với
/// `LocalizationConfig` và `LoggingConfig`.
///
/// Nằm ở `Core/Networking/` (không phải `Data/`) vì `Endpoint` — protocol của Core — khai báo
/// `var baseURL: String { get }`. Nếu config đặt ở `Data/`, Core sẽ phải import Data và đảo chiều
/// dependency. Xem `references/data_layer_architecture.md` §6.
///
/// TODO: Thay toàn bộ URL mock bên dưới bằng URL thật trước khi release. `.staging`/`.production`
/// vẫn trỏ host mock vì backend chưa sẵn sàng cho hai môi trường đó — cùng tình trạng với
/// `LocalizationConfig.serverBaseURL`. `.dev` hiện trỏ tới backend local của BE-Developer
/// (`192.168.1.113:8080`, xác nhận 2026-09-28) để test Login/SignUp thật trên thiết bị vật lý —
/// đây là IP LAN tạm thời của máy BE-Developer, cần cập nhật lại nếu đổi máy/mạng. Đi kèm ngoại lệ
/// ATS ở `Info.plist` cho phép HTTP thường (server dev chưa có TLS).
nonisolated enum APIConfig {

    /// Môi trường backend đang trỏ tới.
    ///
    /// `var` (không phải `let`) để build scheme / test có thể chuyển môi trường mà không phải sửa
    /// code. Mặc định `.dev` — không bao giờ mặc định `.production`.
    enum Environment {
        case dev
        case staging
        case production
    }

    /// Môi trường hiện tại. `AppDelegate` có thể gán lại khi khởi động dựa trên build
    /// configuration; mặc định `.dev` để một build quên cấu hình không vô tình gọi production.
    static var current: Environment = .dev

    static var serverBaseURL: String {
        switch current {
        case .dev:
            return "http://192.168.1.113:8080"
        case .staging:
            return "https://mock-api-staging.internal.innerlamp.app"
        case .production:
            return "https://mock-api.internal.innerlamp.app"
        }
    }

    /// gRPC host/port per `Environment`, extending this same config source rather than adding a
    /// parallel one — see Docs/Specs/GRPC/requirements.md FR-009.
    ///
    /// TODO: Placeholder values — the backend team hasn't confirmed real gRPC host(s)/port(s) for
    /// any environment yet (`Docs/Specs/GRPC/requirements.md` Pending). Replace before any real
    /// gRPC service is consumed; do not treat these as production-ready.
    static var grpcHost: String {
        switch current {
        case .dev:
            return "mock-grpc-dev.internal.innerlamp.app"
        case .staging:
            return "mock-grpc-staging.internal.innerlamp.app"
        case .production:
            return "mock-grpc.internal.innerlamp.app"
        }
    }

    static var grpcPort: Int { 443 }
}
