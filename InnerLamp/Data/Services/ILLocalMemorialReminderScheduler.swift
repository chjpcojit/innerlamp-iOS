//
//  ILLocalMemorialReminderScheduler.swift
//  InnerLamp
//

import Foundation
import UserNotifications

/// Interim local delivery of memorial reminders (D1). It exists because the backend does not have
/// Phase 8–10 (server planning + push) yet; the UI and the use case only know
/// `ILMemorialReminderScheduling`.
///
/// Limits that are accepted and tracked in `TD-MEM-CLIENT-01`/`-03`: no sync across devices, one
/// device = one reminder, 60 pending notifications at most, and the device's local time zone.
actor ILLocalMemorialReminderScheduler: ILMemorialReminderScheduling {

    static let categoryIdentifier = "memorial"
    static let entryIDKey = "entryId"
    private static let deliveredKeysDefaultsKey = "memorial.reminder.deliveredKeys"
    private static let requestedAuthorizationDefaultsKey = "memorial.reminder.authorizationRequested"
    private static let identifierPrefix = "memorial."

    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    func sync(entries: [ILMemorialEntity], now: Date) async {
        await removePending(where: { $0.identifier.hasPrefix(Self.identifierPrefix) })
        let plans = ILMemorialReminderPlanner.plans(
            entries: entries,
            now: now,
            deliveredKeys: deliveredKeys()
        )
        await add(plans)
    }

    func reschedule(entry: ILMemorialEntity, now: Date) async {
        await cancel(entryID: entry.id)
        let plans = ILMemorialReminderPlanner.plans(
            entries: [entry],
            now: now,
            deliveredKeys: deliveredKeys()
        )
        await add(plans)
    }

    func cancel(entryID: String) async {
        let prefix = "\(Self.identifierPrefix)\(entryID)."
        await removePending(where: { $0.identifier.hasPrefix(prefix) })
    }

    func cancelAll() async {
        await removePending(where: { $0.identifier.hasPrefix(Self.identifierPrefix) })
        defaults.removeObject(forKey: Self.deliveredKeysDefaultsKey)
        defaults.removeObject(forKey: Self.requestedAuthorizationDefaultsKey)
    }

    func isNotificationAuthorizationDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    // MARK: - Content

    /// EN: The lock-screen payload holds the entry id only — no name, date, note or photo URL
    /// (NFR-MEM-02, G1 item 5).
    /// VI: Payload màn hình khoá chỉ có entry id — không tên, ngày, ghi chú hay URL ảnh.
    nonisolated static func makeContent(for plan: ILMemorialReminderPlan) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "memorial.notification.title".localized
        content.body = plan.body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = [entryIDKey: plan.entryID]
        return content
    }

    // MARK: - Helpers

    private func deliveredKeys() -> Set<String> {
        Set(defaults.stringArray(forKey: Self.deliveredKeysDefaultsKey) ?? [])
    }

    private func add(_ plans: [ILMemorialReminderPlan]) async {
        guard !plans.isEmpty else { return }
        await requestAuthorizationIfNeeded()

        var scheduledKeys = deliveredKeys()
        for plan in plans {
            let content = Self.makeContent(for: plan)
            let components = Calendar(identifier: .gregorian).dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: plan.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: plan.identifier,
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
                // EN: Every accepted plan is remembered, not only a catch-up: after the scheduled
                // notification fires, a rebuild on the same day must not fire the same giỗ again.
                // VI: Ghi nhớ mọi plan đã được nhận, không chỉ nhắc bù: sau khi nhắc đã hẹn bắn, dựng
                // lại plan trong cùng ngày không được bắn lại cùng một kỳ giỗ.
                scheduledKeys.insert(plan.deliveredKey)
            } catch {
                // A failed schedule is not worth failing the load for; the next app open retries.
                // EN: no PII in a log line — the identifier is the only thing worth keeping.
                // VI: log không có PII — chỉ giữ identifier.
                _ = error
            }
        }
        // Keep the last 100 keys; a stale key is harmless but unbounded growth is not.
        defaults.set(Array(scheduledKeys.sorted().suffix(100)), forKey: Self.deliveredKeysDefaultsKey)
    }

    private func requestAuthorizationIfNeeded() async {
        guard !defaults.bool(forKey: Self.requestedAuthorizationDefaultsKey) else { return }
        defaults.set(true, forKey: Self.requestedAuthorizationDefaultsKey)
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    private func removePending(where predicate: (UNNotificationRequest) -> Bool) async {
        let identifiers = await center.pendingNotificationRequests()
            .filter(predicate)
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
