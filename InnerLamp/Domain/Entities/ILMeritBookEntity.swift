//
//  ILMeritBookEntity.swift
//  InnerLamp
//

import Foundation

/// What a donation was for (design handoff `DN_PURPOSES`).
enum ILMeritPurpose: Equatable {
    case threeJewels
    case monkMeal
    case templeLamp
    case construction
    case charityKitchen
    case lifeRelease
}

/// One offering (cúng dường) in the user's merit book.
struct ILMeritOfferingEntity: Equatable, Identifiable {
    let id: String
    let date: Date
    let purpose: ILMeritPurpose
    let templeName: String
    /// Whole VND.
    let amount: Int
    /// `true` once the temple has confirmed receiving the offering.
    let isConfirmedByTemple: Bool
}

/// The temple's thank-you letter (thư tùy hỷ).
struct ILMeritLetterEntity: Equatable {
    let body: String
    let signerName: String
    let signerTitle: String
}

/// A recurring monthly offering (hộ trì hằng tháng).
struct ILMeritMonthlySupportEntity: Equatable {
    /// Whole VND per month.
    let amount: Int
    let templeName: String
}

/// A public fundraising project of a temple (công khai tài chính).
struct ILMeritBuildProjectEntity: Equatable {
    struct Expense: Equatable {
        let label: String
        /// Whole VND.
        let amount: Int
    }

    let name: String
    /// Temple + round, e.g. "Chùa Từ Quang · đợt 2/2026".
    let subtitle: String
    /// Raised / goal, in million VND.
    let raisedMillions: Int
    let goalMillions: Int
    let updatedAt: Date
    let expenses: [Expense]
}

struct ILMeritBookEntity: Equatable {
    let offerings: [ILMeritOfferingEntity]
    let letter: ILMeritLetterEntity?
    let monthlySupport: ILMeritMonthlySupportEntity?
    let buildProject: ILMeritBuildProjectEntity?
}
