//
//  AppDelegate.swift
//  InnerLamp
//
//  Created by ChjpCoj on 9/9/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        bootstrapLogging()
        bootstrapLocalization()
        return true
    }

    // MARK: - Localization bootstrap

    /// Kiểm tra version file ngôn ngữ trên server, tải bản mới nếu có — chạy nền,
    /// không chặn launch. App vẫn dùng ngay file cache/bundled hiện có trong lúc chờ.
    private func bootstrapLocalization() {
        Task {
            await LocalizationServiceImpl.shared.syncRemoteIfNeeded()
        }
    }

    // MARK: - Logging bootstrap

    private func bootstrapLogging() {
        SentryLoggingService.shared.start()

        let userContext = UserContext(
            sessionId: CorrelationContext.shared.currentSessionId,
            deviceTier: DeviceTier.current.rawValue,
            appVersion: AppVersionProvider.current
        )
        SentryLoggingService.shared.setUserContext(userContext)

        MetricsCollector.shared.record("session.started", tags: [
            "os_version": OSVersionProvider.current,
            "device_tier": DeviceTier.current.rawValue,
            "app_version": AppVersionProvider.current
        ])
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

