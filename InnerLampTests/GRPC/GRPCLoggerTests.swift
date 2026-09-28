//
//  GRPCLoggerTests.swift
//  InnerLampTests
//
//  Covers Docs/Specs/GRPC/tasks.md Phase 6 — one record per unary call; a bearer token never
//  appears in the emitted record; a failed call logs the classification (status code), never
//  raw response content.
//

import XCTest
import GRPCCore
import GRPCProtobuf
@testable import InnerLamp

final class GRPCLoggerTests: XCTestCase {

    private var mockLoggingService: MockGRPCLoggingService!

    override func setUp() {
        super.setUp()
        mockLoggingService = MockGRPCLoggingService()
    }

    override func tearDown() {
        mockLoggingService = nil
        super.tearDown()
    }

    func test_successfulUnaryCall_logsExactlyOneRecordWithNoFailure() async throws {
        let server = GRPCTestServer(interceptors: [GRPCLogger(loggingService: mockLoggingService)])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        _ = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hi" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        )

        XCTAssertEqual(mockLoggingService.records.count, 1)
        XCTAssertNil(mockLoggingService.records.first?.metadata?["failure"])
    }

    func test_failedUnaryCall_logsStatusCodeClassificationNotRawContent() async throws {
        let server = GRPCTestServer(interceptors: [GRPCLogger(loggingService: mockLoggingService)])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        _ = try? await service.unary(
            Innerlamp_Grpctest_EchoRequest.with {
                $0.message = "hi"
                $0.failWithStatusCode = 5 // notFound
            },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        ) as Innerlamp_Grpctest_EchoResponse

        XCTAssertEqual(mockLoggingService.records.count, 1)
        let failure = mockLoggingService.records.first?.metadata?["failure"] as? String
        XCTAssertEqual(failure, "notFound")
    }

    func test_bearerTokenNeverAppearsInEmittedRecord() async throws {
        let authInterceptor = GRPCAuthInterceptor(authTokenProvider: MockAlwaysTokenProviding())
        let server = GRPCTestServer(interceptors: [
            GRPCLogger(loggingService: mockLoggingService),
            authInterceptor
        ])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        _ = try await service.unary(
            Innerlamp_Grpctest_EchoRequest.with { $0.message = "hi" },
            descriptor: .echoTestServiceEcho,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer()
        ) as Innerlamp_Grpctest_EchoResponse

        let allValues = mockLoggingService.records.flatMap { record in
            (record.metadata ?? [:]).values.map { "\($0)" }
        }
        XCTAssertFalse(allValues.contains { $0.contains("super-secret-grpc-token") })
    }
}

private final class MockAlwaysTokenProviding: AuthTokenProviding {
    func currentToken() -> String? { "super-secret-grpc-token" }
}

private final class MockGRPCLoggingService: LoggingService {
    struct Record {
        let level: LogLevel
        let message: String
        let metadata: [String: Any]?
    }

    private(set) var records: [Record] = []

    func breadcrumb(category: BreadcrumbCategory, message: String, data: [String: Any]?) {}

    func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        records.append(Record(level: level, message: message, metadata: metadata))
    }

    func setUserContext(_ context: UserContext) {}
    func clearUserContext() {}
}
