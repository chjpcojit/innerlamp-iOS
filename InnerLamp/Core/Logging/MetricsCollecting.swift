//
//  MetricsCollecting.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Loại record — phân biệt "con số tại một thời điểm" (gauge) và "đếm số lần xảy ra" (counter).
public enum MetricKind: String, Codable {
    case gauge
    case counter
}

/// Một record metric duy nhất, tích lũy trong buffer trước khi batch push.
public struct MetricRecord: Codable {
    public let name: String
    public let kind: MetricKind
    public let value: Double?
    public let unit: String?
    public let tags: [String: String]
    public let timestamp: TimeInterval
}

/// Nhóm 3 — Metrics.
/// Đo sức khỏe app và hành vi sử dụng ở cấp độ tổng thể — value/unit/tags, không phải
/// narrative event như Logs. Đẩy theo batch, không real-time.
public protocol MetricsCollecting: AnyObject {
    /// Ghi một con số tại một thời điểm (performance, timing...).
    func record(_ name: String, value: Double, unit: String, tags: [String: String])

    /// Ghi một event không kèm giá trị số (session context, feature adoption dạng "đã xảy ra").
    func record(_ name: String, tags: [String: String])

    /// Đếm số lần một sự kiện xảy ra (feature adoption, non-fatal error...).
    func count(_ name: String, tags: [String: String])

    /// Ép flush buffer ngay lập tức, bỏ qua các trigger thông thường.
    func flush()
}

public extension MetricsCollecting {
    func record(_ name: String, value: Double, unit: String) {
        record(name, value: value, unit: unit, tags: [:])
    }

    func record(_ name: String) {
        record(name, tags: [:])
    }

    func count(_ name: String) {
        count(name, tags: [:])
    }
}
