//
//  ILLibraryStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 ô truy cập nhanh trong lưới 2 cột đầu màn (Kinh sách / Thiền định / Pháp thoại / Phật & Bồ Tát).
struct ILLibraryQuickAccessModel: Equatable, Identifiable {
    let id: String
    let kind: ILLibraryQuickAccessKind
    let label: String
    let subtitle: String
    let glyph: String
    let tone: ILLibraryTone
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
    var quickAccess: [ILLibraryQuickAccessModel] = []
    var featured: ILLibraryFeaturedModel?
    var deitiesTitle: String = ""
    var deitiesViewAllText: String = ""
    /// Dùng chung `ILHomeDeityModel` với carousel "Thư viện Phật & Bồ Tát" ở Trang chủ — cùng
    /// hình dạng dữ liệu hiển thị (badge loại, danh xưng, ngày vía).
    var deities: [ILHomeDeityModel] = []
    /// "Đang cập nhật" when the server answered with nothing; empty while loading or when cards exist.
    var deitiesEmptyText: String = ""
    /// `true` while the first load is in flight and there are no cards yet (skeleton cards).
    var deitiesLoading: Bool = false
    var sutrasSectionTitle: String = ""
    var sutrasViewAllText: String = ""
    var rows: [ILLibraryRowModel] = []
    var emptyTitle: String = ""
    var emptyMessage: String = ""

    var isListEmpty: Bool { rows.isEmpty }

    static let initial = ILLibraryStateModel()
}
