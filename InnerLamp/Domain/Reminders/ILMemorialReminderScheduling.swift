//
//  ILMemorialReminderScheduling.swift
//  InnerLamp
//

import Foundation

/// Port for the interim local reminder delivery (D1). When the backend plans and pushes reminders
/// (Phase 10), swap the implementation in `DIContainer` for `ILNoopMemorialReminderScheduler`; the
/// use case, ViewModel and UI stay untouched.
nonisolated protocol ILMemorialReminderScheduling {

    /// Replaces every pending memorial reminder with the plan for `entries` (app open).
    func sync(entries: [ILMemorialEntity], now: Date) async

    /// Replaces only one entry's reminders (after a save), leaving the other entries' pending
    /// notifications untouched.
    func reschedule(entry: ILMemorialEntity, now: Date) async

    /// Cancels the reminders of one entry, e.g. after a delete.
    func cancel(entryID: String) async

    /// Cancels every memorial reminder and forgets the delivered keys (sign-out).
    func cancelAll() async

    /// `true` when the system permission is denied. The UI keeps showing "Có nhắc" (the setting is
    /// the account's) and offers "Mở Cài đặt" instead.
    func isNotificationAuthorizationDenied() async -> Bool
}

/// Cutover implementation (D1 B3). One line in `DIContainer` selects it once the server sends
/// reminders; the first launch must still `cancelAll()` the plan the previous build scheduled.
nonisolated final class ILNoopMemorialReminderScheduler: ILMemorialReminderScheduling {
    func sync(entries: [ILMemorialEntity], now: Date) async {}
    func reschedule(entry: ILMemorialEntity, now: Date) async {}
    func cancel(entryID: String) async {}
    func cancelAll() async {}
    func isNotificationAuthorizationDenied() async -> Bool { false }
}
