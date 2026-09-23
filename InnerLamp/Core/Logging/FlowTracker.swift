//
//  FlowTracker.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Nhóm 4 — Flow Tracking.
/// correlationId được sinh khi `startFlow` và giao cho `CorrelationContext` — nơi duy nhất
/// quản lý header `X-Correlation-ID`/`X-Session-ID` cho mọi HTTP request (xem `Endpoint`).
public final class FlowTracker: FlowTracking {
    public static let shared = FlowTracker(transport: MockLogTransport.shared)

    private let transport: LogTransport
    private let queue = DispatchQueue(label: "com.innerlamp.flowtracker")
    private var activeFlow: ActiveFlow?

    public init(transport: LogTransport) {
        self.transport = transport
    }

    public var currentCorrelationId: String? {
        CorrelationContext.shared.currentCorrelationId
    }

    public func startFlow(_ type: FlowType) {
        queue.async { [weak self] in
            guard let self else { return }
            if self.activeFlow != nil {
                self.finishLocked(outcome: .abandoned)
            }
            let correlationId = CorrelationContext.shared.generateCorrelationId()
            self.activeFlow = ActiveFlow(type: type, correlationId: correlationId)
        }
    }

    public func enterStep(_ step: FlowStep) {
        queue.async { [weak self] in
            self?.activeFlow?.enter(step)
        }
    }

    public func completeStep(_ step: FlowStep, metadata: [String: String]?) {
        queue.async { [weak self] in
            self?.activeFlow?.complete(step, metadata: metadata)
        }
    }

    public func failStep(_ step: FlowStep, reason: String, metadata: [String: String]?) {
        queue.async { [weak self] in
            self?.activeFlow?.fail(step, reason: reason, metadata: metadata)
        }
    }

    public func endFlow(outcome: FlowOutcome) {
        queue.async { [weak self] in
            self?.finishLocked(outcome: outcome)
        }
    }

    /// Phải gọi trong `queue`. Gửi payload rồi clear correlationId — flow đã đóng.
    private func finishLocked(outcome: FlowOutcome) {
        guard let flow = activeFlow else { return }
        activeFlow = nil
        transport.send(destination: .analyticsServer, payload: flow.makePayload(outcome: outcome))
        CorrelationContext.shared.clearCorrelationId()
    }
}

/// State nội bộ của một flow đang chạy. Không thread-safe riêng — luôn được truy cập
/// từ bên trong `FlowTracker.queue`.
private final class ActiveFlow {
    let type: FlowType
    let correlationId: String
    let flowId = UUID().uuidString
    let startedAt = Date()

    private var steps: [FlowStepRecord] = []
    private var currentStep: FlowStep?
    private var currentStepStartedAt: Date?

    init(type: FlowType, correlationId: String) {
        self.type = type
        self.correlationId = correlationId
    }

    func enter(_ step: FlowStep) {
        currentStep = step
        currentStepStartedAt = Date()
    }

    func complete(_ step: FlowStep, metadata: [String: String]?) {
        record(step, status: .completed, metadata: metadata)
    }

    func fail(_ step: FlowStep, reason: String, metadata: [String: String]?) {
        record(step, status: .failed, failureReason: reason, metadata: metadata)
    }

    func makePayload(outcome: FlowOutcome) -> FlowPayload {
        let totalDuration = Int(Date().timeIntervalSince(startedAt) * 1000)
        return FlowPayload(
            flowId: flowId,
            flowType: type.rawValue,
            correlationId: correlationId,
            sessionId: CorrelationContext.shared.currentSessionId,
            outcome: outcome,
            totalDurationMs: totalDuration,
            steps: steps
        )
    }

    private func record(_ step: FlowStep, status: StepStatus, failureReason: String? = nil, metadata: [String: String]?) {
        let startedAt = (currentStep == step) ? currentStepStartedAt ?? Date() : Date()
        let duration = Int(Date().timeIntervalSince(startedAt) * 1000)
        steps.append(FlowStepRecord(step: step, status: status, durationMs: duration, failureReason: failureReason, metadata: metadata))
        currentStep = nil
        currentStepStartedAt = nil
    }
}
