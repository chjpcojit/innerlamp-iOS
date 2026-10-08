//
//  ILFamilyTreeMemberStateModel.swift
//  InnerLamp
//

import Foundation

enum ILFamilyTreeMemberMode: Equatable {
    case view
    case edit
}

/// One "key  value" row of the THÔNG TIN card.
struct ILFamilyTreeMemberFactModel: Equatable {
    let key: String
    let value: String
    /// Underlined, tappable value ("Bài vị thờ tại").
    let isLink: Bool
    /// Accent colour for the value ("Với bạn" style emphasis).
    let isEmphasized: Bool
}

/// UI state of the member profile screen — owned by `ILFamilyTreeMemberViewModel`, read-only for
/// the ViewController. The view-mode texts are already resolved; `draft` mirrors raw edit input
/// (may be invalid mid-edit) and the error message is already localized.
struct ILFamilyTreeMemberStateModel: Equatable {
    var mode: ILFamilyTreeMemberMode = .view

    // View mode
    var look = ILFamilyTreeMedallionLook(gender: .male, isLiving: true, isFounder: false, isClanHead: false)
    var name = ""
    var meta = ""
    var status = ""
    var role: String?
    /// "Với bạn" chip; `nil` hides it.
    var kinship: String?
    var facts: [ILFamilyTreeMemberFactModel] = []
    var note: String?
    /// Deceased members show the TƯỞNG NIỆM tiles.
    var showsMemorial = false
    var relations: [ILFamilyTreeRelationModel] = []

    // Edit mode
    var draft = ILFamilyTreeMemberDraft()
    var errorField: ILFamilyTreeMemberField?
    var errorMessage: String?
    /// Save in flight — disables the buttons.
    var isSubmitting = false

    func error(for field: ILFamilyTreeMemberField) -> String? {
        errorField == field ? errorMessage : nil
    }
}
