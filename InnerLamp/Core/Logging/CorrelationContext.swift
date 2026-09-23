//
//  CorrelationContext.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// `nonisolated` — `Endpoint.buildURLRequest()` là nonisolated (được `NetworkServiceImpl` gọi từ
/// isolation domain riêng của actor đó), nên `shared` và `httpHeaders` không được ràng buộc vào main
/// actor. Mọi state mutable đều đã được bảo vệ bằng `lock`, do đó `@unchecked Sendable`.
nonisolated public final class CorrelationContext: @unchecked Sendable {
    public static let shared = CorrelationContext()
    
    private let lock = NSLock()
    private var _sessionId: String
    private var _correlationId: String?
    
    public init() {
        self._sessionId = UUID().uuidString
        self._correlationId = nil
    }
    
    public var currentSessionId: String {
        lock.lock()
        defer { lock.unlock() }
        return _sessionId
    }
    
    public var currentCorrelationId: String? {
        lock.lock()
        defer { lock.unlock() }
        return _correlationId
    }
    
    public func startNewSession() -> String {
        lock.lock()
        defer { lock.unlock() }
        _sessionId = UUID().uuidString
        return _sessionId
    }
    
    public func setCorrelationId(_ correlationId: String?) {
        lock.lock()
        defer { lock.unlock() }
        _correlationId = correlationId
    }
    
    public func generateCorrelationId() -> String {
        let newId = UUID().uuidString
        lock.lock()
        defer { lock.unlock() }
        _correlationId = newId
        return newId
    }
    
    public func clearCorrelationId() {
        lock.lock()
        defer { lock.unlock() }
        _correlationId = nil
    }
    
    public var httpHeaders: [String: String] {
        lock.lock()
        defer { lock.unlock() }
        var headers: [String: String] = [
            "X-Session-ID": _sessionId
        ]
        if let correlationId = _correlationId {
            headers["X-Correlation-ID"] = correlationId
        }
        return headers
    }
}
