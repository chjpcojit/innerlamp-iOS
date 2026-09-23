//
//  ThemeService.swift
//  InnerLamp
//
//  Created by ChjpCoj on 13/9/26.
//

import UIKit

/// 3 lựa chọn giao diện — khớp state `theme` (0/1/2) trong design handoff
/// (màn `lang`: Sáng / Tối / Theo máy).
enum ILThemeMode: Int, Codable, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

protocol ThemeService {
    var currentMode: ILThemeMode { get }
    /// Lưu lựa chọn và áp ngay lên window đang giữ (nếu `apply(to:)` đã gọi trước đó).
    func setMode(_ mode: ILThemeMode)
    /// Gọi một lần lúc tạo window (SceneDelegate) và mỗi khi `setMode` đổi lựa chọn.
    func apply(to window: UIWindow?)
}

/// `.system` để `overrideUserInterfaceStyle = .unspecified` — window tự đọc theo
/// `UITraitCollection` hệ thống, không cần lắng nghe `prefers-color-scheme` thủ công.
final class ThemeServiceImpl: ThemeService {
    static let shared = ThemeServiceImpl()

    private let userDefaultsService: UserDefaultsService
    private weak var window: UIWindow?

    private enum StorageKeys {
        static let mode = "il_theme_mode"
    }

    private(set) var currentMode: ILThemeMode

    init(userDefaultsService: UserDefaultsService = UserDefaultsServiceImpl()) {
        self.userDefaultsService = userDefaultsService
        self.currentMode = userDefaultsService.load(key: StorageKeys.mode, type: ILThemeMode.self) ?? .system
    }

    func setMode(_ mode: ILThemeMode) {
        currentMode = mode
        userDefaultsService.save(key: StorageKeys.mode, value: mode)
        window?.overrideUserInterfaceStyle = mode.userInterfaceStyle
    }

    func apply(to window: UIWindow?) {
        self.window = window
        window?.overrideUserInterfaceStyle = currentMode.userInterfaceStyle
    }
}
