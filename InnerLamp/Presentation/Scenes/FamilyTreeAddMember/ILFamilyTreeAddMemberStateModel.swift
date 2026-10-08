//
//  ILFamilyTreeAddMemberStateModel.swift
//  InnerLamp
//

import Foundation

/// One selectable person in the relative picker.
struct ILFamilyTreeAddMemberPersonRow: Equatable {
    let id: String
    let name: String
    let meta: String
    let isSelected: Bool
}

/// UI state of the "Thêm người vào gia phả" screen — owned by `ILFamilyTreeAddMemberViewModel`,
/// read-only for the ViewController. `draft` mirrors raw input (may be invalid mid-edit); the
/// relative card, the preview line and the error message are already resolved here.
struct ILFamilyTreeAddMemberStateModel: Equatable {
    var draft = ILFamilyTreeAddMemberDraft()

    // Relative card + picker
    var relativeName = ""
    var relativeMeta = ""
    var preview = ""
    var people: [ILFamilyTreeAddMemberPersonRow] = []
    var isPickerOpen = false

    /// Gender as shown: follows the relative for a spouse and is then not editable.
    var shownGender: ILFamilyGender = .male
    var isGenderLocked = false

    // Validation: one error at a time, shown under the field it belongs to
    var errorField: ILFamilyTreeAddMemberField?
    var errorMessage: String?

    // Save in flight — disables the button
    var isSubmitting = false

    func error(for field: ILFamilyTreeAddMemberField) -> String? {
        errorField == field ? errorMessage : nil
    }
}
