//
//  ILMemorialMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for 1 memorial book entry.
///
/// `@objc(ILMemorialMO)` must match `representedClassName` of the `Memorial` entity in
/// `InnerLamp 4.xcdatamodel` (a mismatch fails when the store is opened, not at compile time).
///
/// Core Data has no optionals for scalars or enums, so: `relationship` / `calendarKind` hold the
/// raw strings of `ILMemorialRelationship` / `ILMemorialCalendarKind`; `deathYear == 0` means
/// unknown; `reminderLeadDays == -1` means reminders are off. The mapping to and from
/// `ILMemorialEntity` lives in `ILMemorialLocalDataSourceImpl` and this type never leaves
/// `Data/DataSources/Local/`.
@objc(ILMemorialMO)
nonisolated final class ILMemorialMO: NSManagedObject {

    static let entityName = "Memorial"

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var relationship: String
    @NSManaged var calendarKind: String
    @NSManaged var day: Int16
    @NSManaged var month: Int16
    @NSManaged var deathYear: Int32
    @NSManaged var note: String
    @NSManaged var reminderLeadDays: Int16
    @NSManaged var reminderHour: Int16
    @NSManaged var reminderMinute: Int16
    @NSManaged var syncToReminders: Bool
    @NSManaged var portraitFileName: String?
}
