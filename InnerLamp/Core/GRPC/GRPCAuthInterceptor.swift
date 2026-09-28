//
//  GRPCAuthInterceptor.swift
//  InnerLamp
//
//  Attaches `authorization: Bearer <token>` as gRPC call-metadata when a token exists, reusing
//  the same `AuthTokenProviding` protocol Core/Networking uses — no second token store. See
//  Docs/Specs/GRPC/design.md § "Step-by-step Flow — Unary RPC" Step 2.
//
//  Migrated to gRPC Swift 1.x: interceptors are generic per RPC and passed at call time (see
//  `GRPCService`), rather than attached once to a client.
//

import GRPC
import NIOCore
import NIOHPACK

/// `nonisolated` — interceptors run on the channel's event loop, not the main actor, so they
/// must match the nonisolated `ClientInterceptor` API. `AuthTokenProviding` isn't itself
/// `Sendable`, but every conformer (e.g. `KeychainAuthTokenProviding`) is an immutable,
/// thread-safe reader, the same trust boundary `NetworkServiceImpl` already relies on.
nonisolated final class GRPCAuthInterceptor<Request, Response>: ClientInterceptor<Request, Response> {
    private let authTokenProvider: AuthTokenProviding

    init(authTokenProvider: AuthTokenProviding) {
        self.authTokenProvider = authTokenProvider
        super.init()
    }

    override func send(
        _ part: GRPCClientRequestPart<Request>,
        promise: EventLoopPromise<Void>?,
        context: ClientInterceptorContext<Request, Response>
    ) {
        switch part {
        case .metadata(var headers):
            // No token stored → send with no auth metadata. Do not throw, do not block, do not
            // fabricate an empty token — mirrors Core/Networking's no-token path
            // (NetworkServiceImpl.injectAuthHeader).
            if let token = authTokenProvider.currentToken(), !token.isEmpty {
                headers.add(name: "authorization", value: "Bearer \(token)")
            }
            context.send(.metadata(headers), promise: promise)

        case .message, .end:
            context.send(part, promise: promise)
        }
    }
}
