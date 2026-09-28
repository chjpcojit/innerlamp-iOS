//
//  LocalizationEndpoint.swift
//  InnerLamp
//

import Foundation

/// Endpoint nhẹ — chỉ trả version hiện tại của file ngôn ngữ trên server.
/// Gọi trước để quyết định có cần tải `LocalizationContentEndpoint` hay không.
struct LocalizationVersionEndpoint: Endpoint {
    let language: String

    var baseURL: String { LocalizationConfig.serverBaseURL }
    var path: String { "/localization/\(language)/version" }
    var method: HTTPMethod { .get }
    /// Metadata endpoint — does not speak the business `ApiResponse` envelope.
    var responseEnvelope: ResponseEnvelope { .bare }
}

/// Trả toàn bộ file ngôn ngữ (version + strings) — chỉ gọi khi version server
/// khác version đang dùng.
struct LocalizationContentEndpoint: Endpoint {
    let language: String

    var baseURL: String { LocalizationConfig.serverBaseURL }
    var path: String { "/localization/\(language)" }
    var method: HTTPMethod { .get }
    /// Metadata endpoint — does not speak the business `ApiResponse` envelope.
    var responseEnvelope: ResponseEnvelope { .bare }
}

nonisolated struct LocalizationVersionResponse: Decodable {
    let version: String
}
