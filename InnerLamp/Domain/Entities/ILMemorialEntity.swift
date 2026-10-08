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
    var note: String
    /// `nil` when reminders are off.
    var reminder: ILMemorialReminder?
    /// Also create a Reminders item (not built yet — see `Docs/Specs/Memorial/`).
    var syncToReminders: Bool
    /// File name of the portrait in the app container; `nil` until the portrait feature lands.
    var portraitFileName: String?
}

/// The next time an entry's giỗ falls, relative to a given "now".
struct ILMemorialNextAnniversary: Equatable {
    /// Start of the solar day of the next giỗ (today counts).
    let date: Date
    /// 0 = today.
    let daysUntil: Int
    /// Which giỗ this is (1 = giỗ đầu, 2 = giỗ hết, n ≥ 3 = lần thứ n); `nil` when the death year
    /// is unknown or the result is below 1.
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
