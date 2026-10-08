//
//  GRPCErrorTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/GRPC/tasks.md Phase 3 — every relevant GRPCStatus.Code maps to the correct
//  distinct GRPCError case, and a call exceeding the configured deadline throws .deadlineExceeded.
//

import XCTest
import GRPCCore
import GRPCInProcessTransport
import GRPCProtobuf
import SwiftProtobuf
@testable import InnerLamp

/// gRPC Swift 2.x's `GRPCClient` is generic over its transport, so `GRPCService` is too. Tests
/// that name the service type explicitly use the in-process transport the test server runs on.
private typealias TestGRPCService = GRPCService<InProcessTransport.Client>

final class GRPCErrorTests: XCTestCase {

    private func makeService() -> (GRPCTestServer, TestGRPCService) {
        let server = GRPCTestServer()
        let service = GRPCService(client: server.client)
        return (server, service)
    }

    private func echo(
        _ service: TestGRPCService,
        statusCode: Int32 = 0,
        delayMs: Int32 = 0,
        timeout: Duration? = nil
    ) async throws -> Innerlamp_Grpctest_EchoResponse {
        try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with {
                $0.message = "hi"
                $0.failWithStatusCode = statusCode
                $0.delayMs = delayMs
            },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer(),
            timeout: timeout
        )
    }

    func test_unauthenticated_mapsToNamedCase() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            _ = try await echo(service, statusCode: 16)
            XCTFail("Expected GRPCError.unauthenticated")
        } catch GRPCError.unauthenticated {
            // expected
        }
    }

    func test_unavailable_mapsToNamedCase() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            _ = try await echo(service, statusCode: 14)
            XCTFail("Expected GRPCError.unavailable")
        } catch GRPCError.unavailable {
            // expected
        }
    }

    func test_notFound_mapsToNamedCase() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            _ = try await echo(service, statusCode: 5)
            XCTFail("Expected GRPCError.notFound")
        } catch GRPCError.notFound {
            // expected
        }
    }

    func test_internalError_mapsToServerError() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            _ = try await echo(service, statusCode: 13)
            XCTFail("Expected GRPCError.serverError")
        } catch GRPCError.serverError {
            // expected
        }
    }

    func test_unmappedCode_fallsBackToUnknown() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            // 11 == outOfRange — deliberately not one of GRPCError's named cases.
            _ = try await echo(service, statusCode: 11)
            XCTFail("Expected GRPCError.unknown")
        } catch GRPCError.unknown {
            // expected
        }
    }

    func test_callExceedingDeadline_throwsDeadlineExceeded() async throws {
        let (server, service) = makeService()
        await server.start()
        defer { Task { await server.stop() } }

        do {
            _ = try await echo(service, delayMs: 500, timeout: .milliseconds(20))
            XCTFail("Expected GRPCError.deadlineExceeded")
        } catch GRPCError.deadlineExceeded {
            // expected
        }
    }

    func test_noExplicitTimeout_usesThirtySecondDefault() {
        XCTAssertEqual(GRPCConfiguration.defaultCallTimeout, .seconds(30))
    }
}
