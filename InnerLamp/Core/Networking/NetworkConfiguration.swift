//
//  NetworkConfiguration.swift
//  InnerLamp
//
//  Builds the one `URLSessionConfiguration`/`URLSession` the app uses, so timeout and
//  connectivity behavior are defined in one place instead of inherited from `URLSession.shared`.
//  See Docs/Specs/Networking/design.md § "Layers & components".
//

import Foundation

/// `nonisolated` throughout: this is a pure factory namespace with no main-actor state, and it is
/// called from `NetworkServiceImpl`'s nonisolated actor initializer (default arguments are
/// evaluated in the caller's isolation domain).
enum NetworkConfiguration {
    /// Request timeout — time allowed for the request to complete once it starts.
    nonisolated static let requestTimeoutInterval: TimeInterval = 30
    /// Resource timeout — time allowed for the entire resource (including retries by the
    /// system, redirects, etc.) to complete.
    nonisolated static let resourceTimeoutInterval: TimeInterval = 60
    /// Whether the session waits for connectivity to become available instead of failing
    /// immediately when the device is briefly offline.
    nonisolated static let waitsForConnectivity = false

    nonisolated static func makeConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeoutInterval
        configuration.timeoutIntervalForResource = resourceTimeoutInterval
        configuration.waitsForConnectivity = waitsForConnectivity
        return configuration
    }

    nonisolated static func makeSession() -> URLSession {
        URLSession(configuration: makeConfiguration())
    }
}
