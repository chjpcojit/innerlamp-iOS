//
//  ILMemorialNotificationRouter.swift
//  InnerLamp
//

import UIKit
import UserNotifications

/// Entry point for a memorial local notification (D1). Owns the `UNUserNotificationCenter`
/// delegate, the `memorial` category and the re-plan on app-active / time-zone change; opening a
/// notification pushes the same `ILMemorialCoordinator` the Home link uses, with the tapped entry.
///
/// Why the top-most navigation controller: a notification can arrive while any tab or a modal is
/// on screen, and there is no app-wide deep-link router yet. The lookup is the smallest thing that
/// works without adding one; the memorial flow itself still goes through its coordinator.
@MainActor
final class ILMemorialNotificationRouter: NSObject {

    static let shared = ILMemorialNotificationRouter()

    private weak var container: DIContainer?
    private var activeCoordinator: ILMemorialCoordinator?
    private var observers: [NSObjectProtocol] = []
    /// Set when a notification arrives before the main area exists (cold start on the auth screen).
    private var pendingEntryID: String?

    private override init() {
        super.init()
    }

    func start(container: DIContainer) {
        self.container = container

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(identifier: ILLocalMemorialReminderScheduler.categoryIdentifier, actions: [], intentIdentifiers: [])
        ])

        if observers.isEmpty {
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in self?.rescheduleFromCache() }
                }
            )
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
                ) { [weak self] _ in
                    Task { @MainActor in self?.rescheduleFromCache() }
                }
            )
        }
        rescheduleFromCache()
    }

    /// Rebuilds the pending local plan from the offline copy only — no network call on every
    /// foreground, and a deleted cache simply means "nothing to schedule".
    func rescheduleFromCache() {
        guard let container else { return }
        if let pendingEntryID, Self.topNavigationController() != nil {
            self.pendingEntryID = nil
            open(entryID: pendingEntryID)
        }
        let localDataSource = container.memorialLocalDataSource
        Task {
            guard let entries = try? await localDataSource.fetchAll(), !entries.isEmpty else { return }
            await container.makeMemorialReminderScheduler().sync(entries: entries, now: Date())
        }
    }

    func open(entryID: String) {
        // EN: A notification tapped before sign-in must not push the book onto the auth stack.
        // VI: Nhắc bấm trước khi đăng nhập không được đẩy sổ giỗ lên stack đăng nhập.
        guard Self.mainTabBarController() != nil else {
            pendingEntryID = entryID
            return
        }
        guard let container, let navigationController = Self.topNavigationController() else {
            pendingEntryID = entryID
            return
        }
        let coordinator = container.makeMemorialCoordinator(
            navigationController: navigationController,
            initialEntryID: entryID
        )
        activeCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - Lookup

    private static func mainTabBarController() -> ILMainTabBarController? {
        mainRootViewController() as? ILMainTabBarController
            ?? (mainRootViewController() as? UINavigationController)?
                .viewControllers.compactMap { $0 as? ILMainTabBarController }.first
    }

    private static func mainRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private static func topNavigationController() -> UINavigationController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        return root.flatMap(navigationController(in:))
    }

    private static func navigationController(in viewController: UIViewController) -> UINavigationController? {
        if let presented = viewController.presentedViewController {
            return navigationController(in: presented)
        }
        if let tabBar = viewController as? UITabBarController {
            // Home is the memorial entry point; its nav stack is the one the Home link uses.
            tabBar.selectedIndex = 0
            guard let selected = tabBar.selectedViewController else { return nil }
            return navigationController(in: selected)
        }
        if let navigation = viewController as? UINavigationController {
            if let top = navigation.topViewController, top !== navigation {
                if let nested = navigationController(in: top) { return nested }
            }
            return navigation
        }
        return viewController.navigationController
    }
}

extension ILMemorialNotificationRouter: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let entryID = userInfo[ILLocalMemorialReminderScheduler.entryIDKey] as? String,
           response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                Self.shared.open(entryID: entryID)
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
}
