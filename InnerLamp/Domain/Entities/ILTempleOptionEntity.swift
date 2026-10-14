//
//  ILTempleOptionEntity.swift
//  InnerLamp
//

import Foundation

/// One selectable temple of a picker — the light row of `GET /v1/temples/options`. Domain layer.
///
/// Deliberately smaller than `ILTempleSummaryEntity`: no image, no address, no heritage data.
nonisolated struct ILTempleOptionEntity: Equatable {
    /// Stable server id (`"temple_north_011"`) — the value other endpoints take as a temple id.
    let id: String
    let name: String
    /// Province display name; always present, may be empty.
    let province: String
    /// `nil` for a temple the backend has not re-seeded with a province code yet.
    let provinceCode: String?
}
