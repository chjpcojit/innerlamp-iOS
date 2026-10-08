//
//  GRPCConfiguration.swift
//  InnerLamp
//
//  Builds the one gRPC client the app uses for every RPC — the gRPC analogue of
//  NetworkConfiguration's single URLSession. See Docs/Specs/GRPC/design.md § "Channel lifecycle".
//
//  gRPC Swift 2.x: the shared object is a `GRPCClient` wrapping an HTTP/2 transport built on
//  NIOTransportServices (Network.framework) — the recommended Darwin transport. Interceptors are
//  attached to the client at construction time; gRPC Swift 2 requires iOS 18.0+, matching the
//  app's deployment target.
//

import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2

/// `nonisolated` throughout — a pure factory namespace with no main-actor state, mirroring
/// `NetworkConfiguration`. The resulting client is `Sendable` and is held for the app's
/// lifetime, called from any isolation domain.
nonisolated enum GRPCConfiguration {
    /// The concrete client/transport pair the app uses, so call sites (e.g. `DIContainer`) can
    /// name it without importing the transport module directly.
    typealias Client = GRPCClient<HTTP2ClientTransport.TransportServices>
    typealias Service = GRPCService<HTTP2ClientTransport.TransportServices>

    /// Default per-call deadline when a caller specifies none — matches
    /// `NetworkConfiguration.requestTimeoutInterval`'s existing REST request timeout
    /// (FR-008, NFR-001).
    static let defaultCallTimeout: Duration = .seconds(30)

    /// Builds the shared client for `APIConfig`'s active `Environment`, with the auth and
    /// logging interceptors attached in that order (logging first so it starts timing before
    /// auth-metadata injection — FR-002, FR-010). Server-authenticated TLS only: no identity
    /// provider is configured, so no client certificate is ever presented (FR-003; mutual TLS is
    /// out of scope).
    static func makeClient(
        authTokenProvider: any AuthTokenProviding,
        loggingService: any LoggingService
    ) -> Client {
        do {
            let transport = try HTTP2ClientTransport.TransportServices(
                target: ResolvableTargets.DNS(host: APIConfig.grpcHost, port: APIConfig.grpcPort),
                transportSecurity: .tls
            )
            return Client(
                transport: transport,
                interceptors: [
                    GRPCLogger(loggingService: loggingService),
                    GRPCAuthInterceptor(authTokenProvider: authTokenProvider)
                ]
            )
        } catch {
            // The only documented failure here is "no resolver for the target"; `.dns` always has
            // one registered in the default registry, so this is unreachable in practice.
            preconditionFailure("Unable to build the gRPC transport: \(error)")
        }
    }

    /// Builds the per-call options, applying the 30s default deadline when the caller specifies
    /// none (FR-008, NFR-001).
    static func callOptions(timeout: Duration?) -> CallOptions {
        var options = CallOptions.defaults
        options.timeout = timeout ?? defaultCallTimeout
        return options
    }
}
