//
//  ILAdministrativeUnitEntity.swift
//  InnerLamp
//

import Foundation

/// A province or centrally-run city of the 2-level administrative system in force since
/// 01/07/2025 (34 units; no district level).
nonisolated struct ILProvinceEntity: Equatable, Hashable, Sendable {
    enum Kind: Equatable, Hashable, Sendable {
        case province
        case city
        /// A `type` value this app version does not know yet.
        case other
    }

    /// Opaque string code (e.g. `"79"`) — never parse it as a number. This is the value other
    /// endpoints take (`province_code`).
    let code: String
    /// Short name, e.g. `"Hồ Chí Minh"`.
    let name: String
    /// Full name, e.g. `"Thành phố Hồ Chí Minh"`.
    let fullName: String
    let kind: Kind
}

/// A ward / commune / special zone, the second level under a `ILProvinceEntity`.
nonisolated struct ILWardEntity: Equatable, Hashable, Sendable {
    enum Kind: Equatable, Hashable, Sendable {
        case ward
        case commune
        case specialZone
        /// A `type` value this app version does not know yet.
        case other
    }

    /// Opaque string code (e.g. `"26737"`) — the value other endpoints take (`ward_code`).
    let code: String
    let name: String
    let fullName: String
    let kind: Kind
    let provinceCode: String
}
