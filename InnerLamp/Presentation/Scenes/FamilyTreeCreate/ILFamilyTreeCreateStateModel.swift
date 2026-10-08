//
//  ILFamilyTreeCreateStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the "Tạo gia phả" screen — owned by `ILFamilyTreeCreateViewModel`, read-only for the
/// ViewController. Text fields mirror raw input (may be invalid mid-edit); the header texts and the
/// error message are already resolved here.
struct ILFamilyTreeCreateStateModel: Equatable {
    // Form fields (raw input mirrors)
    var clanName = ""
    var hometown = ""
    var founderName = ""
    var birthYear = ""
    var isFounderLiving = false
    var deathYear = ""
    var anniversary = ""
    var spouseName = ""

    // Header card — follows the form as the user types
    var headerTitle = ""
    var headerSubtitle = ""

    // Validation: one error at a time, shown under the field it belongs to
    var errorField: ILFamilyTreeCreateField?
    var errorMessage: String?

    // Save in flight — disables the button
    var isSubmitting = false

    func error(for field: ILFamilyTreeCreateField) -> String? {
        errorField == field ? errorMessage : nil
    }

    var draft: ILFamilyTreeCreateDraft {
        ILFamilyTreeCreateDraft(
            clanName: clanName, hometown: hometown, founderName: founderName, birthYear: birthYear,
            isFounderLiving: isFounderLiving, deathYear: deathYear, anniversary: anniversary, spouseName: spouseName
        )
    }

    static let initial = ILFamilyTreeCreateStateModel(
        headerTitle: "familyTreeCreate.header.title.placeholder".localized,
        headerSubtitle: "familyTreeCreate.header.subtitle.placeholder".localized
    )
}
