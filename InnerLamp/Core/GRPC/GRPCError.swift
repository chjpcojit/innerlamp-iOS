//
//  GRPCError.swift
//  InnerLamp
//
//  Mirrors NetworkError's role for REST: a stable, Repository-consumable failure shape. No raw
//  grpc-swift error type crosses this boundary (FR-005). See Docs/Specs/GRPC/design.md §
//  "GRPCError — planned shape".
//
//  gRPC Swift 2.x: failures surface as `RPCError` (the library's error shape, carrying an
//  `RPCError.Code`), converted here into the named cases below. `RPCErrorConvertible` covers any
//  feature type that opts into defining its own status.
//

import Foundation
import GRPCCore

nonisolated enum GRPCError: Error, LocalizedError, Sendable {
    /// No token, or the token was rejected by the server — the gRPC analogue of REST's
    /// `.unauthorized`. No token-refresh is attempted here, same deferral as `Core/Networking`.
    case unauthenticated(message: String)
    /// Channel/server unreachable — analogue of `.noInternetConnection` / a REST 5xx that never
    /// reached the app.
    case unavailable(message: String)
    /// The default deadline (or an explicit caller deadline) elapsed — analogue of `.timeout`.
    case deadlineExceeded(message: String)
    /// Analogue of a REST 404.
    case notFound(message: String)
    /// Analogue of `.serverError(statusCode:message:)`.
    case serverError(message: String)
    /// The response failed to decode — analogue of `.decodingError`.
    case decodingError(Error)
    /// Safety net for any gRPC status code this layer doesn't name individually — mirrors
    /// `NetworkError.unknown(_:)`'s role.
    case unknown(code: Int, message: String)

    /// Maps an `RPCError`'s code to a named case — the gRPC equivalent of decoding
    /// `NetworkError` from an HTTP status code.
    init(_ rpcError: RPCError) {
        let message = rpcError.message
        switch rpcError.code {
        case .unauthenticated:
            self = .unauthenticated(message: message)
        case .unavailable:
            self = .unavailable(message: message)
        case .deadlineExceeded:
            self = .deadlineExceeded(message: message)
        case .notFound:
            self = .notFound(message: message)
        case .internalError:
            self = .serverError(message: message)
        default:
            self = .unknown(code: rpcError.code.rawValue, message: message)
        }
    }

    /// Maps *any* error grpc-swift may throw to this layer's own shape, so nothing raw leaks out
    /// (FR-005). `RPCError` is the common case; `RPCErrorConvertible` covers a feature-defined
    /// error carrying its own status; anything else is treated as a decode/transport fault.
    init(_ error: Error) {
        if let grpcError = error as? GRPCError {
            self = grpcError
        } else if let rpcError = error as? RPCError {
            self = GRPCError(rpcError)
        } else if let convertible = error as? RPCErrorConvertible {
            self = GRPCError(RPCError(convertible))
        } else {
            self = .decodingError(error)
        }
    }

    var errorDescription: String? {
        switch self {
        case .unauthenticated(let message):
            return "Not authenticated for this gRPC call: \(message)"
        case .unavailable(let message):
            return "gRPC service unavailable: \(message)"
        case .deadlineExceeded(let message):
            return "gRPC call deadline exceeded: \(message)"
        case .notFound(let message):
            return "gRPC resource not found: \(message)"
        case .serverError(let message):
            return "gRPC server error: \(message)"
        case .decodingError(let error):
            return "Failed to decode gRPC response: \(error.localizedDescription)"
        case .unknown(let code, let message):
            return "Unknown gRPC error (code \(code)): \(message)"
        }
    }
}
