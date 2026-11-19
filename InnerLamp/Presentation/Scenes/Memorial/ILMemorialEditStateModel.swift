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
    /// Server id, or the draft UUID. Used for the photo cache key only.
    var entryID: String = ""
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
    /// EN: The leap-month switch exists only for a lunar date without a year (contract §2.3).
    /// VI: Công tắc tháng nhuận chỉ có với ngày âm không năm (contract §2.3).
    var showLeapMonth: Bool = false
    var leapMonthOn: Bool = false

    var previewNext: String = ""
    var previewDetail: String = ""

    var note: String = ""

    var reminderOn: Bool = true
    /// `id` = days before (0 = on the day).
    var leadOptions: [ILMemorialOptionModel] = []
    /// `id` = hour of day.
    var timeOptions: [ILMemorialOptionModel] = []
    /// EN: The system permission is denied; the setting still stands, so show "Mở Cài đặt".
    /// VI: Quyền hệ thống bị từ chối; cấu hình vẫn giữ, nên hiện "Mở Cài đặt".
    var notificationsDenied: Bool = false

    /// EN: Photo block only when the build flag is on (D4). URL is session state, never stored.
    /// VI: Khối ảnh chỉ hiện khi cờ build bật (D4). URL chỉ sống trong phiên, không lưu.
    var photoEnabled: Bool = false
    var photoURL: String?
    var canRemovePhoto: Bool = false

    static let initial = ILMemorialEditStateModel()
}
