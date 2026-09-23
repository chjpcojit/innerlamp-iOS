//
//  FlowTracking.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Nhóm 4 — Flow Tracking.
/// Ghi nhận hành trình user qua nhiều bước của một flow nghiệp vụ. Không stream từng
/// event lên server — tích lũy trong memory, gửi một payload duy nhất khi flow kết thúc.
public protocol FlowTracking: AnyObject {
    /// correlationId của flow đang active — dùng để đính vào HTTP header (`X-Correlation-ID`).
    /// `nil` khi không có flow nào đang chạy.
    var currentCorrelationId: String? { get }

    func startFlow(_ type: FlowType)
    func enterStep(_ step: FlowStep)
    func completeStep(_ step: FlowStep, metadata: [String: String]?)
    func failStep(_ step: FlowStep, reason: String, metadata: [String: String]?)
    func endFlow(outcome: FlowOutcome)
}

public extension FlowTracking {
    func completeStep(_ step: FlowStep) {
        completeStep(step, metadata: nil)
    }

    func failStep(_ step: FlowStep, reason: String) {
        failStep(step, reason: reason, metadata: nil)
    }
}
