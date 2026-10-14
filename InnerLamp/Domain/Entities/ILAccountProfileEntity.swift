//
//  ILAccountProfileEntity.swift
//  InnerLamp
//

import Foundation

/// The signed-in user's server-side account profile (`GET /v1/users/me`) — Domain only.
struct ILAccountProfileEntity: Equatable {
    struct Temple: Equatable {
        let id: String
        let name: String
    }

    let email: String
    let isEmailVerified: Bool
    let phoneNumber: String
    /// Empty for accounts registered before the full name became required.
    let fullName: String
    /// Empty when the user has not entered a dharma name.
    let dharmaName: String
    let ordinationTemple: Temple?
    let avatarURL: URL?
    /// When `avatarURL` stops working; fetch the profile again after this.
    let avatarURLExpiresAt: Date?
}
