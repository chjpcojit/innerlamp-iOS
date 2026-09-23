//
//  ILOtpRepository.swift
//  InnerLamp
//

import Foundation

/// Domain-layer contract for the OTP feature's two server calls.
///
/// Entity in / Entity out (String inputs stand in for the two request scalars). No `ILOtpDTO` may
/// appear in this file or anywhere else under `Domain/`; no `NetworkError` may cross this line
/// either — the implementation maps it to `ILOtpError`.
nonisolated protocol ILOtpRepository {

    /// Verifies `code` for `phoneNumber` and returns the account's first session.
    func verifyRegistrationOTP(phoneNumber: String, code: String) async throws -> ILAuthSessionEntity

    /// Reissues a registration OTP for `phoneNumber` and returns the new delivery timing.
    func resendRegistrationOTP(phoneNumber: String) async throws -> ILOtpTimingEntity
}
