//
//  GRPCAuthInterceptor.swift
//  InnerLamp
//
//  Attaches `authorization: Bearer <token>` as gRPC call-metadata when a token exists, reusing
//  the same `AuthTokenProviding` protocol Core/Networking uses — no second token store. See
//  Docs/Specs/GRPC/design.md § "Step-by-step Flow — Unary RPC" Step 2.
//
//  gRPC Swift 2.x: `ClientInterceptor` is a non-generic protocol whose `intercept` method wraps
//  one RPC (unary or streaming). One instance is registered on the shared `GRPCClient` and runs
//  on every call, so it carries no per-call state.
//

import GRPCCore

nonisolated struct GRPCAuthInterceptor: ClientInterceptor {
    private let authTokenProvider: GRPCUncheckedSendable<any AuthTokenProviding>

    init(authTokenProvider: any AuthTokenProviding) {
        self.authTokenProvider = GRPCUncheckedSendable(value: authTokenProvider)
    }

    // gRPC Swift 2's `ClientInterceptor` requirement is compiled without
    // `NonisolatedNonsendingByDefault`, so it is `@concurrent`; this app enables that feature, so
    // the conformance must opt back into the concurrent executor explicitly.
    @concurrent
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @concurrent (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        var request = request

        // No token stored → send with no auth metadata. Do not throw, do not block, do not
        // fabricate an empty token — mirrors Core/Networking's no-token path
        // (NetworkServiceImpl.injectAuthHeader).
        if let token = authTokenProvider.value.currentToken(), !token.isEmpty {
            request.metadata.addString("Bearer \(token)", forKey: "authorization")
        }

        return try await next(request, context)
    }
}
