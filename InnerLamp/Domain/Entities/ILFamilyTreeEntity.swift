//
//  ILFamilyTreeEntity.swift
//  InnerLamp
//

import Foundation

enum ILFamilyGender: Equatable {
    case male
    case female
}

/// A lunar day + month, used for a death anniversary ("ngày giỗ") — Domain keeps the numbers,
/// the display text ("15 tháng Chạp") is built in the Presentation layer.
struct ILFamilyLunarDate: Equatable {
    let day: Int
    let month: Int
}

/// One person in the clan book.
// @ai: assumption — see Docs/Assumptions/FamilyTree/AS-FamilyTree-001-member-data-model.md A spouse who married in is a member of their own with `spouseID`
/// pointing at the partner and no `parentID`; blood descendants point at their father/mother via
/// `parentID`.
struct ILFamilyMemberEntity: Equatable, Identifiable {
    let id: String
    var name: String
    var gender: ILFamilyGender
    var birthYear: Int?
    var deathYear: Int?
    var anniversary: ILFamilyLunarDate?
    var note: String?
    let parentID: String?
    let spouseID: String?
    var isClanHead: Bool
    /// Where a living member lives now / where a deceased member is buried. Optional and defaulted,
    /// so existing call sites keep compiling — see AS-FamilyTreeAddMember-003.
    var residence: String? = nil
    var burialPlace: String? = nil
    /// Buddhist name and the temple that keeps the ancestral tablet — edited on the member profile,
    /// see AS-FamilyTreeMember-001.
    var dharmaName: String? = nil
    var tabletTemple: String? = nil

    var isLiving: Bool { deathYear == nil }
}

/// Which side of the viewer's family a clan book is: father's line ("nội") or mother's ("ngoại").
// @ai: assumption — see Docs/Assumptions/FamilyTree/AS-FamilyTree-010-two-books-paternal-maternal.md
enum ILFamilyTreeSide: Equatable {
    case paternal
    case maternal
}

/// Pure business entity for FamilyTree — Domain layer only (no UI-only fields).
struct ILFamilyTreeEntity: Equatable {
    var clanName: String
    var hometown: String
    var members: [ILFamilyMemberEntity]
    /// Identifies the book once the user has more than one. Defaulted, so existing call sites compile.
    var id: String = UUID().uuidString
    var side: ILFamilyTreeSide = .paternal
    /// "Phả ký dòng họ" — the written record of the clan (origin, milestones, shrine, teachings).
    var chronicle: ILFamilyChronicleEntity = .empty

    static let empty = ILFamilyTreeEntity(clanName: "", hometown: "", members: [])
}
