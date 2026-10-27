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

    /// EN: Verifies `code` for the pending registration of `email` and returns the account's first session.
    /// VI: Xác minh `code` cho đăng ký đang chờ của `email` và trả về phiên đầu tiên của tài khoản.
    func verifyRegistrationOTP(email: String, code: String) async throws -> ILAuthSessionEntity

    /// EN: Reissues the registration code for `email` and returns the new delivery timing.
    /// VI: Gửi lại mã đăng ký cho `email` và trả về timing mới.
    func resendRegistrationOTP(email: String) async throws -> ILOtpTimingEntity
}
