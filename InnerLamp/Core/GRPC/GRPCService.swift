//
//  GRPCService.swift
//  InnerLamp
//
//  The app-facing entry point a feature Repository calls — wraps the shared gRPC client and never
//  exposes it (or any raw grpc-swift error type) directly. See Docs/Specs/GRPC/design.md §
//  "Layers & components" and its two Step-by-step Flow sections.
//
//  Deliberately generic over Request/Response in its call methods, and over the transport it
//  wraps: this layer defines only the reusable transport capability, not any concrete `.proto`
//  service — so it stays agnostic to whichever service a future feature generates, and testable
//  against the in-process transport.
//
//  gRPC Swift 2.x: wraps a `GRPCClient` (transport + interceptors) and turns its byte-level /
//  message-level API into one decoded response, or an async sequence of decoded responses, with
//  every failure remapped to `GRPCError`.
//

import Foundation
import GRPCCore

nonisolated struct GRPCService<Transport: ClientTransport> {
    let client: GRPCClient<Transport>

    init(client: GRPCClient<Transport>) {
        self.client = client
    }

    /// Executes a unary RPC: one request, one decoded response, or a thrown `GRPCError` —
    /// analogous to `NetworkService.request(endpoint:responseType:)` (FR-004).
    func unary<Request: Sendable, Response: Sendable>(
        _ request: Request,
        descriptor: MethodDescriptor,
        serializer: some MessageSerializer<Request>,
        deserializer: some MessageDeserializer<Response>,
        timeout: Duration? = nil
    ) async throws -> Response {
        do {
            return try await client.unary(
                request: ClientRequest(message: request),
                descriptor: descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: GRPCConfiguration.callOptions(timeout: timeout)
            ) { response in
                // `message` throws `RPCError` for a rejected/failed call; that is remapped to
                // `GRPCError` by the `catch` below.
                try response.message
            }
        } catch {
            throw GRPCError(error)
        }
    }

    /// Executes a server-streaming RPC: one request, a sequence of decoded responses the caller
    /// iterates with `for await`, or a thrown `GRPCError` if the stream never opens (FR-005). A
    /// lost connection ends/throws on the returned sequence; nothing here resubscribes —
    /// resubscription, if desired, is the calling feature's own decision (FR-006).
    func serverStreaming<Request: Sendable, Response: Sendable>(
        _ request: Request,
        descriptor: MethodDescriptor,
        serializer: some MessageSerializer<Request>,
        deserializer: some MessageDeserializer<Response>,
        timeout: Duration? = nil
    ) async throws -> AsyncThrowingStream<Response, Error> {
        let upstream: RPCAsyncSequence<Response, any Error>
        do {
            upstream = try await client.serverStreaming(
                request: ClientRequest(message: request),
                descriptor: descriptor,
                serializer: serializer,
                deserializer: deserializer,
                options: GRPCConfiguration.callOptions(timeout: timeout)
            ) { response in
                switch response.accepted {
                case .success:
                    return response.messages
                case .failure(let error):
                    throw error
                }
            }
        } catch {
            // A rejected stream open — no message is yielded; the caller sees the mapped error.
            throw GRPCError(error)
        }

        // Remap every mid-stream failure — a decode fault or a dropped connection — to
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
}
