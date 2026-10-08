//
//  GRPCUncheckedSendable.swift
//  InnerLamp
//
//  `AuthTokenProviding` and `LoggingService` are not themselves `Sendable`, but every conformer
//  this layer is given (a Keychain reader, the Sentry singleton) is an immutable, thread-safe
//  reader — the same trust boundary `NetworkServiceImpl` already relies on. gRPC Swift 2.x's
//  `ClientInterceptor` is `Sendable`, so this box carries that documented trust across the
//  compiler's `Sendable` check without loosening any Core protocol.
//

import Foundation

nonisolated struct GRPCUncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
}
