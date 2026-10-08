//
//  ILMemorialEditStateModel.swift
//  InnerLamp
//

import Foundation

/// 1 selectable choice of the form (relationship chip, picker row, lead time, reminder hour).
struct ILMemorialOptionModel: Equatable, Identifiable {
    let id: Int
    let title: String
    let isSelected: Bool
}

/// UI state of the add / edit form ("Thêm người thân" / "Sửa thông tin").
struct ILMemorialEditStateModel: Equatable {
    var title: String = ""
    var saveTitle: String = ""
    /// Edit mode only — shows "Xóa khỏi sổ giỗ".
    var canDelete: Bool = false
    var isSaving: Bool = false

    var name: String = ""
    /// "Vui lòng nhập họ và tên" after a save with an empty name; cleared on the next edit.
    var nameError: String?
    /// `id` = index in `ILMemorialRelationship.allCases`.
    var relationships: [ILMemorialOptionModel] = []

    var calendarKind: ILMemorialCalendarKind = .lunar
    var dayOptions: [ILMemorialOptionModel] = []
    var monthOptions: [ILMemorialOptionModel] = []
    /// `id` = the year, `0` = "Không rõ".
    var yearOptions: [ILMemorialOptionModel] = []
    var selectedDay: Int = 1
    var selectedMonth: Int = 1
    var selectedYear: Int = 0

    var previewNext: String = ""
    var previewDetail: String = ""

    var note: String = ""

    var reminderOn: Bool = true
    /// `id` = days before (0 = on the day).
    var leadOptions: [ILMemorialOptionModel] = []
    /// `id` = hour of day.
    var timeOptions: [ILMemorialOptionModel] = []
    var syncOn: Bool = true

    static let initial = ILMemorialEditStateModel()
}
