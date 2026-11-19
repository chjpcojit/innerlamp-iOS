//
//  ILMemorialEntity.swift
//  InnerLamp
//

import Foundation

/// Who the death anniversary (giỗ) is for. Raw values are what Core Data stores.
enum ILMemorialRelationship: String, CaseIterable, Equatable {
    case paternalGrandfather
    case paternalGrandmother
    case maternalGrandfather
    case maternalGrandmother
    case father
    case mother
    case spouse
    case sibling
    case child
    case other
}

/// Which calendar the stored day/month are in. Raw values are what Core Data stores.
enum ILMemorialCalendarKind: String, Equatable {
    case lunar
    case solar
}

/// "Remind me `leadDays` days before, at `hour:minute`" — `leadDays == 0` means on the day.
struct ILMemorialReminder: Equatable {
    var leadDays: Int
    var hour: Int
    var minute: Int
}

/// 1 person in the memorial book (Sổ giỗ chạp). Raw business data only: the next-anniversary date,
/// days label, ordinal text and every other display string are derived by the use case / ViewModel.
struct ILMemorialEntity: Equatable, Identifiable {
    /// Server id as a string, or a local UUID while the entry is still a draft. The wire type is
    /// `Int64` (see `ILMemorialDTO`); navigation and the draft need a string token.
    let id: String
    var name: String
    var relationship: ILMemorialRelationship
    var calendarKind: ILMemorialCalendarKind
    /// 1...30 for a lunar date, 1...31 for a solar date.
    var day: Int
    /// 1...12.
    var month: Int
    /// Year of death; `nil` when unknown.
    var deathYear: Int?
    /// EN: The lunar leap-month flag of a year-less lunar date (BR-MEM-04).
    /// VI: Cờ tháng nhuận của ngày âm không năm (BR-MEM-04).
    var deathLeapMonth: Bool
    var note: String
    /// `nil` when reminders are off.
    var reminder: ILMemorialReminder?
    /// EN: Signed URL from the current server response. Never persisted (D8); `nil` in the cache.
    /// VI: URL có chữ ký của response hiện tại. Không bao giờ lưu xuống máy (D8); `nil` trong cache.
    var photoURL: URL?

    init(
        id: String,
        name: String,
        relationship: ILMemorialRelationship,
        calendarKind: ILMemorialCalendarKind,
        day: Int,
        month: Int,
        deathYear: Int?,
        deathLeapMonth: Bool = false,
        note: String,
        reminder: ILMemorialReminder?,
        photoURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.calendarKind = calendarKind
        self.day = day
        self.month = month
        self.deathYear = deathYear
        self.deathLeapMonth = deathLeapMonth
        self.note = note
        self.reminder = reminder
        self.photoURL = photoURL
    }
}

/// The next time an entry's giỗ falls, relative to a given "now".
struct ILMemorialNextAnniversary: Equatable {
    /// Start of the solar day of the next giỗ (today counts).
    let date: Date
    /// 0 = today.
    let daysUntil: Int
    /// Which giỗ this is (0 = died today, 1 = giỗ đầu, 2 = giỗ hết, n ≥ 3 = lần thứ n); `nil` when
    /// the death year is unknown.
    let ordinal: Int?
    /// Lunar equivalent of `date` — shown in the preview of a solar entry.
    let lunarDay: Int
    let lunarMonth: Int
}

/// An entry paired with its next anniversary, as the list needs it.
struct ILMemorialItem: Equatable, Identifiable {
    let entry: ILMemorialEntity
    let next: ILMemorialNextAnniversary

    var id: String { entry.id }
}
