//
//  ILUserMeDTO.swift
//  InnerLamp
//

import Foundation

/// `data` of `GET /v1/users/me` — Data layer. Contract: backend `docs/specs/api/openapi.yaml`
/// (`/v1/users/me`).
///
/// No `CodingKeys`: `NetworkServiceImpl` decodes with `.convertFromSnakeCase`. Optional keys are
/// **absent** (not null / "") on the wire when unset — including `full_name` for accounts created
/// before it became required. There is no `id` or `created_at`.
nonisolated struct ILUserMeDTO: Decodable, Sendable {
    let email: String
    let emailVerified: Bool
    /// E.164, e.g. `+84901234567`.
    let phoneNumber: String
    /// Absent for accounts registered before the full name became required.
    let fullName: String?
    let dharmaName: String?
    let ordinationTemple: ILUserMeTempleDTO?
    /// Signed URL, valid ~15 minutes.
    let avatarUrl: String?
    /// RFC 3339 UTC; present together with `avatarUrl`.
    let avatarUrlExpiresAt: String?
}

nonisolated struct ILUserMeTempleDTO: Decodable, Sendable {
    let id: String
    let name: String
}
