//
//  Endpoint.swift
//  base_project
//
//  Created by ChjpCoj on 2/5/26.
//

import Foundation

/// Whether a response is wrapped in the backend's standard `ApiResponse` envelope
/// (`APIEnvelope<T>`) or decodes as `T` directly. See Docs/Specs/Networking/design.md
/// § "Envelope contract".
///
/// `nonisolated` — mọi type ở đây đều là dữ liệu thuần, được `NetworkServiceImpl` (một actor)
/// đọc từ isolation domain riêng của nó. Target bật `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
/// nên phải opt out tường minh.
nonisolated enum ResponseEnvelope: Equatable {
    /// Every business API endpoint — the response body is `APIEnvelope<T>` and `NetworkService`
    /// unwraps `data` before returning it to the caller.
    case standard
    /// Metadata endpoints (e.g. localization) that don't speak the envelope — decoded as `T`
    /// with no unwrapping.
    case bare
}

nonisolated protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? {get}
    var body: Data? { get }
    /// `.standard` (default) unless the endpoint is a metadata endpoint that doesn't speak the
    /// backend's `ApiResponse` envelope.
    var responseEnvelope: ResponseEnvelope { get }
    /// `true` (default) unless the endpoint must guarantee no `Authorization` header is ever
    /// attached, regardless of Keychain state (e.g. forgot-password, guest checkout).
    var requiresAuth: Bool { get }
}

nonisolated extension Endpoint {
    var headers: [String: String]? { nil }
    var queryParameters: [String: String]? { nil }
    var body: Data? { nil }
    var responseEnvelope: ResponseEnvelope { .standard }
    var requiresAuth: Bool { true }
    
    func buildURLRequest() throws -> URLRequest {
        var urlComponents = URLComponents(string: baseURL + path)
        
        // Add query parameters
        if let queryParameters = queryParameters {
            urlComponents?.queryItems = queryParameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Correlation ID — liên kết mobile log với backend log (xem Mobile Logging Architecture.md).
        // X-Session-ID luôn có; X-Correlation-ID chỉ có khi đang trong một flow active.
        CorrelationContext.shared.httpHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Custom headers
        headers?.forEach {key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}
