//
//  MetricsCollector.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation
import Network
#if canImport(UIKit)
import UIKit
#endif

/// Nhóm 3 — Metrics.
/// Batch push — tích lũy trong buffer, đẩy khi đạt queue size, time interval, app
/// background, hoặc khi có Wi-Fi + không Low Power Mode.
public final class MetricsCollector: MetricsCollecting {
    public static let shared = MetricsCollector(transport: MockLogTransport.shared)

    private let transport: LogTransport
    private let queue = DispatchQueue(label: "com.innerlamp.metricscollector")
    private let maxQueueSize = 50
    private let flushInterval: TimeInterval = 5 * 60

    private var buffer: [MetricRecord] = []
    private var timer: Timer?
    private let pathMonitor = NWPathMonitor()
    private var isOnWifi = false
    private var backgroundObserver: NSObjectProtocol?

    public init(transport: LogTransport) {
        self.transport = transport
        startPathMonitoring()
        startTimer()
        observeAppLifecycle()
    }

    deinit {
        timer?.invalidate()
        pathMonitor.cancel()
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }

    public func record(_ name: String, value: Double, unit: String, tags: [String: String]) {
        enqueue(MetricRecord(name: name, kind: .gauge, value: value, unit: unit, tags: tags, timestamp: Date().timeIntervalSince1970))
    }

    public func record(_ name: String, tags: [String: String]) {
        enqueue(MetricRecord(name: name, kind: .gauge, value: nil, unit: nil, tags: tags, timestamp: Date().timeIntervalSince1970))
    }

    public func count(_ name: String, tags: [String: String]) {
        enqueue(MetricRecord(name: name, kind: .counter, value: 1, unit: nil, tags: tags, timestamp: Date().timeIntervalSince1970))
    }

    public func flush() {
        queue.async { [weak self] in
            self?.flushLocked(reason: "manual")
        }
    }

    // MARK: - Private

    private func enqueue(_ record: MetricRecord) {
        queue.async { [weak self] in
            guard let self else { return }
            self.buffer.append(record)
            if self.buffer.count >= self.maxQueueSize {
                self.flushLocked(reason: "queue_size")
            }
        }
    }

    private func flushLocked(reason: String) {
        guard !buffer.isEmpty else { return }
        // Chỉ đẩy khi Wi-Fi + không Low Power Mode — trừ khi app sắp vào background,
        // lúc đó network condition không còn quan trọng bằng việc không mất dữ liệu.
        let isBackgroundFlush = reason == "app_background"
        guard isBackgroundFlush || (isOnWifi && !ProcessInfo.processInfo.isLowPowerModeEnabled) else {
            return
        }

        let batch = buffer
        buffer.removeAll()
        transport.send(destination: .metricsServer, payload: batch)
    }

    private func startPathMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.queue.async {
                self?.isOnWifi = path.usesInterfaceType(.wifi)
            }
        }
        pathMonitor.start(queue: queue)
    }

    private func startTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.queue.async { self?.flushLocked(reason: "time_interval") }
            }
        }
    }

    private func observeAppLifecycle() {
        #if canImport(UIKit)
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.queue.async { self?.flushLocked(reason: "app_background") }
        }
        #endif
    }
}
