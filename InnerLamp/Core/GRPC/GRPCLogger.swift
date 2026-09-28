//
//  GRPCLogger.swift
//  InnerLamp
//
//  Turns one completed RPC into one LoggingService record — method path, outcome, duration —
//  mirroring NetworkLogger's role for REST (FR-010). See Docs/Specs/GRPC/design.md §
//  "Step-by-step Flow — Unary RPC" Step 5.
//
//  Migrated to gRPC Swift 1.x: a per-call interceptor (created by `GRPCService`) that logs once,
//  when the RPC reaches a terminal part — the server's `.end` status, or a caught error. One
//  instance is created per call, so the start-time / "already logged" state is per-call, not
//  shared. Streams therefore produce one record for the stream's *acceptance* outcome, not a
//  flood of per-message records — the granularity resolved in design.md.
//

import Foundation
import GRPC

/// `nonisolated` — interceptors run on the channel's event loop, not the main actor, so they
/// must match the nonisolated `ClientInterceptor` API. `LoggingService` isn't itself `Sendable`,
/// but every conformer (e.g. `SentryLoggingService`) is a thread-safe singleton, the same trust
/// boundary `NetworkLogger` already relies on.
nonisolated final class GRPCLogger<Request, Response>: ClientInterceptor<Request, Response> {
    private let loggingService: LoggingService
    private let startedAt = Date()
    private var hasLogged = false

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        super.init()
    }

    override func receive(
        _ part: GRPCClientResponsePart<Response>,
        context: ClientInterceptorContext<Request, Response>
    ) {
        if case .end(let status, _) = part {
            logOnce(path: context.path, failureClassification: status.isOk ? nil : "\(status.code)")
        }
        context.receive(part)
    }

    override func errorCaught(
        _ error: Error,
        context: ClientInterceptorContext<Request, Response>
    ) {
        logOnce(path: context.path, failureClassification: Self.classification(of: error))
        context.errorCaught(error)
    }

    /// A logging failure must never turn a successful call into a thrown error, mirroring
    /// Core/Networking's equivalent guarantee — `log(...)` below is non-throwing, so this
    /// interceptor only ever propagates whatever the pipeline itself does.
    private func logOnce(path: String, failureClassification: String?) {
        guard !hasLogged else { return }
        hasLogged = true
        log(path: path, failureClassification: failureClassification)
    }

    private func log(path: String, failureClassification: String?) {
        var metadata: [String: Any] = [
            "method": path,
            "duration_ms": Int(Date().timeIntervalSince(startedAt) * 1000)
        ]
        if let failureClassification {
            metadata["failure"] = failureClassification
        }

        // Credential-shaped values (the bearer token attached by GRPCAuthInterceptor) never
        // reach the log destination unmasked.
        let maskedMetadata = PIIMasker.maskMetadata(metadata)
        let level: LogLevel = failureClassification == nil ? .info : .warning
        loggingService.log(level: level, message: "grpc.request", metadata: maskedMetadata)
    }

    /// The classification is the gRPC status code when the error carries one (the `GRPCError`
    /// case / status code), never raw response content.
    private static func classification(of error: Error) -> String {
        if let status = error as? GRPCStatus {
            return "\(status.code)"
        }
        if let transformable = error as? GRPCStatusTransformable {
            return "\(transformable.makeGRPCStatus().code)"
        }
        return "\(type(of: error))"
    }
}
