//
//  GRPCConfiguration.swift
//  InnerLamp
//
//  Builds the one gRPC channel the app uses for every RPC — the gRPC analogue of
//  NetworkConfiguration's single URLSession. See Docs/Specs/GRPC/design.md § "Channel lifecycle".
//
//  Migrated to gRPC Swift 1.x (the `GRPC` product) because gRPC Swift 2 requires iOS 18.0+,
//  while InnerLamp supports iOS 15.0+. In 1.x the shared object is a `ClientConnection`
//  (channel) plus the `EventLoopGroup` that backs it — both held for the app's lifetime.
//

import GRPC
import NIOCore

/// `nonisolated` throughout — a pure factory namespace with no main-actor state, mirroring
/// `NetworkConfiguration`. The resulting channel is `Sendable` and is held for the app's
/// lifetime, called from any isolation domain.
nonisolated enum GRPCConfiguration {
    /// Default per-call deadline when a caller specifies none — matches
    /// `NetworkConfiguration.requestTimeoutInterval`'s existing REST request timeout
    /// (FR-008, NFR-001).
    static let defaultCallTimeout: TimeAmount = .seconds(30)

    /// Owns the shared channel *and* the event-loop group that keeps it alive. The group must
    /// outlive the channel, so both are returned together rather than leaking the group.
    final class ChannelLifetime: @unchecked Sendable {
        let channel: any GRPCChannel
        let eventLoopGroup: any EventLoopGroup

        init(channel: any GRPCChannel, eventLoopGroup: any EventLoopGroup) {
            self.channel = channel
            self.eventLoopGroup = eventLoopGroup
        }
    }

    /// Builds the shared channel for `APIConfig`'s active `Environment`. Server-authenticated
    /// TLS only — no identity provider is configured, so no client certificate is ever presented
    /// (FR-003; mutual TLS is out of scope).
    static func makeChannelLifetime() -> ChannelLifetime {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let channel = ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: APIConfig.grpcHost, port: APIConfig.grpcPort)
        return ChannelLifetime(channel: channel, eventLoopGroup: group)
    }

    /// Wraps the shared channel in the generic call client `GRPCService` calls through. Built
    /// once, at the composition root (`DIContainer`) — never per call, per FR-001.
    static func makeClient(channel: any GRPCChannel) -> GRPCAnyServiceClient {
        GRPCAnyServiceClient(
            channel: channel,
            defaultCallOptions: callOptions(timeout: nil)
        )
    }

    /// Builds the per-call options, applying the 30s default deadline when the caller specifies
    /// none (FR-008, NFR-001).
    static func callOptions(timeout: TimeAmount?) -> CallOptions {
        CallOptions(timeLimit: .timeout(timeout ?? defaultCallTimeout))
    }
}
