//
//  ILMemorialMO.swift
//  InnerLamp
//

import CoreData

/// Core Data storage type for 1 memorial book entry.
///
/// EN: `@objc(ILMemorialMO)` must match `representedClassName` of the `Memorial` entity in
/// `InnerLamp 7.xcdatamodel` (a mismatch fails when the store is opened, not at compile time).
/// VI: `@objc(ILMemorialMO)` phải khớp `representedClassName` của entity `Memorial` trong
/// `InnerLamp 7.xcdatamodel` (lệch nhau sẽ lỗi lúc mở store, không phải lúc biên dịch).
///
/// Core Data has no optionals for scalars or enums, so: `relationship` / `calendarKind` hold the
/// raw strings of `ILMemorialRelationship` / `ILMemorialCalendarKind`; `deathYear == 0` means
/// unknown; `reminderLeadDays == -1` means reminders are off. The photo is **not** stored at all
/// (D8) — only the server response carries its signed URL. The mapping to and from
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
    @NSManaged var deathLeapMonth: Bool
    @NSManaged var note: String
    /// EN: Server user id that owns this cached row. Never empty for a row written by this build;
    /// rows migrated from model 5 have `""` until the first purge.
    /// VI: Id user trên server sở hữu dòng cache này. Không bao giờ rỗng với dòng do bản này ghi;
    /// dòng migrate từ model 5 có `""` cho tới lần purge đầu tiên.
    @NSManaged var ownerAccountID: String
    @NSManaged var reminderLeadDays: Int16
    @NSManaged var reminderHour: Int16
    @NSManaged var reminderMinute: Int16
}
