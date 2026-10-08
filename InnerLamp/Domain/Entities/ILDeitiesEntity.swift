//
//  ILDeitiesEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity cho màn danh sách "Chư Phật & Bồ Tát" (`buddhas` trong design handoff) —
/// Domain layer only.
///
/// Catalog từ server (`ILDeitySummaryEntity`, cùng id với màn chi tiết `Deity`). Trạng thái UI (bộ
/// lọc đang chọn, nhãn `.localized`, placeholder "Đang cập nhật") nằm trên `ILDeitiesStateModel` —
/// xem `references/data_layer_boundaries.md`.
struct ILDeitiesEntity: Equatable {
    /// Toàn bộ catalog theo thứ tự server (Chư Phật trước, rồi Chư Bồ Tát).
    let deities: [ILDeitySummaryEntity]

    static let empty = ILDeitiesEntity(deities: [])
}
