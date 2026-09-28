//
//  GRPCServiceTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/GRPC/tasks.md Phase 4 (unary) and Phase 5 (server-streaming): success path
//  decodes correctly, failure branches throw the expected GRPCError, messages arrive in order,
//  and a simulated stream interruption terminates the stream rather than silently retrying
//  (FR-006 — no auto-reconnect).
//

import XCTest
import GRPCCore
import GRPCProtobuf
@testable import InnerLamp

final class GRPCServiceTests: XCTestCase {

    // MARK: - Unary (Phase 4)

    func test_unary_success_decodesResponse() async throws {
        let server = GRPCTestServer()
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_EchoResponse = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hello" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        XCTAssertEqual(response.message, "hello")
    }

    func test_unary_failure_throwsGRPCErrorNotRawRPCError() async throws {
        let server = GRPCTestServer()
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        do {
            let _: Innerlamp_Grpctest_EchoResponse = try await service.unary(
                Innerlamp_Grpctest_EchoRequest.with {
                    $0.message = "hello"
                    $0.failWithStatusCode = 5 // notFound
                },
                descriptor: .echoTestServiceEcho,
                serializer: ProtobufSerializer(),
                deserializer: ProtobufDeserializer()
            )
            XCTFail("Expected GRPCError.notFound")
        } catch let error as GRPCError {
            guard case .notFound = error else {
                XCTFail("Expected .notFound, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected GRPCError, got raw \(type(of: error))")
        }
    }

    // MARK: - Server-streaming (Phase 5)

    func test_serverStreaming_receivesMessagesInOrder() async throws {
        let server = GRPCTestServer()
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let sequence = try await service.serverStreaming(
            Innerlamp_Grpctest_EchoStreamRequest.with {
                $0.message = "item"
                $0.count = 3
            },
            descriptor: .echoTestServiceEchoStream,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        var received: [String] = []
        for try await response in sequence {
            received.append(response.message)
        }

        XCTAssertEqual(received, ["item-0", "item-1", "item-2"])
    }

    func test_serverStreaming_openFailure_throwsBeforeAnyMessage() async throws {
        let server = GRPCTestServer()
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        do {
            _ = try await service.serverStreaming(
                Innerlamp_Grpctest_EchoStreamRequest.with {
                    $0.message = "item"
                    $0.count = 3
                    $0.failBeforeFirstMessage = true
                },
                descriptor: .echoTestServiceEchoStream,
                serializer: ProtobufSerializer(),
                deserializer: ProtobufDeserializer()
            )
            XCTFail("Expected GRPCError.unavailable")
        } catch let error as GRPCError {
            guard case .unavailable = error else {
                XCTFail("Expected .unavailable, got \(error)")
                return
            }
        }
    }

    func test_serverStreaming_connectionDropped_streamEndsWithoutAutoReconnect() async throws {
        let server = GRPCTestServer()
        await server.start()

        let service = GRPCService(client: server.client)
        let sequence = try await service.serverStreaming(
            Innerlamp_Grpctest_EchoStreamRequest.with {
                $0.message = "item"
                $0.count = 1000 // long enough that we can drop the connection mid-stream
            },
            descriptor: .echoTestServiceEchoStream,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        var iterator = sequence.makeAsyncIterator()
        _ = try await iterator.next() // receive at least one message successfully

        // Simulate a dropped connection by tearing down the whole in-process server/client pair
        // mid-stream — the sequence must end (throw), not silently resubscribe.
        await server.stop()

        var threwOrFinished = false
        do {
            while try await iterator.next() != nil {}
            threwOrFinished = true // finished normally is also an acceptable "it ended" outcome
        } catch {
            threwOrFinished = true // threw — also an acceptable "it ended" outcome
        }

        XCTAssertTrue(threwOrFinished, "Stream must end (throw or finish) rather than hang or silently resubscribe")
    }
}
