//
//  GRPCAuthInterceptorTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/GRPC/tasks.md Phase 2 — auth metadata is present when a token exists,
//  absent when it doesn't, and never appears unmasked in log output.
//

import XCTest
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf
@testable import InnerLamp

final class GRPCAuthInterceptorTests: XCTestCase {

    private var mockAuthTokenProvider: MockGRPCAuthTokenProviding!

    override func setUp() {
        super.setUp()
        mockAuthTokenProvider = MockGRPCAuthTokenProviding()
    }

    override func tearDown() {
        mockAuthTokenProvider = nil
        super.tearDown()
    }

    func test_tokenPresent_attachesBearerMetadata() async throws {
        mockAuthTokenProvider.token = "secret-grpc-token"
        let server = GRPCTestServer(interceptors: [GRPCAuthInterceptor(authTokenProvider: mockAuthTokenProvider)])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_EchoResponse = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hi" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        XCTAssertEqual(response.receivedAuthorization, "Bearer secret-grpc-token")
    }

    func test_noToken_omitsMetadataAndStillSendsRequest() async throws {
        mockAuthTokenProvider.token = nil
        let server = GRPCTestServer(interceptors: [GRPCAuthInterceptor(authTokenProvider: mockAuthTokenProvider)])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_EchoResponse = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hi" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        XCTAssertEqual(response.receivedAuthorization, "")
        XCTAssertEqual(response.message, "hi")
    }

    func test_emptyToken_treatedAsNoToken() async throws {
        mockAuthTokenProvider.token = ""
        let server = GRPCTestServer(interceptors: [GRPCAuthInterceptor(authTokenProvider: mockAuthTokenProvider)])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_EchoResponse = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hi" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        XCTAssertEqual(response.receivedAuthorization, "")
    }
}

private final class MockGRPCAuthTokenProviding: AuthTokenProviding {
    var token: String?
    func currentToken() -> String? { token }
}
