//
//  LoggingService.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// `nonisolated` — business code gọi thẳng từ actor context (ví dụ `NetworkServiceImpl`,
/// một actor, ghi log một request vừa xong) chứ không chỉ từ UI. Target bật
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` nên nếu không opt out tường minh thì mọi
/// requirement ở đây bị MainActor-isolated ngầm, và call site nonisolated sẽ không gọi được.
/// Implementation vì thế cũng phải `nonisolated` — xem `SentryLoggingService`.
nonisolated public protocol LoggingService: AnyObject {
    func breadcrumb(category: BreadcrumbCategory, message: String, data: [String: Any]?)
    func log(level: LogLevel, message: String, metadata: [String: Any]?)
    func setUserContext(_ context: UserContext)
    func clearUserContext()
}

nonisolated public extension LoggingService {
    func breadcrumb(category: BreadcrumbCategory, message: String) {
        breadcrumb(category: category, message: message, data: nil)
    }
    
    func log(level: LogLevel, message: String) {
        log(level: level, message: message, metadata: nil)
    }
}
