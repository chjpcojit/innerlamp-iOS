//
//  ILFamilyChronicleEntity.swift
//  InnerLamp
//

import Foundation

/// One dated entry of the clan's history ("1812 — Lập ấp Hành Thiện").
struct ILFamilyMilestoneEntity: Equatable, Identifiable {
    let id: String
    var year: Int?
    var text: String
}

/// "Phả ký dòng họ" — the written record kept next to a clan book. Every field is optional text:
/// an empty string means "not written yet", and the screen shows its "Chưa có …" placeholder.
struct ILFamilyChronicleEntity: Equatable {
    /// Origin story: hometown, founder, how the clan settled.
    var origin: String
    var milestones: [ILFamilyMilestoneEntity]
    /// "Nhà thờ họ": name, address and the lunar day of the yearly clan gathering ("Ngày 20 tháng Chạp").
    var shrineName: String
    var shrineAddress: String
    var annualGathering: String
    /// "Hoành phi": Han characters, then the reading / meaning.
    var plaqueHan: String
    var plaqueMeaning: String
    /// "Câu đối": the upper and lower line.
    var coupletUpper: String
    var coupletLower: String
    /// "Gia huấn": the elders' sayings and house rules.
    var teachings: String

    static let empty = ILFamilyChronicleEntity(
        origin: "", milestones: [], shrineName: "", shrineAddress: "", annualGathering: "",
        plaqueHan: "", plaqueMeaning: "", coupletUpper: "", coupletLower: "", teachings: ""
    )
}
