//
//  FlowModels.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Loại flow nghiệp vụ. Core không biết trước các flow cụ thể của app —
/// mỗi feature tự khai báo giá trị riêng, giống cách `BreadcrumbCategory` hoạt động.
/// Ví dụ: `extension FlowType { static let onboarding: FlowType = "onboarding" }`
public struct FlowType: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// Một bước trong flow. Cũng open-ended như `FlowType` — feature tự khai báo step của mình.
public struct FlowStep: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// Trạng thái vòng đời cố định của một bước — không phụ thuộc feature nào.
public enum StepStatus: String, Codable {
    case entered
    case completed
    case failed
    case abandoned
}

/// Kết quả cuối cùng của một flow — cố định, giống nhau cho mọi feature.
public enum FlowOutcome: String, Codable {
    case success
    case failed
    case abandoned
    case timeout
}

/// Bản ghi một bước đã xảy ra trong flow, sẵn sàng serialize vào payload.
public struct FlowStepRecord: Codable {
    public let step: String
    public let status: StepStatus
    public let durationMs: Int
    public let failureReason: String?
    public let metadata: [String: String]?

    public init(
        step: FlowStep,
        status: StepStatus,
        durationMs: Int,
        failureReason: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.step = step.rawValue
        self.status = status
        self.durationMs = durationMs
        self.failureReason = failureReason
        self.metadata = metadata
    }
}

/// Payload hoàn chỉnh gửi lên Analytics server khi flow kết thúc — một lần duy nhất.
public struct FlowPayload: Codable {
    public let flowId: String
    public let flowType: String
    public let correlationId: String
    public let sessionId: String
    public let outcome: FlowOutcome
    public let totalDurationMs: Int
    public let steps: [FlowStepRecord]
}
