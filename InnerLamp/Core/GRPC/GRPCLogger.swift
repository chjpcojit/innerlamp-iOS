//
//  GRPCLogger.swift
//  InnerLamp
//
//  Turns one completed RPC into one LoggingService record — method path, outcome, duration —
//  mirroring NetworkLogger's role for REST (FR-010). See Docs/Specs/GRPC/design.md §
//  "Step-by-step Flow — Unary RPC" Step 5.
//
//  gRPC Swift 2.x: a non-generic `ClientInterceptor` registered on the shared `GRPCClient`. One
//  `intercept` call == one RPC, so timing is local and exactly one record is emitted when the
//  call reaches a terminal outcome (server status, or a caught error). For server-streaming this
//  logs the stream's *acceptance/rejection* outcome, not a record per message.
//

import Foundation
import GRPCCore

nonisolated struct GRPCLogger: ClientInterceptor {
    private let loggingService: GRPCUncheckedSendable<any LoggingService>

    init(loggingService: any LoggingService) {
        self.loggingService = GRPCUncheckedSendable(value: loggingService)
    }

    // gRPC Swift 2's `ClientInterceptor` requirement is compiled without
    // `NonisolatedNonsendingByDefault`, so it is `@concurrent`; this app enables that feature, so
    // the conformance must opt back into the concurrent executor explicitly.
    @concurrent
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @concurrent (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        let startedAt = Date()
        let path = context.descriptor.fullyQualifiedMethod

        do {
            let response = try await next(request, context)
            switch response.accepted {
            case .success:
                log(path: path, failureClassification: nil, startedAt: startedAt)
            case .failure(let error):
                log(path: path, failureClassification: "\(error.code)", startedAt: startedAt)
            }
            return response
        } catch {
            log(path: path, failureClassification: Self.classification(of: error), startedAt: startedAt)
            throw error
        }
    }

    /// A logging failure must never turn a successful call into a thrown error, mirroring
    /// Core/Networking's equivalent guarantee — `LoggingService.log` is non-throwing, so this
    /// interceptor only ever propagates whatever the pipeline itself does.
    private func log(path: String, failureClassification: String?, startedAt: Date) {
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
        loggingService.value.log(level: level, message: "grpc.request", metadata: maskedMetadata)
    }

    /// The classification is the gRPC status code when the error carries one (the `RPCError`
    /// case / status code), never raw response content.
    private static func classification(of error: Error) -> String {
        if let rpcError = error as? RPCError {
            return "\(rpcError.code)"
        }
        if let convertible = error as? RPCErrorConvertible {
            return "\(convertible.rpcErrorCode)"
        }
        return "\(type(of: error))"
    }
}
