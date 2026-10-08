//
//  ILSutrasStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chip lọc (mục đích/tông phái hoặc độ dài) trên header màn "Kinh sách".
struct ILSutrasFilterModel<Value: Equatable>: Equatable, Identifiable {
    let id: String
    let label: String
    let value: Value
    let isSelected: Bool
}

/// 1 thẻ bộ kinh trong danh sách — bản presentation của `ILSutraEntity` với chuỗi đã format.
struct ILSutrasItemModel: Equatable, Identifiable {
    let id: String
    let name: String
    let originalName: String
    /// "~22 phút" / "2 giờ 10 phút"; rỗng khi server chưa có ước tính.
    let durationText: String
    /// "Thích Minh Châu · Nam tông"; rỗng khi không có cả hai.
    let translatorLine: String
    let isDownloaded: Bool
    let hasAudio: Bool
    let purposeLabels: [String]
}

/// UI state cho màn "Kinh sách" — do `ILSutrasViewModel` sở hữu. Không UIKit, không business logic.
struct ILSutrasStateModel: Equatable {
    var subtitle: String = ""
    var categories: [ILSutrasFilterModel<ILSutraCategory>] = []
    var lengths: [ILSutrasFilterModel<ILSutraLengthFilter>] = []
    /// "153 bản kinh" / "3 bản kinh phù hợp".
    var countText: String = ""
    var items: [ILSutrasItemModel] = []
    var emptyTitle: String = ""
    var emptyMessage: String = ""
    /// Footer spinner — covers the first page as well as later pages.
    var isLoadingMore: Bool = false
    var hasMore: Bool = false

    static let initial = ILSutrasStateModel()
}
