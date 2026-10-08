//
//  ILDeitySummaryDTO.swift
//  InnerLamp
//

import Foundation

/// Wire format of one row of `/v1/deities/top` and `/v1/deities` — Data layer. Contract:
/// `docs/specs/features/deity/api-contract.md` in the backend repo (`DeitySummary`). All fields
/// are non-null strings. The detail (`DeityDetail`) reuses `ILDeityDTO`.
///
/// `type` reuses `ILDeityTypeDTO`: an unknown value fails decoding, the same policy as the bundled
/// catalog, because `ILDeityKind` is closed and exhaustively switched on in Presentation.
nonisolated struct ILDeitySummaryDTO: Codable, Sendable {
    let id: String
    let type: ILDeityTypeDTO
    let nameVi: String
    let nameSanskrit: String
    let nameChinese: String
    let titleHonorific: String
    let thumbnailUrl: String
    let imageUrl: String
    let coreVirtue: String
    let pureLand: String
}
