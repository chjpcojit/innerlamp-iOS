//
//  NetworkError.swift
//  InnerLamp
//
//  Relocated from HTTPMethod.swift (pure move, no case renamed, no behaviour change) — see
//  Docs/Specs/Networking/design.md § "Layers & components".
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case noInternetConnection
    case timeout
    case unknown(Error)
    /// The response envelope's discriminator — carries the server's `error.code` /
    /// `error.message` / `error.type` when `ApiResponse.success == false`, plus the envelope's
    /// `details` (`map[string]any`), which some failure codes use to carry extra data (e.g.
    /// `{"locked_until": "..."}` / `{"retry_after_seconds": N}`).
    /// See Docs/Specs/Networking/design.md § "Envelope contract".
    case apiError(code: String, message: String, type: String, details: [String: AnyCodable]?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data was returned from the server"
        case .decodingError(let error):
            return "Data returned from the server is not in the correct format. \(error.localizedDescription)"
        case .encodingError(let error):
            return "Error encoding data. \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server returned an error: \(statusCode) - \(message ?? "")"
        case .unauthorized:
            return "You are not authorized to access this content"
        case .noInternetConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return error.localizedDescription
        case .apiError(let code, let message, let type, _):
            return "\(type) error (\(code)): \(message)"
        }
    }
}
