//
//  MockLogTransport.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Implementation tạm thời — chưa có server nội bộ thật (Risk / Metrics / Analytics).
/// In payload ra console thay vì gọi network. Khi backend sẵn sàng, thay bằng implementation
/// dùng `NetworkService` + `Endpoint` thật cho từng `LogDestination`, giữ nguyên protocol
/// `LogTransport` nên không cần sửa `SecurityAlertReporter` / `MetricsCollector` / `FlowTracker`.
public final class MockLogTransport: LogTransport {
    public static let shared = MockLogTransport()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    public init() {}

    public func send<T: Encodable>(destination: LogDestination, payload: T) {
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        #if DEBUG
        print("[MockLogTransport → \(destination.rawValue)] \(json)")
        #endif
    }
}
