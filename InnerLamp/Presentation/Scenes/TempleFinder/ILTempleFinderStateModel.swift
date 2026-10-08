//
//  ILTempleFinderStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 chùa trong danh sách "Chọn chùa tu tập".
struct ILTempleFinderRowModel: Equatable, Identifiable {
    let id: String
    let name: String
    let subtitle: String
    /// Chùa tu tập hiện tại — hiện nhãn "Chùa của bạn" thay cho nút "Chọn".
    let isMine: Bool
}

/// Chip lọc theo miền.
struct ILTempleFinderRegionChipModel: Equatable {
    let filter: ILTempleFinderRegionFilter
    let label: String
    let isSelected: Bool
}

/// Trường của form "Đề xuất thêm chùa" đang bị báo lỗi.
enum ILTempleFinderAddField: Equatable {
    case name
    case province
}

/// Form "Đề xuất thêm chùa" đang mở.
struct ILTempleFinderAddFormModel: Equatable {
    /// Tên điền sẵn từ ô tìm kiếm khi form vừa mở.
    let prefillName: String
    let errorMessage: String?
    let errorField: ILTempleFinderAddField?
}

/// Trạng thái UI của màn "Chọn chùa tu tập" — do `ILTempleFinderViewModel` sở hữu.
struct ILTempleFinderStateModel: Equatable {
    var subtitle = ""
    var rows: [ILTempleFinderRowModel] = []
    /// Khác `nil` khi không có chùa nào khớp bộ lọc.
    var emptyText: String?
    /// Lời nhắn sau khi gửi đề xuất.
    var sentMessage: String?
    /// Khác `nil` → hiện form thay cho danh sách.
    var addForm: ILTempleFinderAddFormModel?
}
