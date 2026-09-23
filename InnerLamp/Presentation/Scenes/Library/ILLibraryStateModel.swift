//
//  ILLibraryStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chip lọc nhóm (Tất cả / Kinh văn / Thiền dẫn / Pháp thoại).
struct ILLibraryChipModel: Equatable {
    let category: ILLibraryCategory
    let title: String
    let isSelected: Bool
}

/// Thẻ nổi bật đã sẵn sàng hiển thị (CTA đã ghép thời lượng).
struct ILLibraryFeaturedModel: Equatable {
    let id: String
    let eyebrow: String
    let title: String
    let ctaTitle: String
}

/// 1 hàng nội dung đã sẵn sàng hiển thị (thời lượng đã format).
struct ILLibraryRowModel: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let durationText: String
    let tone: ILLibraryTone
}

/// Trạng thái UI của màn Thư viện — do `ILLibraryViewModel` sở hữu, `ViewController` chỉ đọc để render.
struct ILLibraryStateModel: Equatable {
    var chips: [ILLibraryChipModel] = []
    var featured: ILLibraryFeaturedModel?
    var sectionTitle: String = ""
    var rows: [ILLibraryRowModel] = []
    var emptyTitle: String = ""
    var emptyMessage: String = ""

    var isListEmpty: Bool { rows.isEmpty }

    static let initial = ILLibraryStateModel()
}
