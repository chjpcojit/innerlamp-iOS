//
//  SecurityEvent.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Vocabulary cố định, không mở rộng theo feature — đây là danh sách tín hiệu tấn công
/// mà security team định nghĩa, khác với `FlowType`/`BreadcrumbCategory` vốn open-ended.
public enum SecurityEvent: String, Codable {
    case jailbreakDetected        = "jailbreak_detected"
    case debuggerAttached         = "debugger_attached"
    case fridaDetected            = "frida_detected"
    case certificatePinningFailed = "cert_pinning_failed"
    case emulatorDetected         = "emulator_detected"
}
