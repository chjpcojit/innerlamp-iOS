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
/// TODO: Thay toàn bộ URL mock bên dưới bằng URL thật trước khi release. Hiện backend chưa sẵn
/// sàng nên cả ba môi trường đều trỏ tới host mock — cùng tình trạng với
/// `LocalizationConfig.serverBaseURL`.
enum APIConfig {

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
            return "https://mock-api-dev.internal.innerlamp.app"
        case .staging:
            return "https://mock-api-staging.internal.innerlamp.app"
        case .production:
            return "https://mock-api.internal.innerlamp.app"
        }
    }
}
