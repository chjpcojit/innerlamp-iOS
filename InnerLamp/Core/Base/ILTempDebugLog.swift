//
//  ILTempDebugLog.swift
//  InnerLamp
//
//  TEMPORARY debugging helper — remove before finishing.
//

import Foundation

func ilDebugLog(_ message: String) {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("il_debug.log")
    let line = "\(Date().timeIntervalSince1970) \(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    if let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    } else {
        try? data.write(to: url)
    }
}
