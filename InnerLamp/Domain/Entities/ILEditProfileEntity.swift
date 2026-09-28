//
//  ILEditProfileEntity.swift
//  InnerLamp
//

import Foundation

/// Visibility level of one piece of practice data inside the user's sangha
/// ("Hiển thị trong đạo tràng" group of the Edit Profile screen).
enum ILEditProfileVisibility: Equatable {
    /// Everyone in the sangha can see it ("Công khai").
    case publicToSangha
    /// Only the user can see it ("Chỉ mình tôi").
    case onlyMe
    /// Shown without the user's name ("Ẩn danh").
    case anonymous
}

/// Editable profile of the current user — business fields only, no UI state or formatted strings.
/// Initials, validation errors and saving flags belong to `ILEditProfileStateModel` (Presentation).
struct ILEditProfileEntity: Equatable {
    /// Dharma name or the name the user wants to be called ("Pháp danh hoặc tên gọi").
    var displayName: String = ""
    /// E.164-style phone number the account is registered with. Read-only on this screen.
    var phoneNumber: String = ""
    /// Temple / sangha the user belongs to ("Chùa / đạo tràng").
    var templeName: String = ""
    /// Short free-text introduction ("Đôi dòng về bạn"). Empty when not set.
    var bio: String = ""

    // Visibility inside the sangha
    var streakVisibility: ILEditProfileVisibility = .publicToSangha
    var journalVisibility: ILEditProfileVisibility = .onlyMe
    var offeringHistoryVisibility: ILEditProfileVisibility = .anonymous

    static let empty = ILEditProfileEntity()
}
