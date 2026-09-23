//
//  APIEnvelope.swift
//  InnerLamp
//
//  Models the backend's standard `ApiResponse` / `ErrorDetail` wrapper, field for field.
//  Never referenced outside `NetworkService` — a feature-level DTO never models the envelope
//  itself. See Docs/Specs/Networking/design.md § "Envelope contract".
//

import Foundation

/// Mirrors the Go `ErrorDetail` struct. All three fields are `String` and required — the
/// envelope's `error` object either carries all three or is absent entirely.
nonisolated struct APIErrorDetail: Decodable {
    let code: String
    let message: String
    let type: String
}

/// Mirrors the Go `ApiResponse` struct. `data` and `error` are mutually exclusive in practice
/// (`success == true` ⇒ `data` may be present, `success == false` ⇒ `error` is present), but both
/// are modeled optional to match the backend's `omitempty` tags exactly.
nonisolated struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIErrorDetail?
    /// `map[string]any` on the backend — a dynamic JSON value, hence `AnyCodable`.
    let details: [String: AnyCodable]?
}

/// Type-erased `Decodable` wrapper for JSON values whose shape isn't known ahead of time.
/// Used only for `APIEnvelope.details` — never for anything a caller decodes as a concrete type.
///
/// `@unchecked Sendable` — every value it holds is produced by a `Decoder` and never mutated
/// afterwards, so sharing one across isolation domains is safe. Explicit because `NetworkError`
/// (which now carries these details) must stay `Sendable` to cross the `NetworkServiceImpl` actor
/// boundary.
nonisolated struct AnyCodable: Decodable, @unchecked Sendable {
    let value: Any

    /// Wraps an already-decoded JSON value — for callers that construct an envelope by hand
    /// (tests, fixtures) rather than decoding one.
    init(value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value in APIEnvelope.details"
            )
        }
    }
}
