//
//  BreadcrumbCategory.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

public struct BreadcrumbCategory: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    // Common standard categories
    public static let navigation: BreadcrumbCategory = "navigation"
    public static let ui: BreadcrumbCategory = "ui"
    public static let http: BreadcrumbCategory = "http"
    public static let transfer: BreadcrumbCategory = "transfer"
    public static let auth: BreadcrumbCategory = "auth"
    public static let system: BreadcrumbCategory = "system"
    public static let business: BreadcrumbCategory = "business"
}
