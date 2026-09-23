//
//  DeviceTier.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Phân loại thiết bị theo cấu hình phần cứng — dùng cho session context (Nhóm 3)
/// và user context (Nhóm 1). Không bao giờ log model máy cụ thể, chỉ log tier.
public enum DeviceTier: String {
    case high
    case mid
    case low

    /// Ước lượng tier dựa trên số nhân CPU khả dụng — heuristic đơn giản, đủ dùng cho phân tích metrics.
    public static var current: DeviceTier {
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        switch coreCount {
        case ..<4: return .low
        case 4...5: return .mid
        default: return .high
        }
    }
}

public enum AppVersionProvider {
    public static var current: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(shortVersion) (\(build))"
    }
}

public enum OSVersionProvider {
    public static var current: String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
}
