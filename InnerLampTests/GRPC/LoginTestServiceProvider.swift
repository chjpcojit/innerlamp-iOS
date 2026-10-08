//
//  LoginTestServiceProvider.swift
//  InnerLampTests
//
//  A mock server for `LoginTestService` (Protos/login_test_service.proto), used only to prove
//  Core/GRPC's unary flow (GRPCAuthInterceptor → GRPCService.unary → GRPCLogger → GRPCError
//  mapping) works end to end against a request/response shape modeled on the real REST login
//  contract (`POST /v1/auth/login`) — see GRPCLoginMockTests.swift. Not a business contract.
//

import GRPCCore
import SwiftProtobuf

/// Accepts exactly one hardcoded credential pair, mirroring the REST login flow's own
/// success/failure split: a match returns a session, anything else throws `.unauthenticated` —
/// the same status `GRPCAuthInterceptorTests`/`GRPCErrorTests` already exercise for other flows.
struct LoginTestServiceProvider: Innerlamp_Grpctest_LoginTestService.ServiceProtocol {
    static let validPhoneNumber = "0900000000"
    static let validPassword = "correct-password"

    func login(
        request: ServerRequest<Innerlamp_Grpctest_LoginRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Innerlamp_Grpctest_LoginResponse> {
        let message = request.message
        guard message.phoneNumber == Self.validPhoneNumber, message.password == Self.validPassword else {
            throw RPCError(code: .unauthenticated, message: "invalid phone number or password")
        }

        let response = Innerlamp_Grpctest_LoginResponse.with {
            $0.accessToken = "mock-access-token"
            $0.refreshToken = "mock-refresh-token"
            $0.user = .with {
                $0.id = 1
                $0.email = "mock@innerlamp.app"
                $0.phoneNumber = message.phoneNumber
                $0.dharmaName = "Tâm An"
                $0.ordinationPlace = ""
            }
        }
        return ServerResponse(message: response)
    }
}

extension MethodDescriptor {
    /// "innerlamp.grpctest.LoginTestService" matches Protos/login_test_service.proto's
    /// `package innerlamp.grpctest; service LoginTestService`.
    static let loginTestServiceLogin = MethodDescriptor(
        fullyQualifiedService: "innerlamp.grpctest.LoginTestService",
        method: "Login"
    )
}
