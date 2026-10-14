//
//  ILLampGardenStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the "Vườn đèn" screen. Display strings and flags only; no UIKit.
struct ILLampGardenStateModel: Equatable {

    struct Chip: Equatable {
        /// `nil` is the "Tất cả" chip.
        let kind: ILLampKind?
        let title: String
        let count: String
        let isSelected: Bool
    }

    struct Card: Equatable, Identifiable {
        let id: String
        let kind: ILLampKind
        let kindName: String
        /// "Của bạn · Cầu an"
        let title: String
        /// "Cho mẹ Nguyễn Thị Hoa"
        let target: String
        /// "Còn 5 ngày" / "Sáng đến hết hôm nay"
        let remaining: String
    }

    var subtitle = ""
    var chips: [Chip] = []
    var cards: [Card] = []
    var hasMore = false
    /// No active lamp matches the current filter.
    var isEmpty = false

    static let initial = ILLampGardenStateModel()
}
