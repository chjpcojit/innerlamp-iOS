//
//  ILDeitySummaryEntity.swift
//  InnerLamp
//

import Foundation

/// Light Buddha / Bodhisattva row used by the "top" carousel and the "show all" bodhisattva list.
/// The full profile (fetched by id on tap) is `ILDeityEntity`.
///
/// `thumbnailURL` / `imageURL` are the raw server strings: absolute, loadable URLs (WebP) on the
/// dev backend. Either may be empty, in which case Presentation falls back to a placeholder.
nonisolated struct ILDeitySummaryEntity: Equatable, Identifiable {
    let id: String
    let kind: ILDeityKind
    let nameVi: String
    let nameSanskrit: String
    let nameChinese: String
    let titleHonorific: String
    let thumbnailURL: String
    let imageURL: String
    let coreVirtue: String
    let pureLand: String
}
