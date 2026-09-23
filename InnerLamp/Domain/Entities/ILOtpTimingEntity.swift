//
//  ILOtpTimingEntity.swift
//  InnerLamp
//

import Foundation

/// OTP-delivery timing returned by the server (`expires_in_seconds` / `resend_after_seconds`) —
/// Domain layer only.
///
/// Drives the OTP screen's countdown and its "code expires in …" copy, replacing the fixed values
/// the design handoff used (47s / "10 phút"). See `Docs/Specs/Otp/design.md`.
struct ILOtpTimingEntity: Equatable {
    /// How long the code stays valid.
    var expiresInSeconds: Int = 0
    /// How long before another code may be requested.
    var resendAfterSeconds: Int = 0

    static let empty = ILOtpTimingEntity()
}
