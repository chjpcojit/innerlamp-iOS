//
//  ILTemplesStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chùa trong danh sách "Tất cả chùa".
struct ILTemplesRowModel: Equatable, Identifiable {
    let id: String
    let name: String
    /// Tỉnh / thành rút gọn ("Ninh Bình").
    let place: String
    /// "Di sản Thế giới · Dựng năm 1428" — rỗng thì ẩn.
    let note: String
    /// Raw server thumbnail URL; `nil` shows the placeholder.
    let thumbnailURL: String?
}

/// UI state của màn "Tất cả chùa" — do `ILTemplesViewModel` sở hữu.
struct ILTemplesStateModel: Equatable {
    /// "179 ngôi chùa" — tổng của danh bạ, không đổi theo bộ lọc.
    var subtitle = ""
    var rows: [ILTemplesRowModel] = []
}
