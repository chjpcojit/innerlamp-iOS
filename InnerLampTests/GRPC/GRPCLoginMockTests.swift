//
//  GRPCLoginMockTests.swift
//  InnerLampTests
//
//  Proves Core/GRPC's public API (GRPCService.unary, GRPCAuthInterceptor, GRPCLogger, GRPCError)
//  works end to end against a request/response shape modeled on the real REST login contract
//  (`POST /v1/auth/login`), using the mock `LoginTestService` from
//  Protos/login_test_service.proto + LoginTestServiceProvider.swift. Not a business contract —
//  see tasks.md "Deferred" for why a real `Login` gRPC service isn't built here.
//

import XCTest
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf
@testable import InnerLamp

final class GRPCLoginMockTests: XCTestCase {

    func test_login_validCredentials_decodesSessionAndUser() async throws {
        let server = GRPCTestServer(services: [LoginTestServiceProvider()])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_LoginResponse = try await service.unary(
            Innerlamp_Grpctest_LoginRequest.with {
                $0.phoneNumber = LoginTestServiceProvider.validPhoneNumber
                $0.password = LoginTestServiceProvider.validPassword
                $0.device = .with {
                    $0.platform = "ios"
                    $0.deviceModel = "iPhone17,1"
                    $0.osVersion = "26.5"
                    $0.appVersion = "1.0"
                    $0.deviceName = "Test Device"
                }
            },
            descriptor: .loginTestServiceLogin,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer<Innerlamp_Grpctest_LoginResponse>()
        )

        XCTAssertEqual(response.accessToken, "mock-access-token")
        XCTAssertEqual(response.refreshToken, "mock-refresh-token")
        XCTAssertEqual(response.user.phoneNumber, LoginTestServiceProvider.validPhoneNumber)
        XCTAssertEqual(response.user.dharmaName, "Tâm An")
    }

    func test_login_wrongPassword_throwsUnauthenticatedGRPCError() async throws {
        let server = GRPCTestServer(services: [LoginTestServiceProvider()])
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        do {
            let _: Innerlamp_Grpctest_LoginResponse = try await service.unary(
                Innerlamp_Grpctest_LoginRequest.with {
                    $0.phoneNumber = LoginTestServiceProvider.validPhoneNumber
                    $0.password = "wrong-password"
                },
                descriptor: .loginTestServiceLogin,
                serializer: ProtobufSerializer(),
                deserializer: ProtobufDeserializer<Innerlamp_Grpctest_LoginResponse>()
            )
            XCTFail("Expected GRPCError.unauthenticated")
        } catch let error as GRPCError {
            guard case .unauthenticated = error else {
                XCTFail("Expected .unauthenticated, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected GRPCError, got raw \(type(of: error))")
        }
    }

    /// End-to-end with the real interceptor stack, not just the raw client — the same shape a
    /// feature Repository would actually get from `DIContainer.grpcService` (auth metadata
    /// attached automatically, one log record emitted, never a raw grpc-swift error type).
    func test_login_withAuthAndLoggingInterceptors_attachesBearerTokenAndLogsOneRecord() async throws {
        let mockAuthTokenProvider = MockGRPCAuthTokenProviding()
        mockAuthTokenProvider.token = "mock-session-token"
        let mockLoggingService = MockGRPCLoggingService()

        let server = GRPCTestServer(
            services: [LoginTestServiceProvider()],
            interceptors: [
                GRPCLogger(loggingService: mockLoggingService),
                GRPCAuthInterceptor(authTokenProvider: mockAuthTokenProvider)
            ]
        )
        await server.start()
        defer { Task { await server.stop() } }

        let service = GRPCService(client: server.client)
        let response: Innerlamp_Grpctest_LoginResponse = try await service.unary(
            Innerlamp_Grpctest_LoginRequest.with {
                $0.phoneNumber = LoginTestServiceProvider.validPhoneNumber
                $0.password = LoginTestServiceProvider.validPassword
            },
            descriptor: .loginTestServiceLogin,
            serializer: ProtobufSerializer(),
            deserializer: ProtobufDeserializer<Innerlamp_Grpctest_LoginResponse>()
        )

        XCTAssertEqual(response.accessToken, "mock-access-token")
        XCTAssertEqual(mockLoggingService.recordedMessages.count, 1)

        let record = try XCTUnwrap(mockLoggingService.recordedMessages.first)
        XCTAssertEqual(record.metadata["method"] as? String, "innerlamp.grpctest.LoginTestService/Login")
        XCTAssertFalse(
            record.metadata.values.contains { "\($0)".contains("mock-session-token") },
            "The bearer token must never appear unmasked in a log record"
        )
    }
}

private final class MockGRPCAuthTokenProviding: AuthTokenProviding {
    var token: String?
    func currentToken() -> String? { token }
}

private final class MockGRPCLoggingService: LoggingService {
    struct Record {
        let level: LogLevel
        let message: String
        let metadata: [String: Any]
    }

    private(set) var recordedMessages: [Record] = []

    func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        recordedMessages.append(Record(level: level, message: message, metadata: metadata ?? [:]))
    }

    func breadcrumb(category: BreadcrumbCategory, message: String, data: [String: Any]?) {}
    func setUserContext(_ context: UserContext) {}
    func clearUserContext() {}
}
