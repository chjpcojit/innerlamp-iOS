//
//  GRPCService.swift
//  InnerLamp
//
//  The app-facing entry point a feature Repository calls — wraps the shared gRPC channel and
//  never exposes it (or any raw grpc-swift error type) directly. See
//  Docs/Specs/GRPC/design.md § "Layers & components" and its two Step-by-step Flow sections.
//
//  Deliberately generic over Request/Response (`SwiftProtobuf.Message`): this layer defines only
//  the reusable transport capability, not any concrete `.proto` service (see requirements.md
//  Pending) — so it stays agnostic to whichever service a future feature generates.
//
//  Migrated to gRPC Swift 1.x (the `GRPC` product) for iOS 15 support: it wraps a
//  `GRPCAnyServiceClient` (channel + default call options) and creates the auth/logging
//  interceptors per call, since 1.x passes interceptors per RPC rather than per client.
//

import Foundation
import GRPC
import NIOCore
import SwiftProtobuf

nonisolated final class GRPCService {
    private let client: GRPCAnyServiceClient
    private let authTokenProvider: AuthTokenProviding
    private let loggingService: LoggingService

    init(
        client: GRPCAnyServiceClient,
        authTokenProvider: AuthTokenProviding,
        loggingService: LoggingService
    ) {
        self.client = client
        self.authTokenProvider = authTokenProvider
        self.loggingService = loggingService
    }

    /// Executes a unary RPC: one request, one decoded response, or a thrown `GRPCError` —
    /// analogous to `NetworkService.request(endpoint:responseType:)` (FR-004).
    func unary<Request: SwiftProtobuf.Message & Sendable, Response: SwiftProtobuf.Message & Sendable>(
        _ request: Request,
        path: String,
        timeout: TimeAmount? = nil
    ) async throws -> Response {
        do {
            return try await client.performAsyncUnaryCall(
                path: path,
                request: request,
                callOptions: GRPCConfiguration.callOptions(timeout: timeout),
                interceptors: makeInterceptors()
            )
        } catch {
            throw GRPCError(error)
        }
    }

    /// Executes a server-streaming RPC: one request, a sequence of decoded responses the
    /// caller iterates with `for await`, or a thrown `GRPCError` if the stream never opens
    /// (FR-005). A lost connection ends/throws on the returned sequence; nothing here
    /// resubscribes — resubscription, if desired, is the calling feature's own decision (FR-006).
    func serverStreaming<Request: SwiftProtobuf.Message & Sendable, Response: SwiftProtobuf.Message & Sendable>(
        _ request: Request,
        path: String,
        timeout: TimeAmount? = nil
    ) -> AsyncThrowingStream<Response, Error> {
        let upstream: GRPCAsyncResponseStream<Response> = client.performAsyncServerStreamingCall(
            path: path,
            request: request,
            callOptions: GRPCConfiguration.callOptions(timeout: timeout),
            interceptors: makeInterceptors()
        )

        // Remap every failure — a rejected stream open or a mid-stream connection drop — to
        // `GRPCError`, so no raw grpc-swift error type crosses this boundary at any point in the
        // stream's lifetime. A lost connection ends the sequence; nothing resubscribes (FR-006).
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in upstream {
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: GRPCError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The logging interceptor is registered first so it starts timing before auth-metadata
    /// injection (FR-010); the auth interceptor follows (FR-002).
    private func makeInterceptors<Request: Sendable, Response: Sendable>()
        -> [ClientInterceptor<Request, Response>]
    {
        [
            GRPCLogger(loggingService: loggingService),
            GRPCAuthInterceptor(authTokenProvider: authTokenProvider)
        ]
    }
}
