//
//  ILSessionDataCleaner.swift
//  InnerLamp
//

import Foundation

/// Removes the data stored on this device that belongs to the signed-in account, so the next
/// account that signs in on the same device cannot read it. Shared catalog caches (temples,
/// deities, sutra quotes, Buddhist-event templates) are not account data and are kept.
nonisolated protocol ILSessionDataCleaner {
    func clearUserScopedData() async throws
}
