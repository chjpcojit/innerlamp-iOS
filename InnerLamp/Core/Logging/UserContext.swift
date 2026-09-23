//
//  UserContext.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

public struct UserContext: Codable, Equatable {
    public let sessionId: String
    public let deviceTier: String
    public let appVersion: String
    
    public init(
        sessionId: String,
        deviceTier: String,
        appVersion: String
    ) {
        self.sessionId = sessionId
        self.deviceTier = deviceTier
        self.appVersion = appVersion
    }
}
