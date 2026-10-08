//
//  GRPCTestServer.swift
//  InnerLampTests
//
//  An in-process (in-memory) gRPC server/client pair used only by XCTest, so Core/GRPC's
//  auth/error/logging/streaming behavior can be exercised against a real wire/serialization
//  path without depending on a live backend. Mirrors NetworkServiceTests' use of
//  MockURLProtocol. See Docs/Specs/GRPC/requirements.md FR-012.
//
//  `EchoTestService` (Protos/echo_test_service.proto) is a test-only service — not a business
//  contract. It exists solely to give Core/GRPC's Phases 1-6 something real to call.
//

import GRPCCore
import GRPCInProcessTransport
import SwiftProtobuf

/// Implements the generated `EchoTestService` against the test-only `.proto` contract, echoing
/// the request back (unary) or emitting `count` echoes in order (server-streaming), with two
/// caller-controlled failure hooks used to exercise `GRPCError`'s status-code mapping and the
/// no-auto-reconnect guarantee (FR-006).
///
/// Conforms to `ServiceProtocol` rather than `SimpleServiceProtocol` because it needs access to
/// inbound call metadata (`request.metadata`) to assert `GRPCAuthInterceptor`'s present/absent
/// matrix (FR-002) — `SimpleServiceProtocol` deliberately drops metadata access for simplicity.
struct EchoTestServiceProvider: Innerlamp_Grpctest_EchoTestService.ServiceProtocol {
    func echo(
        request: ServerRequest<Innerlamp_Grpctest_EchoRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Innerlamp_Grpctest_EchoResponse> {
        if request.message.delayMs > 0 {
            try await Task.sleep(for: .milliseconds(request.message.delayMs))
        }
        if let error = Self.error(forStatusCode: request.message.failWithStatusCode) {
            throw error
        }

        let response = Innerlamp_Grpctest_EchoResponse.with {
            $0.message = request.message.message
            $0.receivedAuthorization = Array(request.metadata[stringValues: "authorization"]).first ?? ""
        }
        return ServerResponse(message: response)
    }

    func echoStream(
        request: ServerRequest<Innerlamp_Grpctest_EchoStreamRequest>,
        context: ServerContext
    ) async throws -> StreamingServerResponse<Innerlamp_Grpctest_EchoResponse> {
        if request.message.failBeforeFirstMessage {
            throw RPCError(code: .unavailable, message: "simulated failure before first message")
        }

        let requestMessage = request.message
        let authorization = Array(request.metadata[stringValues: "authorization"]).first ?? ""
        return StreamingServerResponse(of: Innerlamp_Grpctest_EchoResponse.self) { writer in
            for index in 0..<requestMessage.count {
                try await writer.write(
                    .with {
                        $0.message = "\(requestMessage.message)-\(index)"
                        $0.receivedAuthorization = authorization
                    }
                )
            }
            return [:]
        }
    }

    /// Maps a small, test-only set of status codes to `RPCError`s — enough to exercise every
    /// named `GRPCError` case without needing `RPCError.Code`'s internal raw-value initializer.
    private static func error(forStatusCode code: Int32) -> RPCError? {
        switch code {
        case 0: return nil
        case 16: return RPCError(code: .unauthenticated, message: "test: unauthenticated")
        case 14: return RPCError(code: .unavailable, message: "test: unavailable")
        case 4: return RPCError(code: .deadlineExceeded, message: "test: deadline exceeded")
        case 5: return RPCError(code: .notFound, message: "test: not found")
        case 13: return RPCError(code: .internalError, message: "test: internal error")
        default: return RPCError(code: .unknown, message: "test: unknown (\(code))")
        }
    }
}

/// Pairs an in-process `GRPCServer` (running `EchoTestServiceProvider`) with a `GRPCClient` that
/// talks to it over `InProcessTransport` — no TLS, no real network, no live backend. Every test
/// wires its own interceptors onto the client to isolate what it's asserting.
final class GRPCTestServer {
    let client: GRPCClient<InProcessTransport.Client>

    private let server: GRPCServer<InProcessTransport.Server>
    private var serverTask: Task<Void, Error>?
    private var clientTask: Task<Void, Error>?

    init(
        services: [any RegistrableRPCService] = [EchoTestServiceProvider()],
        interceptors: [any ClientInterceptor] = []
    ) {
        let transport = InProcessTransport()
        self.server = GRPCServer(transport: transport.server, services: services)
        self.client = GRPCClient(transport: transport.client, interceptors: interceptors)
    }

    /// Starts the server and client connections; must be called (and `stop()` eventually
    /// called) around every test that uses `client`.
    func start() async {
        serverTask = Task { try await server.serve() }
        clientTask = Task { try await client.runConnections() }
        // Give both sides a moment to reach a running state before the first call.
        try? await Task.sleep(for: .milliseconds(50))
    }

    func stop() async {
        client.beginGracefulShutdown()
        server.beginGracefulShutdown()
        _ = try? await clientTask?.value
        _ = try? await serverTask?.value
    }
}

extension MethodDescriptor {
    /// The `EchoTestService/Echo` and `.../EchoStream` method descriptors, for tests that call
    /// `GRPCService` directly against `GRPCTestServer.client` rather than through the generated
    /// stub. "innerlamp.grpctest.EchoTestService" matches Protos/echo_test_service.proto's
    /// `package innerlamp.grpctest; service EchoTestService`.
    static let echoTestServiceEcho = MethodDescriptor(
        fullyQualifiedService: "innerlamp.grpctest.EchoTestService",
        method: "Echo"
    )

    static let echoTestServiceEchoStream = MethodDescriptor(
        fullyQualifiedService: "innerlamp.grpctest.EchoTestService",
        method: "EchoStream"
    )
}
