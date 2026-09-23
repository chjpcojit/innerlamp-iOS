//
//  LogLevel.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

public enum LogLevel: String, Codable, CaseIterable, Comparable {
    case debug
    case info
    case warning
    case error
    case fatal
    
    private var severity: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .fatal: return 4
        }
    }
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.severity < rhs.severity
    }
}
