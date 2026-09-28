//
//  ILDeitiesEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity cho màn danh sách "Chư Phật & Bồ Tát" (`buddhas` trong design handoff) —
/// Domain layer only.
///
/// Chỉ là catalog đầy đủ các vị, dùng lại `ILDeityEntity` (cùng aggregate với màn chi tiết `Deity`)
/// thay vì sao chép trường. Trạng thái UI (bộ lọc đang chọn, nhãn `.localized`, chuỗi ngày vía đã
/// format) nằm trên `ILDeitiesStateModel` — xem `references/data_layer_boundaries.md`.
struct ILDeitiesEntity: Equatable {
    /// Toàn bộ catalog, giữ nguyên thứ tự file (Chư Phật trước, rồi Chư Bồ Tát).
    let deities: [ILDeityEntity]
}
