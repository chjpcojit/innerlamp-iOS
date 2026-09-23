//
//  NetworkLogger.swift
//  InnerLamp
//
//  Turns one completed request into one `LoggingService` record — method, path, status code,
//  duration — routing anything credential-shaped through `PIIMasker` first. See
//  Docs/Specs/Networking/design.md § "Request lifecycle" Step 6.
//

import Foundation

/// `nonisolated` — gọi từ `NetworkServiceImpl` (một actor), và `log` là đồng bộ nên không thể
/// hop sang main actor. Xem thêm ghi chú ở `LoggingService`.
nonisolated protocol NetworkLogging {
    /// Records exactly one completed request. `failureClassification` is the `NetworkError`
    /// case name (or the envelope's `error.code`) — never the raw response body. `nil` means the
    /// request succeeded.
    func log(
        method: String,
        path: String,
        statusCode: Int?,
        duration: TimeInterval,
        failureClassification: String?
    )
}

nonisolated final class NetworkLogger: NetworkLogging {
    private let loggingService: LoggingService

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
    }

    func log(
        method: String,
        path: String,
        statusCode: Int?,
        duration: TimeInterval,
        failureClassification: String?
    ) {
        var metadata: [String: Any] = [
            "method": method,
            "path": path,
            "duration_ms": Int(duration * 1000)
        ]
        if let statusCode {
            metadata["status_code"] = statusCode
        }
        if let failureClassification {
            metadata["failure"] = failureClassification
        }

        // Credential-shaped values (bearer token, password fields) never reach the log
        // destination unmasked. A logging failure must never turn a successful request into a
        // thrown error — `PIIMasker` and `LoggingService.log` are both non-throwing, so this
        // call site cannot propagate a failure to the caller.
        let maskedMetadata = PIIMasker.maskMetadata(metadata)
        let level: LogLevel = failureClassification == nil ? .info : .warning
        loggingService.log(level: level, message: "network.request", metadata: maskedMetadata)
    }
}
