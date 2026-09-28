//
//  ILEditProfileStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the Edit Profile screen — owned by `ILEditProfileViewModel`, read-only for the
/// `ViewController`. No UIKit, no business logic. Text fields mirror raw input (may be invalid
/// mid-edit); every display string (initials, visibility labels, errors) is already resolved here.
struct ILEditProfileStateModel: Equatable {
    // Avatar
    var initials: String = ""

    // Form fields (raw input mirrors)
    var displayName: String = ""
    var phoneNumber: String = ""
    var templeName: String = ""
    var bio: String = ""

    // Validation
    var displayNameError: String?

    // "Hiển thị trong đạo tràng"
    var streakVisibilityTitle: String = ""
    var journalVisibilityTitle: String = ""
    var offeringHistoryVisibilityTitle: String = ""

    // Save in flight — disables the "Lưu" action
    var isSaving: Bool = false

    static let initial = ILEditProfileStateModel()
}
